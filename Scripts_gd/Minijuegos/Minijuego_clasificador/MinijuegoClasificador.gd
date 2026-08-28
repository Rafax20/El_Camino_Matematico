# res://Scripts_gd/Minijuegos/Minijuego_clasificador/MinijuegoClasificador.gd
extends Control

## Minijuego: Clasificador de Cinta Transportadora (Línea de Pedidos Espacial)
## Paquetes espaciales con operaciones matemáticas avanzan por la cinta. El niño debe
## presionar la escotilla/tubo con la respuesta correcta antes de que la caja llegue al final.

signal minijuego_finalizado(es_correcto: bool)

# --- TEXTURAS ---
var Fondo_Tex: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Fondo_Clasificador.jpg")

var tex_azul_n: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Azul_Normal.png")
var tex_azul_p: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Azul_Presionado.png")

var tex_verde_n: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Verde_Normal.png")
var tex_verde_p: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Verde_Presionado.png")

var tex_amarillo_n: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Amarillo_Normal.png")
var tex_amarillo_p: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Amarillo_Presionado.png")

var tex_rojo_n: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Rojo_Normal.png")
var tex_rojo_p: Texture2D = preload("res://assets/Minijuegos/minijuego Clasificador/Boton_Rojo_Presionado.png")

var Botones_Normal: Array[Texture2D] = []
var Botones_Presionado: Array[Texture2D] = []

var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

# Colores asociados a cada escotilla (Azul, Verde, Amarillo, Rojo)
var colores_escotilla: Array[String] = ["Azul", "Verde", "Amarillo", "Rojo"]
var colores_rgb: Array[Color] = [
	Color("#3b82f6"), # Azul
	Color("#22c55e"), # Verde
	Color("#eab308"), # Amarillo
	Color("#ef4444")  # Rojo
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

func _ready():
	Botones_Normal = [tex_azul_n, tex_verde_n, tex_amarillo_n, tex_rojo_n]
	Botones_Presionado = [tex_azul_p, tex_verde_p, tex_amarillo_p, tex_rojo_p]
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
	if Fondo_Tex: 
		fondo_textura.texture = Fondo_Tex
	else:
		var color_fallback = ColorRect.new()
		color_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_fallback.color = Color(0.06, 0.08, 0.15, 0.95)
		panel_contenedor.add_child(color_fallback)
	panel_contenedor.add_child(fondo_textura)

	# 2. 🎛️ HEADER DE NAVEGACIÓN ESPACIAL
	header_panel = Panel.new()
	header_panel.name = "HeaderPanel"
	header_panel.position = Vector2(25, 10)
	header_panel.custom_minimum_size = Vector2(1100, 60)
	header_panel.size = Vector2(1100, 60)
	
	var style_header = StyleBoxFlat.new()
	style_header.bg_color = Color("#0f172a") # Azul pizarra oscuro
	style_header.border_color = Color("#0284c7") # Borde cian nave
	style_header.set_border_width_all(3)
	style_header.set_corner_radius_all(14)
	style_header.shadow_color = Color(0, 0, 0, 0.6)
	style_header.shadow_size = 6
	header_panel.add_theme_stylebox_override("panel", style_header)
	panel_contenedor.add_child(header_panel)

	var hbox_header = HBoxContainer.new()
	hbox_header.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox_header.add_theme_constant_override("margin_left", 20)
	hbox_header.add_theme_constant_override("margin_right", 20)
	hbox_header.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(hbox_header)

	var margin_left_spacer = Control.new()
	margin_left_spacer.custom_minimum_size = Vector2(15, 10)
	hbox_header.add_child(margin_left_spacer)

	label_titulo = Label.new()
	label_titulo.text = "LÍNEA DE PEDIDOS"
	label_titulo.add_theme_font_size_override("font_size", 26)
	label_titulo.add_theme_color_override("font_color", Color("#fbbf24")) # Dorado ámbar
	label_titulo.add_theme_color_override("font_outline_color", Color("#78350f"))
	label_titulo.add_theme_constant_override("outline_size", 4)
	hbox_header.add_child(label_titulo)
	
	var sp1 = Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(sp1)
	
	label_aciertos = Label.new()
	label_aciertos.name = "LabelAciertos"
	label_aciertos.text = "Aciertos: 0/5"
	label_aciertos.add_theme_font_size_override("font_size", 24)
	label_aciertos.add_theme_color_override("font_color", Color("#38bdf8")) # Cian luminoso
	label_aciertos.add_theme_color_override("font_outline_color", Color("#0369a1"))
	label_aciertos.add_theme_constant_override("outline_size", 4)
	hbox_header.add_child(label_aciertos)
	
	var sp2 = Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(sp2)
	
	label_dificultad = Label.new()
	label_dificultad.text = "Dificultad: Fácil"
	label_dificultad.add_theme_font_size_override("font_size", 18)
	label_dificultad.add_theme_color_override("font_color", Color("#a5f3fc"))
	hbox_header.add_child(label_dificultad)
	
	var sp3 = Control.new()
	sp3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(sp3)
	
	contenedor_corazones = HBoxContainer.new()
	contenedor_corazones.name = "ContenedorCorazones"
	contenedor_corazones.add_theme_constant_override("separation", 10)
	for i in range(3):
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(40, 40)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = textura_corazon_lleno
		contenedor_corazones.add_child(tex_rect)
	hbox_header.add_child(contenedor_corazones)

	var margin_right_spacer = Control.new()
	margin_right_spacer.custom_minimum_size = Vector2(15, 10)
	hbox_header.add_child(margin_right_spacer)

	# 3. ⚙️ CINTA TRANSPORTADORA
	cinta_grafica = Panel.new()
	cinta_grafica.name = "CintaTransportadora"
	cinta_grafica.position = Vector2(30, 335)
	cinta_grafica.size = Vector2(1090, 30)
	
	var style_cinta = StyleBoxFlat.new()
	style_cinta.bg_color = Color("#334155")
	style_cinta.border_color = Color("#f59e0b") # Borde amarillo advertencia
	style_cinta.set_border_width_all(2)
	style_cinta.set_corner_radius_all(6)
	cinta_grafica.add_theme_stylebox_override("panel", style_cinta)
	panel_contenedor.add_child(cinta_grafica)

	# 4. 📦 CONTENEDOR DE CARGA ESPACIAL (Caja con pantalla digital)
	caja_paquete = Panel.new()
	caja_paquete.name = "CajaPaquete"
	caja_paquete.size = Vector2(250, 130)
	caja_paquete.position = pos_inicio_caja
	
	var style_caja = StyleBoxFlat.new()
	style_caja.bg_color = Color("#0f172a") # Metal espacial oscuro
	style_caja.border_color = Color("#f59e0b") # Marco brillante
	style_caja.set_border_width_all(4)
	style_caja.set_corner_radius_all(14)
	style_caja.shadow_color = Color(0.96, 0.62, 0.04, 0.5) # Glow dorado
	style_caja.shadow_size = 12
	caja_paquete.add_theme_stylebox_override("panel", style_caja)
	panel_contenedor.add_child(caja_paquete)
	
	# Pantalla digital interna de la caja
	var pantalla_interior = Panel.new()
	pantalla_interior.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla_interior.offset_left = 12
	pantalla_interior.offset_top = 12
	pantalla_interior.offset_right = -12
	pantalla_interior.offset_bottom = -12
	
	var style_pantalla = StyleBoxFlat.new()
	style_pantalla.bg_color = Color("#022c22") # Verde/Cian cibernético profundo
	style_pantalla.border_color = Color("#38bdf8") # Borde cian neón
	style_pantalla.set_border_width_all(2)
	style_pantalla.set_corner_radius_all(8)
	pantalla_interior.add_theme_stylebox_override("panel", style_pantalla)
	caja_paquete.add_child(pantalla_interior)

	label_operacion_caja = Label.new()
	label_operacion_caja.name = "LabelOperacion"
	label_operacion_caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_operacion_caja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_operacion_caja.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_operacion_caja.add_theme_font_size_override("font_size", 32)
	label_operacion_caja.add_theme_color_override("font_color", Color("#38bdf8")) # Texto cian brillante
	label_operacion_caja.add_theme_color_override("font_outline_color", Color("#0284c7"))
	label_operacion_caja.add_theme_constant_override("outline_size", 4)
	pantalla_interior.add_child(label_operacion_caja)

	# 5. 🚀 ESCOTILLAS / TUBOS Y BOTONES ARCADE
	contenedor_clasificadores = HBoxContainer.new()
	contenedor_clasificadores.name = "ContenedorClasificadores"
	contenedor_clasificadores.position = Vector2(60, 390)
	contenedor_clasificadores.custom_minimum_size = Vector2(1030, 245)
	contenedor_clasificadores.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_clasificadores.add_theme_constant_override("separation", 35)
	panel_contenedor.add_child(contenedor_clasificadores)

func iniciar_minijuego(_tema: String = "espacio"):
	visible = true
	if panel_contenedor: panel_contenedor.visible = true
	
	vidas_actuales = 3
	aciertos_actuales = 0
	juego_activo = true
	esperando_respuesta = false
	
	_ajustar_velocidad_segun_dificultad()
	_recargar_cola_preguntas()
	_actualizar_ui_header()
	_cargar_siguiente_caja()

func _ajustar_velocidad_segun_dificultad():
	var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
	match dif:
		0: velocidad_cinta = 80.0
		1: velocidad_cinta = 115.0
		2: velocidad_cinta = 150.0
		_: velocidad_cinta = 90.0

func _recargar_cola_preguntas():
	cola_preguntas.clear()
	var banco = banco_respaldo
	if DatosUsuario and DatosUsuario.banco_preguntas.size() > 0:
		banco = DatosUsuario.banco_preguntas
	var dif = DatosUsuario.dificultad_actual if DatosUsuario else 0
	for preg in banco:
		if int(preg.get("dificultad", 0)) == dif:
			cola_preguntas.append(preg)
	if cola_preguntas.size() == 0:
		cola_preguntas = banco.duplicate()
	cola_preguntas.shuffle()

func _cargar_siguiente_caja():
	if cola_preguntas.size() == 0:
		_recargar_cola_preguntas()
		if cola_preguntas.size() == 0: return
		
	datos_pregunta_actual = cola_preguntas.pop_front()
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
	tween_caja.finished.connect(_on_caja_llego_al_final)

func _on_caja_llego_al_final():
	if not juego_activo or not esperando_respuesta: return
	esperando_respuesta = false
	vidas_actuales -= 1
	_reproducir_sonido("Incorrecto")
	_actualizar_ui_header()
	
	if caja_paquete:
		caja_paquete.modulate = Color(1.0, 0.3, 0.3, 0.6)
		
	if vidas_actuales <= 0:
		await get_tree().create_timer(0.8).timeout
		_finalizar_minijuego(false)
	else:
		await get_tree().create_timer(0.8).timeout
		_cargar_siguiente_caja()

func _formatear_y_mostrar_operacion(op_str: String):
	var op_limpia = op_str.to_lower()
	op_limpia = op_limpia.replace(" por ", " x ")
	op_limpia = op_limpia.replace(" mas ", " + ").replace(" más ", " + ")
	op_limpia = op_limpia.replace(" menos ", " - ")
	op_limpia = op_limpia.replace(" dividido en ", " ÷ ").replace(" / ", " ÷ ")
	if not op_limpia.ends_with("="):
		op_limpia += " = ?"
	if label_operacion_caja:
		label_operacion_caja.text = op_limpia.to_upper()

func _generar_botones_clasificadores():
	if not contenedor_clasificadores: return
	for hijo in contenedor_clasificadores.get_children():
		hijo.queue_free()
		
	var opciones: Array = [respuesta_correcta]
	while opciones.size() < 4:
		var desvio = randi_range(-5, 7)
		if desvio == 0: desvio = 3
		var val_alt = respuesta_correcta + desvio
		if val_alt > 0 and not val_alt in opciones:
			opciones.append(val_alt)
	opciones.shuffle()
	
	for i in range(opciones.size()):
		var opc = opciones[i]
		var idx_color = i % colores_escotilla.size()
		var color_base = colores_rgb[idx_color]
		
		# Contenedor vertical para el tubo neumático + botón
		var columna_tubo = VBoxContainer.new()
		columna_tubo.name = "ColumnaTubo_" + str(i)
		columna_tubo.custom_minimum_size = Vector2(210, 240)
		columna_tubo.alignment = BoxContainer.ALIGNMENT_CENTER
		columna_tubo.add_theme_constant_override("separation", 6)
		
		# 1. 🧪 TUBO NEUMÁTICO DE CRISTAL (Visual como en el mockup)
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
		
		# 2. 🎮 BOTÓN TÁCTIL ARCADE (TextureButton)
		var btn = TextureButton.new()
		btn.name = "BotonEscotilla_" + str(i)
		btn.custom_minimum_size = Vector2(180, 120)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if Botones_Normal.size() > idx_color and Botones_Normal[idx_color]:
			btn.texture_normal = Botones_Normal[idx_color]
		if Botones_Presionado.size() > idx_color and Botones_Presionado[idx_color]:
			btn.texture_pressed = Botones_Presionado[idx_color]
			
		# Fallback estilizado si la textura falta
		if not btn.texture_normal:
			var btn_fallback = Panel.new()
			btn_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
			var sf = StyleBoxFlat.new()
			sf.bg_color = color_base
			sf.border_color = Color("#ffffff")
			sf.set_border_width_all(4)
			sf.set_corner_radius_all(18)
			btn_fallback.add_theme_stylebox_override("panel", sf)
			btn_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(btn_fallback)
		
		# 3. 🔢 NÚMERO CENTRADO PERFECTAMENTE EN EL BOTÓN
		var lbl = Label.new()
		lbl.name = "LabelNumero"
		lbl.text = str(opc)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.anchor_left = 0.0
		lbl.anchor_top = 0.0
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 1.0
		lbl.offset_left = 0
		lbl.offset_top = 0
		lbl.offset_right = 0
		lbl.offset_bottom = 0
		
		lbl.add_theme_font_size_override("font_size", 46)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 0.95))
		lbl.add_theme_constant_override("outline_size", 8)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 3)
		lbl.add_theme_constant_override("shadow_offset_y", 3)
		
		# Efecto de presión física táctil
		btn.button_down.connect(func(): lbl.position.y = 6.0)
		var restaurar = func(): lbl.position.y = 0.0
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
	
	if valor_elegido == respuesta_correcta:
		aciertos_actuales += 1
		_reproducir_sonido("Correcto")
		
		if caja_paquete:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(caja_paquete, "position:y", caja_paquete.position.y + 120, 0.4)
			tw.tween_property(caja_paquete, "modulate:a", 0.0, 0.4)
			
		_actualizar_ui_header()
		
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nueva_dif = SistemaExperto.evaluar_desempeno(dif_ant, true, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nueva_dif

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
			
		_actualizar_ui_header()
		
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nueva_dif = SistemaExperto.evaluar_desempeno(dif_ant, false, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nueva_dif

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
	if panel_contenedor: panel_contenedor.visible = false
	minijuego_finalizado.emit(es_exito)
