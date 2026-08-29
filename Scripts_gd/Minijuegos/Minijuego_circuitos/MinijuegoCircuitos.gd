# res://Scripts_gd/Minijuegos/Minijuego_circuitos/MinijuegoCircuitos.gd
extends Control

## Minijuego: Conector de Circuitos Estelares
## Conectar terminales cilíndricos izquierdos (operaciones) con terminales derechos (respuestas)
## mediante cables trenzados de energía de plasma verde neón con física de caída realista.

signal minijuego_finalizado(es_correcto: bool)

# --- TEXTURAS ---
var Fondo_Tex: Texture2D = null
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")

# --- ESTADO ---
var vidas_actuales: int = 3
var aciertos_actuales: int = 0
var META_ACIERTOS: int = 5
var juego_activo: bool = false
var tiempo_inicio_panel: float = 0.0

var nodo_izq_seleccionado: Button = null
var conexiones_completadas: int = 0
var total_conexiones_panel: int = 3
var cola_preguntas: Array = []
var pares_actuales: Array = []

# --- BANCO DE PREGUNTAS (4to Grado) ---
var banco_respaldo: Array = [
	# Fácil
	{"operacion": "40 / 5", "respuesta_correcta": "8", "dificultad": 0},
	{"operacion": "45 - 15", "respuesta_correcta": "30", "dificultad": 0},
	{"operacion": "15 + 25", "respuesta_correcta": "40", "dificultad": 0},
	{"operacion": "7 x 6", "respuesta_correcta": "42", "dificultad": 0},
	{"operacion": "22 + 18", "respuesta_correcta": "40", "dificultad": 0},
	{"operacion": "56 - 24", "respuesta_correcta": "32", "dificultad": 0},
	{"operacion": "8 x 5", "respuesta_correcta": "40", "dificultad": 0},
	# Media
	{"operacion": "130 + 85", "respuesta_correcta": "215", "dificultad": 1},
	{"operacion": "180 - 65", "respuesta_correcta": "115", "dificultad": 1},
	{"operacion": "13 x 4", "respuesta_correcta": "52", "dificultad": 1},
	{"operacion": "72 / 8", "respuesta_correcta": "9", "dificultad": 1},
	{"operacion": "215 + 130", "respuesta_correcta": "345", "dificultad": 1},
	{"operacion": "250 - 95", "respuesta_correcta": "155", "dificultad": 1},
	{"operacion": "11 x 6", "respuesta_correcta": "66", "dificultad": 1},
	# Difícil
	{"operacion": "240 + 175", "respuesta_correcta": "415", "dificultad": 2},
	{"operacion": "320 - 145", "respuesta_correcta": "175", "dificultad": 2},
	{"operacion": "18 x 5", "respuesta_correcta": "90", "dificultad": 2},
	{"operacion": "144 / 12", "respuesta_correcta": "12", "dificultad": 2},
	{"operacion": "367 + 258", "respuesta_correcta": "625", "dificultad": 2},
	{"operacion": "500 - 213", "respuesta_correcta": "287", "dificultad": 2},
	{"operacion": "24 x 3", "respuesta_correcta": "72", "dificultad": 2},
]

# --- NODOS ---
@onready var panel_contenedor: Control = $PanelContenedor if has_node("PanelContenedor") else null
var label_aciertos: Label
var label_dificultad: Label
var contenedor_corazones: HBoxContainer
var contenedor_izquierdo: VBoxContainer
var contenedor_derecho: VBoxContainer
var capa_lineas: Control

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
	Fondo_Tex = _obtener_recurso_textura("res://assets/Minijuegos/minijuego Circuitos/Fondo_Circuitos")

func _construir_interfaz():
	if panel_contenedor == null:
		panel_contenedor = Control.new()
		panel_contenedor.name = "PanelContenedor"
		panel_contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(panel_contenedor)

	# 1. 🌌 FONDO DE PANEL ELÉCTRICO DE NAVE
	var fondo = TextureRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if Fondo_Tex: 
		fondo.texture = Fondo_Tex
	else:
		var fb = ColorRect.new()
		fb.set_anchors_preset(Control.PRESET_FULL_RECT)
		fb.color = Color(0.04, 0.08, 0.12, 0.95)
		panel_contenedor.add_child(fb)
	panel_contenedor.add_child(fondo)

	# 2. 🎛️ HEADER DE ESTADO DE CIRCUITOS
	var header_panel = Panel.new()
	header_panel.position = Vector2(30, 15)
	header_panel.size = Vector2(370, 80)
	var st_hdr = StyleBoxFlat.new()
	st_hdr.bg_color = Color("#0f172a")
	st_hdr.border_color = Color("#0284c7")
	st_hdr.set_border_width_all(3)
	st_hdr.set_corner_radius_all(14)
	st_hdr.shadow_color = Color(0, 0, 0, 0.6)
	st_hdr.shadow_size = 6
	header_panel.add_theme_stylebox_override("panel", st_hdr)
	panel_contenedor.add_child(header_panel)

	var vbox_hdr = VBoxContainer.new()
	vbox_hdr.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox_hdr.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_hdr.add_theme_constant_override("separation", 3)
	header_panel.add_child(vbox_hdr)

	label_aciertos = Label.new()
	label_aciertos.name = "LabelAciertos"
	label_aciertos.text = "Circuitos Reparados: 0/5"
	label_aciertos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_aciertos.add_theme_font_size_override("font_size", 22)
	label_aciertos.add_theme_color_override("font_color", Color("#38bdf8")) # Cian brillante
	label_aciertos.add_theme_color_override("font_outline_color", Color("#0369a1"))
	label_aciertos.add_theme_constant_override("outline_size", 3)
	vbox_hdr.add_child(label_aciertos)

	label_dificultad = Label.new()
	label_dificultad.name = "LabelDificultad"
	label_dificultad.text = "Dificultad: Fácil"
	label_dificultad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_dificultad.add_theme_font_size_override("font_size", 18)
	label_dificultad.add_theme_color_override("font_color", Color("#a5f3fc"))
	vbox_hdr.add_child(label_dificultad)

	# 3. ❤️ CÁPSULA DE VIDAS
	var placa_cor = Panel.new()
	placa_cor.position = Vector2(870, 18)
	placa_cor.size = Vector2(240, 60)
	var st_cor = StyleBoxFlat.new()
	st_cor.bg_color = Color("#0f172a")
	st_cor.border_color = Color("#ef4444")
	st_cor.set_border_width_all(3)
	st_cor.set_corner_radius_all(25)
	placa_cor.add_theme_stylebox_override("panel", st_cor)
	panel_contenedor.add_child(placa_cor)

	contenedor_corazones = HBoxContainer.new()
	contenedor_corazones.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_corazones.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_corazones.add_theme_constant_override("separation", 15)
	for i in range(3):
		var t = TextureRect.new()
		t.custom_minimum_size = Vector2(40, 40)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture = textura_corazon_lleno
		contenedor_corazones.add_child(t)
	placa_cor.add_child(contenedor_corazones)

	# 4. ⚡ CAPA DE CABLES DE ENERGÍA (Por detrás de los terminales)
	capa_lineas = Control.new()
	capa_lineas.name = "CapaLineas"
	capa_lineas.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_lineas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_contenedor.add_child(capa_lineas)

	# 5. 🔌 CONTENEDOR DE TERMINALES (Izquierda y Derecha)
	var cont_term = HBoxContainer.new()
	cont_term.position = Vector2(60, 120)
	cont_term.custom_minimum_size = Vector2(1040, 480)
	cont_term.alignment = BoxContainer.ALIGNMENT_CENTER
	cont_term.add_theme_constant_override("separation", 240)
	
	contenedor_izquierdo = VBoxContainer.new()
	contenedor_izquierdo.custom_minimum_size = Vector2(350, 450)
	contenedor_izquierdo.add_theme_constant_override("separation", 35)
	cont_term.add_child(contenedor_izquierdo)
	
	contenedor_derecho = VBoxContainer.new()
	contenedor_derecho.custom_minimum_size = Vector2(350, 450)
	contenedor_derecho.add_theme_constant_override("separation", 35)
	cont_term.add_child(contenedor_derecho)
	
	panel_contenedor.add_child(cont_term)

func iniciar_minijuego(_tema: String = "espacio"):
	visible = true
	if panel_contenedor: panel_contenedor.visible = true
	vidas_actuales = 3
	aciertos_actuales = 0
	juego_activo = true
	_recargar_cola_preguntas()
	_actualizar_ui_header()
	_cargar_nuevo_panel_circuitos()

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

func _cargar_nuevo_panel_circuitos():
	nodo_izq_seleccionado = null
	conexiones_completadas = 0
	_limpiar_cables()
	if cola_preguntas.size() < total_conexiones_panel:
		_recargar_cola_preguntas()
	pares_actuales.clear()
	for i in range(total_conexiones_panel):
		if cola_preguntas.size() > 0:
			pares_actuales.append(cola_preguntas.pop_front())
	_construir_nodos_panel()
	tiempo_inicio_panel = Time.get_ticks_msec()

func _construir_nodos_panel():
	if not contenedor_izquierdo or not contenedor_derecho: return
	for h in contenedor_izquierdo.get_children(): h.queue_free()
	for h in contenedor_derecho.get_children(): h.queue_free()
	
	# --- TERMINALES IZQUIERDOS (Cápsulas metálicas cilíndricas con Operación) ---
	for i in range(pares_actuales.size()):
		var datos = pares_actuales[i]
		var raw_op = datos.get("operacion", datos.get("pregunta", "10 + 10"))
		var resp = int(datos.get("respuesta_correcta", 20))
		
		var btn = Button.new()
		btn.name = "TerminalIzq_" + str(i)
		btn.custom_minimum_size = Vector2(340, 95)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.set_meta("respuesta_correcta", resp)
		btn.set_meta("datos_pregunta", p)
		btn.set_meta("resuelto", false)
		
		# Carcasa metálica cilíndrica horizontal (Pill Shape)
		var carcasa = Panel.new()
		carcasa.name = "Carcasa"
		carcasa.set_anchors_preset(Control.PRESET_FULL_RECT)
		carcasa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var st_carc = StyleBoxFlat.new()
		st_carc.bg_color = Color("#475569") # Acero metálico
		st_carc.border_color = Color("#94a3b8") # Resalte metálico
		st_carc.set_border_width_all(4)
		st_carc.set_corner_radius_all(32) # Extremos redondeados tipo cápsula
		st_carc.shadow_color = Color(0, 0, 0, 0.6)
		st_carc.shadow_size = 8
		carcasa.add_theme_stylebox_override("panel", st_carc)
		btn.add_child(carcasa)
		
		# Pantalla digital interior
		var pantalla = Panel.new()
		pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
		pantalla.offset_left = 14
		pantalla.offset_top = 12
		pantalla.offset_right = -42 # Deja espacio para el puerto derecho
		pantalla.offset_bottom = -12
		pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var st_pant = StyleBoxFlat.new()
		st_pant.bg_color = Color("#0f172a") # Fondo digital azul oscuro
		st_pant.border_color = Color("#38bdf8") # Borde cian neón
		st_pant.set_border_width_all(2)
		st_pant.set_corner_radius_all(18)
		pantalla.add_theme_stylebox_override("panel", st_pant)
		btn.add_child(pantalla)
		
		# Puerto/Conector de cable derecho
		var puerto = Panel.new()
		puerto.size = Vector2(24, 40)
		puerto.position = Vector2(310, 27)
		puerto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_port = StyleBoxFlat.new()
		st_port.bg_color = Color("#1e293b")
		st_port.border_color = Color("#22c55e") # Luz verde de puerto
		st_port.set_border_width_all(3)
		st_port.set_corner_radius_all(6)
		puerto.add_theme_stylebox_override("panel", st_port)
		btn.add_child(puerto)
		
		# MarginContainer con Label de operación
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.offset_left = 16
		margin.offset_top = 14
		margin.offset_right = -46
		margin.offset_bottom = -14
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(margin)
		
		var lbl = Label.new()
		lbl.name = "LabelTexto"
		lbl.text = _formatear_operacion(str(raw_op))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color("#38bdf8")) # Cian luminoso
		lbl.add_theme_color_override("font_outline_color", Color("#0369a1"))
		lbl.add_theme_constant_override("outline_size", 3)
		margin.add_child(lbl)
		
		btn.button_down.connect(func(): carcasa.position.y = 4.0)
		var restaurar = func(): carcasa.position.y = 0.0
		btn.button_up.connect(restaurar)
		btn.mouse_exited.connect(restaurar)
		
		var b_ref = btn
		btn.pressed.connect(func(): _seleccionar_nodo_izquierdo(b_ref))
		contenedor_izquierdo.add_child(btn)

	# --- TERMINALES DERECHOS (Cápsulas con nombre de Terminal y Respuesta) ---
	var respuestas: Array = []
	for p in pares_actuales:
		respuestas.append(int(p.get("respuesta_correcta", 20)))
	respuestas.shuffle()
	
	for val_resp in respuestas:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(340, 95)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.set_meta("valor_respuesta", val_resp)
		btn.set_meta("resuelto", false)
		
		# Carcasa metálica
		var carcasa = Panel.new()
		carcasa.name = "Carcasa"
		carcasa.set_anchors_preset(Control.PRESET_FULL_RECT)
		carcasa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var st_carc = StyleBoxFlat.new()
		st_carc.bg_color = Color("#475569")
		st_carc.border_color = Color("#94a3b8")
		st_carc.set_border_width_all(4)
		st_carc.set_corner_radius_all(32)
		st_carc.shadow_color = Color(0, 0, 0, 0.6)
		st_carc.shadow_size = 8
		carcasa.add_theme_stylebox_override("panel", st_carc)
		btn.add_child(carcasa)
		
		# Puerto/Conector izquierdo
		var puerto = Panel.new()
		puerto.size = Vector2(24, 40)
		puerto.position = Vector2(6, 27)
		puerto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_port = StyleBoxFlat.new()
		st_port.bg_color = Color("#1e293b")
		st_port.border_color = Color("#eab308") # Luz ámbar de puerto
		st_port.set_border_width_all(3)
		st_port.set_corner_radius_all(6)
		puerto.add_theme_stylebox_override("panel", st_port)
		btn.add_child(puerto)
		
		# Pantalla digital interior
		var pantalla = Panel.new()
		pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
		pantalla.offset_left = 42 # Deja espacio para el puerto izquierdo
		pantalla.offset_top = 12
		pantalla.offset_right = -14
		pantalla.offset_bottom = -12
		pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var st_pant = StyleBoxFlat.new()
		st_pant.bg_color = Color("#0f172a")
		st_pant.border_color = Color("#eab308") # Borde dorado/ámbar
		st_pant.set_border_width_all(2)
		st_pant.set_corner_radius_all(18)
		pantalla.add_theme_stylebox_override("panel", st_pant)
		btn.add_child(pantalla)
		
		# MarginContainer con Label de Terminal
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.offset_left = 46
		margin.offset_top = 14
		margin.offset_right = -16
		margin.offset_bottom = -14
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(margin)
		
		var lbl = Label.new()
		lbl.name = "LabelTexto"
		lbl.text = "Terminal " + str(val_resp)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color("#fbbf24")) # Ámbar/dorado brillante
		lbl.add_theme_color_override("font_outline_color", Color("#78350f"))
		lbl.add_theme_constant_override("outline_size", 3)
		margin.add_child(lbl)
		
		btn.button_down.connect(func(): carcasa.position.y = 4.0)
		var restaurar = func(): carcasa.position.y = 0.0
		btn.button_up.connect(restaurar)
		btn.mouse_exited.connect(restaurar)
		
		var b_ref = btn
		btn.pressed.connect(func(): _seleccionar_nodo_derecho(b_ref))
		contenedor_derecho.add_child(btn)

func _formatear_operacion(op_str: String) -> String:
	var op = op_str.to_lower()
	op = op.replace(" por ", " x ").replace(" mas ", " + ").replace(" más ", " + ")
	op = op.replace(" menos ", " - ").replace(" dividido en ", " ÷ ").replace(" / ", " ÷ ")
	if not op.ends_with("="): op += " = ?"
	return op.to_upper()

func _seleccionar_nodo_izquierdo(btn: Button):
	if not juego_activo or btn.get_meta("resuelto", false): return
	if nodo_izq_seleccionado and is_instance_valid(nodo_izq_seleccionado):
		nodo_izq_seleccionado.modulate = Color.WHITE
	nodo_izq_seleccionado = btn
	nodo_izq_seleccionado.modulate = Color("#fde047") # Amarillo de selección

func _seleccionar_nodo_derecho(btn_der: Button):
	if not juego_activo or not nodo_izq_seleccionado or btn_der.get_meta("resuelto", false): return
	var resp_esperada = int(nodo_izq_seleccionado.get_meta("respuesta_correcta"))
	var resp_ofrecida = int(btn_der.get_meta("valor_respuesta"))
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_panel) / 1000.0
	var datos_p = nodo_izq_seleccionado.get_meta("datos_pregunta", {})
	var es_correcto = (resp_esperada == resp_ofrecida)
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(datos_p)
		ConexionSupabase.registrar_en_historial(cat, es_correcto, tiempo_tardado)
	
	if es_correcto:
		_reproducir_sonido("Correcto")
		nodo_izq_seleccionado.set_meta("resuelto", true)
		btn_der.set_meta("resuelto", true)
		nodo_izq_seleccionado.modulate = Color("#4ade80") # Verde neón
		btn_der.modulate = Color("#4ade80")
		
		_trazar_cable_realista(nodo_izq_seleccionado, btn_der, true)
		nodo_izq_seleccionado = null
		
		conexiones_completadas += 1
		if conexiones_completadas >= total_conexiones_panel:
			aciertos_actuales += 1
			_actualizar_ui_header()
			var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
			if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
				var nd = SistemaExperto.evaluar_desempeno(dif_ant, true, tiempo_tardado)
				if DatosUsuario: DatosUsuario.dificultad_actual = nd
			if aciertos_actuales >= META_ACIERTOS:
				await get_tree().create_timer(1.0).timeout
				_finalizar_minijuego(true)
			else:
				await get_tree().create_timer(1.0).timeout
				_cargar_nuevo_panel_circuitos()
	else:
		_reproducir_sonido("Incorrecto")
		vidas_actuales -= 1
		var cable_error = _trazar_cable_realista(nodo_izq_seleccionado, btn_der, false)
		_actualizar_ui_header()
		var dif_ant = DatosUsuario.dificultad_actual if DatosUsuario else 0
		if SistemaExperto and SistemaExperto.has_method("evaluar_desempeno"):
			var nd = SistemaExperto.evaluar_desempeno(dif_ant, false, tiempo_tardado)
			if DatosUsuario: DatosUsuario.dificultad_actual = nd
		if nodo_izq_seleccionado:
			nodo_izq_seleccionado.modulate = Color.WHITE
			nodo_izq_seleccionado = null
		await get_tree().create_timer(0.6).timeout
		if is_instance_valid(cable_error): 
			cable_error.queue_free()
		if vidas_actuales <= 0:
			_finalizar_minijuego(false)

## ⚡ Trazador de Cables Realistas Multicapa con Curva Bézier y Plasma
func _trazar_cable_realista(btn_a: Control, btn_b: Control, es_exito: bool) -> Control:
	if not capa_lineas: return null
	
	# Puntos de conexión en los puertos de los terminales
	var pos_a = btn_a.global_position + Vector2(btn_a.size.x - 10, btn_a.size.y / 2.0) - capa_lineas.global_position
	var pos_b = btn_b.global_position + Vector2(10, btn_b.size.y / 2.0) - capa_lineas.global_position
	
	var contenedor_cable = Control.new()
	contenedor_cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Cálculo de curva Bézier cúbica con comba física realista
	var puntos_curva = PackedVector2Array()
	var distancia = pos_a.distance_to(pos_b)
	var sag = randf_range(30.0, 70.0) # Caída por gravedad del cable
	
	var p0 = pos_a
	var p1 = pos_a + Vector2(distancia * 0.35, sag)
	var p2 = pos_b - Vector2(distancia * 0.35, -sag * 0.5)
	var p3 = pos_b
	
	for step in range(21):
		var t = step / 20.0
		var punto = p0.bezier_interpolate(p1, p2, p3, t)
		puntos_curva.append(punto)
	
	# Capa 1: Resplandor exterior amplio (Glow)
	var glow_line = Line2D.new()
	glow_line.width = 24.0
	glow_line.default_color = Color(0.13, 0.9, 0.4, 0.35) if es_exito else Color(0.9, 0.2, 0.2, 0.35)
	glow_line.points = puntos_curva
	glow_line.joint_mode = Line2D.LINE_JOINT_ROUND
	glow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	contenedor_cable.add_child(glow_line)
	
	# Capa 2: Malla exterior del cable trenzado industrial (Verde oscuro / Rojo oscuro)
	var cable_base = Line2D.new()
	cable_base.width = 14.0
	cable_base.default_color = Color("#15803d") if es_exito else Color("#7f1d1d")
	cable_base.points = puntos_curva
	cable_base.joint_mode = Line2D.LINE_JOINT_ROUND
	cable_base.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cable_base.end_cap_mode = Line2D.LINE_CAP_ROUND
	contenedor_cable.add_child(cable_base)
	
	# Capa 3: Canal de plasma de energía brillante
	var cable_plasma = Line2D.new()
	cable_plasma.width = 7.0
	cable_plasma.default_color = Color("#4ade80") if es_exito else Color("#ef4444")
	cable_plasma.points = puntos_curva
	cable_plasma.joint_mode = Line2D.LINE_JOINT_ROUND
	cable_plasma.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cable_plasma.end_cap_mode = Line2D.LINE_CAP_ROUND
	contenedor_cable.add_child(cable_plasma)
	
	# Capa 4: Núcleo eléctrico central blanco luminoso
	var cable_core = Line2D.new()
	cable_core.width = 2.5
	cable_core.default_color = Color("#f0fdf4") if es_exito else Color("#fee2e2")
	cable_core.points = puntos_curva
	cable_core.joint_mode = Line2D.LINE_JOINT_ROUND
	cable_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cable_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	contenedor_cable.add_child(cable_core)
	
	capa_lineas.add_child(contenedor_cable)
	return contenedor_cable

func _limpiar_cables():
	if capa_lineas:
		for h in capa_lineas.get_children(): h.queue_free()

func _actualizar_ui_header():
	if label_aciertos:
		label_aciertos.text = "Circuitos Reparados: " + str(aciertos_actuales) + "/" + str(META_ACIERTOS)
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
	if panel_contenedor: panel_contenedor.visible = false
	minijuego_finalizado.emit(es_exito)
