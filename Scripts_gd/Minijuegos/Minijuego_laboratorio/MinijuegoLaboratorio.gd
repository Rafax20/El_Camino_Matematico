extends Control

# --- CONFIGURACIÓN Y NODOS UI ---
@export var OFFSET_Y_GLOBAL: float = 60.0

@onready var cliente_alien: TextureRect = $MinijuegoCompleto/ClienteAlien
@onready var globo_dialogo: PanelContainer = $MinijuegoCompleto/GloboDialogo
@onready var texto_dialogo: Label = $MinijuegoCompleto/GloboDialogo/TextoDialogo

# Nodos de los dos paneles nativos de la escena
@onready var panel_operacion: Panel = $MinijuegoCompleto/PanelOperacion
@onready var panel_grande: Panel = $MinijuegoCompleto/PanelGrande

@onready var contenedor_fichas = $MinijuegoCompleto/ContenedorFichas
@onready var gemas_label = $MinijuegoCompleto/UIHeader/AciertosLabel
@onready var vidas_container = $MinijuegoCompleto/UIHeader/VidasContainer
@onready var pizarra_borrador = $MinijuegoCompleto/PizarraBorrador
@onready var audio_player: AudioStreamPlayer = get_node_or_null("MinijuegoCompleto/AudioPlayer") as AudioStreamPlayer
@onready var UI = $MinijuegoCompleto/UIHeader

# Sprites y Texturas
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")
var Check_Morado = preload("res://assets/Imagenes/Check_pequeno.png")
var Digito = preload("res://assets/Minijuegos/minijuego Laboratorio/Digito.png")
var Digito_Presionado = preload("res://assets/Minijuegos/minijuego Laboratorio/Digito_Presionado.png")

var texturas_aliens: Array = [
	preload("res://assets/Minijuegos/minijuego Laboratorio/Alien1.png"),
	preload("res://assets/Minijuegos/minijuego Laboratorio/Alien2.png"),
	preload("res://assets/Minijuegos/minijuego Laboratorio/Alien3.png"),
]

# Aliens 4-7 se cargan dinámicamente porque pueden no existir aún
var _rutas_aliens_extra: Array[String] = [
	"res://assets/Minijuegos/minijuego Laboratorio/Alien4.jpg",
	"res://assets/Minijuegos/minijuego Laboratorio/Alien5.jpg",
	"res://assets/Minijuegos/minijuego Laboratorio/Alien6.jpg",
	"res://assets/Minijuegos/minijuego Laboratorio/Alien7.jpg",
]

signal minijuego_finalizado(es_correcto: bool)

# --- ESTADO DEL JUEGO ---
var vidas: int = 3
var aciertos: int = 0
var resultado_final_str: String = ""
var bloqueado: bool = false

var casillas_paso_1: Array = []
var valores_paso_1: Array = []

var esta_expandido: bool = false
var tween_panel: Tween

# --- BANCO DE PREGUNTAS (16 preguntas de regla de tres para 4to grado) ---
var banco_preguntas: Array = [
	# --- ORIGINALES ---
	{ "cantidad_a1": 2, "objeto_a": "motores", "cantidad_b1": 8, "objeto_b": "tanques de gas", "cantidad_a2": 5 },
	{ "cantidad_a1": 3, "objeto_a": "pócimas", "cantidad_b1": 12, "objeto_b": "cristales de hiperviaje", "cantidad_a2": 4 },
	{ "cantidad_a1": 4, "objeto_a": "propulsores", "cantidad_b1": 20, "objeto_b": "baterías de plasma", "cantidad_a2": 6 },
	{ "cantidad_a1": 5, "objeto_a": "sondas", "cantidad_b1": 15, "objeto_b": "celdas de energía", "cantidad_a2": 8 },
	# --- NUEVAS ---
	{ "cantidad_a1": 2, "objeto_a": "naves", "cantidad_b1": 10, "objeto_b": "misiles de protón", "cantidad_a2": 3 },
	{ "cantidad_a1": 3, "objeto_a": "escudos", "cantidad_b1": 9, "objeto_b": "generadores de fuerza", "cantidad_a2": 5 },
	{ "cantidad_a1": 4, "objeto_a": "robots", "cantidad_b1": 12, "objeto_b": "chips de memoria", "cantidad_a2": 7 },
	{ "cantidad_a1": 6, "objeto_a": "trajes espaciales", "cantidad_b1": 18, "objeto_b": "tanques de oxígeno", "cantidad_a2": 4 },
	{ "cantidad_a1": 2, "objeto_a": "telescopios", "cantidad_b1": 6, "objeto_b": "lentes de cuarzo", "cantidad_a2": 5 },
	{ "cantidad_a1": 5, "objeto_a": "drones", "cantidad_b1": 20, "objeto_b": "baterías solares", "cantidad_a2": 3 },
	{ "cantidad_a1": 3, "objeto_a": "estaciones", "cantidad_b1": 15, "objeto_b": "módulos de habitar", "cantidad_a2": 6 },
	{ "cantidad_a1": 4, "objeto_a": "cruceros", "cantidad_b1": 24, "objeto_b": "cápsulas de combustible", "cantidad_a2": 5 },
	{ "cantidad_a1": 2, "objeto_a": "satélites", "cantidad_b1": 14, "objeto_b": "antenas de señal", "cantidad_a2": 3 },
	{ "cantidad_a1": 5, "objeto_a": "rovers", "cantidad_b1": 10, "objeto_b": "ruedas todo terreno", "cantidad_a2": 8 },
	{ "cantidad_a1": 3, "objeto_a": "cañones", "cantidad_b1": 6, "objeto_b": "núcleos de energía", "cantidad_a2": 7 },
	{ "cantidad_a1": 4, "objeto_a": "contenedores", "cantidad_b1": 16, "objeto_b": "cristales de argón", "cantidad_a2": 6 },
]

var datos_pregunta_actual: Dictionary = {}

func _ready():
	$MinijuegoCompleto.visible = false
	_cargar_aliens_disponibles()
	panel_operacion.visible = false
	if panel_grande:
		panel_grande.visible = false
		panel_grande.modulate.a = 0.0
		
	globo_dialogo.visible = false
	UI.visible = false

func _cargar_aliens_disponibles():
	for ruta in _rutas_aliens_extra:
		var r_png = ruta.replace(".jpg", ".png")
		if ResourceLoader.exists(ruta):
			texturas_aliens.append(load(ruta))
		elif ResourceLoader.exists(r_png):
			texturas_aliens.append(load(r_png))
	
	# Asegurar que el Botón OK no tape las casillas del panel pequeño
	if panel_operacion.has_node("BotonPantalla"):
		var btn_ok_peq = panel_operacion.get_node("BotonPantalla")
		btn_ok_peq.mouse_filter = Control.MOUSE_FILTER_PASS
		btn_ok_peq.pressed.connect(expandir_panel)

	# Asegurar que el Botón OK no tape las casillas del panel grande
	if panel_grande and panel_grande.has_node("BotonPantalla"):
		var btn_ok_grande = panel_grande.get_node("BotonPantalla")
		btn_ok_grande.mouse_filter = Control.MOUSE_FILTER_PASS
		btn_ok_grande.pressed.connect(minimizar_panel)
		
		
	if get_tree().current_scene == self:
		$MinijuegoCompleto.visible = true
		iniciar_minijuego("espacio")

# --- TRANSICIÓN FADE IN / FADE OUT ENTRE PANELES ---
func expandir_panel():
	if esta_expandido or not panel_grande: return
	esta_expandido = true
	
	if pizarra_borrador and pizarra_borrador.visible:
		pizarra_borrador.visible = false

	if tween_panel and tween_panel.is_running():
		tween_panel.kill()

	panel_grande.visible = true
	panel_grande.z_index = 10
	
	tween_panel = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_panel.tween_property(panel_operacion, "modulate:a", 0.0, 0.25)
	tween_panel.tween_property(panel_grande, "modulate:a", 1.0, 0.25)
	
	tween_panel.chain().tween_callback(func():
		panel_operacion.visible = false
	)

func minimizar_panel():
	if not esta_expandido or not panel_grande: return
	esta_expandido = false
	
	if tween_panel and tween_panel.is_running():
		tween_panel.kill()

	panel_operacion.visible = true
	
	tween_panel = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_panel.tween_property(panel_grande, "modulate:a", 0.0, 0.25)
	tween_panel.tween_property(panel_operacion, "modulate:a", 1.0, 0.25)
	
	tween_panel.chain().tween_callback(func():
		panel_grande.visible = false
		panel_grande.z_index = 0
	)

func _unhandled_input(event: InputEvent):
	if esta_expandido and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if panel_grande:
			var rect_panel = Rect2(panel_grande.global_position, panel_grande.size)
			if not rect_panel.has_point(event.global_position):
				minimizar_panel()
				get_viewport().set_input_as_handled()

var tiempo_inicio_mision: float = 0.0

# --- CARGA Y ACTUALIZACIÓN DE DATOS EN LA ESCENA ---
func _cargar_nueva_mision(datos: Dictionary):
	tiempo_inicio_mision = Time.get_ticks_msec()
	UI.visible = true
	var a1 = datos.get("cantidad_a1", 2)
	var b1 = datos.get("cantidad_b1", 8)
	var a2 = datos.get("cantidad_a2", 5)
	var obj_a = datos.get("objeto_a", "cohetes")
	var obj_b = datos.get("objeto_b", "tanques")
	
	var resp_calculada = (a2 * b1) / max(1, a1)
	resultado_final_str = str(resp_calculada)
	
	valores_paso_1.clear()
	for i in range(resultado_final_str.length()):
		valores_paso_1.append("")

	# 1. Actualizar el Panel Pequeño (PanelOperacion)
	_actualizar_textos_panel(panel_operacion, a1, b1, a2, obj_a, obj_b)
	
	# 2. Actualizar el Panel Grande (PanelGrande)
	if panel_grande:
		_actualizar_textos_panel(panel_grande, a1, b1, a2, obj_a, obj_b)
		
	# Preparar las casillas para la entrada numérica
	_preparar_casillas_respuestas()
	_generar_fichas_digitos_combinadas([resultado_final_str])

func _actualizar_textos_panel(target_panel: Panel, a1: int, b1: int, a2: int, obj_a: String, obj_b: String):
	# Fila Base (Información conocida)
	if target_panel.has_node("MarginContainer/VBoxContainer/FilaBase/Cantidad A1"):
		target_panel.get_node("MarginContainer/VBoxContainer/FilaBase/Cantidad A1").text = str(a1) + " " + obj_a
	if target_panel.has_node("MarginContainer/VBoxContainer/FilaBase/Cantidad B1"):
		target_panel.get_node("MarginContainer/VBoxContainer/FilaBase/Cantidad B1").text = str(b1) + " " + obj_b
		
	# Fila Incógnita (Operación a resolver)
	if target_panel.has_node("MarginContainer/VBoxContainer/FilaIncognita/Cantidad A2"):
		target_panel.get_node("MarginContainer/VBoxContainer/FilaIncognita/Cantidad A2").text = str(a2) + " " + obj_a
	if target_panel.has_node("MarginContainer/VBoxContainer/FilaIncognita/Nombre del Objeto B"):
		target_panel.get_node("MarginContainer/VBoxContainer/FilaIncognita/Nombre del Objeto B").text = obj_b

func _preparar_casillas_respuestas():
	casillas_paso_1.clear()
	
	var contenedores: Array = []
	if panel_operacion.has_node("MarginContainer/VBoxContainer/FilaIncognita/ContenedorCasillas"):
		contenedores.append(panel_operacion.get_node("MarginContainer/VBoxContainer/FilaIncognita/ContenedorCasillas"))
	if panel_grande and panel_grande.has_node("MarginContainer/VBoxContainer/FilaIncognita/ContenedorCasillas"):
		contenedores.append(panel_grande.get_node("MarginContainer/VBoxContainer/FilaIncognita/ContenedorCasillas"))

	for c in contenedores:
		
		for child in c.get_children():
			child.queue_free()
			
		for i in range(resultado_final_str.length()):
			var btn = Button.new()
			btn.text = "?"
			btn.custom_minimum_size = Vector2(24, 24)
			
			# Asegurar la captura del clic
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			
			var idx = i
			btn.pressed.connect(func():
				valores_paso_1[idx] = ""
				_sincronizar_casillas()
			)
			c.add_child(btn)
			casillas_paso_1.append(btn)

func _sincronizar_casillas():
	for i in range(casillas_paso_1.size()):
		var idx_valor = i % resultado_final_str.length()
		var txt = valores_paso_1[idx_valor]
		casillas_paso_1[i].text = "?" if txt == "" else txt

# --- MÉTODOS COMPLEMENTARIOS Y LÓGICA DE JUEGO ---
func iniciar_minijuego(tema: String = "espacio"):
	$MinijuegoCompleto.visible = true
	visible = true
	UI.visible = true
	panel_operacion.visible = true
	panel_operacion.modulate.a = 1.0
	contenedor_fichas.visible = true
	
	await get_tree().process_frame
	
	vidas = 3
	aciertos = 0
	bloqueado = false # REINICIAMOS EL CANDADO
	_actualizar_ui_header()
	_mostrar_banner_instrucciones("🧪 ¡Calcula la regla de tres y arrastra los números para resolver la fórmula!")
	obtener_siguiente_pregunta()
	iniciar_secuencia_alien()

func _mostrar_banner_instrucciones(texto: String, audio_nombre: String = "Instrucciones/como_jugar_laboratorio"):
	var root_ui = $MinijuegoCompleto
	if not root_ui: return
	var banner_previo = root_ui.get_node_or_null("BannerInstrucciones")
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
	root_ui.add_child(panel)
	
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

func obtener_siguiente_pregunta():
	banco_preguntas.shuffle()
	datos_pregunta_actual = banco_preguntas[0]
	_cargar_nueva_mision(datos_pregunta_actual)

func _sacudir_panel():
	var panel_activo = panel_grande if esta_expandido else panel_operacion
	var pos_base = panel_activo.position.x
	var tween = create_tween()
	tween.tween_property(panel_activo, "position:x", pos_base + 8.0, 0.05)
	tween.tween_property(panel_activo, "position:x", pos_base - 8.0, 0.05)
	tween.tween_property(panel_activo, "position:x", pos_base, 0.05)

func _validar_respuesta():
	if bloqueado: return # Si el candado está activo, ignora los clics
	bloqueado = true     # Cierra el candado inmediatamente al presionar el botón
	
	var respuesta_ingresada = ""
	for val in valores_paso_1:
		respuesta_ingresada += val
		
	if respuesta_ingresada == resultado_final_str:
		_al_acertar()
	else:
		_al_fallar()

func _al_acertar():
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_mision) / 1000.0
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(datos_pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, true, tiempo_tardado)
	
	aciertos += 1
	_actualizar_ui_header()
	if aciertos >= 3:
		_finalizar_minijuego(true)
	else:
		await get_tree().create_timer(0.5).timeout
		alien_atendido_con_exito()

func _al_fallar():
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_mision) / 1000.0
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(datos_pregunta_actual)
		ConexionSupabase.registrar_en_historial(cat, false, tiempo_tardado)
		
	vidas -= 1
	_sacudir_panel()
	_actualizar_ui_header()
	
	if vidas == 2:
		_reproducir_voz("res://assets/Audio/juli_casi.ogg")
	elif vidas == 1:
		_reproducir_voz("res://assets/Audio/juli_ultimo_intento.ogg")
	
	for i in range(valores_paso_1.size()):
		valores_paso_1[i] = ""
	_sincronizar_casillas()
		
	if vidas <= 0:
		_reproducir_voz("res://assets/Audio/juli_game_over.ogg")
		await get_tree().create_timer(1.2).timeout
		aciertos = 0
		_finalizar_minijuego(false)
	else:
		bloqueado = false # DESBLOQUEA para que pueda intentar de nuevo

func _reproducir_voz(ruta_stream: String):
	if audio_player and ResourceLoader.exists(ruta_stream):
		audio_player.stream = load(ruta_stream)
		audio_player.play()

func _actualizar_ui_header():
	if gemas_label:
		gemas_label.text = "Aciertos: " + str(aciertos) + "/3"
	if vidas_container:
		var corazones = vidas_container.get_children()
		for i in range(corazones.size()):
			if corazones[i] is TextureRect:
				corazones[i].texture = textura_corazon_lleno if i < vidas else textura_corazon_vacio

func iniciar_secuencia_alien() -> void:
	if texturas_aliens.size() > 0:
		cliente_alien.texture = texturas_aliens.pick_random()

	cliente_alien.position = Vector2(1200, 100) 
	cliente_alien.visible = true
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(cliente_alien, "position", Vector2(450, 100), 1.2)
	tween.finished.connect(_mostrar_peticion_alien)

func _mostrar_peticion_alien() -> void:
	globo_dialogo.visible = true
	var cant_objetivo = datos_pregunta_actual.get("cantidad_a2", 4)
	var obj_condicion = datos_pregunta_actual.get("objeto_a", "pócimas")
	var obj_buscar = datos_pregunta_actual.get("objeto_b", "cristales de hiperviaje")
	
	texto_dialogo.text = "¡Saludos! Necesito comprar suficientes " + obj_buscar + " para abastecer " + str(cant_objetivo) + " " + obj_condicion + " de mi nave."
	texto_dialogo.visible_ratio = 0.0
	
	var tween_texto = create_tween()
	tween_texto.tween_property(texto_dialogo, "visible_ratio", 1.0, 1.2)
	tween_texto.finished.connect(func(): 
		if panel_operacion:
			panel_operacion.modulate.a = 1.0
			panel_operacion.visible = true
		bloqueado = false # DESBLOQUEA el input cuando termina de hablar
	)

func alien_atendido_con_exito() -> void:
	esta_expandido = false
	if tween_panel and tween_panel.is_running():
		tween_panel.kill()
		
	if panel_grande:
		panel_grande.visible = false
		panel_grande.modulate.a = 0.0
		panel_grande.z_index = 0
		
	if panel_operacion:
		panel_operacion.visible = false
		panel_operacion.modulate.a = 1.0
		
	globo_dialogo.visible = false
	
	var tween_salida = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_salida.tween_property(cliente_alien, "position", Vector2(-400, 200), 1.0)
	tween_salida.finished.connect(obtener_siguiente_pregunta)
	tween_salida.finished.connect(iniciar_secuencia_alien)


func _generar_fichas_digitos_combinadas(_respuestas: Array):
	for child in contenedor_fichas.get_children():
		child.queue_free()
	
	var style_empty = StyleBoxEmpty.new()
	var offset_arriba: float = -3.0 # Pixeles a subir el Label cuando el botón está suelto
		
	for digito in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		var btn_ficha = TextureButton.new()
		btn_ficha.texture_normal = Digito
		btn_ficha.texture_pressed = Digito_Presionado
		
		# --- ESCALADO DE LA TEXTURA ---
		btn_ficha.custom_minimum_size = Vector2(33, 33)
		btn_ficha.ignore_texture_size = true
		btn_ficha.stretch_mode = TextureButton.STRETCH_SCALE
		
		# --- CREACIÓN Y CENTRADO DEL LABEL HIJO ---
		var lbl_digito = Label.new()
		lbl_digito.text = digito
		lbl_digito.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_digito.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_digito.add_theme_stylebox_override("normal", style_empty)
		lbl_digito.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_digito.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_digito.add_theme_font_size_override("font_size", 14)
		
		# Posición inicial: desplazado ligeramente hacia arriba
		lbl_digito.position.y = offset_arriba
		
		# --- EFECTO DE HUNDIMIENTO Y RESTAURACIÓN ---
		# Función helper para restaurar el estado elevado
		var restaurar_label = func():
			lbl_digito.position.y = offset_arriba

		btn_ficha.button_down.connect(func():
			lbl_digito.position.y = 0.0 # Al presionar, baja al centro perfecto
		)
		
		# Restaura si se suelta el clic o si el cursor sale del botón
		btn_ficha.button_up.connect(restaurar_label)
		btn_ficha.mouse_exited.connect(restaurar_label)
		
		btn_ficha.add_child(lbl_digito)
		
		# --- EVENTO DEL BOTÓN ---
		var d_val = digito
		btn_ficha.pressed.connect(func(): _insertar_digito_en_casilla_vacia(d_val))
		contenedor_fichas.add_child(btn_ficha)

func _insertar_digito_en_casilla_vacia(digito: String):
	for i in range(valores_paso_1.size()):
		if valores_paso_1[i] == "":
			valores_paso_1[i] = digito
			_sincronizar_casillas()
			break

func _finalizar_minijuego(es_exito: bool):
	bloqueado = true # Asegura que nada se pueda presionar
	visible = false
	$MinijuegoCompleto.visible = false # ESTO FALTABA PARA OCULTAR TODO EL CONTENEDOR
	
	if UI: UI.visible = false 
	if panel_operacion: panel_operacion.visible = false
	if panel_grande: panel_grande.visible = false
	if globo_dialogo: globo_dialogo.visible = false
	if contenedor_fichas: contenedor_fichas.visible = false
	if pizarra_borrador: pizarra_borrador.visible = false
	
	if has_node("PistasHelper"): $PistasHelper.visible = false
	
	minijuego_finalizado.emit(es_exito)

func AbrirCerrar_Pizarra():
	if pizarra_borrador and pizarra_borrador.has_method("toggle_pizarra"):
		#if esta_expandido:
			#minimizar_panel()
		pizarra_borrador.toggle_pizarra()
		pizarra_borrador.z_index = 20
	
