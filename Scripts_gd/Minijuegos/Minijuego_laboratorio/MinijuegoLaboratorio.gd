extends Control

# --- CONFIGURACIÓN Y NODOS UI ---
@export var OFFSET_Y_GLOBAL: float = 60.0

@onready var panel_operacion = $PanelOperacion
@onready var contenedor_fichas = $ContenedorFichas
@onready var gemas_label = $UIHeader/GemasLabel
@onready var vidas_container = $UIHeader/VidasContainer

signal minijuego_finalizado(es_correcto: bool)

# --- ESTADO DEL JUEGO ---
var vidas: int = 3
var gemas: int = 0
var resultado_final_str: String = ""

# Guardar referencias de elementos instanciados para limpiarlos
var elementos_dinamicos: Array = []
var casillas_paso_1: Array = []
var valores_paso_1: Array = []

# --- BANCO DE PREGUNTAS ---
var banco_preguntas: Array = [
	{
		"cantidad_a1": 2, "objeto_a": "cohetes",
		"cantidad_b1": 8, "objeto_b": "tanques",
		"cantidad_a2": 5
	},
	{
		"cantidad_a1": 3, "objeto_a": "pócimas",
		"cantidad_b1": 12, "objeto_b": "cristales",
		"cantidad_a2": 4
	},
	{
		"cantidad_a1": 4, "objeto_a": "motores",
		"cantidad_b1": 20, "objeto_b": "baterías",
		"cantidad_a2": 6
	},
	{
		"cantidad_a1": 5, "objeto_a": "sondas",
		"cantidad_b1": 15, "objeto_b": "módulos",
		"cantidad_a2": 8
	}
]

var datos_pregunta_actual: Dictionary = {}

func _ready():
	# Si ejecutas la escena del minijuego sola directamente (F6), la iniciamos manualmente
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func iniciar_minijuego(tema: String = "espacio"):
	# 1. Encender visibilidad de la raíz y de sus componentes UI de golpe
	visible = true
	$UIHeader.visible = true
	panel_operacion.visible = true
	contenedor_fichas.visible = true
	if has_node("PistasHelper"):
		$PistasHelper.visible = true
	
	# ⚠️ CLAVE: Esperamos un frame para que Godot reconozca la visibilidad 
	# y calcule las dimensiones reales (size.x) del panel antes de añadir hijos.
	await get_tree().process_frame
	
	# 2. Posicionar contenedores correctamente
	_posicionar_contenedor_fichas()
	
	# 3. Reiniciar variables de estado
	vidas = 3
	gemas = 0
	_actualizar_ui_header()
	
	# 4. Generar la pregunta y sus elementos visuales en el panel visible
	obtener_siguiente_pregunta()

# --- NÚCLEO DE CARGA Y BANCO DE PREGUNTAS ---
func obtener_siguiente_pregunta():
	banco_preguntas.shuffle()
	datos_pregunta_actual = banco_preguntas[0]
	_cargar_nueva_mision(datos_pregunta_actual)

func _cargar_nueva_mision(datos: Dictionary):
	_limpiar_elementos_operacion()
	_disposicion_regla_de_tres(datos)

func _disposicion_regla_de_tres(datos: Dictionary):
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
	
	var separacion_x: float = 40.0
	var centro_x = _obtener_ancho_panel() / 2.0
	var y_base = OFFSET_Y_GLOBAL + 80.0
	
	# 1. Título de la Misión
	var lbl_titulo = Label.new()
	lbl_titulo.text = "🧪 MEZCLA DE PROPULSIÓN GALÁCTICA"
	lbl_titulo.position = Vector2(centro_x - 180.0, y_base)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	panel_operacion.add_child(lbl_titulo)
	elementos_dinamicos.append(lbl_titulo)
	
	# 2. Fila 1: Base conocida
	var y_fila1 = y_base + 60.0
	var texto_fila1 = str(a1) + " " + obj_a + "   ────────►   " + str(b1) + " " + obj_b
	var lbl_f1 = _crear_label_formateado(texto_fila1, Vector2(centro_x - 220.0, y_fila1))
	lbl_f1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel_operacion.add_child(lbl_f1)
	elementos_dinamicos.append(lbl_f1)
	
	# 3. Fila 2: Incógnita
	var y_fila2 = y_fila1 + 50.0
	var texto_fila2_izq = str(a2) + " " + obj_a + "   ────────►   "
	var lbl_f2_izq = _crear_label_formateado(texto_fila2_izq, Vector2(centro_x - 220.0, y_fila2))
	lbl_f2_izq.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel_operacion.add_child(lbl_f2_izq)
	elementos_dinamicos.append(lbl_f2_izq)
	
	# 4. Instanciar casillas alineadas
	var x_casillas = centro_x + 50.0
	casillas_paso_1 = _instanciar_casillas(
		resultado_final_str.length(), 
		x_casillas, 
		separacion_x, 
		y_fila2 - 5.0, 
		valores_paso_1
	)
	
	# Unidad al lado de las casillas
	var ancho_casillas = resultado_final_str.length() * separacion_x
	var lbl_unidad = _crear_label_formateado(obj_b, Vector2(x_casillas + ancho_casillas + 10.0, y_fila2))
	lbl_unidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel_operacion.add_child(lbl_unidad)
	elementos_dinamicos.append(lbl_unidad)

	# 5. Generar Fichas e instanciar Botón Comprobar
	_generar_fichas_digitos_combinadas([resultado_final_str])
	_crear_boton_comprobar(y_fila2 + 90.0)

# --- CREACIÓN DE ELEMENTOS UI AUXILIARES ---
func _crear_label_formateado(texto: String, pos: Vector2) -> Label:
	var lbl = Label.new()
	lbl.text = texto
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 24)
	return lbl

func _instanciar_casillas(cantidad: int, x_inicio: float, sep_x: float, y_pos: float, arreglo_guardado: Array) -> Array:
	var lista_casillas = []
	for i in range(cantidad):
		var btn = Button.new()
		btn.text = "?"
		btn.custom_minimum_size = Vector2(35, 35)
		btn.position = Vector2(x_inicio + (i * sep_x), y_pos)
		btn.add_theme_font_size_override("font_size", 20)
		
		var idx = i
		btn.pressed.connect(func():
			arreglo_guardado[idx] = ""
			btn.text = "?"
		)
		
		panel_operacion.add_child(btn)
		elementos_dinamicos.append(btn)
		lista_casillas.append(btn)
	return lista_casillas

func _posicionar_contenedor_fichas():
	var pantalla_size = get_viewport_rect().size
	if contenedor_fichas:
		contenedor_fichas.custom_minimum_size = Vector2(600, 60)
		
		# Forzamos anclaje centrado en X y cerca del borde inferior en Y
		var x_pos = (pantalla_size.x - 600.0) / 2.0
		var y_pos = pantalla_size.y - 120.0 # Se despega 120px del fondo
		
		contenedor_fichas.position = Vector2(x_pos, y_pos)
		
		if contenedor_fichas.has_method("set_alignment"):
			contenedor_fichas.alignment = BoxContainer.ALIGNMENT_CENTER

func _generar_fichas_digitos_combinadas(respuestas: Array):
	for child in contenedor_fichas.get_children():
		child.queue_free()
		
	var pool_digitos: Array = []
	for resp in respuestas:
		for char_digito in resp:
			if not pool_digitos.has(char_digito):
				pool_digitos.append(char_digito)
				
	var opciones_extra = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	opciones_extra.shuffle()
	for d in opciones_extra:
		if pool_digitos.size() >= 8: break
		if not pool_digitos.has(d):
			pool_digitos.append(d)
			
	pool_digitos.shuffle()
	
	for digito in pool_digitos:
		var btn_ficha = Button.new()
		btn_ficha.text = digito
		btn_ficha.custom_minimum_size = Vector2(50, 50)
		btn_ficha.add_theme_font_size_override("font_size", 24)
		
		var d_val = digito
		btn_ficha.pressed.connect(func(): _insertar_digito_en_casilla_vacia(d_val))
		contenedor_fichas.add_child(btn_ficha)

func _insertar_digito_en_casilla_vacia(digito: String):
	for i in range(valores_paso_1.size()):
		if valores_paso_1[i] == "":
			valores_paso_1[i] = digito
			casillas_paso_1[i].text = digito
			break

func _crear_boton_comprobar(y_pos: float):
	var btn = Button.new()
	btn.text = "✔ Comprobar"
	btn.custom_minimum_size = Vector2(140, 40)
	var centro_x = _obtener_ancho_panel() / 2.0
	btn.position = Vector2(centro_x - 70.0, y_pos)
	btn.add_theme_font_size_override("font_size", 18)
	
	btn.pressed.connect(_validar_respuesta)
	
	panel_operacion.add_child(btn)
	elementos_dinamicos.append(btn)

# --- LÓGICA DE VALIDACIÓN Y CONTROL DE FLUJO ---
func _validar_respuesta():
	var respuesta_ingresada = ""
	for val in valores_paso_1:
		respuesta_ingresada += val
		
	if respuesta_ingresada == resultado_final_str:
		_al_acertar()
	else:
		_al_fallar()

func _al_acertar():
	gemas += 1
	_actualizar_ui_header()
	if gemas >= 3:
		visible = false
		minijuego_finalizado.emit(true)
	else:
		await get_tree().create_timer(0.8).timeout
		obtener_siguiente_pregunta()

func _al_fallar():
	vidas -= 1
	_actualizar_ui_header()
	
	for i in range(valores_paso_1.size()):
		valores_paso_1[i] = ""
		casillas_paso_1[i].text = "?"
		
	if vidas <= 0:
		await get_tree().create_timer(1.0).timeout
		gemas = 0
		visible = false
		minijuego_finalizado.emit(false)

# --- MÉTODOS DE LIMPIEZA Y UTILIDADES ---
func _limpiar_elementos_operacion():
	for elem in elementos_dinamicos:
		if is_instance_valid(elem):
			elem.queue_free()
	elementos_dinamicos.clear()
	casillas_paso_1.clear()

func _actualizar_ui_header():
	if gemas_label:
		gemas_label.text = "Gemas: " + str(gemas) + "/3"
	if vidas_container:
		var corazones = vidas_container.get_children()
		for i in range(corazones.size()):
			corazones[i].visible = i < vidas

func _obtener_ancho_panel() -> float:
	if panel_operacion and panel_operacion.size.x > 100:
		return panel_operacion.size.x
	# Si por algún motivo el panel no ha calculado su layout, usamos un estándar
	return 800.0
