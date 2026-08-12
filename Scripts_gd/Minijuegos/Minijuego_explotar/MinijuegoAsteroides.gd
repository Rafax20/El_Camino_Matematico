# res://Escenas/Minijuegos/MinijuegoAsteroides.gd
extends Node2D

signal minijuego_finalizado(es_correcto)

@export var escena_objeto: PackedScene # Asigna ObjetoFlotante.tscn en el inspector

@onready var label_pregunta = $CanvasLayer/LabelPregunta
@onready var timer_spawn: Timer = $CanvasLayer/Timer if has_node("CanvasLayer/Timer") else $Timer
@onready var Fondo = $CanvasLayer
@onready var contenedor_corazones = $CanvasLayer/ContenedorCorazones

# 💖 Texturas de corazones (Asegúrate de colocar las rutas correctas de tus imágenes)
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

var texturas_tableros = {
	"colegio": preload("res://assets/Minijuegos/minijuego Explotar/globo_tablero1.png"),
	"espacio": preload("res://assets/Minijuegos/minijuego Explotar/asteroide_tablero2.png")
}

var tiempo_inicio_asteroide: float = 0.0
var tema_actual: String
var respuesta_correcta: int = 0
var juego_activo: bool = false
var vidas_actuales: int = 3

func iniciar_minijuego(datos_pregunta: Dictionary, tema: String):
	Fondo.visible = true
	tema_actual = tema
	vidas_actuales = 3
	
	# ⏱️ 1. Registrar inicio
	tiempo_inicio_asteroide = Time.get_ticks_msec()
	
	_actualizar_interfaz_corazones()
	
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
	
	if $CanvasLayer/ContenedorAsteroides:
		$CanvasLayer/ContenedorAsteroides.add_child(nuevo_objeto)
	else:
		add_child(nuevo_objeto)
	
	var textura_a_usar = texturas_tableros.get(tema_actual)
	nuevo_objeto.configurar(numero_a_mostrar, textura_a_usar, randf_range(120.0, 180.0), tema_actual)

func _on_objeto_tocado(valor_tocado: int):
	if not juego_activo: return
	
	if valor_tocado == respuesta_correcta:
		var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_asteroide) / 1000.0
		
		# 🧠 Evaluar acierto rápido
		DatosUsuario.dificultad_actual = SistemaExperto.evaluar_desempeno(
			DatosUsuario.dificultad_actual, 
			true, 
			tiempo_tardado
		)
		print("🎉 Correcto en asteroides. Nueva dificultad: ", DatosUsuario.dificultad_actual)
		_finalizar_juego(true)
		
	else:
		print("❌ Tocó el número ", valor_tocado, " pero se esperaba ", respuesta_correcta)
		vidas_actuales -= 1
		_actualizar_interfaz_corazones()
		
		if vidas_actuales <= 0:
			var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_asteroide) / 1000.0
			
			# 🧠 Evaluar fallo al agotar vidas
			DatosUsuario.dificultad_actual = SistemaExperto.evaluar_desempeno(
				DatosUsuario.dificultad_actual, 
				false, 
				tiempo_tardado
			)
			_finalizar_juego(false)

# 💖 Actualiza los 3 sprites de corazón en el HBoxContainer
func _actualizar_interfaz_corazones():
	if not contenedor_corazones: return
	
	print("CANTIDAD DE VIDAS RESTANTES: ", vidas_actuales)
	var corazones = contenedor_corazones.get_children()
	for i in range(corazones.size()):
		if corazones[i] is TextureRect:
			# Reseteamos el color original
			corazones[i].modulate = Color.WHITE
			
			
			if i < vidas_actuales:
				if textura_corazon_lleno:
					corazones[i].texture = textura_corazon_lleno
			else:
				if textura_corazon_vacio:
					corazones[i].texture = textura_corazon_vacio
				else:
					# Si no hay textura vacía asignada, lo oscurece como respaldo
					corazones[i].modulate = Color(0.2, 0.2, 0.2, 0.4)

func _finalizar_juego(es_exito: bool):
	juego_activo = false
	if timer_spawn: timer_spawn.stop()
	
	# Limpiamos los objetos/globos flotantes que hayan quedado en pantalla
	if $CanvasLayer/ContenedorAsteroides:
		for hijo in $CanvasLayer/ContenedorAsteroides.get_children():
			hijo.queue_free()
			
	for hijo in get_children():
		if hijo is Area2D: 
			hijo.queue_free()
		
	visible = false
	minijuego_finalizado.emit(es_exito) # 👈 Notifica true si ganó o false si perdió todas las vidas
	await get_tree().create_timer(2.0).timeout
	Fondo.visible = false
