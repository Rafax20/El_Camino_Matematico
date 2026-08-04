# res://Escenas/Minijuegos/MinijuegoAsteroides.gd
extends Node2D

signal minijuego_finalizado(es_correcto)

@export var escena_objeto: PackedScene # Asigna ObjetoFlotante.tscn en el inspector

@onready var label_pregunta = $CanvasLayer/LabelPregunta
@onready var timer_spawn: Timer = $CanvasLayer/Timer if has_node("CanvasLayer/Timer") else $Timer
@onready var Fondo = $CanvasLayer

var texturas_tableros = {
	"colegio": preload("res://assets/Imagenes/globo_tablero1.png"),
	"espacio": preload("res://assets/Imagenes/asteroide_tablero2.png")
}

var tema_actual: String
var respuesta_correcta: int = 0
var juego_activo: bool = false

func iniciar_minijuego(datos_pregunta: Dictionary, tema: String):
	Fondo.visible = true
	tema_actual = tema
	
	# 🛡️ Garantizamos la referencia al Timer
	if not timer_spawn:
		timer_spawn = get_node_or_null("CanvasLayer/Timer")
		if not timer_spawn:
			timer_spawn = get_node_or_null("Timer")
		
	if not label_pregunta:
		label_pregunta = $CanvasLayer/LabelPregunta
	
	# 📝 1. EXTRAER 'operacion' DE TU TABLA DE SUPABASE
	var texto = datos_pregunta.get("operacion", datos_pregunta.get("pregunta", "2 más 2"))
	if label_pregunta:
		label_pregunta.text = str(texto)
		
	# 🎯 2. EXTRAER 'respuesta_correcta' DE TU TABLA DE SUPABASE
	var raw_respuesta = datos_pregunta.get("respuesta_correcta", 4)
	respuesta_correcta = int(raw_respuesta)
	
	print("🎮 MINIJUEGO CARGADO DE SUPABASE -> Operación: '", texto, "' | Respuesta Correcta: ", respuesta_correcta)
	
	juego_activo = true
	visible = true
	
	if timer_spawn:
		timer_spawn.start()
	else:
		push_error("❌ No se encontró el nodo Timer en la escena.")

func _on_timer_spawn_timeout():
	if not juego_activo or not escena_objeto: return
	
	var nuevo_objeto = escena_objeto.instantiate()
	
	var numero_a_mostrar: int
	# 30% de probabilidad de mostrar la respuesta correcta
	if randf() < 0.3:
		numero_a_mostrar = respuesta_correcta
	else:
		# Genera un distractor cercano (ej. entre -4 y +5 de la respuesta real)
		var desvio = randi_range(-4, 5)
		if desvio == 0: desvio = 1 # Evitamos que coincida con la correcta
		
		numero_a_mostrar = respuesta_correcta + desvio
		
		# Aseguramos que no genere números negativos en operaciones de primaria
		if numero_a_mostrar < 0:
			numero_a_mostrar = respuesta_correcta + randi_range(1, 6)

	# Posición horizontal aleatoria
	var x_pos = randf_range(150, 1000)
	nuevo_objeto.position = Vector2(x_pos, 680)
	
	nuevo_objeto.objeto_tocado.connect(_on_objeto_tocado)
	
	if $CanvasLayer:
		$CanvasLayer/ContenedorAsteroides.add_child(nuevo_objeto)
	else:
		add_child(nuevo_objeto)
	
	var textura_a_usar = texturas_tableros.get(tema_actual)
	nuevo_objeto.configurar(numero_a_mostrar, textura_a_usar, randf_range(120.0, 180.0), tema_actual)

func _on_objeto_tocado(valor_tocado: int):
	if not juego_activo: return
	
	if valor_tocado == respuesta_correcta:
		print("🎉 ¡Respuesta CORRECTA tocada!")
		juego_activo = false
		if timer_spawn: timer_spawn.stop()
		
		# Limpiamos los objetos/globos flotantes que hayan quedado en pantalla
		for hijo in get_children():
			if hijo is Area2D: 
				hijo.queue_free()
			
		visible = false
		minijuego_finalizado.emit(true) # 👈 Notifica a Tablero.gd que se superó el minijuego
		await get_tree().create_timer(2.0).timeout
		Fondo.visible = false
	else:
		print("❌ Tocó el número ", valor_tocado, " pero se esperaba ", respuesta_correcta)
		# El objeto se destruye solo en su propio script, así que el juego continúa
