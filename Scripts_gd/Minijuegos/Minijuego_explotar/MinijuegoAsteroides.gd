# res://Escenas/Minijuegos/MinijuegoAsteroides.gd
extends Node2D

signal minijuego_finalizado(es_correcto)

@export var escena_objeto: PackedScene # Asigna ObjetoFlotante.tscn en el inspector

@onready var label_pregunta = $CanvasLayer/LabelPregunta
@onready var timer_spawn: Timer = $CanvasLayer/Timer if has_node("CanvasLayer/Timer") else $Timer
@onready var Fondo = $CanvasLayer
@onready var contenedor_corazones = $CanvasLayer/ContenedorCorazones
@onready var label_aciertos = $CanvasLayer/LabelAciertos

# 💖 Texturas de corazones
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

var texturas_tableros = {
	"colegio": preload("res://assets/Minijuegos/minijuego Explotar/globo_tablero1.png"),
	"espacio": preload("res://assets/Minijuegos/minijuego Explotar/asteroide_tablero2.png")
}

# --- ESTADO Y REGLAS DEL JUEGO ---
var tiempo_inicio_pregunta: float = 0.0
var tema_actual: String
var respuesta_correcta: int = 0
var juego_activo: bool = false
var vidas_actuales: int = 3

var aciertos_actuales: int = 0
var META_ACIERTOS: int = 5

var cola_preguntas: Array = []

func _ready():
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func iniciar_minijuego(tema: String = "espacio"):
	Fondo.visible = true
	tema_actual = tema
	vidas_actuales = 3
	aciertos_actuales = 0
	
	# 🎯 Cargar y filtrar preguntas directamente desde DatosUsuario
	_recargar_cola_preguntas()
	
	_actualizar_interfaz_corazones()
	_actualizar_ui_aciertos()
	
	if not timer_spawn:
		timer_spawn = get_node_or_null("CanvasLayer/Timer") if has_node("CanvasLayer/Timer") else get_node_or_null("Timer")
		
	if not label_pregunta:
		label_pregunta = $CanvasLayer/LabelPregunta

	juego_activo = true
	visible = true
	
	_cargar_siguiente_pregunta()

func _recargar_cola_preguntas():
	cola_preguntas.clear()
	var banco = DatosUsuario.banco_preguntas
	var dif = DatosUsuario.dificultad_actual
	
	# Filtramos por la dificultad actual del usuario
	for preg in banco:
		if int(preg.get("dificultad", 0)) == dif:
			cola_preguntas.append(preg)
			
	# Si no hay preguntas de esa dificultad en RAM, usamos todo el banco
	if cola_preguntas.size() == 0:
		cola_preguntas = banco.duplicate()
		
	cola_preguntas.shuffle()

func _cargar_siguiente_pregunta():
	if cola_preguntas.size() == 0:
		_recargar_cola_preguntas()
		if cola_preguntas.size() == 0:
			print("❌ No hay preguntas cargadas en DatosUsuario.banco_preguntas")
			return

	_limpiar_asteroides_pantalla()

	# Extraemos la pregunta actual (sin repetirla)
	var datos_pregunta = cola_preguntas.pop_front()

	var texto = datos_pregunta.get("operacion", datos_pregunta.get("pregunta", "2 más 2"))
	if label_pregunta:
		label_pregunta.text = str(texto)
		
	var raw_respuesta = datos_pregunta.get("respuesta_correcta", 4)
	respuesta_correcta = int(raw_respuesta)
	
	print("🎮 NUEVA PREGUNTA -> Operación: '", texto, "' | Respuesta: ", respuesta_correcta)
	
	tiempo_inicio_pregunta = Time.get_ticks_msec()
	
	if timer_spawn:
		timer_spawn.start()

func _on_timer_spawn_timeout():
	if not juego_activo or not escena_objeto: return
	
	var nuevo_objeto = escena_objeto.instantiate()
	var numero_a_mostrar: int
	
	if randf() < 0.3:
		numero_a_mostrar = respuesta_correcta
	else:
		var desvio = randi_range(-4, 5)
		if desvio == 0: desvio = 1
		numero_a_mostrar = respuesta_correcta + desvio
		if numero_a_mostrar < 0:
			numero_a_mostrar = respuesta_correcta + randi_range(1, 6)

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
	
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_pregunta) / 1000.0
	
	if valor_tocado == respuesta_correcta:
		aciertos_actuales += 1
		_actualizar_ui_aciertos()
		
		# 🧠 Evaluar desempeño en el Sistema Experto
		var dif_anterior = DatosUsuario.dificultad_actual
		var nueva_dif = SistemaExperto.evaluar_desempeno(dif_anterior, true, tiempo_tardado)
		DatosUsuario.dificultad_actual = nueva_dif
		
		print("🎉 Acierto ", aciertos_actuales, "/", META_ACIERTOS, ". Tiempo: ", tiempo_tardado, "s | Dificultad actual: ", nueva_dif)
		
		if aciertos_actuales >= META_ACIERTOS:
			_finalizar_juego(true)
		else:
			# Si el Sistema Experto cambió la dificultad, refrescamos la cola
			if nueva_dif != dif_anterior:
				_recargar_cola_preguntas()
			_cargar_siguiente_pregunta()
		
	else:
		print("❌ Tocó ", valor_tocado, " pero se esperaba ", respuesta_correcta)
		vidas_actuales -= 1
		_actualizar_interfaz_corazones()
		
		var nueva_dif = SistemaExperto.evaluar_desempeno(DatosUsuario.dificultad_actual, false, tiempo_tardado)
		DatosUsuario.dificultad_actual = nueva_dif
		
		if vidas_actuales <= 0:
			_finalizar_juego(false)

func _actualizar_ui_aciertos():
	if label_aciertos:
		label_aciertos.text = "Aciertos: " + str(aciertos_actuales) + "/" + str(META_ACIERTOS)

func _actualizar_interfaz_corazones():
	if not contenedor_corazones: return
	var corazones = contenedor_corazones.get_children()
	for i in range(corazones.size()):
		if corazones[i] is TextureRect:
			corazones[i].modulate = Color.WHITE
			if i < vidas_actuales:
				if textura_corazon_lleno: corazones[i].texture = textura_corazon_lleno
			else:
				if textura_corazon_vacio: corazones[i].texture = textura_corazon_vacio
				else: corazones[i].modulate = Color(0.2, 0.2, 0.2, 0.4)

func _limpiar_asteroides_pantalla():
	if $CanvasLayer/ContenedorAsteroides:
		for hijo in $CanvasLayer/ContenedorAsteroides.get_children():
			hijo.queue_free()
	for hijo in get_children():
		if hijo is Area2D: 
			hijo.queue_free()

func _finalizar_juego(es_exito: bool):
	juego_activo = false
	if timer_spawn: timer_spawn.stop()
	_limpiar_asteroides_pantalla()
	visible = false
	minijuego_finalizado.emit(es_exito)
	await get_tree().create_timer(2.0).timeout
	Fondo.visible = false
