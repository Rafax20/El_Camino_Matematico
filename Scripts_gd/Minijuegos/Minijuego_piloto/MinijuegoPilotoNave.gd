# res://Scripts_gd/Minijuegos/Minijuego_piloto/MinijuegoPilotoNave.gd
class_name MinijuegoPilotoNave
extends Control

## Minijuego: Pilotaje de Cabina Espacial (Bifurcación de Caminos)
## El estudiante pilotea una nave espacial viendo desde la perspectiva de la cabina.
## Aparece una pregunta matemática en el HUD y 2 portales/aros hiperespaciales.
## Debe elegir el camino correcto 5 veces seguidas para completar el minijuego.

signal minijuego_finalizado(es_correcto: bool)

# --- TEXTURAS & RECURSOS ---
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

# --- ESTADO Y VARIABLES ---
var vidas_actuales: int = 3
var aciertos_actuales: int = 0
var META_ACIERTOS: int = 5
var juego_activo: bool = false
var animando_transicion: bool = false
var tiempo_inicio_pregunta: float = 0.0

var pregunta_actual: Dictionary = {}
var opcion_izquierda: String = ""
var opcion_derecha: String = ""
var respuesta_correcta_lado: String = "" # "izquierda" o "derecha"

# --- BANCO DE PREGUNTAS (Adaptado a 4to Grado con 3 Niveles de Dificultad) ---
var banco_preguntas: Array = [
	# Nivel Fácil (Dificultad 0)
	{"operacion": "40 ÷ 5", "correcta": 8, "distractores": [6, 10, 7], "dificultad": 0},
	{"operacion": "45 - 15", "correcta": 30, "distractores": [25, 35, 40], "dificultad": 0},
	{"operacion": "15 + 25", "correcta": 40, "distractores": [35, 50, 45], "dificultad": 0},
	{"operacion": "7 × 6", "correcta": 42, "distractores": [48, 36, 40], "dificultad": 0},
	{"operacion": "22 + 18", "correcta": 40, "distractores": [38, 42, 30], "dificultad": 0},
	{"operacion": "56 - 24", "correcta": 32, "distractores": [28, 34, 30], "dificultad": 0},
	{"operacion": "8 × 5", "correcta": 40, "distractores": [35, 45, 48], "dificultad": 0},
	{"operacion": "63 ÷ 7", "correcta": 9, "distractores": [8, 7, 6], "dificultad": 0},
	
	# Nivel Medio (Dificultad 1)
	{"operacion": "130 + 85", "correcta": 215, "distractores": [205, 225, 195], "dificultad": 1},
	{"operacion": "180 - 65", "correcta": 115, "distractores": [125, 105, 110], "dificultad": 1},
	{"operacion": "13 × 4", "correcta": 52, "distractores": [48, 56, 62], "dificultad": 1},
	{"operacion": "72 ÷ 8", "correcta": 9, "distractores": [8, 6, 12], "dificultad": 1},
	{"operacion": "215 + 130", "correcta": 345, "distractores": [335, 355, 325], "dificultad": 1},
	{"operacion": "250 - 95", "correcta": 155, "distractores": [145, 165, 150], "dificultad": 1},
	{"operacion": "11 × 6", "correcta": 66, "distractores": [56, 76, 60], "dificultad": 1},
	
	# Nivel Difícil (Dificultad 2)
	{"operacion": "240 + 175", "correcta": 415, "distractores": [405, 425, 395], "dificultad": 2},
	{"operacion": "320 - 145", "correcta": 175, "distractores": [165, 185, 195], "dificultad": 2},
	{"operacion": "18 × 5", "correcta": 90, "distractores": [85, 95, 100], "dificultad": 2},
	{"operacion": "144 ÷ 12", "correcta": 12, "distractores": [14, 10, 16], "dificultad": 2},
	{"operacion": "367 + 258", "correcta": 625, "distractores": [615, 635, 605], "dificultad": 2},
	{"operacion": "500 - 213", "correcta": 287, "distractores": [277, 297, 267], "dificultad": 2},
	{"operacion": "24 × 3", "correcta": 72, "distractores": [68, 76, 82], "dificultad": 2}
]

# --- NODOS UI ---
@onready var canvas_ui: CanvasLayer = $CanvasUI
@onready var contenedor_corazones: HBoxContainer = $CanvasUI/BarraSuperior/Corazones
@onready var label_aciertos: Label = $CanvasUI/BarraSuperior/LabelAciertos
@onready var label_dificultad: Label = $CanvasUI/BarraSuperior/LabelDificultad

@onready var label_pregunta: Label = $CanvasUI/HUD_Cabina/PanelOperacion/LabelOperacion
@onready var btn_camino_izq: TextureButton = $CanvasUI/EspacioVisor/BtnCaminoIzquierdo
@onready var btn_camino_der: TextureButton = $CanvasUI/EspacioVisor/BtnCaminoDerecho

@onready var label_val_izq: Label = $CanvasUI/EspacioVisor/BtnCaminoIzquierdo/LabelValor
@onready var label_val_der: Label = $CanvasUI/EspacioVisor/BtnCaminoDerecho/LabelValor

@onready var panel_resultado: PanelContainer = $CanvasUI/PanelResultado
@onready var lbl_res_titulo: Label = $CanvasUI/PanelResultado/VBox/LabelTitulo
@onready var lbl_res_desc: Label = $CanvasUI/PanelResultado/VBox/LabelMensaje
@onready var btn_res_continuar: Button = $CanvasUI/PanelResultado/VBox/BtnContinuar

@onready var visor_cabina: Control = $CanvasUI/EspacioVisor
@onready var flash_retroalimentacion: ColorRect = $CanvasUI/FlashEFX

var pizarra_borrador: Control = null
var btn_pizarra: TextureButton = null
var escena_pizarra = preload("res://Escenas/Minijuegos/PizarraBorrador.tscn")
var tex_cuaderno = preload("res://assets/Minijuegos/minijuego Laboratorio/Cuaderno.png")

func _ready():
	visible = false
	if canvas_ui: canvas_ui.visible = false
	if panel_resultado: panel_resultado.visible = false
	if flash_retroalimentacion: flash_retroalimentacion.visible = false
	
	if escena_pizarra and canvas_ui:
		pizarra_borrador = escena_pizarra.instantiate()
		pizarra_borrador.name = "PizarraBorrador"
		pizarra_borrador.visible = false
		pizarra_borrador.z_index = 30
		canvas_ui.add_child(pizarra_borrador)
		
	if canvas_ui:
		btn_pizarra = TextureButton.new()
		btn_pizarra.name = "BotonPizarra"
		btn_pizarra.texture_normal = tex_cuaderno
		btn_pizarra.custom_minimum_size = Vector2(85, 85)
		btn_pizarra.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		btn_pizarra.anchor_left = 1.0
		btn_pizarra.anchor_right = 1.0
		btn_pizarra.anchor_top = 0.5
		btn_pizarra.anchor_bottom = 0.5
		btn_pizarra.offset_left = -115.0
		btn_pizarra.offset_right = -20.0
		btn_pizarra.offset_top = 35.0
		btn_pizarra.offset_bottom = 130.0
		btn_pizarra.ignore_texture_size = true
		btn_pizarra.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn_pizarra.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_pizarra.pressed.connect(AbrirCerrar_Pizarra)
		canvas_ui.add_child(btn_pizarra)
	
	if btn_camino_izq: 
		btn_camino_izq.pressed.connect(func(): _on_camino_seleccionado("izquierda"))
	if btn_camino_der: 
		btn_camino_der.pressed.connect(func(): _on_camino_seleccionado("derecha"))
	if btn_res_continuar: 
		btn_res_continuar.pressed.connect(_on_btn_continuar_pressed)
	
	# Solo se inicia automáticamente si se ejecuta como escena independiente de prueba
	if get_tree() and get_tree().current_scene == self:
		iniciar_minijuego()

func AbrirCerrar_Pizarra():
	if pizarra_borrador and pizarra_borrador.has_method("toggle_pizarra"):
		pizarra_borrador.toggle_pizarra()
		pizarra_borrador.z_index = 30

func _input(event):
	if not visible or not juego_activo or animando_transicion: return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_LEFT or event.keycode == KEY_A or event.is_action_pressed("ui_left"):
			_on_camino_seleccionado("izquierda")
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D or event.is_action_pressed("ui_right"):
			_on_camino_seleccionado("derecha")

func iniciar_minijuego():
	visible = true
	if canvas_ui: canvas_ui.visible = true
	
	vidas_actuales = 3
	aciertos_actuales = 0
	juego_activo = true
	animando_transicion = false
	
	if panel_resultado: panel_resultado.visible = false
	_actualizar_corazones()
	_actualizar_aciertos()
	_mostrar_banner_instrucciones("Calcula la operacion y elige el portal con la respuesta correcta.")
	_cargar_siguiente_pregunta()

func _mostrar_banner_instrucciones(texto: String, audio_nombre: String = "Instrucciones/como_jugar_piloto"):
	if not canvas_ui: return
	var banner_previo = canvas_ui.get_node_or_null("BannerInstrucciones")
	if banner_previo:
		banner_previo.queue_free()
		
	var panel = PanelContainer.new()
	panel.name = "BannerInstrucciones"
	panel.anchors_preset = Control.PRESET_CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -370.0
	panel.offset_right = 370.0
	panel.offset_top = 80.0
	panel.offset_bottom = 120.0
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
	canvas_ui.add_child(panel)
	
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

func _actualizar_corazones():
	if not contenedor_corazones: return
	for i in range(contenedor_corazones.get_child_count()):
		var img_corazon = contenedor_corazones.get_child(i) as TextureRect
		if img_corazon:
			if i < vidas_actuales:
				img_corazon.texture = textura_corazon_lleno
			else:
				img_corazon.texture = textura_corazon_vacio

func _actualizar_aciertos():
	if label_aciertos:
		label_aciertos.text = "PROGRESO: %d / %d" % [aciertos_actuales, META_ACIERTOS]
	if label_dificultad:
		var dif_val = DatosUsuario.dificultad_actual if DatosUsuario else 0
		var dif_nombre = "FÁCIL"
		if dif_val == 1: dif_nombre = "MEDIO"
		elif dif_val == 2: dif_nombre = "DIFÍCIL"
		label_dificultad.text = "NIVEL: %s" % dif_nombre

func _cargar_siguiente_pregunta():
	animando_transicion = false
	tiempo_inicio_pregunta = Time.get_ticks_msec()
	_actualizar_aciertos()
	_actualizar_corazones()
	
	var dif_val = DatosUsuario.dificultad_actual if DatosUsuario else 0
	var preg_filtradas = banco_preguntas.filter(func(p):
		return int(p.get("dificultad", 0)) == dif_val
	)
	if preg_filtradas.is_empty():
		preg_filtradas = banco_preguntas
		
	pregunta_actual = preg_filtradas.pick_random()
	var op_str = str(pregunta_actual.get("operacion", "2 + 2"))
	var val_correcta = str(pregunta_actual.get("correcta", 4))
	
	var arr_distractores = pregunta_actual.get("distractores", [3, 5])
	var val_distractor = str(arr_distractores.pick_random())
	
	if randf() < 0.5:
		opcion_izquierda = val_correcta
		opcion_derecha = val_distractor
		respuesta_correcta_lado = "izquierda"
	else:
		opcion_izquierda = val_distractor
		opcion_derecha = val_correcta
		respuesta_correcta_lado = "derecha"
		
	if label_pregunta:
		label_pregunta.text = "%s = ?" % op_str
	if label_val_izq:
		label_val_izq.text = "[ %s ]" % opcion_izquierda
	if label_val_der:
		label_val_der.text = "[ %s ]" % opcion_derecha

func _on_camino_seleccionado(lado: String):
	if not juego_activo or animando_transicion: return
	animando_transicion = true
	
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_pregunta) / 1000.0
	var es_correcto = (lado == respuesta_correcta_lado)
	
	# Registro en Supabase
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, es_correcto, tiempo_tardado)
		
	var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
	if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
		var nueva_dif = SistemaExperto.evaluar_desempeno(dif_ant, es_correcto, tiempo_tardado)
		if DatosUsuario: DatosUsuario.dificultad_actual = nueva_dif
	
	if es_correcto:
		aciertos_actuales += 1
		_actualizar_aciertos()
		_animar_efecto_correcto(lado)
	else:
		vidas_actuales -= 1
		_actualizar_aciertos()
		_actualizar_corazones()
		_animar_efecto_error(lado)

func _animar_efecto_correcto(lado: String):
	GestionAudio.reproducir_audio_local("Elogios/" + ["elogio1", "elogio2", "elogio3"].pick_random())
	
	if flash_retroalimentacion:
		flash_retroalimentacion.color = Color(0.1, 0.9, 0.4, 0.35)
		flash_retroalimentacion.visible = true
		
	var tw = create_tween().set_parallel(true)
	var btn_elegido = btn_camino_izq if lado == "izquierda" else btn_camino_der
	if btn_elegido:
		tw.tween_property(btn_elegido, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK)
		
	if visor_cabina:
		var dir_offset = Vector2(-70, 0) if lado == "izquierda" else Vector2(70, 0)
		tw.tween_property(visor_cabina, "position", visor_cabina.position + dir_offset, 0.3).set_trans(Tween.TRANS_QUAD)
		
	await get_tree().create_timer(0.4).timeout
	
	if flash_retroalimentacion: flash_retroalimentacion.visible = false
	
	if btn_elegido: btn_elegido.scale = Vector2.ONE
	if visor_cabina: visor_cabina.position = Vector2.ZERO
		
	if aciertos_actuales >= META_ACIERTOS:
		_finalizar_minijuego(true)
	else:
		_cargar_siguiente_pregunta()

func _animar_efecto_error(_lado: String):
	GestionAudio.reproducir_audio_local("Animos/" + ["animo1", "animo2", "animo3"].pick_random())
	
	if flash_retroalimentacion:
		flash_retroalimentacion.color = Color(0.9, 0.1, 0.2, 0.45)
		flash_retroalimentacion.visible = true
		
	var tw = create_tween()
	if visor_cabina:
		for i in range(4):
			var shake_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			tw.tween_property(visor_cabina, "position", shake_offset, 0.06)
		tw.tween_property(visor_cabina, "position", Vector2.ZERO, 0.06)
		
	await tw.finished
	if flash_retroalimentacion: flash_retroalimentacion.visible = false
	
	if vidas_actuales <= 0:
		_finalizar_minijuego(false)
	else:
		_cargar_siguiente_pregunta()

func _finalizar_minijuego(victoria: bool):
	juego_activo = false
	if pizarra_borrador: pizarra_borrador.visible = false
	if panel_resultado:
		panel_resultado.visible = true
		if victoria:
			lbl_res_titulo.text = "¡NAVEGACIÓN ESPACIAL EXITOSA!"
			lbl_res_titulo.modulate = Color("#fde047")
			lbl_res_desc.text = "¡Has seleccionado los caminos correctos y completado los 5 saltos estelares!"
			btn_res_continuar.text = "Continuar Aventura"
		else:
			lbl_res_titulo.text = "¡ESCUDOS AGOTADOS!"
			lbl_res_titulo.modulate = Color("#ef4444")
			lbl_res_desc.text = "La nave sufrió demasiados impactos por elegir los caminos erróneos."
			btn_res_continuar.text = "Reintentar"

func _on_btn_continuar_pressed():
	var gano = (aciertos_actuales >= META_ACIERTOS)
	if gano:
		visible = false
		if canvas_ui: canvas_ui.visible = false
		minijuego_finalizado.emit(true)
	else:
		iniciar_minijuego()
