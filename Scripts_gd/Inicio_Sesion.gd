extends Control

# --- NODOS DE INTERFAZ ---
@onready var contenedor = $ContenedorPopup
@onready var fondo_oscuro = $OscurecerFondo
@onready var input_usuario = $ContenedorPopup/VBoxContainer/InputUsuario
@onready var input_clave = $ContenedorPopup/VBoxContainer/InputClave
@onready var texto_error = $ContenedorPopup/VBoxContainer/Titulo

# --- REFERENCIA AL SCRIPT DE SUPABASE ---
@onready var http_request = $HTTPRequest 

const SUPABASE_URL_USUARIOS = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/usuarios"
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

var operacion_actual: String = ""

func _ready():
	self.modulate.a = 0
	contenedor.scale = Vector2(0.5, 0.5)
	contenedor.pivot_offset = contenedor.size / 2 
	self.visible = false
	
	# Conectar respuesta de red de forma segura por código
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	http_request.accept_gzip = false

# ==========================================
# 🎬 ANIMACIONES DE ENTRADA Y SALIDA
# ==========================================
func aparecer():
	self.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(contenedor, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_boton_cerrar_pressed() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(contenedor, "scale", Vector2(0.7, 0.7), 0.2)
	await tween.finished
	self.visible = false

# ==========================================
# 📡 ENVIAR DATOS (LOGIN / REGISTRO)
# ==========================================

# Asegúrate de conectar este método a la señal pressed() de tu BotonEntrar
func _on_boton_entrar_pressed() -> void:
	var usuario = input_usuario.text.to_lower().strip_edges()
	var clave = input_clave.text.strip_edges()
	
	print("🔍 Intentando iniciar sesión con Usuario: '" + usuario + "'")
	
	if usuario == "" or clave == "":
		animar_error_infantil("¡Faltan datos por escribir!")
		return
		
	operacion_actual = "LOGIN"
	var url = SUPABASE_URL_USUARIOS + "?usuario=eq." + usuario + "&clave=eq." + clave
	enviar_peticion_supabase(url, HTTPClient.METHOD_GET, "")

# Asegúrate de conectar este método a la señal pressed() de tu BotonRegistrar
func _on_boton_registrar_pressed() -> void:
	var usuario = input_usuario.text.to_lower().strip_edges()
	var clave = input_clave.text.strip_edges()
	
	print("📝 Intentando registrar al Usuario: '" + usuario + "'")
	
	if usuario == "" or clave == "":
		animar_error_infantil("¡Escribe un nombre y clave!")
		return
		
	operacion_actual = "REGISTRO"
	var datos = { "usuario": usuario, "clave": clave }
	enviar_peticion_supabase(SUPABASE_URL_USUARIOS, HTTPClient.METHOD_POST, JSON.stringify(datos))

func enviar_peticion_supabase(url: String, metodo: int, cuerpo: String):
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	var error = http_request.request(url, headers, metodo, cuerpo)
	if error != OK:
		print("❌ Error al levantar la conexión HTTPRequest")
		animar_error_infantil("¡Error de red interno!")

# ==========================================
# ⚙️ RESPUESTAS DEL SERVIDOR Y VALIDACIÓN
# ==========================================
func _on_request_completed(result, response_code, headers, body):
	var respuesta = body.get_string_from_utf8()
	print("📡 Servidor respondió con código: " + str(response_code))
	print("📄 Cuerpo de la respuesta: " + respuesta)
	
	var json = JSON.new()
	var error_parseo = json.parse(respuesta)
	
	if response_code != 200 and response_code != 201:
		print("❌ Error de comunicación con la API. Código de estado inválido.")
		animar_error_infantil("¡Error de conexión!")
		return

	var datos_recibidos = json.data

	if operacion_actual == "LOGIN":
		if datos_recibidos is Array and datos_recibidos.size() > 0:
			print("🎉 ¡Inicio exitoso! Bienvenido de vuelta: " + str(datos_recibidos[0].get("nombre", "")))
			_on_boton_cerrar_pressed() 
		else:
			print("❌ Login fallido: El usuario no existe o la contraseña está mal.")
			animar_error_infantil("¡Usuario o Clave incorrectos!")

	elif operacion_actual == "REGISTRO":
		if response_code == 201:
			print("🎉 ¡Registro exitoso en Supabase!")
			_on_boton_cerrar_pressed()
		else:
			print("❌ Registro fallido: Posible nombre duplicado.")
			animar_error_infantil("¡Ese nombre ya existe!")

# ==========================================
# 💥 ANIMACIÓN INFANTIL DE ERROR (Juice Effect)
# ==========================================
func animar_error_infantil(mensaje: String):
	print("💥 Error mostrado al niño: '" + mensaje + "'")
	
	texto_error.text = mensaje
	texto_error.modulate = Color(1, 0.3, 0.3) # Rojo amigable
	
	var posicion_original = contenedor.position
	var tween_shake = create_tween()
	
	# Efecto Shake corregido para compatibilidad de vectores en Godot 4
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x - 15, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x + 15, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x - 10, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x + 10, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", posicion_original, 0.05)
	
	# Efecto elástico de escala
	var tween_scale = create_tween()
	contenedor.pivot_offset = contenedor.size / 2
	tween_scale.tween_property(contenedor, "scale", Vector2(0.9, 0.9), 0.1)
	tween_scale.tween_property(contenedor, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK)
	tween_scale.tween_property(contenedor, "scale", Vector2(1.0, 1.0), 0.1)
