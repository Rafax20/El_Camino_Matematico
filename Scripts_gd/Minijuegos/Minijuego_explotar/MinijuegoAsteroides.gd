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
	# Fácil (Dificultad 0)
	{"operacion": "5 x 5", "respuesta_correcta": "25", "dificultad": 0},
	{"operacion": "4 x 9", "respuesta_correcta": "36", "dificultad": 0},
	{"operacion": "15 + 24", "respuesta_correcta": "39", "dificultad": 0},
	{"operacion": "30 - 12", "respuesta_correcta": "18", "dificultad": 0},
	{"operacion": "6 x 7", "respuesta_correcta": "42", "dificultad": 0},
	{"operacion": "48 / 6", "respuesta_correcta": "8", "dificultad": 0},
	{"operacion": "50 + 35", "respuesta_correcta": "85", "dificultad": 0},
	# Media (Dificultad 1)
	{"operacion": "120 + 65", "respuesta_correcta": "185", "dificultad": 1},
	{"operacion": "150 - 45", "respuesta_correcta": "105", "dificultad": 1},
	{"operacion": "12 x 6", "respuesta_correcta": "72", "dificultad": 1},
	{"operacion": "81 / 9", "respuesta_correcta": "9", "dificultad": 1},
	{"operacion": "210 + 140", "respuesta_correcta": "350", "dificultad": 1},
	{"operacion": "200 - 75", "respuesta_correcta": "125", "dificultad": 1},
	{"operacion": "14 x 4", "respuesta_correcta": "56", "dificultad": 1},
	# Difícil (Dificultad 2)
	{"operacion": "250 + 175", "respuesta_correcta": "425", "dificultad": 2},
	{"operacion": "300 - 135", "respuesta_correcta": "165", "dificultad": 2},
	{"operacion": "16 x 5", "respuesta_correcta": "80", "dificultad": 2},
	{"operacion": "144 / 12", "respuesta_correcta": "12", "dificultad": 2},
	{"operacion": "350 + 250", "respuesta_correcta": "600", "dificultad": 2},
	{"operacion": "500 - 225", "respuesta_correcta": "275", "dificultad": 2},
	{"operacion": "25 x 4", "respuesta_correcta": "100", "dificultad": 2},
]

var tiempo_inicio_pregunta: float = 0.0
var tema_actual: String
var respuesta_correcta: int = 0
var juego_activo: bool = false
var vidas_actuales: int = 3
var pregunta_actual: Dictionary = {}

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
	
	_mostrar_banner_instrucciones("Haz clic o toca sobre el asteroide con el resultado correcto.", "Asteroide")
	_cargar_siguiente_pregunta()

func _mostrar_banner_instrucciones(texto: String, audio_nombre: String = "Asteroide"):
	if not Fondo: return
	var banner_previo = Fondo.get_node_or_null("BannerInstrucciones")
	if banner_previo:
		banner_previo.queue_free()
		
	var panel = PanelContainer.new()
	panel.name = "BannerInstrucciones"
	panel.anchors_preset = Control.PRESET_CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -360.0
	panel.offset_right = 360.0
	panel.offset_top = 85.0
	panel.offset_bottom = 125.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.z_index = 20
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.16, 0.90)
	style.border_color = Color(0.2, 0.75, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.75))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	if ResourceLoader.exists("res://Fuentes/Fredoka/static/Fredoka-Bold.ttf"):
		label.add_theme_font_override("font", load("res://Fuentes/Fredoka/static/Fredoka-Bold.ttf"))
		
	panel.add_child(label)
	Fondo.add_child(panel)
	
	# Reproducción de voz opcional (segura, no detiene el juego si no existe)
	if audio_nombre != "" and GestionAudio:
		GestionAudio.reproducir_audio_local(audio_nombre)
	
	# Animación: Aparece -> Espera 3.5s -> Desaparece
	panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5)
	tw.tween_callback(panel.queue_free)

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
	pregunta_actual = datos_pregunta
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
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE (Registra TODAS las respuestas)
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, es_correcto, tiempo_tardado)
	
	if es_correcto:
		if timer_spawn: timer_spawn.stop()
		_limpiar_asteroides_pantalla()
		
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
