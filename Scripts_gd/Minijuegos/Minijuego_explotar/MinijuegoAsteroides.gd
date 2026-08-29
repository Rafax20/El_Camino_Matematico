# res://Escenas/Minijuegos/MinijuegoAsteroides.gd
extends Node2D

signal minijuego_finalizado(es_correcto)

@export var escena_objeto: PackedScene
@export var sonido_tecleo: AudioStream # Asigna el efecto de sonido .wav / .mp3 en el inspector

@onready var pantalla_operacion = $CanvasLayer/PantallaOperacion
@onready var label_pregunta = $CanvasLayer/PantallaOperacion/LabelPregunta
@onready var audio_player = $AudioStreamPlayer
@onready var timer_spawn: Timer = $CanvasLayer/Timer if has_node("CanvasLayer/Timer") else $Timer
@onready var Fondo = $CanvasLayer
@onready var contenedor_corazones = $CanvasLayer/ContenedorCorazones
@onready var label_aciertos = $CanvasLayer/LabelAciertos
@onready var pizarra_borrador = $CanvasLayer/PizarraBorrador if has_node("CanvasLayer/PizarraBorrador") else null

var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

var texturas_tableros = {
	"colegio": preload("res://assets/Minijuegos/minijuego Explotar/globo_tablero1.png"),
	"espacio": preload("res://assets/Minijuegos/minijuego Explotar/asteroide_tablero2.png")
}

var banco_respaldo = [
	{"operacion": "5 por 5", "respuesta_correcta": "25"},
	{"operacion": "4 por 9", "respuesta_correcta": "36"},
	{"operacion": "15 mas 4", "respuesta_correcta": "19"},
	{"operacion": "20 mas 7", "respuesta_correcta": "27"},
]

var tiempo_inicio_pregunta: float = 0.0
var tema_actual: String
var respuesta_correcta: int = 0
var juego_activo: bool = false
var vidas_actuales: int = 3

var aciertos_actuales: int = 0
var META_ACIERTOS: int = 5

var cola_preguntas: Array = []

func _ready():
	Fondo.visible = false
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func iniciar_minijuego(tema: String = "espacio"):
	Fondo.visible = true
	tema_actual = tema
	vidas_actuales = 3
	aciertos_actuales = 0
	
	_recargar_cola_preguntas()
	_actualizar_interfaz_corazones()
	_actualizar_ui_aciertos()
	
	juego_activo = true
	visible = true
	
	_cargar_siguiente_pregunta()

func _recargar_cola_preguntas():
	cola_preguntas.clear()
	var banco
	if DatosUsuario.banco_preguntas.size() > 0:
		banco = DatosUsuario.banco_preguntas
	else:
		banco = banco_respaldo
	var dif = DatosUsuario.dificultad_actual
	
	for preg in banco:
		if int(preg.get("dificultad", 0)) == dif:
			cola_preguntas.append(preg)
			
	if cola_preguntas.size() == 0:
		cola_preguntas = banco.duplicate()
		
	cola_preguntas.shuffle()

func _formatear_operacion(texto_raw: String) -> String:
	var texto_limpio = texto_raw.to_lower()
	texto_limpio = texto_limpio.replace(" por ", " x ")
	texto_limpio = texto_limpio.replace(" mas ", " + ")
	texto_limpio = texto_limpio.replace(" más ", " + ")
	texto_limpio = texto_limpio.replace(" menos ", " - ")
	texto_limpio = texto_limpio.replace(" dividido en ", " ÷ ")
	
	if not texto_limpio.ends_with("="):
		texto_limpio += " = ?"
		
	return texto_limpio.to_upper()

func _cargar_siguiente_pregunta():
	if cola_preguntas.size() == 0:
		_recargar_cola_preguntas()
		if cola_preguntas.size() == 0:
			print("❌ No hay preguntas cargadas en DatosUsuario.banco_preguntas")
			return

	_limpiar_asteroides_pantalla()

	var datos_pregunta = cola_preguntas.pop_front()
	var texto_raw = datos_pregunta.get("operacion", datos_pregunta.get("pregunta", "2 mas 2"))
	var texto_formateado = _formatear_operacion(texto_raw)
	
	var raw_respuesta = datos_pregunta.get("respuesta_correcta", 4)
	respuesta_correcta = int(raw_respuesta)
	
	print("🎮 NUEVA PREGUNTA -> Operación: '", texto_formateado, "' | Respuesta: ", respuesta_correcta)
	
	# Ejecutamos la animación visual y sonora
	animar_aparicion_operacion(texto_formateado)
	
	tiempo_inicio_pregunta = Time.get_ticks_msec()
	
	if timer_spawn:
		timer_spawn.start()

func animar_aparicion_operacion(texto_operacion: String):
	label_pregunta.text = texto_operacion
	label_pregunta.visible_characters = 0
	
	# Solo ocultamos la pantalla con transparencia (sin alterar escala ni posición)
	pantalla_operacion.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(false)
	
	# Paso 1: Aparecer suavemente con Fade In
	tween.tween_property(pantalla_operacion, "modulate:a", 1.0, 0.25)
	
	# Paso 2: Escritura carácter por carácter con sonido
	var total_caracteres = label_pregunta.get_total_character_count()
	
	for i in range(1, total_caracteres + 1):
		tween.tween_property(label_pregunta, "visible_characters", i, 0.04)
		tween.tween_callback(_reproducir_sonido_tecleo)

func _reproducir_sonido_tecleo():
	if audio_player:
		if sonido_tecleo and audio_player.stream != sonido_tecleo:
			audio_player.stream = sonido_tecleo
		if audio_player.stream:
			# Modulación ligera de pitch para varianza realista
			audio_player.pitch_scale = randf_range(0.95, 1.05)
			audio_player.play()

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
	var es_correcto = (valor_tocado == respuesta_correcta)
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, es_correcto, tiempo_tardado)
	
	if es_correcto:
		aciertos_actuales += 1
		GestionAudio.reproducir_audio_local("Minijuegos/Minijuego_explotar/" + ["Correcto_1", "Correcto_2", "Correcto_3"].pick_random())
		_actualizar_ui_aciertos()
		
		var dif_anterior = DatosUsuario.dificultad_actual
		var nueva_dif = SistemaExperto.evaluar_desempeno(dif_anterior, true, tiempo_tardado)
		DatosUsuario.dificultad_actual = nueva_dif
		
		if aciertos_actuales >= META_ACIERTOS:
			_finalizar_juego(true)
		else:
			if nueva_dif != dif_anterior:
				_recargar_cola_preguntas()
			_cargar_siguiente_pregunta()
	else:
		vidas_actuales -= 1
		GestionAudio.reproducir_audio_local("Minijuegos/Minijuego_explotar/" + ["Incorrecto_1", "Incorrecto_2", "Incorrecto_3"].pick_random())
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
	if pizarra_borrador and pizarra_borrador.has_method("ocultar_pizarra"):
		pizarra_borrador.ocultar_pizarra()
	visible = false
	minijuego_finalizado.emit(es_exito)
	await get_tree().create_timer(2.0).timeout
	Fondo.visible = false
	

func AbrirCerrar_Pizarra():
	if pizarra_borrador and pizarra_borrador.has_method("toggle_pizarra"):
		#if esta_expandido:
			#minimizar_panel()
		pizarra_borrador.toggle_pizarra()
		pizarra_borrador.z_index = 20
