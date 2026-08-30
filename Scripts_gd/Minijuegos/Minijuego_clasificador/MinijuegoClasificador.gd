# res://Scripts_gd/Minijuegos/Minijuego_clasificador/MinijuegoClasificador.gd
class_name MinijuegoClasificador
extends Control

## Minijuego: Clasificador de Cinta Transportadora (Línea de Pedidos Espacial)
## Paquetes espaciales con operaciones matemáticas avanzan por la cinta. El niño debe
## presionar la escotilla/tubo con la respuesta correcta antes de que la caja llegue al final.

signal minijuego_finalizado(es_correcto: bool)

# --- TEXTURAS Y ESTILOS ---
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

# Paleta de 4 tubos y botones (Azul, Verde, Amarillo, Rojo)
var paleta_escotillas: Array[Dictionary] = [
	{ "nombre": "Azul", "base": Color("#3b82f6"), "borde": Color("#1d4ed8"), "glow": Color(0.23, 0.51, 0.96, 0.4), "texto": Color.WHITE },
	{ "nombre": "Verde", "base": Color("#22c55e"), "borde": Color("#15803d"), "glow": Color(0.13, 0.77, 0.37, 0.4), "texto": Color.WHITE },
	{ "nombre": "Amarillo", "base": Color("#eab308"), "borde": Color("#a16207"), "glow": Color(0.92, 0.70, 0.03, 0.4), "texto": Color.WHITE },
	{ "nombre": "Rojo", "base": Color("#ef4444"), "borde": Color("#b91c1c"), "glow": Color(0.94, 0.27, 0.27, 0.4), "texto": Color.WHITE }
]

# --- ESTADO DEL JUEGO ---
var vidas_actuales: int = 3
var aciertos_actuales: int = 0
var META_ACIERTOS: int = 5
var juego_activo: bool = false
var tiempo_inicio_pregunta: float = 0.0

var respuesta_correcta: int = 0
var velocidad_cinta: float = 90.0
var pos_inicio_caja: Vector2 = Vector2(50, 205)
var pos_limite_cinta: float = 1000.0
var esperando_respuesta: bool = false

var cola_preguntas: Array = []
var datos_pregunta_actual: Dictionary = {}
var pregunta_actual: Dictionary = {}
var tween_caja: Tween = null

# --- BANCO DE RESPALDO (4to Grado) ---
var banco_respaldo: Array = [
	# Fácil
	{"operacion": "40 + 15", "respuesta_correcta": "55", "dificultad": 0},
	{"operacion": "50 - 18", "respuesta_correcta": "32", "dificultad": 0},
	{"operacion": "5 x 8", "respuesta_correcta": "40", "dificultad": 0},
	{"operacion": "24 / 4", "respuesta_correcta": "6", "dificultad": 0},
	{"operacion": "33 + 12", "respuesta_correcta": "45", "dificultad": 0},
	{"operacion": "70 - 35", "respuesta_correcta": "35", "dificultad": 0},
	{"operacion": "3 x 9", "respuesta_correcta": "27", "dificultad": 0},
	# Media
	{"operacion": "125 + 47", "respuesta_correcta": "172", "dificultad": 1},
	{"operacion": "200 - 85", "respuesta_correcta": "115", "dificultad": 1},
	{"operacion": "14 x 5", "respuesta_correcta": "70", "dificultad": 1},
	{"operacion": "96 / 8", "respuesta_correcta": "12", "dificultad": 1},
	{"operacion": "178 + 56", "respuesta_correcta": "234", "dificultad": 1},
	{"operacion": "300 - 135", "respuesta_correcta": "165", "dificultad": 1},
	{"operacion": "11 x 7", "respuesta_correcta": "77", "dificultad": 1},
	# Difícil
	{"operacion": "280 + 145", "respuesta_correcta": "425", "dificultad": 2},
	{"operacion": "350 - 165", "respuesta_correcta": "185", "dificultad": 2},
	{"operacion": "16 x 7", "respuesta_correcta": "112", "dificultad": 2},
	{"operacion": "108 / 9", "respuesta_correcta": "12", "dificultad": 2},
	{"operacion": "456 + 278", "respuesta_correcta": "734", "dificultad": 2},
	{"operacion": "500 - 237", "respuesta_correcta": "263", "dificultad": 2},
	{"operacion": "23 x 4", "respuesta_correcta": "92", "dificultad": 2},
]

# --- NODOS ---
@onready var panel_contenedor: Control = $PanelContenedor if has_node("PanelContenedor") else null
var fondo_textura: TextureRect
var header_panel: Panel
var label_titulo: Label
var label_aciertos: Label
var label_dificultad: Label
var contenedor_corazones: HBoxContainer
var caja_paquete: Panel
var label_operacion_caja: Label
var contenedor_clasificadores: HBoxContainer
var cinta_grafica: Panel
var pizarra_borrador: Control = null
var btn_pizarra: TextureButton = null
var escena_pizarra = preload("res://Escenas/Minijuegos/PizarraBorrador.tscn")
var tex_cuaderno = preload("res://assets/Minijuegos/minijuego Laboratorio/Cuaderno.png")

func _ready():
	visible = false
	_construir_interfaz()
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func _construir_interfaz():
	if panel_contenedor == null:
		panel_contenedor = Control.new()
		panel_contenedor.name = "PanelContenedor"
		panel_contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(panel_contenedor)

	# 1. 🌌 FONDO ESPACIAL
	fondo_textura = TextureRect.new()
	fondo_textura.name = "FondoTextura"
	fondo_textura.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo_textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var ruta_fondo = "res://assets/Minijuegos/minijuego Clasificador/Fondo_Clasificador.jpg"
	if ResourceLoader.exists(ruta_fondo):
		fondo_textura.texture = load(ruta_fondo)
		panel_contenedor.add_child(fondo_textura)
	else:
		var color_fallback = ColorRect.new()
		color_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_fallback.color = Color(0.06, 0.08, 0.15, 0.95)
		panel_contenedor.add_child(color_fallback)

	# 2. 🏆 HEADER DE ESTADO (Aciertos, Dificultad y Vidas)
	header_panel = Panel.new()
	header_panel.name = "HeaderPanel"
	header_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_panel.custom_minimum_size = Vector2(0, 75)
	header_panel.offset_left = 30
	header_panel.offset_top = 20
	header_panel.offset_right = -30
	header_panel.offset_bottom = 95
	
	var style_header = StyleBoxFlat.new()
	style_header.bg_color = Color(0.08, 0.10, 0.18, 0.88)
	style_header.border_color = Color("#38bdf8")
	style_header.set_border_width_all(2)
	style_header.set_corner_radius_all(16)
	style_header.shadow_color = Color(0, 0, 0, 0.6)
	style_header.shadow_size = 10
	header_panel.add_theme_stylebox_override("panel", style_header)
	panel_contenedor.add_child(header_panel)

	var hbox_header = HBoxContainer.new()
	hbox_header.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox_header.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_header.add_theme_constant_override("separation", 35)
	header_panel.add_child(hbox_header)

	label_titulo = Label.new()
	label_titulo.text = "LÍNEA DE PEDIDOS ESPACIAL"
	label_titulo.add_theme_font_size_override("font_size", 24)
	label_titulo.add_theme_color_override("font_color", Color("#38bdf8"))
	label_titulo.add_theme_color_override("font_outline_color", Color("#0369a1"))
	label_titulo.add_theme_constant_override("outline_size", 3)
	hbox_header.add_child(label_titulo)

	label_dificultad = Label.new()
	label_dificultad.text = "Dificultad: Media"
	label_dificultad.add_theme_font_size_override("font_size", 20)
	label_dificultad.add_theme_color_override("font_color", Color("#fde047"))
	hbox_header.add_child(label_dificultad)

	label_aciertos = Label.new()
	label_aciertos.text = "Aciertos: 0/5"
	label_aciertos.add_theme_font_size_override("font_size", 20)
	label_aciertos.add_theme_color_override("font_color", Color("#4ade80"))
	hbox_header.add_child(label_aciertos)

	contenedor_corazones = HBoxContainer.new()
	contenedor_corazones.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_corazones.add_theme_constant_override("separation", 6)
	for i in range(3):
		var img_corazon = TextureRect.new()
		img_corazon.texture = textura_corazon_lleno
		img_corazon.custom_minimum_size = Vector2(34, 34)
		img_corazon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_corazon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		contenedor_corazones.add_child(img_corazon)
	hbox_header.add_child(contenedor_corazones)

	# 3. ⚙️ CINTA TRANSPORTADORA INDUSTRIAL (Riel con rodillos)
	cinta_grafica = Panel.new()
	cinta_grafica.name = "CintaTransportadora"
	cinta_grafica.position = Vector2(0, 240)
	cinta_grafica.size = Vector2(1152, 45)
	
	var style_cinta = StyleBoxFlat.new()
	style_cinta.bg_color = Color("#334155")
	style_cinta.border_color = Color("#64748b")
	style_cinta.set_border_width_all(3)
	style_cinta.shadow_color = Color(0, 0, 0, 0.7)
	style_cinta.shadow_size = 8
	cinta_grafica.add_theme_stylebox_override("panel", style_cinta)
	cinta_grafica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_contenedor.add_child(cinta_grafica)

	# 4. 📦 PAQUETE ESPACIAL FLOTANTE / RODANTE
	caja_paquete = Panel.new()
	caja_paquete.name = "CajaPaquete"
	caja_paquete.size = Vector2(230, 95)
	caja_paquete.position = pos_inicio_caja
	
	var style_caja = StyleBoxFlat.new()
	style_caja.bg_color = Color("#b45309")
	style_caja.border_color = Color("#fde047")
	style_caja.set_border_width_all(4)
	style_caja.set_corner_radius_all(14)
	style_caja.shadow_color = Color(0, 0, 0, 0.6)
	style_caja.shadow_size = 12
	caja_paquete.add_theme_stylebox_override("panel", style_caja)
	caja_paquete.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_contenedor.add_child(caja_paquete)

	label_operacion_caja = Label.new()
	label_operacion_caja.name = "LabelOperacion"
	label_operacion_caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_operacion_caja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_operacion_caja.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_operacion_caja.add_theme_font_size_override("font_size", 30)
	label_operacion_caja.add_theme_color_override("font_color", Color("#ffffff"))
	label_operacion_caja.add_theme_color_override("font_outline_color", Color("#78350f"))
	label_operacion_caja.add_theme_constant_override("outline_size", 4)
	label_operacion_caja.text = "15 + 15 = ?"
	caja_paquete.add_child(label_operacion_caja)

	# 5. 🎯 ZONA INFERIOR: 4 ESCOTILLAS / TUBOS PNEUMÁTICOS CON BOTONES ARCADE
	contenedor_clasificadores = HBoxContainer.new()
	contenedor_clasificadores.name = "ContenedorClasificadores"
	contenedor_clasificadores.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	contenedor_clasificadores.offset_left = 40
	contenedor_clasificadores.offset_top = -280
	contenedor_clasificadores.offset_right = -40
	contenedor_clasificadores.offset_bottom = -20
	contenedor_clasificadores.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_clasificadores.add_theme_constant_override("separation", 24)
	panel_contenedor.add_child(contenedor_clasificadores)
	
	# 6. 📝 BOTÓN DE PIZARRA Y PIZARRA BORRADOR (Lado Derecho)
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
	btn_pizarra.offset_top = 25.0
	btn_pizarra.offset_bottom = 120.0
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
	vidas_actuales = 3
	aciertos_actuales = 0
	juego_activo = true
	visible = true
	if panel_contenedor: panel_contenedor.visible = true
	
	_ajustar_velocidad_segun_dificultad()
	_actualizar_ui_header()
	_mostrar_banner_instrucciones("📦 ¡Calcula la operación del paquete y presiona el botón con el color correcto!")
	_cargar_siguiente_caja()

func _mostrar_banner_instrucciones(texto: String, audio_nombre: String = "Instrucciones/como_jugar_clasificador"):
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

func _ajustar_velocidad_segun_dificultad():
	var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
	match dif:
		0: velocidad_cinta = 75.0
		1: velocidad_cinta = 95.0
		2: velocidad_cinta = 125.0

func _obtener_pregunta_actual_dinamica() -> Dictionary:
	var banco = DatosUsuario.banco_preguntas if (DatosUsuario and DatosUsuario.banco_preguntas.size() > 0) else banco_respaldo
	var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
	var filtradas = banco.filter(func(p): return int(p.get("dificultad", 0)) == dif)
	if filtradas.size() == 0:
		filtradas = banco
	return filtradas.pick_random()

func _cargar_siguiente_caja():
	_actualizar_ui_header()
	_ajustar_velocidad_segun_dificultad()
	datos_pregunta_actual = _obtener_pregunta_actual_dinamica()
	pregunta_actual = datos_pregunta_actual
	var raw_op = datos_pregunta_actual.get("operacion", datos_pregunta_actual.get("pregunta", "15 + 15"))
	var raw_resp = datos_pregunta_actual.get("respuesta_correcta", 30)
	respuesta_correcta = int(raw_resp)
	
	_formatear_y_mostrar_operacion(str(raw_op))
	_generar_botones_clasificadores()
	
	if caja_paquete:
		caja_paquete.position = pos_inicio_caja
		caja_paquete.modulate = Color.WHITE
		caja_paquete.rotation_degrees = 0.0
		
	esperando_respuesta = true
	tiempo_inicio_pregunta = Time.get_ticks_msec()
	
	_iniciar_movimiento_cinta()

func _iniciar_movimiento_cinta():
	if tween_caja and tween_caja.is_running():
		tween_caja.kill()
	
	var distancia = pos_limite_cinta - pos_inicio_caja.x
	var duracion = distancia / max(10.0, velocidad_cinta)
	
	tween_caja = create_tween()
	tween_caja.tween_property(caja_paquete, "position:x", pos_limite_cinta, duracion)
	tween_caja.finished.connect(_on_caja_cayo_al_vacio)

func _on_caja_cayo_al_vacio():
	if not esperando_respuesta or not juego_activo: return
	esperando_respuesta = false
	
	vidas_actuales -= 1
	_reproducir_sonido("Incorrecto")
	
	if caja_paquete:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(caja_paquete, "position:y", caja_paquete.position.y + 150, 0.4)
		tw.tween_property(caja_paquete, "rotation_degrees", 45.0, 0.4)
		tw.tween_property(caja_paquete, "modulate:a", 0.0, 0.4)
	
	_actualizar_ui_header()
	
	var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
	if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
		var nueva_dif = SistemaExperto.evaluar_desempeno(dif_ant, false, 8.0)
		if DatosUsuario: DatosUsuario.dificultad_actual = nueva_dif
		
	if vidas_actuales <= 0:
		await get_tree().create_timer(0.6).timeout
		_finalizar_minijuego(false)
	else:
		await get_tree().create_timer(0.6).timeout
		_cargar_siguiente_caja()

func _formatear_y_mostrar_operacion(op_str: String):
	var op = op_str.to_lower()
	op = op.replace(" por ", " x ").replace(" mas ", " + ").replace(" más ", " + ")
	op = op.replace(" menos ", " - ").replace(" dividido en ", " ÷ ").replace(" / ", " ÷ ")
	if not op.ends_with("="): op += " = ?"
	if label_operacion_caja:
		label_operacion_caja.text = op.to_upper()

func _generar_botones_clasificadores():
	if not contenedor_clasificadores: return
	for child in contenedor_clasificadores.get_children():
		child.queue_free()
		
	var opciones: Array = [respuesta_correcta]
	while opciones.size() < 4:
		var delta = randi_range(-6, 8)
		if delta == 0: delta = 2
		var val = respuesta_correcta + delta
		if val > 0 and not val in opciones:
			opciones.append(val)
	opciones.shuffle()
	
	for i in range(opciones.size()):
		var opc = opciones[i]
		var info_estilo = paleta_escotillas[i % paleta_escotillas.size()]
		var color_base: Color = info_estilo["base"]
		var color_borde: Color = info_estilo["borde"]
		var color_glow: Color = info_estilo["glow"]
		var color_texto: Color = info_estilo["texto"]
		
		var columna_tubo = VBoxContainer.new()
		columna_tubo.name = "ColumnaTubo_" + str(i)
		columna_tubo.custom_minimum_size = Vector2(210, 240)
		columna_tubo.alignment = BoxContainer.ALIGNMENT_CENTER
		columna_tubo.add_theme_constant_override("separation", 6)
		
		# 1. 🧪 TUBO NEUMÁTICO DE CRISTAL
		var tubo_cristal = Panel.new()
		tubo_cristal.custom_minimum_size = Vector2(170, 95)
		
		var style_tubo = StyleBoxFlat.new()
		style_tubo.bg_color = Color(color_base.r, color_base.g, color_base.b, 0.35)
		style_tubo.border_color = color_base
		style_tubo.set_border_width_all(3)
		style_tubo.corner_radius_top_left = 18
		style_tubo.corner_radius_top_right = 18
		style_tubo.corner_radius_bottom_left = 4
		style_tubo.corner_radius_bottom_right = 4
		style_tubo.shadow_color = Color(color_base.r, color_base.g, color_base.b, 0.4)
		style_tubo.shadow_size = 6
		tubo_cristal.add_theme_stylebox_override("panel", style_tubo)
		tubo_cristal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna_tubo.add_child(tubo_cristal)
		
		# 2. 🎮 BOTÓN TÁCTIL ARCADE VECTORIAL (Sin dependencias de textura externas)
		var btn = Button.new()
		btn.name = "BotonEscotilla_" + str(i)
		btn.custom_minimum_size = Vector2(180, 110)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var fondo_btn = Panel.new()
		fondo_btn.name = "FondoBtn"
		fondo_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		fondo_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sf_norm = StyleBoxFlat.new()
		sf_norm.bg_color = color_base
		sf_norm.border_color = Color(0.9, 0.95, 1.0, 0.9)
		sf_norm.set_border_width_all(4)
		sf_norm.set_corner_radius_all(20)
		sf_norm.shadow_color = color_glow
		sf_norm.shadow_size = 10
		fondo_btn.add_theme_stylebox_override("panel", sf_norm)
		btn.add_child(fondo_btn)
		
		# 3. 🔢 NÚMERO CENTRADO PERFECTAMENTE EN EL BOTÓN
		var lbl = Label.new()
		lbl.name = "LabelNumero"
		lbl.text = str(opc)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		lbl.add_theme_font_size_override("font_size", 42)
		lbl.add_theme_color_override("font_color", color_texto)
		lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 0.95))
		lbl.add_theme_constant_override("outline_size", 6)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		
		# Efecto de presión táctil
		btn.button_down.connect(func(): 
			lbl.position.y = 5.0
			fondo_btn.position.y = 4.0
		)
		var restaurar = func(): 
			lbl.position.y = 0.0
			fondo_btn.position.y = 0.0
		btn.button_up.connect(restaurar)
		btn.mouse_exited.connect(restaurar)
		
		btn.add_child(lbl)
		
		var valor_capturado = opc
		btn.pressed.connect(func(): _evaluar_respuesta(valor_capturado))
		
		columna_tubo.add_child(btn)
		contenedor_clasificadores.add_child(columna_tubo)

func _evaluar_respuesta(valor_elegido: int):
	if not juego_activo or not esperando_respuesta: return
	esperando_respuesta = false
	
	if tween_caja and tween_caja.is_running():
		tween_caja.kill()
	
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_pregunta) / 1000.0
	var es_correcto = (valor_elegido == respuesta_correcta)
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, es_correcto, tiempo_tardado)
	
	if es_correcto:
		aciertos_actuales += 1
		_reproducir_sonido("Correcto")
		
		if caja_paquete:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(caja_paquete, "position:y", caja_paquete.position.y + 120, 0.4)
			tw.tween_property(caja_paquete, "modulate:a", 0.0, 0.4)
			
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nueva_dif = SistemaExperto.evaluar_desempeno(dif_ant, true, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nueva_dif
		_actualizar_ui_header()

		if aciertos_actuales >= META_ACIERTOS:
			await get_tree().create_timer(0.8).timeout
			_finalizar_minijuego(true)
		else:
			await get_tree().create_timer(0.8).timeout
			_ajustar_velocidad_segun_dificultad()
			_cargar_siguiente_caja()
	else:
		vidas_actuales -= 1
		_reproducir_sonido("Incorrecto")
		
		if caja_paquete:
			caja_paquete.modulate = Color(1.0, 0.2, 0.2)
			var tw = create_tween()
			tw.tween_property(caja_paquete, "rotation_degrees", 15.0, 0.2)
			
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nueva_dif = SistemaExperto.evaluar_desempeno(dif_ant, false, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nueva_dif
		_actualizar_ui_header()

		if vidas_actuales <= 0:
			await get_tree().create_timer(0.8).timeout
			_finalizar_minijuego(false)
		else:
			await get_tree().create_timer(0.8).timeout
			_cargar_siguiente_caja()

func _actualizar_ui_header():
	if label_aciertos:
		label_aciertos.text = "Aciertos: " + str(aciertos_actuales) + "/" + str(META_ACIERTOS)
	if label_dificultad:
		var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
		var nombres = ["Fácil", "Media", "Difícil"]
		label_dificultad.text = "Dificultad: " + nombres[clampi(dif, 0, 2)]
	if contenedor_corazones:
		var corazones = contenedor_corazones.get_children()
		for i in range(corazones.size()):
			if corazones[i] is TextureRect:
				corazones[i].texture = textura_corazon_lleno if i < vidas_actuales else textura_corazon_vacio

func _reproducir_sonido(tipo: String):
	if GestionAudio and GestionAudio.has_method("reproducir_audio_local"):
		if tipo == "Correcto":
			GestionAudio.reproducir_audio_local("Minijuegos/Minijuego_explotar/" + ["Correcto_1", "Correcto_2", "Correcto_3"].pick_random())
		else:
			GestionAudio.reproducir_audio_local("Minijuegos/Minijuego_explotar/" + ["Incorrecto_1", "Incorrecto_2", "Incorrecto_3"].pick_random())

func _finalizar_minijuego(es_exito: bool):
	juego_activo = false
	esperando_respuesta = false
	if tween_caja and tween_caja.is_running():
		tween_caja.kill()
	visible = false
	if pizarra_borrador: pizarra_borrador.visible = false
	if panel_contenedor: panel_contenedor.visible = false
	minijuego_finalizado.emit(es_exito)
