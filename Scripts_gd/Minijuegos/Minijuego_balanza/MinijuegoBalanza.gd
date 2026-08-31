# res://Scripts_gd/Minijuegos/Minijuego_balanza/MinijuegoBalanza.gd
class_name MinijuegoBalanza
extends Control

## Minijuego: Balanzador de Energía Espacial (Steampunk)
## Se muestra una balanza mecánica con una bombona/cápsula de gas que contiene
## una operación matemática en pantalla digital y platillos de energía cian y roja.
## El niño debe presionar el botón arcade correcto para equilibrar la balanza.

signal minijuego_finalizado(es_correcto: bool)

# --- TEXTURAS ---
var Fondo_Tex: Texture2D = null
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

# Colores de los 4 botones arcade inferiores (como en el ejemplo)
var paleta_botones: Array[Dictionary] = [
	{ "base": Color("#a7f3d0"), "borde": Color("#059669"), "texto": Color("#064e3b"), "glow": Color(0.2, 0.8, 0.5, 0.4) }, # Verde Menta
	{ "base": Color("#bae6fd"), "borde": Color("#0284c7"), "texto": Color("#0c4a6e"), "glow": Color(0.2, 0.6, 0.9, 0.4) }, # Azul Cielo
	{ "base": Color("#fef08a"), "borde": Color("#ca8a04"), "texto": Color("#713f12"), "glow": Color(0.9, 0.7, 0.1, 0.4) }, # Amarillo Oro
	{ "base": Color("#fecaca"), "borde": Color("#dc2626"), "texto": Color("#7f1d1d"), "glow": Color(0.9, 0.3, 0.3, 0.4) }  # Rojo Coral
]

# --- ESTADO DEL JUEGO ---
var vidas_actuales: int = 3
var aciertos_actuales: int = 0
var META_ACIERTOS: int = 5
var juego_activo: bool = false
var tiempo_inicio_pregunta: float = 0.0
var respuesta_correcta: int = 0
var pregunta_actual: Dictionary = {}
var cola_preguntas: Array = []

# --- BANCO DE RESPALDO (4to Grado) ---
var banco_respaldo: Array = [
	# Fácil
	{"operacion": "25 + 34", "respuesta_correcta": "59", "dificultad": 0},
	{"operacion": "60 - 25", "respuesta_correcta": "35", "dificultad": 0},
	{"operacion": "6 x 7", "respuesta_correcta": "42", "dificultad": 0},
	{"operacion": "36 / 6", "respuesta_correcta": "6", "dificultad": 0},
	{"operacion": "18 + 27", "respuesta_correcta": "45", "dificultad": 0},
	{"operacion": "55 - 30", "respuesta_correcta": "25", "dificultad": 0},
	{"operacion": "4 x 8", "respuesta_correcta": "32", "dificultad": 0},
	# Media
	{"operacion": "145 + 68", "respuesta_correcta": "213", "dificultad": 1},
	{"operacion": "150 - 74", "respuesta_correcta": "76", "dificultad": 1},
	{"operacion": "12 x 8", "respuesta_correcta": "96", "dificultad": 1},
	{"operacion": "81 / 9", "respuesta_correcta": "9", "dificultad": 1},
	{"operacion": "230 + 85", "respuesta_correcta": "315", "dificultad": 1},
	{"operacion": "180 - 56", "respuesta_correcta": "124", "dificultad": 1},
	{"operacion": "15 x 4", "respuesta_correcta": "60", "dificultad": 1},
	# Difícil
	{"operacion": "320 + 185", "respuesta_correcta": "505", "dificultad": 2},
	{"operacion": "450 - 185", "respuesta_correcta": "265", "dificultad": 2},
	{"operacion": "15 x 6", "respuesta_correcta": "90", "dificultad": 2},
	{"operacion": "144 / 12", "respuesta_correcta": "12", "dificultad": 2},
	{"operacion": "278 + 356", "respuesta_correcta": "634", "dificultad": 2},
	{"operacion": "600 - 275", "respuesta_correcta": "325", "dificultad": 2},
	{"operacion": "25 x 4", "respuesta_correcta": "100", "dificultad": 2},
]

# --- NODOS ---
@onready var panel_contenedor: Control = $PanelContenedor if has_node("PanelContenedor") else null
var label_operacion: Label
var label_aciertos: Label
var label_dificultad: Label
var contenedor_corazones: HBoxContainer
var contenedor_gemas: HBoxContainer
var balanza_brazo: Control
var gema_platillo_der: Label
var pizarra_borrador: Control = null
var btn_pizarra: TextureButton = null
var escena_pizarra = preload("res://Escenas/Minijuegos/PizarraBorrador.tscn")
var tex_cuaderno = preload("res://assets/Minijuegos/minijuego Laboratorio/Cuaderno.png")

func _ready():
	_precargar_texturas_botones()
	visible = false
	_construir_interfaz()
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func _obtener_recurso_textura(ruta_base: String) -> Texture2D:
	var extensiones = [".png", ".jpg", ".jpeg", ".webp"]
	for ext in extensiones:
		var ruta = ruta_base + ext
		if ResourceLoader.exists(ruta):
			var res = load(ruta)
			if res is Texture2D:
				return res
		
		# Carga directa mediante Image
		var ruta_global = ProjectSettings.globalize_path(ruta)
		var ruta_a_usar = ""
		if FileAccess.file_exists(ruta):
			ruta_a_usar = ruta
		elif FileAccess.file_exists(ruta_global):
			ruta_a_usar = ruta_global
			
		if ruta_a_usar != "":
			var img = Image.load_from_file(ruta_a_usar)
			if img and not img.is_empty():
				return ImageTexture.create_from_image(img)
	return null

func _precargar_texturas_botones():
	Fondo_Tex = _obtener_recurso_textura("res://assets/Minijuegos/minijuego Balanza/Fondo_Balanza")

func _construir_interfaz():
	if panel_contenedor == null:
		panel_contenedor = Control.new()
		panel_contenedor.name = "PanelContenedor"
		panel_contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(panel_contenedor)

	# 1. 🌌 FONDO ESPACIAL (Cabina con ventana al cosmos)
	var fondo_tex = TextureRect.new()
	fondo_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if Fondo_Tex: 
		fondo_tex.texture = Fondo_Tex
	else:
		var fallback = ColorRect.new()
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.color = Color(0.06, 0.08, 0.14, 0.95)
		panel_contenedor.add_child(fallback)
	panel_contenedor.add_child(fondo_tex)

	# 2. 📜 PLACA DE INFORMACIÓN SUPERIOR IZQUIERDA (Estilo madera/bronce)
	var placa_info = Panel.new()
	placa_info.name = "PlacaInfo"
	placa_info.position = Vector2(30, 18)
	placa_info.size = Vector2(360, 85)
	
	var st_placa = StyleBoxFlat.new()
	st_placa.bg_color = Color("#3e2723") # Marrón madera/bronce steampunk
	st_placa.border_color = Color("#d97706") # Marco dorado
	st_placa.set_border_width_all(4)
	st_placa.set_corner_radius_all(14)
	st_placa.shadow_color = Color(0, 0, 0, 0.6)
	st_placa.shadow_size = 6
	placa_info.add_theme_stylebox_override("panel", st_placa)
	panel_contenedor.add_child(placa_info)

	var vbox_info = VBoxContainer.new()
	vbox_info.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_info.add_theme_constant_override("separation", 4)
	placa_info.add_child(vbox_info)

	label_aciertos = Label.new()
	label_aciertos.name = "LabelAciertos"
	label_aciertos.text = "Circuitos Reparados: 0/5"
	label_aciertos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_aciertos.add_theme_font_size_override("font_size", 20)
	label_aciertos.add_theme_color_override("font_color", Color("#fde047")) # Dorado brillante
	label_aciertos.add_theme_color_override("font_outline_color", Color("#78350f"))
	label_aciertos.add_theme_constant_override("outline_size", 3)
	vbox_info.add_child(label_aciertos)

	label_dificultad = Label.new()
	label_dificultad.name = "LabelDificultad"
	label_dificultad.text = "Dificultad: Fácil"
	label_dificultad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_dificultad.add_theme_font_size_override("font_size", 18)
	label_dificultad.add_theme_color_override("font_color", Color("#fde68a")) # Ámbar suave
	vbox_info.add_child(label_dificultad)

	# 3. ❤️ CAPSULA DE CORAZONES SUPERIOR DERECHA
	var placa_corazones = Panel.new()
	placa_corazones.name = "PlacaCorazones"
	placa_corazones.position = Vector2(860, 22)
	placa_corazones.size = Vector2(250, 60)
	
	var st_cor = StyleBoxFlat.new()
	st_cor.bg_color = Color("#3e2723")
	st_cor.border_color = Color("#d97706")
	st_cor.set_border_width_all(3)
	st_cor.set_corner_radius_all(25)
	st_cor.shadow_color = Color(0, 0, 0, 0.6)
	st_cor.shadow_size = 6
	placa_corazones.add_theme_stylebox_override("panel", st_cor)
	panel_contenedor.add_child(placa_corazones)

	contenedor_corazones = HBoxContainer.new()
	contenedor_corazones.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_corazones.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_corazones.add_theme_constant_override("separation", 15)
	for i in range(3):
		var t = TextureRect.new()
		t.custom_minimum_size = Vector2(42, 42)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture = textura_corazon_lleno
		contenedor_corazones.add_child(t)
	placa_corazones.add_child(contenedor_corazones)

	# 4. ⚙️ BASE Y TORRE CENTRAL STEAMPUNK
	var base_torre = Control.new()
	base_torre.name = "BaseTorre"
	base_torre.position = Vector2(576, 360)
	panel_contenedor.add_child(base_torre)

	# Soporte pedestal de metal
	var pedestal = Panel.new()
	pedestal.size = Vector2(170, 110)
	pedestal.position = Vector2(-85, 30)
	var st_ped = StyleBoxFlat.new()
	st_ped.bg_color = Color("#451a03")
	st_ped.border_color = Color("#b45309")
	st_ped.set_border_width_all(4)
	st_ped.corner_radius_top_left = 35
	st_ped.corner_radius_top_right = 35
	st_ped.corner_radius_bottom_left = 12
	st_ped.corner_radius_bottom_right = 12
	st_ped.shadow_color = Color(0, 0, 0, 0.6)
	st_ped.shadow_size = 8
	pedestal.add_theme_stylebox_override("panel", st_ped)
	base_torre.add_child(pedestal)

	# Rueda/Engranaje central
	var engranaje = Panel.new()
	engranaje.size = Vector2(90, 90)
	engranaje.position = Vector2(-45, -45)
	var st_eng = StyleBoxFlat.new()
	st_eng.bg_color = Color("#b45309")
	st_eng.border_color = Color("#fef08a")
	st_eng.set_border_width_all(4)
	st_eng.set_corner_radius_all(45)
	engranaje.add_theme_stylebox_override("panel", st_eng)
	base_torre.add_child(engranaje)

	# 5. ⚖️ BRAZO MECÁNICO DE LA BALANZA (Pivote central)
	balanza_brazo = Control.new()
	balanza_brazo.name = "BalanzaBrazo"
	balanza_brazo.position = Vector2(576, 315)
	panel_contenedor.add_child(balanza_brazo)

	# Barra principal de bronce/dorado
	var barra = Panel.new()
	barra.size = Vector2(600, 18)
	barra.position = Vector2(-300, -9)
	var st_barra = StyleBoxFlat.new()
	st_barra.bg_color = Color("#b45309")
	st_barra.border_color = Color("#fbbf24")
	st_barra.set_border_width_all(3)
	st_barra.set_corner_radius_all(8)
	barra.add_theme_stylebox_override("panel", st_barra)
	balanza_brazo.add_child(barra)

	# --- LADO IZQUIERDO: BOMBONA DE GAS / CÁPSULA + PLATAFORMA CIAN ---
	var lado_izq = Control.new()
	lado_izq.name = "LadoIzquierdo"
	lado_izq.position = Vector2(-280, 0)
	balanza_brazo.add_child(lado_izq)

	# Bombona/Cápsula de gas horizontal
	var capsula_op = Panel.new()
	capsula_op.name = "CapsulaOperacion"
	capsula_op.size = Vector2(240, 95)
	capsula_op.position = Vector2(-120, -115)
	var st_cap = StyleBoxFlat.new()
	st_cap.bg_color = Color("#57534e") # Carcasa metálica
	st_cap.border_color = Color("#d97706") # Borde dorado/latón
	st_cap.set_border_width_all(4)
	st_cap.set_corner_radius_all(35) # Forma de bombona/cápsula redondeada
	st_cap.shadow_color = Color(0, 0, 0, 0.6)
	st_cap.shadow_size = 8
	capsula_op.add_theme_stylebox_override("panel", st_cap)
	lado_izq.add_child(capsula_op)

	# Pantalla digital interna de la bombona
	var pantalla_op = Panel.new()
	pantalla_op.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla_op.offset_left = 12
	pantalla_op.offset_top = 12
	pantalla_op.offset_right = -12
	pantalla_op.offset_bottom = -12
	var st_pant = StyleBoxFlat.new()
	st_pant.bg_color = Color("#1c1917") # Fondo digital oscuro
	st_pant.border_color = Color("#eab308") # Borde ámbar
	st_pant.set_border_width_all(2)
	st_pant.set_corner_radius_all(22)
	pantalla_op.add_theme_stylebox_override("panel", st_pant)
	capsula_op.add_child(pantalla_op)

	# MarginContainer para evitar desborde del texto
	var margin_op = MarginContainer.new()
	margin_op.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_op.add_theme_constant_override("margin_left", 8)
	margin_op.add_theme_constant_override("margin_right", 8)
	pantalla_op.add_child(margin_op)

	label_operacion = Label.new()
	label_operacion.name = "LabelOperacion"
	label_operacion.text = "25 + 34 = ?"
	label_operacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_operacion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_operacion.add_theme_font_size_override("font_size", 30)
	label_operacion.add_theme_color_override("font_color", Color("#fde047")) # Amarillo dorado brillante
	label_operacion.add_theme_color_override("font_outline_color", Color("#78350f"))
	label_operacion.add_theme_constant_override("outline_size", 3)
	label_operacion.add_theme_color_override("font_shadow_color", Color(0.95, 0.75, 0.1, 0.6))
	label_operacion.add_theme_constant_override("shadow_offset_x", 2)
	label_operacion.add_theme_constant_override("shadow_offset_y", 2)
	margin_op.add_child(label_operacion)

	# Plataforma de energía Cian Neón (debajo de la bombona)
	var plataforma_cian = Panel.new()
	plataforma_cian.size = Vector2(220, 16)
	plataforma_cian.position = Vector2(-110, -5)
	var st_cian = StyleBoxFlat.new()
	st_cian.bg_color = Color("#38bdf8") # Cian neón
	st_cian.border_color = Color("#e0f2fe")
	st_cian.set_border_width_all(2)
	st_cian.set_corner_radius_all(8)
	st_cian.shadow_color = Color(0.22, 0.74, 0.97, 0.9) # Glow cian intenso
	st_cian.shadow_size = 14
	plataforma_cian.add_theme_stylebox_override("panel", st_cian)
	lado_izq.add_child(plataforma_cian)

	# --- LADO DERECHO: CÁPSULA DE INCÓGNITA + PLATAFORMA CORAL/ROJA ---
	var lado_der = Control.new()
	lado_der.name = "LadoDerecho"
	lado_der.position = Vector2(280, 0)
	balanza_brazo.add_child(lado_der)

	# Cápsula de respuesta derecha
	var capsula_der = Panel.new()
	capsula_der.size = Vector2(150, 85)
	capsula_der.position = Vector2(-75, -105)
	var st_cap_der = StyleBoxFlat.new()
	st_cap_der.bg_color = Color("#57534e")
	st_cap_der.border_color = Color("#d97706")
	st_cap_der.set_border_width_all(3)
	st_cap_der.set_corner_radius_all(30)
	st_cap_der.shadow_color = Color(0, 0, 0, 0.6)
	st_cap_der.shadow_size = 6
	capsula_der.add_theme_stylebox_override("panel", st_cap_der)
	lado_der.add_child(capsula_der)

	var pantalla_der = Panel.new()
	pantalla_der.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla_der.offset_left = 10
	pantalla_der.offset_top = 10
	pantalla_der.offset_right = -10
	pantalla_der.offset_bottom = -10
	var st_pant_der = StyleBoxFlat.new()
	st_pant_der.bg_color = Color("#1c1917")
	st_pant_der.border_color = Color("#f87171")
	st_pant_der.set_border_width_all(2)
	st_pant_der.set_corner_radius_all(20)
	pantalla_der.add_theme_stylebox_override("panel", st_pant_der)
	capsula_der.add_child(pantalla_der)

	gema_platillo_der = Label.new()
	gema_platillo_der.name = "GemaPlatilloDer"
	gema_platillo_der.text = "?"
	gema_platillo_der.set_anchors_preset(Control.PRESET_FULL_RECT)
	gema_platillo_der.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gema_platillo_der.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gema_platillo_der.add_theme_font_size_override("font_size", 34)
	gema_platillo_der.add_theme_color_override("font_color", Color("#fde047"))
	gema_platillo_der.add_theme_color_override("font_outline_color", Color("#78350f"))
	gema_platillo_der.add_theme_constant_override("outline_size", 3)
	pantalla_der.add_child(gema_platillo_der)

	# Plataforma de energía Coral / Roja (debajo de la incógnita)
	var plataforma_roja = Panel.new()
	plataforma_roja.size = Vector2(220, 16)
	plataforma_roja.position = Vector2(-110, -5)
	var st_roja = StyleBoxFlat.new()
	st_roja.bg_color = Color("#f87171") # Coral neón
	st_roja.border_color = Color("#fee2e2")
	st_roja.set_border_width_all(2)
	st_roja.set_corner_radius_all(8)
	st_roja.shadow_color = Color(0.97, 0.44, 0.44, 0.9) # Glow rojo intenso
	st_roja.shadow_size = 14
	plataforma_roja.add_theme_stylebox_override("panel", st_roja)
	lado_der.add_child(plataforma_roja)

	# 6. 🎮 CONSOLA INFERIOR DE BOTONES ARCADE
	var consola_panel = Panel.new()
	consola_panel.name = "ConsolaPanel"
	consola_panel.position = Vector2(170, 520)
	consola_panel.size = Vector2(810, 115)
	
	var st_consola = StyleBoxFlat.new()
	st_consola.bg_color = Color("#292524") # Metal grafito
	st_consola.border_color = Color("#b45309") # Borde de latón
	st_consola.set_border_width_all(4)
	st_consola.set_corner_radius_all(20)
	st_consola.shadow_color = Color(0, 0, 0, 0.7)
	st_consola.shadow_size = 10
	consola_panel.add_theme_stylebox_override("panel", st_consola)
	panel_contenedor.add_child(consola_panel)

	contenedor_gemas = HBoxContainer.new()
	contenedor_gemas.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_gemas.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_gemas.add_theme_constant_override("separation", 45)
	consola_panel.add_child(contenedor_gemas)
	
	# 7. 📝 BOTÓN DE PIZARRA Y PIZARRA BORRADOR (Lado Derecho)
	if escena_pizarra:
		pizarra_borrador = escena_pizarra.instantiate()
		pizarra_borrador.name = "PizarraBorrador"
		pizarra_borrador.visible = false
		pizarra_borrador.z_index = 30
		panel_contenedor.add_child(pizarra_borrador)
		
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
	panel_contenedor.add_child(btn_pizarra)

func AbrirCerrar_Pizarra():
	if pizarra_borrador and pizarra_borrador.has_method("toggle_pizarra"):
		pizarra_borrador.toggle_pizarra()
		pizarra_borrador.z_index = 30

func iniciar_minijuego(_tema: String = "espacio"):
	visible = true
	if panel_contenedor: panel_contenedor.visible = true
	vidas_actuales = 3
	aciertos_actuales = 0
	juego_activo = true
	_actualizar_ui_header()
	_mostrar_banner_instrucciones("Calcula la operacion y presiona el boton con el resultado correcto para equilibrar la balanza.", "Balanza")
	_cargar_siguiente_pregunta()

func _mostrar_banner_instrucciones(texto: String, audio_nombre: String = "Balanza"):
	if not panel_contenedor: return
	var banner_previo = panel_contenedor.get_node_or_null("BannerInstrucciones")
	if banner_previo:
		banner_previo.queue_free()
		
	var panel = PanelContainer.new()
	panel.name = "BannerInstrucciones"
	panel.anchors_preset = Control.PRESET_CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -390.0
	panel.offset_right = 390.0
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
	panel_contenedor.add_child(panel)
	
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

func _obtener_pregunta_actual_dinamica() -> Dictionary:
	var banco = banco_respaldo
	if DatosUsuario and DatosUsuario.banco_preguntas.size() > 0:
		banco = DatosUsuario.banco_preguntas
	var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
	var filtradas = banco.filter(func(p): return int(p.get("dificultad", 0)) == dif)
	if filtradas.size() == 0:
		filtradas = banco
	return filtradas.pick_random()

func _cargar_siguiente_pregunta():
	_actualizar_ui_header()
	pregunta_actual = _obtener_pregunta_actual_dinamica()
	var raw_op = pregunta_actual.get("operacion", pregunta_actual.get("pregunta", "10 + 10"))
	respuesta_correcta = int(pregunta_actual.get("respuesta_correcta", 20))
	
	_formatear_y_mostrar_operacion(str(raw_op))
	_generar_opciones_gemas()
	
	if balanza_brazo:
		var tw = create_tween()
		tw.tween_property(balanza_brazo, "rotation_degrees", -10.0, 0.4)
	if gema_platillo_der:
		gema_platillo_der.text = "?"
	tiempo_inicio_pregunta = Time.get_ticks_msec()

func _formatear_y_mostrar_operacion(op_str: String):
	var op = op_str.to_lower()
	op = op.replace(" por ", " x ").replace(" mas ", " + ").replace(" más ", " + ")
	op = op.replace(" menos ", " - ").replace(" dividido en ", " ÷ ").replace(" / ", " ÷ ")
	if not op.ends_with("="): op += " = ?"
	if label_operacion: label_operacion.text = op.to_upper()

func _generar_opciones_gemas():
	if not contenedor_gemas: return
	for h in contenedor_gemas.get_children(): h.queue_free()
	
	var opciones: Array = [respuesta_correcta]
	while opciones.size() < 4:
		var desvio = randi_range(-6, 8)
		if desvio == 0: desvio = 2
		var v = respuesta_correcta + desvio
		if v > 0 and not v in opciones: opciones.append(v)
	opciones.shuffle()
	
	for i in range(opciones.size()):
		var opc = opciones[i]
		var estilo_color = paleta_botones[i % paleta_botones.size()]
		
		# Botón arcade circular 3D sin marcos blancos
		var btn = Button.new()
		btn.name = "BotonArcade_" + str(i)
		btn.custom_minimum_size = Vector2(130, 85)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Panel visual interno con forma redondeada y brillo
		var fondo_btn = Panel.new()
		fondo_btn.name = "FondoVisual"
		fondo_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		fondo_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sf_normal = StyleBoxFlat.new()
		sf_normal.bg_color = estilo_color["base"]
		sf_normal.border_color = estilo_color["borde"]
		sf_normal.set_border_width_all(4)
		sf_normal.set_corner_radius_all(30)
		sf_normal.shadow_color = estilo_color["glow"]
		sf_normal.shadow_size = 8
		fondo_btn.add_theme_stylebox_override("panel", sf_normal)
		btn.add_child(fondo_btn)
		
		# Label con el número centrado
		var lbl = Label.new()
		lbl.name = "LabelNumero"
		lbl.text = str(opc)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.add_theme_color_override("font_color", estilo_color["texto"])
		lbl.add_theme_color_override("font_outline_color", Color("#ffffff"))
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		btn.add_child(lbl)
		
		# Efecto de presión física
		btn.button_down.connect(func(): 
			lbl.position.y = 5.0
			fondo_btn.position.y = 4.0
		)
		var restaurar = func(): 
			lbl.position.y = 0.0
			fondo_btn.position.y = 0.0
		btn.button_up.connect(restaurar)
		btn.mouse_exited.connect(restaurar)
		
		var val = opc
		btn.pressed.connect(func(): _evaluar_respuesta(val))
		contenedor_gemas.add_child(btn)

func _evaluar_respuesta(valor: int):
	if not juego_activo: return
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_pregunta) / 1000.0
	if gema_platillo_der: gema_platillo_der.text = str(valor)
	var es_correcto = (valor == respuesta_correcta)
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, es_correcto, tiempo_tardado)
	
	if es_correcto:
		aciertos_actuales += 1
		_reproducir_sonido("Correcto")
		if balanza_brazo:
			var tw = create_tween()
			tw.tween_property(balanza_brazo, "rotation_degrees", 0.0, 0.4).set_trans(Tween.TRANS_BOUNCE)
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nd = SistemaExperto.evaluar_desempeno(dif_ant, true, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nd
		_actualizar_ui_header()
		if aciertos_actuales >= META_ACIERTOS:
			await get_tree().create_timer(1.0).timeout
			_finalizar_minijuego(true)
		else:
			await get_tree().create_timer(1.0).timeout
			_cargar_siguiente_pregunta()
	else:
		vidas_actuales -= 1
		_reproducir_sonido("Incorrecto")
		
		# ⚖️ FÍSICA DE LA BALANZA:
		# Si la respuesta es menor, el lado izquierdo sigue siendo más pesado (se mueve levemente pero no se nivela)
		# Si la respuesta es mayor, el lado derecho se vuelve más pesado y cae hacia la derecha (+15°)
		if balanza_brazo:
			var tw = create_tween()
			if valor < respuesta_correcta:
				# Insuficiente peso en la derecha: sube un poco pero no llega a 0° y vuelve a caer a la izquierda (-8°)
				tw.tween_property(balanza_brazo, "rotation_degrees", -4.0, 0.22).set_trans(Tween.TRANS_QUAD)
				tw.tween_property(balanza_brazo, "rotation_degrees", -8.0, 0.25).set_trans(Tween.TRANS_BOUNCE)
			else:
				# Exceso de peso en la derecha: se inclina y cae a la derecha (+15°)
				tw.tween_property(balanza_brazo, "rotation_degrees", 15.0, 0.35).set_trans(Tween.TRANS_BOUNCE)
				
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nd = SistemaExperto.evaluar_desempeno(dif_ant, false, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nd
		_actualizar_ui_header()
		if vidas_actuales <= 0:
			await get_tree().create_timer(1.0).timeout
			_finalizar_minijuego(false)
		else:
			await get_tree().create_timer(1.0).timeout
			_cargar_siguiente_pregunta()

func _actualizar_ui_header():
	if label_aciertos:
		label_aciertos.text = "Energía Equilibrada: " + str(aciertos_actuales) + "/" + str(META_ACIERTOS)
	if label_dificultad:
		var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
		label_dificultad.text = "Dificultad: " + ["Fácil", "Media", "Difícil"][clampi(dif, 0, 2)]
	if contenedor_corazones:
		for i in range(contenedor_corazones.get_child_count()):
			var c = contenedor_corazones.get_child(i)
			if c is TextureRect:
				c.texture = textura_corazon_lleno if i < vidas_actuales else textura_corazon_vacio

func _reproducir_sonido(tipo: String):
	if GestionAudio and GestionAudio.has_method("reproducir_audio_local"):
		if tipo == "Correcto":
			GestionAudio.reproducir_audio_local("Minijuegos/Minijuego_explotar/" + ["Correcto_1", "Correcto_2", "Correcto_3"].pick_random())
		else:
			GestionAudio.reproducir_audio_local("Minijuegos/Minijuego_explotar/" + ["Incorrecto_1", "Incorrecto_2", "Incorrecto_3"].pick_random())

func _finalizar_minijuego(es_exito: bool):
	juego_activo = false
	visible = false
	if pizarra_borrador: pizarra_borrador.visible = false
	if panel_contenedor: panel_contenedor.visible = false
	minijuego_finalizado.emit(es_exito)
