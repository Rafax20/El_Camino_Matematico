extends Control

# --- CONFIGURACIÓN Y NODOS UI ---
@export var OFFSET_Y_GLOBAL: float = 60.0

@onready var cliente_alien: TextureRect = $ClienteAlien
@onready var globo_dialogo: PanelContainer = $GloboDialogo
@onready var texto_dialogo: Label = $GloboDialogo/TextoDialogo
@onready var panel_operacion: Panel = $PanelOperacion
@onready var contenedor_fichas = $ContenedorFichas
@onready var gemas_label = $UIHeader/GemasLabel
@onready var vidas_container = $UIHeader/VidasContainer
@onready var pizarra_borrador = $PizarraBorrador # Asegúrate de que el nombre coincida

# 🔊 NODO DE AUDIO (Asegúrate de agregar un AudioStreamPlayer en tu escena como hijo de la raíz)
@onready var audio_player: AudioStreamPlayer = $AudioPlayer 

# Sprites y Texturas
var textura_corazon_lleno = preload("res://assets/Minijuegos/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Minijuegos/corazon_vacio.png")
var tubo_ensayo = preload("res://assets/Imagenes/Tubito.png")
var Check_Morado = preload("res://assets/Imagenes/Check_pequeno.png")

# Array de Aliens Dinámicos
var texturas_aliens: Array = [
	preload("res://assets/Minijuegos/minijuego Laboratorio/Alien1.png"),
	preload("res://assets/Minijuegos/minijuego Laboratorio/Alien2.png"),
	preload("res://assets/Minijuegos/minijuego Laboratorio/Alien3.png")
]

signal minijuego_finalizado(es_correcto: bool)

# --- ESTADO DEL JUEGO ---
var vidas: int = 3
var aciertos: int = 0
var resultado_final_str: String = ""

var elementos_dinamicos: Array = []
var casillas_paso_1: Array = []
var valores_paso_1: Array = []

# Guardar posición original del panel para la sacudida
var posicion_original_panel: Vector2

# --- BANCO DE PREGUNTAS ---
var banco_preguntas: Array = [
	{ "cantidad_a1": 2, "objeto_a": "motores", "cantidad_b1": 8, "objeto_b": "tanques de gas", "cantidad_a2": 5 },
	{ "cantidad_a1": 3, "objeto_a": "pócimas", "cantidad_b1": 12, "objeto_b": "cristales de hiperviaje", "cantidad_a2": 4 },
	{ "cantidad_a1": 4, "objeto_a": "propulsores", "cantidad_b1": 20, "objeto_b": "baterías de plasma", "cantidad_a2": 6 },
	{ "cantidad_a1": 5, "objeto_a": "sondas", "cantidad_b1": 15, "objeto_b": "celdas de energía", "cantidad_a2": 8 }
]

var datos_pregunta_actual: Dictionary = {}

func _ready():
	panel_operacion.visible = false
	globo_dialogo.visible = false
	
	# Desactivar la pizarra al iniciar la escena
	if pizarra_borrador:
		pizarra_borrador.visible = false
		
	if panel_operacion:
		posicion_original_panel = panel_operacion.position
		
	if get_tree().current_scene == self:
		iniciar_minijuego("espacio")

func iniciar_minijuego(tema: String = "espacio"):
	visible = true
	$UIHeader.visible = true
	panel_operacion.visible = true
	contenedor_fichas.visible = true
	if has_node("PistasHelper"):
		$PistasHelper.visible = true
	
	await get_tree().process_frame
	
	_posicionar_contenedor_fichas()
	
	vidas = 3
	aciertos = 0
	_actualizar_ui_header()
	
	posicion_original_panel = panel_operacion.position
	
	obtener_siguiente_pregunta()
	iniciar_secuencia_alien()

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
	
	var x_margen = 10.0
	
	# --- TÍTULO ---
	var y_titulo = 6.0
	var lbl_titulo = Label.new()
	lbl_titulo.text = "MEZCLA GALÁCTICA"
	lbl_titulo.position = Vector2(x_margen, y_titulo)
	lbl_titulo.add_theme_font_size_override("font_size", 10)
	panel_operacion.add_child(lbl_titulo)
	elementos_dinamicos.append(lbl_titulo)
	
	# --- FILA 1 ---
	var y_fila1 = y_titulo + 18.0
	var texto_fila1 = str(a1) + " " + obj_a + "  ➜  " + str(b1) + " " + obj_b
	var lbl_f1 = _crear_label_formateado(texto_fila1, Vector2(x_margen, y_fila1))
	lbl_f1.add_theme_font_size_override("font_size", 9)
	panel_operacion.add_child(lbl_f1)
	elementos_dinamicos.append(lbl_f1)
	
	# --- FILA 2 ---
	var y_fila2 = y_fila1 + 16.0
	var texto_fila2_izq = str(a2) + " " + obj_a + "  ➜  "
	var lbl_f2_izq = _crear_label_formateado(texto_fila2_izq, Vector2(x_margen, y_fila2))
	lbl_f2_izq.add_theme_font_size_override("font_size", 9)
	panel_operacion.add_child(lbl_f2_izq)
	elementos_dinamicos.append(lbl_f2_izq)
	
	# --- FILA 3 (Casillas + Nombre del objeto abajo para espacio completo) ---
	var y_fila3 = y_fila2 + 16.0
	var separacion_x: float = 22.0
	var x_casillas = x_margen + 5.0
	
	casillas_paso_1 = _instanciar_casillas(
		resultado_final_str.length(), 
		x_casillas, 
		separacion_x, 
		y_fila3 - 2.0, 
		valores_paso_1
	)
	
	var ancho_casillas = resultado_final_str.length() * separacion_x
	var lbl_unidad = _crear_label_formateado(obj_b, Vector2(x_casillas + ancho_casillas + 4.0, y_fila3))
	lbl_unidad.add_theme_font_size_override("font_size", 9)
	panel_operacion.add_child(lbl_unidad)
	elementos_dinamicos.append(lbl_unidad)

	_generar_fichas_digitos_combinadas([resultado_final_str])
	_crear_boton_comprobar(y_fila3 + 22.0)
	_crear_boton_libreta()

# --- EFECTO DE SACUDIDA (SCREEN SHAKE) ---
func _sacudir_panel():
	var tween = create_tween()
	var duracion_paso = 0.05
	var fuerza = 12.0
	
	# Serie de desplazamientos rápidos en X
	tween.tween_property(panel_operacion, "position:x", posicion_original_panel.x + fuerza, duracion_paso)
	tween.tween_property(panel_operacion, "position:x", posicion_original_panel.x - fuerza, duracion_paso)
	tween.tween_property(panel_operacion, "position:x", posicion_original_panel.x + (fuerza * 0.5), duracion_paso)
	tween.tween_property(panel_operacion, "position:x", posicion_original_panel.x - (fuerza * 0.5), duracion_paso)
	tween.tween_property(panel_operacion, "position:x", posicion_original_panel.x, duracion_paso)

# --- LÓGICA DE VALIDACIÓN ---
func _validar_respuesta():
	var respuesta_ingresada = ""
	for val in valores_paso_1:
		respuesta_ingresada += val
		
	if respuesta_ingresada == resultado_final_str:
		_al_acertar()
	else:
		_al_fallar()

func _al_acertar():
	aciertos += 1
	_actualizar_ui_header()
	
	# Reproducir sonido de éxito (opcional)
	# _reproducir_voz("res://assets/Audio/acierto_juli.ogg")
	
	if aciertos >= 3:
		visible = false
		minijuego_finalizado.emit(true)
	else:
		await get_tree().create_timer(0.5).timeout
		alien_atendido_con_exito()

func _al_fallar():
	vidas -= 1
	_sacudir_panel() # 💥 Efecto de sacudida visual
	_actualizar_ui_header()
	
	# Cargar voz de error de Juli según vidas restantes
	if vidas == 2:
		_reproducir_voz("res://assets/Audio/juli_casi.ogg") # "¡Oh no! Estuviste cerca..."
	elif vidas == 1:
		_reproducir_voz("res://assets/Audio/juli_ultimo_intento.ogg") # "¡Cuidado, nos queda una vida!"
	
	for i in range(valores_paso_1.size()):
		valores_paso_1[i] = ""
		casillas_paso_1[i].text = "?"
		
	if vidas <= 0:
		_reproducir_voz("res://assets/Audio/juli_game_over.ogg") # "Oh no, fallamos..."
		await get_tree().create_timer(1.2).timeout
		aciertos = 0
		visible = false
		minijuego_finalizado.emit(false)

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

# --- SECUENCIA Y ANIMACIÓN DE ALIEN ---
func iniciar_secuencia_alien() -> void:
	if texturas_aliens.size() > 0:
		cliente_alien.texture = texturas_aliens.pick_random()

	var posicion_inicial = Vector2(1200, 100) 
	var posicion_centro = Vector2(450, 100)
	
	cliente_alien.position = posicion_inicial
	cliente_alien.visible = true
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(cliente_alien, "position", posicion_centro, 1.2)
	tween.finished.connect(_mostrar_peticion_alien)

func _mostrar_peticion_alien() -> void:
	globo_dialogo.visible = true
	
	# Extraemos las variables correspondientes a la meta a resolver
	var cant_objetivo = datos_pregunta_actual.get("cantidad_a2", 4)
	var obj_condicion = datos_pregunta_actual.get("objeto_a", "pócimas")
	var obj_buscar = datos_pregunta_actual.get("objeto_b", "cristales de hiperviaje")
	
	# El diálogo plantea la incógnita basándose en la cantidad requerida (a2)
	var peticion_texto = "¡Saludos! Necesito comprar suficientes " + obj_buscar + " para abastecer " + str(cant_objetivo) + " " + obj_condicion + " de mi nave."
	
	texto_dialogo.text = peticion_texto
	texto_dialogo.visible_ratio = 0.0
	
	var tween_texto = create_tween()
	tween_texto.tween_property(texto_dialogo, "visible_ratio", 1.0, 1.2)
	tween_texto.finished.connect(_abrir_minijuego_matematico)

func _abrir_minijuego_matematico() -> void:
	await get_tree().create_timer(0.3).timeout
	panel_operacion.visible = true

func alien_atendido_con_exito() -> void:
	panel_operacion.visible = false
	globo_dialogo.visible = false
	
	var tween_salida = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_salida.tween_property(cliente_alien, "position", Vector2(-400, 200), 1.0)
	tween_salida.finished.connect(obtener_siguiente_pregunta)
	tween_salida.finished.connect(iniciar_secuencia_alien)

# (Métodos auxiliares _crear_label_formateado, _instanciar_casillas, _posicionar_contenedor_fichas, _generar_fichas_digitos_combinadas, _insertar_digito_en_casilla_vacia, _crear_boton_comprobar, _limpiar_elementos_operacion y _obtener_ancho_panel se mantienen igual)

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
		btn.custom_minimum_size = Vector2(20, 20)
		btn.position = Vector2(x_inicio + (i * sep_x), y_pos)
		btn.add_theme_font_size_override("font_size", 10)
		
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
	if contenedor_fichas:
		# Si cambiaste el nodo a GridContainer en el editor, forzamos 4 columnas
		if contenedor_fichas is GridContainer:
			contenedor_fichas.columns = 4
		
		# Ajusta la posición para que caiga sobre el teclado de la registradora
		contenedor_fichas.position = Vector2(650, 435)

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
		btn_ficha.custom_minimum_size = Vector2(28, 28)
		btn_ficha.add_theme_font_size_override("font_size", 12)
		
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
	btn.text = "OK"
	btn.custom_minimum_size = Vector2(80, 25)
	
	# Centrar el botón en el panel de la computadora
	var centro_x = _obtener_ancho_panel() / 2.0
	btn.position = Vector2(centro_x - 40.0, y_pos)
	btn.add_theme_font_size_override("font_size", 12)
	
	if Check_Morado:
		btn.icon = Check_Morado
	
	btn.pressed.connect(_validar_respuesta)
	
	panel_operacion.add_child(btn)
	elementos_dinamicos.append(btn)
	
# --- MÉTODOS DE LIMPIEZA Y UTILIDADES ---
func _limpiar_elementos_operacion():
	for elem in elementos_dinamicos:
		if is_instance_valid(elem):
			elem.queue_free()
	elementos_dinamicos.clear()
	casillas_paso_1.clear()
	
func _obtener_ancho_panel() -> float:
	if panel_operacion and panel_operacion.size.x > 100:
		return panel_operacion.size.x
	# Si por algún motivo el panel no ha calculado su layout, usamos un estándar
	return 800.0
	
func _crear_boton_libreta():
	var btn_libreta = Button.new()
	btn_libreta.text = "✏️ Borrador"
	btn_libreta.custom_minimum_size = Vector2(75, 22)
	btn_libreta.position = Vector2(10, 105)
	btn_libreta.add_theme_font_size_override("font_size", 9)
	
	btn_libreta.pressed.connect(func():
		if pizarra_borrador:
			pizarra_borrador.visible = !pizarra_borrador.visible
	)
	
	panel_operacion.add_child(btn_libreta)
	elementos_dinamicos.append(btn_libreta)
