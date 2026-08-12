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
					URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + API_KEY_LOCAL
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
	
	# 🔒 Bloquear botón mientras Render responde
	$VBoxContainer/HBoxContainer/Button.disabled = true
	
	agregar_mensaje_a_pantalla("Niño: " + texto)
	line_edit.text = ""
	
	# Mantiene el cursor activo dentro del LineEdit para seguir escribiendo
	line_edit.grab_focus()
	
	var headers = ["Content-Type: application/json"]
	var payload_string = ""
	
	# 🔀 Estructura condicional según el entorno donde corra el juego
	if modo_local:
		# Añadimos la orden estricta de no usar LaTeX ni símbolos de formato científico
		var prompt_sistema = "Eres July, una tutora pedagógica amigable de matemáticas para niños de primaria. Responde de forma muy corta, directa y alegre (máximo 3 o 4 líneas). IMPORTANTE: Escribe las operaciones matemáticas de forma simple usando la letra 'x' para multiplicar y el signo '+' para sumar. Está estrictamente prohibido usar símbolos de formato matemático como $, \\times o expresiones de tipo LaTeX."
		var payload_google = {
			"contents": [{"parts": [{"text": prompt_sistema + "\nNiño: " + texto}]}]
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
	# 🔓 Desbloquear botón al recibir respuesta de Render
	$VBoxContainer/HBoxContainer/Button.disabled = false
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
					agregar_mensaje_a_pantalla("July: Respondió el servidor, pero hubo un error interno con la IA. ¡Revisa los logs de Render!")
				else:
					print("❌ Formato de diccionario desconocido. Llaves: ", json.keys())
			else:
				print("❌ Error en formato de respuesta desde Render. El JSON no es un diccionario válido.")
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
	var label = RichTextLabel.new() # <-- Aquí nace 'label'
	label.bbcode_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.fit_content = true
	label.custom_minimum_size.x = 600
	
	# 🛠️ CORRECCIÓN DE FUENTES Y EMOJIS EMBEBIDOS
	# 1. Cargamos Fredoka con tu ruta corregida
	var fuente_fredoka = load("res://Fuentes/Fredoka/static/Fredoka-Bold.ttf")
	label.add_theme_font_override("normal_font", fuente_fredoka)
	
	# 2. Cargamos el archivo físico de emojis que descargaste
	var fuente_emojis = load("res://Fuentes/NotoColorEmoji.ttf")
	
	# 3. Se lo asignamos como fallback directo a la fuente principal
	if fuente_fredoka and fuente_emojis:
		fuente_fredoka.fallbacks.append(fuente_emojis)
	
	# Añadimos el color de texto oscuro
	label.add_theme_color_override("default_color", Color("263238"))
	
	# Formateamos las negritas de Markdown a BBCode (Tu bucle while se queda igual)
	var texto_formateado = texto
	while "**" in texto_formateado:
		texto_formateado = texto_formateado.replace("**", "[b]")
		if "**" in texto_formateado:
			texto_formateado = texto_formateado.replace("**", "[/b]")

	label.text = texto_formateado
	
	# 3. Ensamblamos la estructura
	burbuja.add_child(label)
	vbox_mensajes.add_child(burbuja)
	
	# Auto-scroll hacia abajo
	await get_tree().process_frame 
	$VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.get_v_scroll_bar().max_value


func _on_texture_button_pressed() -> void:
	NavegacionGlobal.volver_a_pantalla_previa()
