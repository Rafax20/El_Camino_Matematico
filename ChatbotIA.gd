extends Control

const API_KEY = "" # Pega aquí tu clave completa
const URL = "=" + API_KEY

# Rutas actualizadas según tu jerarquía
@onready var http_request = $HTTPRequest 
@onready var line_edit = $VBoxContainer/HBoxContainer/LineEdit
@onready var vbox_mensajes = $VBoxContainer/ScrollContainer/VBoxContainer 

func _ready():
	# Conexión correcta a la señal del botón
	$VBoxContainer/HBoxContainer/Button.pressed.connect(_enviar_mensaje)
	http_request.request_completed.connect(_on_request_completed)

func _enviar_mensaje():
	var texto = line_edit.text
	if texto == "": return
	
	agregar_mensaje_a_pantalla("Niño: " + texto)
	line_edit.text = ""
	
	var prompt_sistema = "Eres July, una tutora pedagógica amigable. Responde solo dudas sobre matemáticas de primaria."
	var payload = {
		"contents": [{"parts": [{"text": prompt_sistema + "\nNiño: " + texto}]}]
	}
	
	# Solución al error de HTTP_METHOD_POST (ahora usa HTTPClient)
	http_request.request(URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))

func _on_request_completed(_result, _response_code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("candidates"):
		var respuesta = json["candidates"][0]["content"]["parts"][0]["text"]
		agregar_mensaje_a_pantalla("July: " + respuesta)
	else:
		print("Error en la respuesta: ", body.get_string_from_utf8())

func agregar_mensaje_a_pantalla(texto):
	var label = Label.new()
	label.text = texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# --- AÑADE ESTO PARA QUE SE ESTIRE ---
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# -------------------------------------
	
	vbox_mensajes.add_child(label)
	
	# Esto hace que el scroll baje automáticamente al final
	await get_tree().process_frame 
	$VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.get_v_scroll_bar().max_value
