# res://Escenas/Minijuegos/Minijuego_oscuras/MinijuegoBuscador.gd
extends Node2D

signal minijuego_finalizado(es_correcto)

@onready var nivel = $Nivel
@onready var Parallax = $Parallax2D
@onready var jugador = $Nivel/Jugador
@onready var HUD = $HUD
@onready var interfaz_pregunta = $HUD/InterfazPregunta

# 🎯 Nodos UI
@onready var label_num1 = $HUD/InterfazPregunta/VBoxContainer/PanelOperacion/LabelNum1
@onready var label_signo = $HUD/InterfazPregunta/VBoxContainer/PanelOperacion/LabelSigno
@onready var label_num2 = $HUD/InterfazPregunta/VBoxContainer/PanelOperacion/LabelNum2
@onready var linea_resta_suma = $HUD/InterfazPregunta/VBoxContainer/PanelOperacion/LineaRestaSuma
@onready var panel_operacion = $HUD/InterfazPregunta/VBoxContainer/PanelOperacion/TextureRect
@onready var contenedor_fichas = $HUD/InterfazPregunta/VBoxContainer/ContenedorFichas
@onready var pizarra_borrador = $HUD/InterfazPregunta/PizarraBorrador
@onready var controles_tactiles = $ControlesTactiles

@onready var label_gemas = $HUD/LabelGemas
@onready var contenedor_corazones = $HUD/ContenedorCorazones
@onready var luz_iluminacion_global = $Nivel/CanvasModulate

@export var escena_caja: PackedScene
@export var escena_ficha: PackedScene
@export var escena_casilla_destino: PackedScene
@export var cantidad_cajas_a_generar: int = 5

@onready var puntos_spawn = $Nivel/PuntosSpawn
@onready var contenedor_cajas = $Nivel/ContenedorCajas
@onready var mesa_generador: Area2D = $Nivel/MesaGenerador # Ajusta la ruta a tu nodo Area2D
@onready var collision_mesa: CollisionShape2D = $Nivel/MesaGenerador/CollisionShape2D
@onready var label_mensaje: Label = get_node_or_null("HUD/LabelMensaje") as Label
@onready var animador: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")
var Check_Morado = preload("res://assets/Imagenes/Check_pequeno.png")


var num1_activo: int = 0
var num2_activo: int = 0
var gemas_obtenidas: int = 0
var gemas_requeridas: int = 3
var vidas_actuales: int = 3
var juego_activo: bool = false
var pregunta_abierta: bool = false
var pregunta_actual_dict: Dictionary = {}

var caja_actual_interactuando: Node = null

# 🎨 Variables para la lógica por Pasos / Etapas
enum TipoOperacion { ESTANDAR, MULTI_LARGA }
var modo_actual: TipoOperacion = TipoOperacion.ESTANDAR

var etapa_multi: int = 1 # 1 = Productos Parciales, 2 = Suma Final
var prod_parcial_1_str: String = ""
var prod_parcial_2_str: String = ""
var resultado_final_str: String = ""

# Referencias dinámicas de casillas e insumos
var elementos_dinamicos: Array = []
var casillas_paso_1: Array = []
var casillas_paso_2: Array = []
var valores_paso_1: Dictionary = {}
var valores_paso_2: Dictionary = {}
var valores_llevadas: Dictionary = {}
var digitos_num1_estado: Array = []
var casillas_llevada_suma: Array = []

var btn_comprobar: Button = null

# 📐 Offsets y posiciones de UI
var OFFSET_Y_GLOBAL: float = 100.0

const POSICION_INICIAL: Vector2 = Vector2(376, 249)

func _ready():
	controles_tactiles.visible = false
	
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func iniciar_minijuego(_tema: String = "espacio"):
	if jugador:
		jugador.position = POSICION_INICIAL
		var cam_jugador = $Nivel/Jugador/Camera2D
		if cam_jugador:
			cam_jugador.enabled = true
			cam_jugador.make_current()
			
		if jugador.has_method("activar_movimiento"):
			jugador.activar_movimiento()
	
	if collision_mesa:
		collision_mesa.set_deferred("disabled", true)
	if label_mensaje:
		label_mensaje.visible = false
		
	gemas_obtenidas = 0
	vidas_actuales = 3
	juego_activo = true
	nivel.visible = true
	HUD.visible = true
	Parallax.visible = true
	
	generar_cajas_aleatorias()
	_actualizar_hud_gemas()
	_actualizar_interfaz_corazones()
	
	if interfaz_pregunta:
		interfaz_pregunta.visible = false
	
	if luz_iluminacion_global:
		luz_iluminacion_global.color = Color(0.08, 0.08, 0.15, 1.0)
	
	_configurar_controles_tactiles()
	_mostrar_banner_instrucciones("Muevete con WASD / Flechas y presiona E (o el boton tactil) para abrir las cajas.", "Buscador")

func _mostrar_banner_instrucciones(texto: String, audio_nombre: String = "Buscador"):
	if not HUD: return
	var banner_previo = HUD.get_node_or_null("BannerInstrucciones")
	if banner_previo:
		banner_previo.queue_free()
		
	var panel = PanelContainer.new()
	panel.name = "BannerInstrucciones"
	panel.anchors_preset = Control.PRESET_CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -370.0
	panel.offset_right = 370.0
	panel.offset_top = 20.0
	panel.offset_bottom = 62.0
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
	HUD.add_child(panel)
	
	# Reproducción de voz opcional (segura, no detiene el juego si no existe)
	if audio_nombre != "" and GestionAudio:
		GestionAudio.reproducir_audio_local(audio_nombre)
	
	# Animación: Aparece -> Espera 4.0s -> Desaparece
	panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_interval(4.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5)
	tw.tween_callback(panel.queue_free)

# Guardamos el tiempo exacto en el que se abre la caja
var tiempo_inicio_caja: float = 0.0

func _on_caja_solicitar_operacion(caja_node: Node2D):
	caja_actual_interactuando = caja_node
	
	# ⏱️ 1. Iniciar cronómetro de esta caja
	tiempo_inicio_caja = Time.get_ticks_msec()
	
	var pregunta = _obtener_datos_operacion()
	pregunta_actual_dict = pregunta
	_maquetar_operacion_matematica(pregunta)
	
	if HUD and HUD.has_node("BannerInstrucciones"):
		HUD.get_node("BannerInstrucciones").visible = false
	
	if interfaz_pregunta:
		interfaz_pregunta.visible = true
		pregunta_abierta = true
		if controles_tactiles:
			controles_tactiles.visible = false

func _limpiar_elementos_operacion():
	for node in elementos_dinamicos:
		if is_instance_valid(node):
			node.queue_free()
	elementos_dinamicos.clear()
	casillas_paso_1.clear()
	casillas_paso_2.clear()
	casillas_llevada_suma.clear() 
	valores_paso_1.clear()
	valores_paso_2.clear()
	valores_llevadas.clear()
	digitos_num1_estado.clear()
	
	label_num1.visible = false
	label_num2.visible = false
	if linea_resta_suma: linea_resta_suma.visible = false

func _maquetar_operacion_matematica(datos: Dictionary):
	_limpiar_elementos_operacion()
	
	print("ESTO ES DATOS: ", datos)
	
	# 1. Intentar obtener los números directamente
	var num1 = int(datos.get("num1", 0))
	var num2 = int(datos.get("num2", 0))
	
	# 2. Si no venían como num1/num2, parsear desde el campo "operacion" ("20 menos 11", "20 - 11", etc.)
	if num1 == 0 and num2 == 0 and datos.has("operacion"):
		var texto_op: String = str(datos["operacion"])
		var regex = RegEx.new()
		regex.compile("\\d+") # Buscar todas las secuencias de dígitos
		var coincidencias = regex.search_all(texto_op)
		
		if coincidencias.size() >= 2:
			num1 = int(coincidencias[0].get_string())
			num2 = int(coincidencias[1].get_string())
		else:
			# Respaldo si no hay números en el string
			num1 = 18
			num2 = 15
	elif num1 == 0 and num2 == 0:
		num1 = 18
		num2 = 15

	var cat = datos.get("categoria", "suma").to_lower()
	
	# Guardar referencias para mantener consistencia entre etapas
	num1_activo = num1
	num2_activo = num2
	
	var resp_val = int(datos.get("respuesta_correcta", num1 + num2))
	resultado_final_str = str(abs(resp_val))
	
	match cat:
		"suma":
			modo_actual = TipoOperacion.ESTANDAR
			label_signo.text = "+"
			_disposicion_vertical_estandar(num1, num2, "suma", "+")
			
		"resta":
			modo_actual = TipoOperacion.ESTANDAR
			var mayor = max(num1, num2)
			var menor = min(num1, num2)
			label_signo.text = "-"
			_disposicion_vertical_estandar(mayor, menor, "resta", "-")
			
		"multiplicacion", "multi":
			label_signo.text = "x"
			if str(num2).length() > 1:
				modo_actual = TipoOperacion.MULTI_LARGA
				etapa_multi = 1
				_disposicion_multiplicacion_larga(num1, num2)
			else:
				modo_actual = TipoOperacion.ESTANDAR
				print("ES MULTIPLICACION CORTAa")
				_disposicion_multiplicacion_corta(num1, num2)
			
		"division", "divi":
			modo_actual = TipoOperacion.ESTANDAR
			label_signo.text = "÷"
			# Garantizar que el resultado esperado sea el cociente de la división
			var cociente = num1 / max(1, num2)
			resultado_final_str = str(cociente)
			_disposicion_division_galera(num1, num2)

# 🔘 Botón de Validación Único
func _crear_boton_comprobar(pos_y: float):
	if btn_comprobar and is_instance_valid(btn_comprobar):
		btn_comprobar.queue_free()
		
	btn_comprobar = Button.new()
	btn_comprobar.text = "Comprobar"
	btn_comprobar.custom_minimum_size = Vector2(140, 40)
	var ancho_p = _obtener_ancho_panel()
	btn_comprobar.position = Vector2((ancho_p / 2.0) - 70, pos_y)
	btn_comprobar.add_theme_font_size_override("font_size", 18)
	btn_comprobar.pressed.connect(_validar_intento)
	btn_comprobar.icon = Check_Morado
	
	panel_operacion.add_child(btn_comprobar)
	elementos_dinamicos.append(btn_comprobar)

# Guardaremos referencias a los dígitos del minuendo para actualizar la cascada
var controles_prestamo_resta: Array = []

func _disposicion_vertical_estandar(num1: int, num2: int, tipo_operacion: String, signo_mostrar: String = "+"):
	var str_num1 = str(num1)
	var str_num2 = str(num2)
		
	var separacion_x: float = 40.0
	var centro_x = _obtener_ancho_panel() / 2.0
	var y_top = OFFSET_Y_GLOBAL + 30.0
	
	var max_len = max(str_num1.length(), str_num2.length())
	var total_cols = max(max_len, resultado_final_str.length())
	
	var x_unidades = centro_x + ((total_cols - 1) * separacion_x * 0.5)
	var y_casillas: float
	
	if label_signo:
		label_signo.visible = false

	controles_prestamo_resta.clear()

	# ➕ Llevadas para Suma / Multiplicación
	if tipo_operacion in ["suma", "multiplicacion"]:
		var y_llevada = y_top - 40.0
		for col in range(1, total_cols):
			var pos_x = x_unidades - (col * separacion_x)
			var btn_llevada = _crear_control_llevada(Vector2(pos_x, y_llevada), col)
			panel_operacion.add_child(btn_llevada)
			elementos_dinamicos.append(btn_llevada)

	# ➖ Renderizado de Num1 (Soporta prestar si es resta)
	for i in range(str_num1.length()):
		var idx_der = str_num1.length() - 1 - i
		var pos_x = x_unidades - (idx_der * separacion_x)
		
		if tipo_operacion == "resta":
			var ctrl = _crear_control_prestamo_cascada(str_num1[i], Vector2(pos_x, y_top), i, str_num1)
			panel_operacion.add_child(ctrl)
			elementos_dinamicos.append(ctrl)
			controles_prestamo_resta.append(ctrl)
		else:
			var lbl = _crear_label_formateado(str_num1[i], Vector2(pos_x, y_top))
			panel_operacion.add_child(lbl)
			elementos_dinamicos.append(lbl)

	# Dibujar Num2
	var y_num2 = y_top + 40.0
	for i in range(str_num2.length()):
		var idx_der = str_num2.length() - 1 - i
		var pos_x = x_unidades - (idx_der * separacion_x)
		var lbl = _crear_label_formateado(str_num2[i], Vector2(pos_x, y_num2))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# Signo
	var pos_x_signo = x_unidades - (max(str_num1.length(), str_num2.length()) * separacion_x)
	var lbl_signo_dinamico = _crear_label_formateado(signo_mostrar, Vector2(pos_x_signo, y_num2))
	panel_operacion.add_child(lbl_signo_dinamico)
	elementos_dinamicos.append(lbl_signo_dinamico)

	# Línea divisoria
	var y_linea = y_num2 + 35.0
	var x_inicio_linea = pos_x_signo - 10.0
	var largo_linea = (x_unidades - pos_x_signo) + separacion_x + 15.0
		
	var line = _crear_linea(Vector2(x_inicio_linea, y_linea), largo_linea)
	panel_operacion.add_child(line)
	elementos_dinamicos.append(line)

	# Casillas y Fichas
	y_casillas = y_linea + 15.0
	casillas_paso_1 = _instanciar_casillas(resultado_final_str.length(), x_unidades, separacion_x, y_casillas, valores_paso_1)
	
	_generar_fichas_digitos_combinadas([resultado_final_str])
	_crear_boton_comprobar(y_casillas + 85.0)


func _crear_control_prestamo_cascada(digito_char: String, pos: Vector2, idx_posicion: int, numero_completo: String) -> Control:
	var cont = Control.new()
	cont.position = pos
	cont.custom_minimum_size = Vector2(30, 40)
	
	var btn_prestamo = Button.new()
	btn_prestamo.text = ""
	btn_prestamo.custom_minimum_size = Vector2(26, 20)
	btn_prestamo.position = Vector2(2, -22)
	btn_prestamo.add_theme_font_size_override("font_size", 12)
	
	var lbl_num = Label.new()
	lbl_num.text = digito_char
	lbl_num.custom_minimum_size = Vector2(30, 30)
	lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_num.add_theme_font_size_override("font_size", 26)
	
	var linea_tacho = ColorRect.new()
	linea_tacho.size = Vector2(24, 3)
	linea_tacho.position = Vector2(3, 14)
	linea_tacho.color = Color.RED
	linea_tacho.visible = false
	
	var btn_click = TextureButton.new()
	btn_click.size = Vector2(30, 30)
	btn_click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Metadata para el motor de cascada
	cont.set_meta("valor_original", int(digito_char))
	cont.set_meta("idx", idx_posicion)
	cont.set_meta("tachado", false)
	cont.set_meta("lbl_prestamo", btn_prestamo)
	cont.set_meta("linea_tacho", linea_tacho)
	
	btn_click.pressed.connect(func():
		# 🚫 El dígito de las unidades (el último a la derecha) no puede prestar
		if idx_posicion == numero_completo.length() - 1:
			return
			
		var esta_tachado = cont.get_meta("tachado")
		cont.set_meta("tachado", not esta_tachado)
		_recalcular_prestamos_resta(numero_completo)
	)
	
	cont.add_child(lbl_num)
	cont.add_child(linea_tacho)
	cont.add_child(btn_prestamo)
	cont.add_child(btn_click)
	
	return cont


func _recalcular_prestamos_resta(numero_original: String) -> void:
	var total_digitos = controles_prestamo_resta.size()
	if total_digitos == 0: return

	# 1. Determinar el estado de tachado de cada columna
	var tachados = []
	for ctrl in controles_prestamo_resta:
		tachados.append(ctrl.get_meta("tachado"))

	# 2. Calcular los valores actualizados en cascada de izquierda a derecha
	var valores_calculados = []
	for i in range(total_digitos):
		valores_calculados.append(int(numero_original[i]))

	for i in range(total_digitos):
		if tachados[i]:
			var val_actual = valores_calculados[i]
			if val_actual > 0:
				valores_calculados[i] = val_actual - 1
			
			# Transferir el préstamo de 10 a la columna contigua a la derecha
			if i + 1 < total_digitos:
				valores_calculados[i + 1] += 10

	# 3. Reflejar visualmente los cambios en los nodos UI
	for i in range(total_digitos):
		var ctrl = controles_prestamo_resta[i]
		var val_orig = int(numero_original[i])
		var val_nuevo = valores_calculados[i]
		var es_tachado = tachados[i]
		
		var btn_p: Button = ctrl.get_meta("lbl_prestamo")
		var tacho: ColorRect = ctrl.get_meta("linea_tacho")
		
		tacho.visible = es_tachado
		
		# Si la casilla cambió de valor respecto al original o fue tachada explícitamente, mostrar el número
		if val_nuevo != val_orig or es_tachado:
			btn_p.text = str(val_nuevo)
		else:
			btn_p.text = ""

func _disposicion_multiplicacion_corta(num1: int, num2: int):
	var str_num1 = str(num1)
	var str_num2 = str(num2)
	
	var separacion_x: float = 40.0
	var centro_x = _obtener_ancho_panel() / 2.0
	var y_renglon = OFFSET_Y_GLOBAL + 80.0
	var y_llevadas = y_renglon - 40.0
	
	if label_signo:
		label_signo.visible = false

	# 1. Construir la secuencia de caracteres horizontal: "6", "x", "3"
	var operacion_caracteres: Array = []
	for c in str_num1:
		operacion_caracteres.append(c)
	operacion_caracteres.append("x")
	for c in str_num2:
		operacion_caracteres.append(c)

	var total_caracteres = operacion_caracteres.size()
	var ancho_total_texto = (total_caracteres - 1) * separacion_x
	var x_inicio = centro_x - (ancho_total_texto / 2.0)

	# 2. Llevadas: SOLO se crean si el primer número tiene 2 o más dígitos
	if str_num1.length() > 1:
		for col in range(str_num1.length()):
			var idx_der = str_num1.length() - 1 - col
			var pos_x = x_inicio + (idx_der * separacion_x)
			var btn_llevada = _crear_control_llevada(Vector2(pos_x, y_llevadas), col + 1)
			panel_operacion.add_child(btn_llevada)
			elementos_dinamicos.append(btn_llevada)

	# 3. Dibujar todos los caracteres de la operación
	for i in range(total_caracteres):
		var pos_x = x_inicio + (i * separacion_x)
		var lbl = _crear_label_formateado(operacion_caracteres[i], Vector2(pos_x, y_renglon))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# 4. Línea divisoria
	var y_linea = y_renglon + 35.0
	var x_inicio_linea = x_inicio - 15.0
	var largo_linea = (total_caracteres * separacion_x) + 10.0
	
	var line = _crear_linea(Vector2(x_inicio_linea, y_linea), largo_linea)
	panel_operacion.add_child(line)
	elementos_dinamicos.append(line)

	# 5. Punto de referencia X para alineación de casillas
	var x_unidades = x_inicio + (total_caracteres - 1) * separacion_x

	# 6. Casillas de resultado
	var y_casillas = y_linea + 15.0
	casillas_paso_1 = _instanciar_casillas(resultado_final_str.length(), x_unidades, separacion_x, y_casillas, valores_paso_1)
	
	# 7. Teclado de fichas y botón Comprobar
	_generar_fichas_digitos_combinadas([resultado_final_str])
	_crear_boton_comprobar(y_casillas + 80.0)
	
# ✖️ Multiplicación en Línea Horizontal (24 x 12)
func _disposicion_multiplicacion_larga(num1: int, num2: int):
	var str_num1 = str(num1)
	var str_num2 = str(num2)
	
	# 1. Obtener los dígitos del multiplicador (de derecha a izquierda)
	var d_unidades = int(str_num2[str_num2.length() - 1])
	var d_decenas = int(str_num2[0])
	
	# 2. Calcular los productos parciales numéricos
	var val_p1 = num1 * d_unidades
	var val_p2 = num1 * d_decenas

	# 3. Forzar a que la representación en texto tenga el ancho adecuado
	# Si val_p1 es 0 (ej: 26 x 0), se rellena a "00" para dar el espacio de unidades y decenas
	if val_p1 == 0:
		prod_parcial_1_str = "%0*d" % [str_num1.length(), 0]
	else:
		prod_parcial_1_str = str(val_p1)

	if val_p2 == 0:
		prod_parcial_2_str = "%0*d" % [str_num1.length(), 0]
	else:
		prod_parcial_2_str = str(val_p2)

	# 1. OCULTAR el Label de signo de la escena
	if label_signo:
		label_signo.visible = false

	# 2. Arreglo de la operación en una sola línea
	var operacion_caracteres: Array = []
	for c in str_num1:
		operacion_caracteres.append(c)
	operacion_caracteres.append("×") # Signo x integrado en el texto
	for c in str_num2:
		operacion_caracteres.append(c)

	var total_caracteres = operacion_caracteres.size()
	var separacion_x: float = 40.0
	var centro_x = _obtener_ancho_panel() / 2.0
	
	var y_renglon = OFFSET_Y_GLOBAL + 80.0
	var y_llevadas = y_renglon - 50.0

	var ancho_total_texto = (total_caracteres - 1) * separacion_x
	var x_inicio = centro_x - (ancho_total_texto / 2.0)

	# 3. Renderizar el enunciado en la misma línea
	for i in range(total_caracteres):
		var pos_x = x_inicio + (i * separacion_x)
		var lbl = _crear_label_formateado(operacion_caracteres[i], Vector2(pos_x, y_renglon))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# 4. Llevadas sobre el primer número (24)
	for i in range(str_num1.length()):
		var pos_x = x_inicio + (i * separacion_x)
		var btn_llevada = _crear_control_llevada(Vector2(pos_x, y_llevadas), i)
		panel_operacion.add_child(btn_llevada)
		elementos_dinamicos.append(btn_llevada)

	# 5. Línea divisoria continua
	var y_linea = y_renglon + 35.0
	var x_inicio_linea = x_inicio - 15.0
	var largo_linea = (total_caracteres * separacion_x) + 10.0
	
	var linea_base = _crear_linea(Vector2(x_inicio_linea, y_linea), largo_linea)
	panel_operacion.add_child(linea_base)
	elementos_dinamicos.append(linea_base)

	# 6. CASILLAS: Generar los DOS productos parciales
	var x_unidades = x_inicio + (str_num1.length() - 1) * separacion_x
	
	# Fila 1: Primer producto parcial (ej: 00) -> 2 casillas ? ?
	var y_prod1 = y_linea + 15.0
	var cas_prod1 = _instanciar_casillas(
		prod_parcial_1_str.length(), 
		x_unidades, 
		separacion_x, 
		y_prod1, 
		valores_paso_1, 
		0
	)

	# Fila 2: Segundo producto parcial (ej: 26) -> 2 casillas ? ? (desplazadas a las decenas)
	var y_prod2 = y_prod1 + 45.0
	var x_decenas = x_unidades - separacion_x
	var cas_prod2 = _instanciar_casillas(
		prod_parcial_2_str.length(), 
		x_decenas, 
		separacion_x, 
		y_prod2, 
		valores_paso_1, 
		prod_parcial_1_str.length()
	)

	# Registrar las casillas para la validación
	casillas_paso_1 = cas_prod1 + cas_prod2
	
	# Generar fichas de números para arrastrar
	_generar_fichas_digitos_combinadas([prod_parcial_1_str, prod_parcial_2_str])

	# 7. Botón Comprobar
	_crear_boton_comprobar(y_prod2 + 80.0)

func _activar_etapa_2_multiplicacion():
	etapa_multi = 2
	
	for node in elementos_dinamicos:
		if is_instance_valid(node): node.queue_free()
	elementos_dinamicos.clear()
	casillas_paso_1.clear()
	casillas_llevada_suma.clear()
	
	# Re-calcular resultado total explícitamente (18 * 15 = 270 -> 3 dígitos)
	resultado_final_str = str(num1_activo * num2_activo)
	
	var str_num1 = str(num1_activo)
	var str_num2 = str(num2_activo)
	
	var separacion_x: float = 40.0
	var centro_x = _obtener_ancho_panel() / 2.0
	var y_renglon = OFFSET_Y_GLOBAL + 80.0

	# 1. Enunciado en una sola línea
	var operacion_caracteres: Array = []
	for c in str_num1: operacion_caracteres.append(c)
	operacion_caracteres.append("×")
	for c in str_num2: operacion_caracteres.append(c)

	var total_caracteres = operacion_caracteres.size()
	var ancho_total_texto = (total_caracteres - 1) * separacion_x
	var x_inicio = centro_x - (ancho_total_texto / 2.0)

	for i in range(total_caracteres):
		var pos_x = x_inicio + (i * separacion_x)
		var lbl = _crear_label_formateado(operacion_caracteres[i], Vector2(pos_x, y_renglon))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# 2. Primera línea divisoria
	var y_linea = y_renglon + 35.0
	var x_inicio_linea = x_inicio - 15.0
	var largo_linea = (total_caracteres * separacion_x) + 10.0
	
	var linea_base = _crear_linea(Vector2(x_inicio_linea, y_linea), largo_linea)
	panel_operacion.add_child(linea_base)
	elementos_dinamicos.append(linea_base)

	# 3. Producto Parcial 1 (90) y Llevadas de la suma
	var x_unidades = x_inicio + (str_num1.length() - 1) * separacion_x
	var y_prod1 = y_linea + 50.0
	var y_llevada_suma = y_prod1 - 45.0
	
	var total_cols_suma = resultado_final_str.length()
	for col in range(1, total_cols_suma):
		var pos_x = x_unidades - (col * separacion_x)
		var btn_llevada = _crear_control_llevada(Vector2(pos_x, y_llevada_suma), 10 + col)
		panel_operacion.add_child(btn_llevada)
		elementos_dinamicos.append(btn_llevada)
		casillas_llevada_suma.append(btn_llevada)

	for i in range(prod_parcial_1_str.length()):
		var idx_der = prod_parcial_1_str.length() - 1 - i
		var pos_x = x_unidades - (idx_der * separacion_x)
		var lbl = _crear_label_formateado(prod_parcial_1_str[i], Vector2(pos_x, y_prod1))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# 4. Producto Parcial 2 (18_)
	var y_prod2 = y_prod1 + 45.0
	var x_decenas = x_unidades - separacion_x
	
	for i in range(prod_parcial_2_str.length()):
		var idx_der = prod_parcial_2_str.length() - 1 - i
		var pos_x = x_decenas - (idx_der * separacion_x)
		var lbl = _crear_label_formateado(prod_parcial_2_str[i], Vector2(pos_x, y_prod2))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# Signo +
	var pos_x_mas = x_decenas - (prod_parcial_2_str.length() * separacion_x)
	var lbl_mas = _crear_label_formateado("+", Vector2(pos_x_mas, y_prod2))
	panel_operacion.add_child(lbl_mas)
	elementos_dinamicos.append(lbl_mas)

	# 5. Segunda línea divisoria
	var y_linea2 = y_prod2 + 35.0
	var linea_suma = _crear_linea(Vector2(x_inicio_linea, y_linea2), largo_linea)
	panel_operacion.add_child(linea_suma)
	elementos_dinamicos.append(linea_suma)

	# 6. Casillas de respuesta final (Asegurando 3 casillas para 270)
	var y_final = y_linea2 + 15.0
	casillas_paso_2 = _instanciar_casillas(resultado_final_str.length(), x_unidades, separacion_x, y_final, valores_paso_2)
	
	# Generar fichas que garantizan incluir todos los dígitos de la respuesta
	_generar_fichas_digitos_combinadas([resultado_final_str])

	# 7. Botón Comprobar
	_crear_boton_comprobar(y_final + 80.0)

# 🔍 Lógica Central de Validación
func _validar_intento():
	if not juego_activo or not caja_actual_interactuando: return
	
	if modo_actual == TipoOperacion.ESTANDAR:
		var resp_alumno = _obtener_string_desde_diccionario(valores_paso_1, resultado_final_str.length())
		if resp_alumno == resultado_final_str:
			_procesar_acierto()
		else:
			_procesar_error(resp_alumno, resultado_final_str)

	elif modo_actual == TipoOperacion.MULTI_LARGA:
		if etapa_multi == 1:
			var p1_len = prod_parcial_1_str.length()
			var p2_len = prod_parcial_2_str.length()
			
			var p1_alumno = _obtener_string_rango(valores_paso_1, 0, p1_len)
			var p2_alumno = _obtener_string_rango(valores_paso_1, p1_len, p1_len + p2_len)
			
			if p1_alumno == prod_parcial_1_str and p2_alumno == prod_parcial_2_str:
				_activar_etapa_2_multiplicacion()
			else:
				_procesar_error(p1_alumno + " / " + p2_alumno, prod_parcial_1_str + " / " + prod_parcial_2_str)
				
		elif etapa_multi == 2:
			var resp_alumno = _obtener_string_desde_diccionario(valores_paso_2, resultado_final_str.length())
			if resp_alumno == resultado_final_str:
				_procesar_acierto()
			else:
				_procesar_error(resp_alumno, resultado_final_str)

func _procesar_acierto():
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_caja) / 1000.0
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual_dict)
		ConexionSupabase.registrar_en_historial(cat, true, tiempo_tardado)
	
	DatosUsuario.dificultad_actual = SistemaExperto.evaluar_desempeno(
		DatosUsuario.dificultad_actual, 
		true, 
		tiempo_tardado
	)
	
	gemas_obtenidas += 1
	_actualizar_hud_gemas()
	
	caja_actual_interactuando.abrir_caja()
	interfaz_pregunta.visible = false
	pregunta_abierta = false
	if HUD and HUD.has_node("BannerInstrucciones"):
		HUD.get_node("BannerInstrucciones").visible = true
	_configurar_controles_tactiles()
	
	# ⚡ Al obtener las gemas requeridas, activamos la mesa del generador para que el jugador vaya a ella
	if gemas_obtenidas >= gemas_requeridas:
		_activar_generador()

func _activar_generador():
	print("Generador activado - El jugador debe ir a la mesa para restaurar la energia.")
	if collision_mesa:
		collision_mesa.set_deferred("disabled", false)
	if label_mensaje:
		label_mensaje.text = "Gemas recolectadas: Ve a la Mesa del Generador."
		label_mensaje.visible = true
	_mostrar_banner_instrucciones("Gemas recolectadas: Ve a la Mesa del Generador para restaurar la energia.")

func _procesar_error(_ingresado: String, _esperado: String):
	# ⏱️ 2. Calcular tiempo tardado antes del error
	var tiempo_tardado = (Time.get_ticks_msec() - tiempo_inicio_caja) / 1000.0
	
	# 📊 REGISTRO PEDAGÓGICO EN HISTORIAL DE SUPABASE
	if ConexionSupabase:
		var cat = ConexionSupabase.determinar_categoria(pregunta_actual_dict)
		ConexionSupabase.registrar_en_historial(cat, false, tiempo_tardado)
	
	# 🧠 3. Evaluar con el Sistema Experto
	DatosUsuario.dificultad_actual = SistemaExperto.evaluar_desempeno(
		DatosUsuario.dificultad_actual, 
		false, 
		tiempo_tardado
	)
	
	vidas_actuales -= 1
	_actualizar_interfaz_corazones()
	
	if vidas_actuales <= 0:
		interfaz_pregunta.visible = false
		pregunta_abierta = false
		_finalizar_juego(false)

# 🛠️ Métodos Auxiliares
func _instanciar_casillas(cant: int, x_base: float, sep_x: float, pos_y: float, dict_destino: Dictionary, offset_idx: int = 0) -> Array:
	var arreglo_casillas = []
	for i in range(cant):
		var idx_derecha = cant - 1 - i
		var pos_x = x_base - (idx_derecha * sep_x)
		
		var nueva_casilla: Control = null
		if escena_casilla_destino:
			nueva_casilla = escena_casilla_destino.instantiate()
		else:
			var base = $HUD/InterfazPregunta/Casilla_Destino
			if base: nueva_casilla = base.duplicate()
			
		if not nueva_casilla: continue
		
		panel_operacion.add_child(nueva_casilla)
		elementos_dinamicos.append(nueva_casilla)
		var ancho_casilla = nueva_casilla.size.x if nueva_casilla.size.x > 0 else 30.0
		nueva_casilla.position = Vector2(pos_x - (ancho_casilla / 2.0) + 15.0, pos_y)
		nueva_casilla.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if nueva_casilla.has_node("LabelValor"): nueva_casilla.get_node("LabelValor").text = "?"
		elif nueva_casilla.has_node("Label"): nueva_casilla.get_node("Label").text = "?"
		
		var idx_global = offset_idx + i
		if nueva_casilla.has_signal("ficha_depositada"):
			var conexiones = nueva_casilla.ficha_depositada.get_connections()
			for c in conexiones: nueva_casilla.ficha_depositada.disconnect(c.callable)
			nueva_casilla.ficha_depositada.connect(func(val): dict_destino[idx_global] = val)
			
		arreglo_casillas.append(nueva_casilla)
	return arreglo_casillas

func _generar_fichas_digitos_combinadas(_respuestas_array: Array):
	for child in contenedor_fichas.get_children():
		child.queue_free()
		
	# Generar exactamente los números del 0 al 9 en orden constante
	for valor in range(10):
		if escena_ficha:
			var nueva_ficha = escena_ficha.instantiate()
			
			# 🎯 Asegurar captura de touch/click en botones instanciados dinámicamente
			nueva_ficha.mouse_filter = Control.MOUSE_FILTER_STOP
			nueva_ficha.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			contenedor_fichas.add_child(nueva_ficha)
			
			if nueva_ficha.has_method("configurar"):
				nueva_ficha.configurar(valor)

func _obtener_string_desde_diccionario(dict: Dictionary, largo: int) -> String:
	var str_out = ""
	for i in range(largo):
		str_out += str(dict.get(i, ""))
	return str_out

func _obtener_string_rango(dict: Dictionary, inicio: int, fin: int) -> String:
	var str_out = ""
	for i in range(inicio, fin):
		str_out += str(dict.get(i, ""))
	return str_out

# ➕ Llevadas Corregidas (Contenedor con tamaño mínimo real)
func _crear_control_llevada(pos: Vector2, idx_columna: int) -> Control:
	var cont = Control.new()
	cont.position = pos
	cont.custom_minimum_size = Vector2(30, 40)
	
	var btn = Button.new()
	btn.text = "+"
	btn.custom_minimum_size = Vector2(24, 20)
	btn.position = Vector2(0, 0)
	
	var lbl = Label.new()
	lbl.text = "0"
	lbl.custom_minimum_size = Vector2(24, 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, 30)
	lbl.modulate = Color(0.2, 0.9, 0.4, 0.0)
	
	valores_llevadas[idx_columna] = 0
	btn.pressed.connect(func():
		var actual = (valores_llevadas.get(idx_columna, 0) + 1) % 6
		valores_llevadas[idx_columna] = actual
		lbl.text = str(actual)
		lbl.modulate = Color(0.2, 0.9, 0.4, 1.0) if actual > 0 else Color(0.2, 0.9, 0.4, 0.0)
	)
	
	cont.add_child(btn)
	cont.add_child(lbl)
	return cont

func _crear_label_formateado(texto: String, pos: Vector2) -> Label:
	var lbl = Label.new()
	lbl.text = texto
	lbl.custom_minimum_size = Vector2(30, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 26)
	return lbl

func _crear_linea(pos: Vector2, ancho: float) -> ColorRect:
	var rect = ColorRect.new()
	rect.position = pos
	rect.size = Vector2(ancho, 3)
	rect.color = Color.WHITE
	return rect

func _disposicion_division_galera(dividendo: int, divisor: int):
	var str_dividendo = str(dividendo)
	var str_divisor = str(divisor)
	
	if label_signo: label_signo.visible = false
	if label_num1: label_num1.visible = false
	if label_num2: label_num2.visible = false
	
	var separacion_x: float = 35.0
	var centro_x = _obtener_ancho_panel() / 2.0
	var y_top = OFFSET_Y_GLOBAL + 30.0
	
	# Calcular ancho visual para centrar dividendo y divisor juntos
	var ancho_dividendo = str_dividendo.length() * separacion_x
	var ancho_divisor = str_divisor.length() * separacion_x
	var ancho_total = ancho_dividendo + 25.0 + ancho_divisor
	
	var x_inicio_dividendo = centro_x - (ancho_total / 2.0)
	
	# 1. Dibujar Dígitos del Dividendo (Ej: 45)
	for i in range(str_dividendo.length()):
		var pos_x = x_inicio_dividendo + (i * separacion_x)
		var lbl = _crear_label_formateado(str_dividendo[i], Vector2(pos_x, y_top))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# 2. Líneas de la Galera / Cajita (Ángulo L)
	var x_linea_vert = x_inicio_dividendo + ancho_dividendo + 10.0
	var y_linea_horiz = y_top + 35.0
	var largo_horiz = max(ancho_divisor + 20.0, resultado_final_str.length() * separacion_x + 20.0)
	
	# Línea vertical
	var line_v = ColorRect.new()
	line_v.position = Vector2(x_linea_vert, y_top - 5.0)
	line_v.size = Vector2(3, 40)
	line_v.color = Color.WHITE
	panel_operacion.add_child(line_v)
	elementos_dinamicos.append(line_v)

	# Línea horizontal
	var line_h = _crear_linea(Vector2(x_linea_vert, y_linea_horiz), largo_horiz)
	panel_operacion.add_child(line_h)
	elementos_dinamicos.append(line_h)

	# 3. Dibujar Dígitos del Divisor (Arriba de la línea horizontal, ej: 9)
	var x_inicio_divisor = x_linea_vert + 15.0
	for i in range(str_divisor.length()):
		var pos_x = x_inicio_divisor + (i * separacion_x)
		var lbl = _crear_label_formateado(str_divisor[i], Vector2(pos_x, y_top))
		panel_operacion.add_child(lbl)
		elementos_dinamicos.append(lbl)

	# 4. Casillas de Respuesta (Cociente) debajo de la línea horizontal
	var y_casillas = y_linea_horiz + 15.0
	var cant_casillas = resultado_final_str.length()
	var x_base_casillas = x_inicio_divisor + ((cant_casillas - 1) * separacion_x)
	
	casillas_paso_1 = _instanciar_casillas(cant_casillas, x_base_casillas, separacion_x, y_casillas, valores_paso_1)
	
	# 5. Fichas de Respuesta y Botón Comprobar
	_generar_fichas_digitos_combinadas([resultado_final_str])
	_crear_boton_comprobar(y_casillas + 80.0)

func _actualizar_hud_gemas():
	if label_gemas: label_gemas.text = "Gemas: " + str(gemas_obtenidas) + "/" + str(gemas_requeridas)

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

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			if HUD: HUD.visible = false
			if controles_tactiles: controles_tactiles.visible = false

func _finalizar_juego(es_exito: bool):
	if jugador and jugador.has_method("desactivar_movimiento"):
		jugador.desactivar_movimiento()
		
	# Apagamos la cámara local para que no interfiera con el tablero
	var cam_jugador = $Nivel/Jugador/Camera2D
	if cam_jugador:
		cam_jugador.enabled = false
		
	juego_activo = false
	visible = false
	if HUD:
		HUD.visible = false
	if controles_tactiles:
		controles_tactiles.visible = false
	minijuego_finalizado.emit(es_exito)

func _obtener_datos_operacion() -> Dictionary:
	var lista = DatosUsuario.banco_preguntas
	
	if lista != null and not lista.is_empty():
		# Forzamos int tanto para el valor buscado como para el parámetro del diccionario
		var dif_buscada: int = int(DatosUsuario.dificultad_actual)
		
		# 1. Filtrar asegurando casteo a entero en ambos lados
		var filtradas = lista.filter(func(p): 
			if not p.has("dificultad") or p["dificultad"] == null:
				return false
			return int(p["dificultad"]) == dif_buscada
		)
		
		print("Dificultad Buscada: ", dif_buscada, " | Preguntas encontradas: ", filtradas.size())
		
		# 2. Devolver una pregunta aleatoria de la dificultad deseada
		if not filtradas.is_empty(): 
			return filtradas.pick_random()
			
		print("ADVERTENCIA: No se encontraron preguntas para la dificultad ", dif_buscada, ". Usando aleatoria del banco.")
		return lista.pick_random()
	
	# 3. Respaldo dinámico
	var n1 = randi_range(15, 30)
	var n2 = randi_range(1, 10)
	print("FALLO: No hay preguntas en la RAM (DatosUsuario.banco_preguntas está vacío)")
	return {
		"num1": n1, 
		"num2": n2, 
		"categoria": "suma", 
		"respuesta_correcta": n1 + n2
	}
func _crear_digit_prestamo(digito_char: String, pos: Vector2, col_idx: int) -> Control:
	var cont = Control.new()
	cont.position = pos
	cont.custom_minimum_size = Vector2(30, 40)
	
	# Casilla/Botón para ingresar o ver el valor de reemplazo al prestar
	var btn_prestamo = Button.new()
	btn_prestamo.text = ""
	btn_prestamo.custom_minimum_size = Vector2(26, 20)
	btn_prestamo.position = Vector2(2, -22)
	btn_prestamo.add_theme_font_size_override("font_size", 12)
	
	# Label original del número
	var lbl_num = Label.new()
	lbl_num.text = digito_char
	lbl_num.custom_minimum_size = Vector2(30, 30)
	lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_num.add_theme_font_size_override("font_size", 26)
	
	# Línea de tachado (oculta por defecto)
	var linea_tacho = ColorRect.new()
	linea_tacho.size = Vector2(24, 3)
	linea_tacho.position = Vector2(3, 14)
	linea_tacho.color = Color.RED
	linea_tacho.visible = false
	
	# Botón invisible sobre el número para detectar interacción de prestado
	var btn_click = TextureButton.new()
	btn_click.size = Vector2(30, 30)
	btn_click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var estado_prestamo = {"tachado": false, "nuevo_valor": 0}
	
	btn_click.pressed.connect(func():
		var val_orig = int(digito_char)
		if not estado_prestamo["tachado"]:
			estado_prestamo["tachado"] = true
			linea_tacho.visible = true
			estado_prestamo["nuevo_valor"] = max(0, val_orig - 1)
			btn_prestamo.text = str(estado_prestamo["nuevo_valor"])
		else:
			estado_prestamo["tachado"] = false
			linea_tacho.visible = false
			btn_prestamo.text = ""
	)
	
	cont.add_child(lbl_num)
	cont.add_child(linea_tacho)
	cont.add_child(btn_prestamo)
	cont.add_child(btn_click)
	
	return cont
	
func generar_cajas_aleatorias():
	# 1. Limpiar cajas existentes
	for caja in contenedor_cajas.get_children():
		caja.queue_free()
		
	if not puntos_spawn or not escena_caja:
		return

	# 2. Obtener solo los nodos de salas que tengan al menos un Marker2D
	var salas_disponibles: Array = []
	for nodo_sala in puntos_spawn.get_children():
		# Verificar si la sala tiene marcadores válidos adentro
		var tiene_marcadores = false
		for hijo in nodo_sala.get_children():
			if hijo is Marker2D:
				tiene_marcadores = true
				break
		
		if tiene_marcadores:
			salas_disponibles.append(nodo_sala)

	if salas_disponibles.is_empty():
		return

	# 3. Mezclar la lista de salas para asegurar aleatoriedad sin repetir sala
	salas_disponibles.shuffle()

	# 4. Determinar cuántas cajas se crearán (sin exceder el total de salas disponibles)
	var total_a_crear = mini(cantidad_cajas_a_generar, salas_disponibles.size())

	# 5. Generar solo 1 caja por cada sala elegida
	for i in range(total_a_crear):
		var sala_seleccionada = salas_disponibles[i]
		
		# Filtrar los Marker2D dentro de la sala elegida
		var marcadores_sala: Array = []
		for hijo in sala_seleccionada.get_children():
			if hijo is Marker2D:
				marcadores_sala.append(hijo)
				
		# Seleccionar un punto aleatorio dentro de esa sala
		var marcador_elegido: Marker2D = marcadores_sala.pick_random()

		# Instanciar e insertar en la jerarquía PRIMERO
		var nueva_caja = escena_caja.instantiate()
		contenedor_cajas.add_child(nueva_caja)

		# Asignar la posición global DESPUÉS de que está en el árbol
		nueva_caja.global_position = marcador_elegido.global_position
		nueva_caja.solicitar_operacion.connect(_on_caja_solicitar_operacion)

func _obtener_ancho_panel() -> float:
	if panel_operacion and panel_operacion.size.x > 50:
		return panel_operacion.size.x
	elif interfaz_pregunta and interfaz_pregunta.size.x > 50:
		return interfaz_pregunta.size.x
	return get_viewport_rect().size.x * 0.65

func _on_mesa_generador_body_entered(body: Node2D):
	# Verificamos que sea el jugador y que tengamos el total de gemas
	if (body == jugador or body.name == "Jugador" or body.is_in_group("jugador")) and gemas_obtenidas >= gemas_requeridas and juego_activo:
		_secuencia_restaurar_energia()

func _secuencia_restaurar_energia():
	juego_activo = false # Desactivar interacción
	
	# 1. Bloquear al jugador para que no camine durante la secuencia
	if jugador and jugador.has_method("desactivar_movimiento"):
		jugador.desactivar_movimiento()
		
	if HUD and HUD.has_node("BannerInstrucciones"):
		HUD.get_node("BannerInstrucciones").visible = false

	if label_mensaje:
		label_mensaje.text = "¡Todas las gemas recolectadas! Restaurando energía..."
		label_mensaje.visible = true

	# 2. Transición progresiva de luz con CanvasModulate usando un Tween
	if luz_iluminacion_global:
		var tween = create_tween()
		tween.tween_property(luz_iluminacion_global, "color", Color(1.0, 1.0, 1.0, 1.0), 1.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		await tween.finished

	# 3. Mostrar mensaje de éxito
	if label_mensaje:
		label_mensaje.text = "¡Excelente! La energía ha sido restaurada."
		
	# Esperar 1.5 segundos para que el jugador lea el mensaje
	await get_tree().create_timer(1.5).timeout
	
	# 4. Ocultar mensaje y salir al tablero
	if label_mensaje:
		label_mensaje.visible = false
		
	_finalizar_juego(true)

func AbrirCerrar_Pizarra():
	if pizarra_borrador and pizarra_borrador.has_method("toggle_pizarra"):
		#if esta_expandido:
			#minimizar_panel()
		pizarra_borrador.toggle_pizarra()
		pizarra_borrador.z_index = 20
		
func _configurar_controles_tactiles():
	if not controles_tactiles:
		return
		
	var nombre_os = OS.get_name()
	var es_movil_nativo = nombre_os in ["Android", "iOS"]
	print("Sistema Operativo: ", nombre_os)
	print("Es movil:", es_movil_nativo)
	
	var es_web_movil = false
	if nombre_os == "Web" or OS.has_feature("web"):
		print("ENTRO?", OS.has_feature("web"))
		if JavaScriptBridge:
			var user_agent = JavaScriptBridge.eval("navigator.userAgent", true)
			if user_agent != null:
				var ua_lower = str(user_agent).to_lower()
				if "android" in ua_lower or "iphone" in ua_lower or "ipad" in ua_lower or "mobile" in ua_lower:
					es_web_movil = true

	# 📱 Mostrar controles táctiles solo si es móvil nativo o navegador móvil (teléfono/tablet)
	var debe_mostrar_tactil = es_movil_nativo or es_web_movil
	controles_tactiles.visible = debe_mostrar_tactil
	
	# Asegurar etiquetas WASD y E centradas y con mouse_filter IGNORE (para no bloquear el clic/toque)
	_configurar_label_boton_tactil(controles_tactiles.get_node_or_null("DPad/BtnArriba"), "W")
	_configurar_label_boton_tactil(controles_tactiles.get_node_or_null("DPad/BtnIzquierda"), "A")
	_configurar_label_boton_tactil(controles_tactiles.get_node_or_null("DPad/BtnAbajo"), "S")
	_configurar_label_boton_tactil(controles_tactiles.get_node_or_null("DPad/BtnDerecha"), "D")
	_configurar_label_boton_tactil(controles_tactiles.get_node_or_null("BtnInteractuar"), "E")
	
	# 🔒 Ocultar explícitamente el botón de interacción al arrancar el minijuego
	var hud_touch = get_tree().get_nodes_in_group("boton_interactuar_touch")
	if not hud_touch.is_empty():
		hud_touch[0].visible = false

func _configurar_label_boton_tactil(btn: TouchScreenButton, letra: String):
	if not btn: return
	var lbl = btn.get_node_or_null("Label")
	if not lbl:
		lbl = Label.new()
		lbl.name = "Label"
		btn.add_child(lbl)
		
	lbl.text = letra
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.offset_left = 0.0
	lbl.offset_top = 0.0
	lbl.offset_right = 709.0
	lbl.offset_bottom = 709.0
	lbl.add_theme_font_size_override("font_size", 280)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("outline_size", 32)
