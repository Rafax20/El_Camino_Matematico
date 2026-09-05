extends Control

@onready var grid_laminas = $GridLaminas
@onready var label_titulo_pais = $Titulo_pais

@onready var boton_anterior = $BotonAnterior
@onready var boton_siguiente = $BotonSiguiente
@onready var label_monedas = $ContenedorMonedas/HBoxContainer/LabelMonedas if has_node("ContenedorMonedas/HBoxContainer/LabelMonedas") else null
@onready var boton_tienda = $BotonTienda

# 📌 Estructura de navegación sin duplicar rutas de imágenes
var paginas_mundial: Array = [
	{ "pais": "Venezuela", "inicio": 1, "fin": 18 },
	{ "pais": "Argentina", "inicio": 19, "fin": 36 },
	{ "pais": "Portugal", "inicio": 37, "fin": 54 },
	{ "pais": "España", "inicio": 55, "fin": 72 },
	{ "pais": "Inglaterra", "inicio": 73, "fin": 90 },
	{ "pais": "Brasil", "inicio": 91, "fin": 108 },
]

var pagina_actual_indice: int = 0
var posicion_original_y: float = 0.0 # 📌 Guardará la altura correcta
var posicion_original_x: float = 0.0 # 📌 Nueva variable para bloquear la X inicial
var is_animating: bool = false # 🔒 Bandera de bloqueo

func _ready():
	pagina_actual_indice = 0
	# Registramos la posición vertical inicial configurada desde el editor
	posicion_original_y = grid_laminas.position.y
	posicion_original_x = grid_laminas.position.x
	
	actualizar_ui_monedas()
	await ConexionSupabase.cargar_album_nube()
	actualizar_ui_monedas()
	_mostrar_pagina(pagina_actual_indice, "derecha")

func actualizar_ui_monedas():
	if label_monedas:
		label_monedas.text = "Monedas: %d" % DatosUsuario.monedas

func _mostrar_pagina(indice: int, direccion: String):
	# 🔒 1. PROTECCIÓN: Si ya hay una animación en curso, salimos
	if is_animating: 
		return
		
	is_animating = true
	
	# Deshabilitamos botones para evitar interrupciones durante la transición
	boton_anterior.disabled = true
	boton_siguiente.disabled = true
	
	var datos_pais = paginas_mundial[indice]
	label_titulo_pais.text = "Colección " + datos_pais["pais"] + " - Edición Especial"
	
	# 🎬 2. ANIMACIÓN DE SALIDA
	var tween = create_tween().set_parallel(true)
	var offset_salida = -300 if direccion == "derecha" else 300
	tween.tween_property(grid_laminas, "position:x", grid_laminas.position.x + offset_salida, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(grid_laminas, "modulate:a", 0.0, 0.25)
	
	await tween.finished
	
	# 🛠️ 3. CONSTRUCCIÓN DINÁMICA
	for hijo in grid_laminas.get_children():
		hijo.queue_free()
		
	var escena_ranura = preload("res://Escenas/RanuraLamina.tscn")
	for id in range(datos_pais["inicio"], datos_pais["fin"] + 1):
		var nueva_ranura = escena_ranura.instantiate()
		grid_laminas.add_child(nueva_ranura)
		nueva_ranura.id_lamina = id
		
		# Referencia al catálogo centralizado en DatosUsuario
		if DatosUsuario.CATALOGO_LAMINAS.has(id):
			nueva_ranura.textura_jugador = DatosUsuario.CATALOGO_LAMINAS[id]
		else:
			nueva_ranura.textura_jugador = null
			
		nueva_ranura.actualizar_estado()
		
	# Actualizamos visibilidad de botones
	boton_anterior.visible = (indice > 0)
	boton_siguiente.visible = (indice < paginas_mundial.size() - 1)
	
	# 🎬 4. ANIMACIÓN DE ENTRADA
	var offset_entrada = 300 if direccion == "derecha" else -300

	# El punto de destino final siempre será 'posicion_original_x' fijo
	grid_laminas.position.x = posicion_original_x + offset_entrada
	grid_laminas.position.y = posicion_original_y 

	var tween_entrada = create_tween().set_parallel(true)
	# Animamos hacia la posición X fija guardada del editor
	tween_entrada.tween_property(grid_laminas, "position:x", posicion_original_x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_entrada.tween_property(grid_laminas, "modulate:a", 1.0, 0.3)

	await tween_entrada.finished
	
	# 🔓 5. REINICIO: Reactivamos botones y liberamos el bloqueo
	boton_anterior.disabled = false
	boton_siguiente.disabled = false
	is_animating = false

func _on_boton_siguiente_pressed():
	if pagina_actual_indice < paginas_mundial.size() - 1:
		pagina_actual_indice += 1
		_mostrar_pagina(pagina_actual_indice, "derecha")

func _on_boton_anterior_pressed():
	if pagina_actual_indice > 0:
		pagina_actual_indice -= 1
		_mostrar_pagina(pagina_actual_indice, "izquierda")

# ==========================================
# 🏪 TIENDA ESPACIAL DE SOBRES
# ==========================================
func _on_boton_tienda_pressed():
	_abrir_tienda_sobres()

func _abrir_tienda_sobres():
	var capa_tienda = CanvasLayer.new()
	capa_tienda.name = "CapaTiendaSobres"
	capa_tienda.layer = 90
	add_child(capa_tienda)
	
	var fondo = ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.04, 0.08, 0.9)
	capa_tienda.add_child(fondo)
	
	var tarjeta = Panel.new()
	tarjeta.set_anchors_preset(Control.PRESET_CENTER)
	tarjeta.anchor_left = 0.5
	tarjeta.anchor_top = 0.5
	tarjeta.anchor_right = 0.5
	tarjeta.anchor_bottom = 0.5
	tarjeta.offset_left = -520
	tarjeta.offset_top = -290
	tarjeta.offset_right = 520
	tarjeta.offset_bottom = 290
	tarjeta.pivot_offset = Vector2(520, 290)
	
	var st_tarjeta = StyleBoxFlat.new()
	st_tarjeta.bg_color = Color("#0f172a")
	st_tarjeta.border_color = Color("#f59e0b")
	st_tarjeta.set_border_width_all(4)
	st_tarjeta.set_corner_radius_all(20)
	st_tarjeta.shadow_color = Color(0.96, 0.62, 0.04, 0.4)
	st_tarjeta.shadow_size = 18
	tarjeta.add_theme_stylebox_override("panel", st_tarjeta)
	capa_tienda.add_child(tarjeta)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	tarjeta.add_child(vbox)
	
	# Encabezado con Icono PNG
	var hbox_tit = HBoxContainer.new()
	hbox_tit.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_tit.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox_tit)
	
	var ico_tienda = TextureRect.new()
	ico_tienda.custom_minimum_size = Vector2(32, 32)
	ico_tienda.texture = load("res://assets/Iconos_UI/Icono_Tienda.png")
	ico_tienda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico_tienda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox_tit.add_child(ico_tienda)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "TIENDA DE SOBRES DEL MUNDIAL"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 24)
	lbl_titulo.add_theme_color_override("font_color", Color("#fde047"))
	lbl_titulo.add_theme_color_override("font_outline_color", Color("#78350f"))
	lbl_titulo.add_theme_constant_override("outline_size", 3)
	hbox_tit.add_child(lbl_titulo)
	
	# Saldo con Icono de Moneda PNG
	var hbox_saldo = HBoxContainer.new()
	hbox_saldo.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_saldo.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_saldo)
	
	var ico_moneda_saldo = TextureRect.new()
	ico_moneda_saldo.custom_minimum_size = Vector2(24, 24)
	ico_moneda_saldo.texture = load("res://assets/Iconos_UI/Icono_Moneda.png")
	ico_moneda_saldo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico_moneda_saldo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox_saldo.add_child(ico_moneda_saldo)
	
	var lbl_saldo = Label.new()
	lbl_saldo.text = "Tus Monedas: %d  (Cada sobre cuesta 10 monedas y contiene 5 láminas)" % DatosUsuario.monedas
	lbl_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_saldo.add_theme_font_size_override("font_size", 16)
	lbl_saldo.add_theme_color_override("font_color", Color("#38bdf8"))
	hbox_saldo.add_child(lbl_saldo)
	
	# Cuadrícula de paquetes de países (3 columnas x 2 filas)
	var grid_sobres = GridContainer.new()
	grid_sobres.columns = 3
	grid_sobres.add_theme_constant_override("h_separation", 14)
	grid_sobres.add_theme_constant_override("v_separation", 10)
	grid_sobres.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid_sobres)
	
	var paises_tienda = [
		{"pais": "Venezuela", "flag_path": "res://assets/Iconos_UI/Bandera_Venezuela.png", "inicio": 1, "fin": 18, "color": Color("#1e3a8a")},
		{"pais": "Argentina", "flag_path": "res://assets/Iconos_UI/Bandera_Argentina.png", "inicio": 19, "fin": 36, "color": Color("#0284c7")},
		{"pais": "Portugal", "flag_path": "res://assets/Iconos_UI/Bandera_Portugal.png", "inicio": 37, "fin": 54, "color": Color("#991b1b")},
		{"pais": "España", "flag_path": "res://assets/Iconos_UI/Bandera_Espana.png", "inicio": 55, "fin": 72, "color": Color("#b45309")},
		{"pais": "Inglaterra", "flag_path": "res://assets/Iconos_UI/Bandera_Inglaterra.png", "inicio": 73, "fin": 90, "color": Color("#1e293b")},
		{"pais": "Brasil", "flag_path": "res://assets/Iconos_UI/Bandera_Brasil.png", "inicio": 91, "fin": 108, "color": Color("#15803d")}
	]
	
	var lbl_mensaje_error = Label.new()
	lbl_mensaje_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mensaje_error.add_theme_font_size_override("font_size", 14)
	lbl_mensaje_error.add_theme_color_override("font_color", Color("#f87171"))
	lbl_mensaje_error.text = ""
	
	for p_info in paises_tienda:
		var panel_sobre = Panel.new()
		panel_sobre.custom_minimum_size = Vector2(175, 145)
		var st_sobre = StyleBoxFlat.new()
		st_sobre.bg_color = p_info["color"]
		st_sobre.border_color = Color("#fde047")
		st_sobre.set_border_width_all(2)
		st_sobre.set_corner_radius_all(12)
		panel_sobre.add_theme_stylebox_override("panel", st_sobre)
		grid_sobres.add_child(panel_sobre)
		
		var vbox_p = VBoxContainer.new()
		vbox_p.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox_p.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_p.add_theme_constant_override("separation", 4)
		panel_sobre.add_child(vbox_p)
		
		# Bandera PNG
		var tex_flag = TextureRect.new()
		tex_flag.custom_minimum_size = Vector2(65, 42)
		if ResourceLoader.exists(p_info["flag_path"]):
			tex_flag.texture = load(p_info["flag_path"])
		tex_flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox_p.add_child(tex_flag)
		
		var lbl_nombre = Label.new()
		lbl_nombre.text = "Sobre " + p_info["pais"]
		lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_nombre.add_theme_font_size_override("font_size", 14)
		lbl_nombre.add_theme_color_override("font_color", Color.WHITE)
		vbox_p.add_child(lbl_nombre)
		
		var btn_comprar = Button.new()
		btn_comprar.text = "COMPRAR (10 Monedas)"
		btn_comprar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_comprar.custom_minimum_size = Vector2(150, 32)
		
		var st_btn = StyleBoxFlat.new()
		st_btn.bg_color = Color("#f59e0b")
		st_btn.set_corner_radius_all(8)
		btn_comprar.add_theme_stylebox_override("normal", st_btn)
		btn_comprar.add_theme_color_override("font_color", Color("#0f172a"))
		btn_comprar.add_theme_font_size_override("font_size", 12)
		
		btn_comprar.pressed.connect(func():
			if DatosUsuario.monedas < 10:
				lbl_mensaje_error.text = "Monedas insuficientes. Completa tableros para ganar más monedas."
				var tw_err = create_tween()
				tw_err.tween_property(lbl_mensaje_error, "scale", Vector2(1.1, 1.1), 0.1)
				tw_err.tween_property(lbl_mensaje_error, "scale", Vector2.ONE, 0.1)
				return
				
			# 🪙 Cobrar 10 monedas
			DatosUsuario.monedas -= 10
			ConexionSupabase.actualizar_monedas_en_nube(DatosUsuario.monedas)
			actualizar_ui_monedas()
			lbl_saldo.text = "Tus Monedas: %d  (Cada sobre cuesta 10 monedas y contiene 5 láminas)" % DatosUsuario.monedas
			lbl_mensaje_error.text = ""
			
			# 🎁 Abrir 5 láminas al azar
			var resultado_apertura: Array = []
			var id_inicio = p_info["inicio"]
			var id_fin = p_info["fin"]
			
			var hubo_nuevas = false
			for i in range(5):
				var lamina_id = randi_range(id_inicio, id_fin)
				var es_nueva = not DatosUsuario.laminas_poseidas.has(lamina_id)
				if es_nueva:
					DatosUsuario.laminas_poseidas.append(lamina_id)
					hubo_nuevas = true
					
				resultado_apertura.append({
					"id": lamina_id,
					"es_nueva": es_nueva
				})
			
			if hubo_nuevas:
				DatosUsuario.laminas_poseidas.sort()
				ConexionSupabase.guardar_laminas_poseidas_en_nube()
				
			capa_tienda.queue_free()
			_mostrar_unboxing_sobre(p_info["pais"], resultado_apertura)
		)
		vbox_p.add_child(btn_comprar)
		
	vbox.add_child(lbl_mensaje_error)
	
	# Botón para cerrar tienda
	var btn_cerrar = Button.new()
	btn_cerrar.text = "CERRAR TIENDA"
	btn_cerrar.custom_minimum_size = Vector2(180, 40)
	btn_cerrar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var st_cerrar = StyleBoxFlat.new()
	st_cerrar.bg_color = Color("#334155")
	st_cerrar.set_corner_radius_all(10)
	btn_cerrar.add_theme_stylebox_override("normal", st_cerrar)
	btn_cerrar.pressed.connect(func(): capa_tienda.queue_free())
	vbox.add_child(btn_cerrar)

# ==========================================
# 🎁 VENTANA DE UNBOXING Y REVELACIÓN DE SOBRE
# ==========================================
func _mostrar_unboxing_sobre(nombre_pais: String, cartas: Array):
	var capa_unboxing = CanvasLayer.new()
	capa_unboxing.name = "CapaUnboxing"
	capa_unboxing.layer = 95
	add_child(capa_unboxing)
	
	var fondo = ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.04, 0.08, 0.94)
	capa_unboxing.add_child(fondo)
	
	var tarjeta = Panel.new()
	tarjeta.set_anchors_preset(Control.PRESET_CENTER)
	tarjeta.anchor_left = 0.5
	tarjeta.anchor_top = 0.5
	tarjeta.anchor_right = 0.5
	tarjeta.anchor_bottom = 0.5
	tarjeta.offset_left = -520
	tarjeta.offset_top = -280
	tarjeta.offset_right = 520
	tarjeta.offset_bottom = 280
	tarjeta.pivot_offset = Vector2(520, 280)
	
	var st_t = StyleBoxFlat.new()
	st_t.bg_color = Color("#0b1329")
	st_t.border_color = Color("#38bdf8")
	st_t.set_border_width_all(4)
	st_t.set_corner_radius_all(24)
	st_t.shadow_color = Color(0.22, 0.74, 0.97, 0.5)
	st_t.shadow_size = 20
	tarjeta.add_theme_stylebox_override("panel", st_t)
	capa_unboxing.add_child(tarjeta)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	tarjeta.add_child(vbox)
	
	# Encabezado con Icono PNG de fiesta
	var hbox_tit = HBoxContainer.new()
	hbox_tit.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_tit.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_tit)
	
	var ico_fiesta = TextureRect.new()
	ico_fiesta.custom_minimum_size = Vector2(36, 36)
	ico_fiesta.texture = load("res://assets/Iconos_UI/Icono_Fiesta.png")
	ico_fiesta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico_fiesta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox_tit.add_child(ico_fiesta)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "¡SOBRE DE %s ABIERTO!" % nombre_pais.to_upper()
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_font_size_override("font_size", 28)
	lbl_tit.add_theme_color_override("font_color", Color("#fde047"))
	lbl_tit.add_theme_color_override("font_outline_color", Color("#78350f"))
	lbl_tit.add_theme_constant_override("outline_size", 4)
	hbox_tit.add_child(lbl_tit)
	
	var hbox_cartas = HBoxContainer.new()
	hbox_cartas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_cartas.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_cartas)
	
	for c_data in cartas:
		var id_lam = c_data["id"]
		var es_nueva = c_data["es_nueva"]
		
		var contenedor_carta = Control.new()
		contenedor_carta.custom_minimum_size = Vector2(170, 230)
		hbox_cartas.add_child(contenedor_carta)
		
		var panel_carta = Panel.new()
		panel_carta.set_anchors_preset(Control.PRESET_FULL_RECT)
		var st_c = StyleBoxFlat.new()
		st_c.bg_color = Color("#1e293b")
		st_c.border_color = Color("#10b981") if es_nueva else Color("#475569")
		st_c.set_border_width_all(3)
		st_c.set_corner_radius_all(12)
		panel_carta.add_theme_stylebox_override("panel", st_c)
		contenedor_carta.add_child(panel_carta)
		
		# Textura de la lámina
		var tex_rect = TextureRect.new()
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if DatosUsuario.CATALOGO_LAMINAS.has(id_lam):
			tex_rect.texture = DatosUsuario.CATALOGO_LAMINAS[id_lam]
		panel_carta.add_child(tex_rect)
		
		# Etiqueta ¡NUEVO! o (Repetida)
		if es_nueva:
			var hbox_nuevo = HBoxContainer.new()
			hbox_nuevo.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_nuevo.position = Vector2(10, 195)
			hbox_nuevo.size = Vector2(150, 26)
			
			var ico_star = TextureRect.new()
			ico_star.custom_minimum_size = Vector2(20, 20)
			ico_star.texture = load("res://assets/Iconos_UI/Icono_Estrella.png")
			ico_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ico_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox_nuevo.add_child(ico_star)
			
			var badge_nuevo = Label.new()
			badge_nuevo.text = "¡NUEVO!"
			badge_nuevo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge_nuevo.add_theme_font_size_override("font_size", 16)
			badge_nuevo.add_theme_color_override("font_color", Color("#34d399"))
			badge_nuevo.add_theme_color_override("font_outline_color", Color("#064e3b"))
			badge_nuevo.add_theme_constant_override("outline_size", 3)
			hbox_nuevo.add_child(badge_nuevo)
			
			panel_carta.add_child(hbox_nuevo)
			
			# Animación pulsante para el badge de NUEVO (vinculada al nodo para que muera con él)
			var tw_pulse = hbox_nuevo.create_tween().set_loops()
			tw_pulse.tween_property(hbox_nuevo, "scale", Vector2(1.15, 1.15), 0.5)
			tw_pulse.tween_property(hbox_nuevo, "scale", Vector2.ONE, 0.5)
		else:
			var badge_rep = Label.new()
			badge_rep.text = "Repetida"
			badge_rep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge_rep.add_theme_font_size_override("font_size", 13)
			badge_rep.add_theme_color_override("font_color", Color("#94a3b8"))
			badge_rep.position = Vector2(10, 200)
			badge_rep.size = Vector2(150, 25)
			panel_carta.add_child(badge_rep)
			
	# Botón para volver al álbum
	var btn_volver_album = Button.new()
	btn_volver_album.text = "GUARDAR Y VOLVER AL ÁLBUM"
	btn_volver_album.custom_minimum_size = Vector2(260, 46)
	btn_volver_album.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var st_btn_volver = StyleBoxFlat.new()
	st_btn_volver.bg_color = Color("#10b981")
	st_btn_volver.set_corner_radius_all(12)
	btn_volver_album.add_theme_stylebox_override("normal", st_btn_volver)
	btn_volver_album.add_theme_font_size_override("font_size", 16)
	
	btn_volver_album.pressed.connect(func():
		btn_volver_album.disabled = true
		capa_unboxing.queue_free()
		
		# Navegamos a la página del país del sobre que se abrió si existe
		var idx_pais = _obtener_indice_pais(nombre_pais)
		if idx_pais != -1:
			pagina_actual_indice = idx_pais
		_mostrar_pagina(pagina_actual_indice, "derecha")
	)
	vbox.add_child(btn_volver_album)

func _obtener_indice_pais(nombre: String) -> int:
	for i in range(paginas_mundial.size()):
		if str(paginas_mundial[i]["pais"]).to_lower() == nombre.to_lower():
			return i
	return -1
