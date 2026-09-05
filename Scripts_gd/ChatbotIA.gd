extends Control

# URL de producción por defecto (Pasarela segura en Render)
var URL = "https://july-videojuego-render.onrender.com/index.php"

# Variables para el modo de prueba local directo a Google
var modo_local: bool = false
var API_KEY_LOCAL: String = ""

# Rutas de tu jerarquía de nodos
@onready var http_request = $HTTPRequest 
@onready var line_edit = $VBoxContainer/HBoxContainer/LineEdit
@onready var vbox_mensajes = $VBoxContainer/ScrollContainer/VBoxContainer 

# Fuente principal para el chat
const FUENTE_FREDOKA = preload("res://Fuentes/Fredoka/static/Fredoka-Bold.ttf")

# Variables para indicador de carga de July
var burbuja_pensando: PanelContainer = null
var timer_pensando: Timer = null
var contador_puntos: int = 0

func _ready():
	# 1. Verificar si podemos usar el entorno local directo
	_configurar_entorno()
	
	# 2. Conexión del botón de enviar
	var boton = $VBoxContainer/HBoxContainer/Button
	if boton and not boton.pressed.is_connected(_enviar_mensaje):
		boton.pressed.connect(_enviar_mensaje)
	
	# 3. Escuchar la tecla ENTER en el LineEdit mediante su señal nativa
	if line_edit:
		line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	
	# 4. Conexión de la solicitud HTTP
	if http_request and not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)

# Función auxiliar para enviar el mensaje al presionar Enter en el chat box
func _on_line_edit_text_submitted(_texto_ingresado: String):
	_enviar_mensaje()
	

func _configurar_entorno():
	if FileAccess.file_exists("res://.env"):
		var archivo = FileAccess.open("res://.env", FileAccess.READ)
		
		while not archivo.eof_reached():
			var linea = archivo.get_line().strip_edges()
			if linea.begins_with("GEMINI_API_KEY="):
				var partes = linea.split("=")
				if partes.size() > 1:
					API_KEY_LOCAL = partes[1].strip_edges()
					# Cambiamos la URL a la directa de Google para tus pruebas locales
					URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + API_KEY_LOCAL
					modo_local = true
					print("🛠️ Modo local activo: Utilizando API Key del .env directamente con Google.")
					return
		print("⚠️ Se encontró el .env pero no la variable GEMINI_API_KEY. Usando Render por defecto.")
	else:
		print("🌐 Modo producción activo: No se encontró .env. Usando pasarela de Render.")

func _enviar_mensaje():
	if URL == "":
		print("❌ Error: La URL no está configurada.")
		return
		
	var texto = line_edit.text.strip_edges()
	if texto == "": return
	
	# 🔒 Bloquear controles mientras responde July
	$VBoxContainer/HBoxContainer/Button.disabled = true
	$VBoxContainer/HBoxContainer/Button.text = "..."
	line_edit.editable = false
	line_edit.placeholder_text = "July está pensando..."
	
	agregar_mensaje_a_pantalla("Niño: " + texto)
	line_edit.text = ""
	
	_mostrar_indicador_pensando()
	
	var headers = ["Content-Type: application/json"]
	var payload_string = ""
	
	# 🔀 Estructura condicional según el entorno donde corra el juego
	if modo_local:
		# Añadimos la orden estricta de no usar LaTeX ni emojis Unicode
		var prompt_sistema = "Eres July, una tutora pedagógica amigable de matemáticas para niños de primaria. Responde de forma muy corta, directa y alegre (máximo 3 o 4 líneas). IMPORTANTE: Escribe las operaciones matemáticas de forma simple usando la letra 'x' para multiplicar y el signo '+' para sumar. Está estrictamente prohibido usar símbolos de formato matemático como $, \\times o expresiones de tipo LaTeX. NO USES EMOJIS (como 🎈, ⭐, 🤖); usa palabras alegres, signos de admiración o caritas de texto como :) o :D."
		var payload_google = {
			"contents": [{"parts": [{"text": prompt_sistema + "\nNiño: " + texto}]}],
			"generationConfig": {
				"temperature": 0.7,
				"maxOutputTokens": 1000
			}
		}
		payload_string = JSON.stringify(payload_google)
	else:
		# Si es producción en Render, enviamos el JSON simple que espera tu index.php
		var payload_render = {
			"prompt": texto
		}
		payload_string = JSON.stringify(payload_render)
	
	http_request.request(URL, headers, HTTPClient.METHOD_POST, payload_string)

func _on_request_completed(_result, response_code, _headers, body):
	# 🔓 Desbloquear controles al recibir respuesta de Render
	_ocultar_indicador_pensando()
	$VBoxContainer/HBoxContainer/Button.disabled = false
	$VBoxContainer/HBoxContainer/Button.text = "Enviar"
	line_edit.editable = true
	line_edit.placeholder_text = "Haz una pregunta"
	line_edit.grab_focus()
	if response_code == 200:
		var texto_crudo = body.get_string_from_utf8().strip_edges()
		
		# 🩺 SPY PRINT 1: Ver exactamente qué texto plano responde Render
		print("🧠 [GEMINI CRUDO] Texto recibido desde Render:\n", texto_crudo)
		
		# 🧹 LIMPIEZA: Aplicamos el mismo parche de barras que en GlobalConfig por si acaso
		texto_crudo = texto_crudo.replace("\\/", "/")
		
		var json = JSON.parse_string(texto_crudo)
		
		# 🩺 SPY PRINT 2: Ver cómo Godot interpretó el objeto parseado
		print("🧠 [GEMINI PARSEADO] ¿Es diccionario?: ", json is Dictionary)
		if json is Dictionary:
			print("🧠 [GEMINI LLAVES] Llaves encontradas en el JSON: ", json.keys())
		
		if modo_local:
			# Procesar formato nativo de Google Gemini
			if json and json.has("candidates"):
				var respuesta = json["candidates"][0]["content"]["parts"][0]["text"]
				agregar_mensaje_a_pantalla("July: " + respuesta)
			else:
				print("❌ Error en formato nativo de Google: ", texto_crudo)
		else:
			# Procesar formato simplificado de tu escudo en Render
			if json is Dictionary:
				if json.has("response"):
					var respuesta_july = json["response"]
					agregar_mensaje_a_pantalla("July: " + respuesta_july)
				elif json.has("error"):
					# 🚨 DETECTADO: Si el servidor manda un error controlado por ti, lo mostramos amigablemente
					print("⚠️ El servidor de Render reportó un problema interno: ", json["error"])
					var http_code = json.get("http_code_servidor", 0)
					var resp_cruda = str(json.get("respuesta_cruda_google", ""))
					if http_code == 503 or "high demand" in resp_cruda or "UNAVAILABLE" in resp_cruda:
						agregar_mensaje_a_pantalla("July: ¡Estoy pensando muchas cosas a la vez y mis circuitos están ocupados! :) Por favor intenta preguntarme de nuevo en unos segundos.")
					elif http_code == 429 or "RESOURCE_EXHAUSTED" in resp_cruda:
						agregar_mensaje_a_pantalla("July: ¡Hemos hecho muchas preguntas muy rápido! Dame un momentito para descansar y vuelve a intentarlo.")
					else:
						agregar_mensaje_a_pantalla("July: Tuve un pequeño problema con mi conexión artificial. ¡Intenta preguntarme de nuevo en un momento!")
				else:
					print("❌ Formato de diccionario desconocido. Llaves: ", json.keys())
					agregar_mensaje_a_pantalla("July: No pude entender bien la respuesta. ¿Me preguntas otra vez?")
			else:
				print("❌ Error en formato de respuesta desde Render. El JSON no es un diccionario válido.")
				agregar_mensaje_a_pantalla("July: Tuve un problema al procesar la respuesta del servidor.")
	else:
		print("❌ Error de comunicación. Código HTTP: ", response_code)
		print("Detalles del fallo: ", body.get_string_from_utf8())
		agregar_mensaje_a_pantalla("July: Tuve un pequeño problema al procesar la idea. ¿Me repites la pregunta?")

func agregar_mensaje_a_pantalla(texto: String):
	# 1. Creamos la burbuja contenedora
	var burbuja = PanelContainer.new()
	
	# Creamos un estilo único y redondeado para la burbuja
	var estilo_burbuja = StyleBoxFlat.new()
	estilo_burbuja.corner_radius_top_left = 15
	estilo_burbuja.corner_radius_top_right = 15
	estilo_burbuja.corner_radius_bottom_left = 15
	estilo_burbuja.corner_radius_bottom_right = 15
	estilo_burbuja.content_margin_left = 12
	estilo_burbuja.content_margin_right = 12
	estilo_burbuja.content_margin_top = 8
	estilo_burbuja.content_margin_bottom = 8
	
	# Separamos visualmente si habla el Niño o July
	if texto.begins_with("Niño:"):
		estilo_burbuja.bg_color = Color("b3e5fc") # Azul pastel para el niño
		burbuja.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN # Alineado a la izquierda
	else:
		estilo_burbuja.bg_color = Color("fff9c4") # Amarillo/Crema pedagógico para July
		burbuja.size_flags_horizontal = Control.SIZE_SHRINK_END # Alineado a la derecha (opcional)

	burbuja.add_theme_stylebox_override("panel", estilo_burbuja)

	# 2. Creamos el texto enriquecido (RichTextLabel)
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.fit_content = true
	label.custom_minimum_size.x = 600
	
	# 🛠️ APLICAR FUENTE FREDOKA
	if FUENTE_FREDOKA:
		label.add_theme_font_override("normal_font", FUENTE_FREDOKA)
	
	# Añadimos el color de texto oscuro
	label.add_theme_color_override("default_color", Color("263238"))
	
	# 3. Procesar emojis y formato de negritas
	label.text = _procesar_texto_y_emojis(texto)
	
	# 4. Ensamblamos la estructura
	burbuja.add_child(label)
	vbox_mensajes.add_child(burbuja)
	
	# Auto-scroll hacia abajo
	await get_tree().process_frame 
	$VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.get_v_scroll_bar().max_value

# Función auxiliar para convertir o limpiar emojis y formatear BBCode
func _procesar_texto_y_emojis(texto_original: String) -> String:
	var texto_procesado = texto_original
	
	# Mapeo de emojis comunes a caritas o expresiones legibles
	var reemplazos = {
		"🎈": "!",
		"⭐": "★",
		"🌟": "★",
		"🤖": ":)",
		"⏳": "...",
		"⚡": "!",
		"🍎": "manzanas",
		"👍": ":)",
		"🎉": "¡Viva!",
		"😊": ":)",
		"😄": ":D",
		"✨": "*",
		"❤️": "♥",
		"💡": "¡Idea!",
		"👏": "¡Bravo!"
	}
	
	for emoji in reemplazos.keys():
		texto_procesado = texto_procesado.replace(emoji, reemplazos[emoji])
	
	# Eliminar cualquier otro emoji Unicode residual que cause el cuadro [?] en Web
	var regex = RegEx.new()
	regex.compile("[\\x{1F300}-\\x{1FAFF}|\\x{2600}-\\x{27BF}|\\x{FE00}-\\x{FE0F}]")
	texto_procesado = regex.sub(texto_procesado, "", true)
	
	# Formateamos las negritas de Markdown a BBCode ([b]...[/b])
	while "**" in texto_procesado:
		texto_procesado = texto_procesado.replace("**", "[b]")
		if "**" in texto_procesado:
			texto_procesado = texto_procesado.replace("**", "[/b]")
			
	return texto_procesado


func _on_texture_button_pressed() -> void:
	NavegacionGlobal.volver_a_pantalla_previa()

func _mostrar_indicador_pensando() -> void:
	_ocultar_indicador_pensando()
	
	burbuja_pensando = PanelContainer.new()
	var estilo = StyleBoxFlat.new()
	estilo.corner_radius_top_left = 15
	estilo.corner_radius_top_right = 15
	estilo.corner_radius_bottom_left = 15
	estilo.corner_radius_bottom_right = 15
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	estilo.bg_color = Color("fff9c4") # Crema suave para July
	burbuja_pensando.add_theme_stylebox_override("panel", estilo)
	burbuja_pensando.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.custom_minimum_size.x = 220
	if FUENTE_FREDOKA:
		label.add_theme_font_override("normal_font", FUENTE_FREDOKA)
	label.add_theme_color_override("default_color", Color("5d4037"))
	label.text = "[b]July está pensando[/b] ."
	burbuja_pensando.add_child(label)
	
	vbox_mensajes.add_child(burbuja_pensando)
	
	# Auto-scroll hacia abajo
	await get_tree().process_frame
	if has_node("VBoxContainer/ScrollContainer"):
		$VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.get_v_scroll_bar().max_value
	
	# Timer para animar los puntos suspensivos (...)
	contador_puntos = 1
	timer_pensando = Timer.new()
	timer_pensando.wait_time = 0.45
	timer_pensando.autostart = true
	timer_pensando.timeout.connect(func():
		if not is_instance_valid(burbuja_pensando) or not is_instance_valid(label):
			return
		contador_puntos = (contador_puntos % 3) + 1
		var puntos = ""
		for p in range(contador_puntos):
			puntos += " ."
		label.text = "[b]July está pensando[/b]" + puntos
	)
	add_child(timer_pensando)

func _ocultar_indicador_pensando() -> void:
	if timer_pensando != null and is_instance_valid(timer_pensando):
		timer_pensando.stop()
		timer_pensando.queue_free()
		timer_pensando = null
		
	if burbuja_pensando != null and is_instance_valid(burbuja_pensando):
		burbuja_pensando.queue_free()
		burbuja_pensando = null

