extends Node

# Necesitas un nodo HTTPRequest hijo en la escena donde uses este script
@onready var http_request = $HTTPRequest

# --- CONFIGURACIÓN DE TU ENDPOINT ---
const SUPABASE_URL_USUARIOS = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/usuarios"
const SUPABASE_URL_REGISTRO = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/registro"

const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

# SEÑALES: Para avisarle a tu juego principal cuándo continuar
signal login_exitoso(usuario_id: int, casilla: int, monedas: int)
signal registro_exitoso(usuario_id: int)
signal error_operacion(mensaje: String)

# Variable interna para saber qué estamos haciendo en la red
var operacion_actual: String = ""
var usuario_id_temporal: int = 0

func _ready():
	# Conectamos la señal nativa de red y aplicamos el fix de Gzip
	http_request.request_completed.connect(_on_request_completed)
	http_request.accept_gzip = false

# ==========================================
# 🚀 1. REGISTRAR UN NUEVO NIÑO
# ==========================================
func registrar_nuevo_nino(nombre_nino: String):
	if nombre_nino.strip_edges() == "":
		emit_signal("error_operacion", "El nombre no puede estar vacío.")
		return
		
	operacion_actual = "REGISTRAR_USUARIO"
	print("📡 Registrando a ", nombre_nino, " en la base de datos...")
	
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json",
		"Prefer: return=representation" # 👈 Le pide a Supabase que devuelva los datos creados (incluyendo el ID e int8 generado)
	]
	
	var datos = { "nombre": nombre_nino }
	var cuerpo_json = JSON.stringify(datos)
	
	var error = http_request.request(SUPABASE_URL_USUARIOS, headers, HTTPClient.METHOD_POST, cuerpo_json)
	if error != OK:
		emit_signal("error_operacion", "Error de red al intentar registrar.")

# ==========================================
# 🔑 2. INICIAR SESIÓN (CARGAR PROGRESO)
# ==========================================
func iniciar_sesion_nino(id_entero_nino: int):
	operacion_actual = "CARGAR_PROGRESO"
	usuario_id_temporal = id_entero_nino
	print("📡 Buscando el progreso del usuario ID: ", id_entero_nino)
	
	# Consultamos la tabla registro filtrando por el usuario_id (int8)
	var url_consulta = SUPABASE_URL_REGISTRO + "?usuario_id=eq." + str(id_entero_nino)
	
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	
	var error = http_request.request(url_consulta, headers, HTTPClient.METHOD_GET)
	if error != OK:
		emit_signal("error_operacion", "Error de red al iniciar sesión.")

# ==========================================
# ⚙️ PROCESAMIENTO DE RESPUESTAS DEL SERVIDOR
# ==========================================
func _on_request_completed(result, response_code, headers, body):
	var respuesta_cruda = body.get_string_from_utf8()
	var json = JSON.new()
	var error_parseo = json.parse(respuesta_cruda)
	
	# Verificación básica de errores HTTP
	if response_code != 200 and response_code != 201:
		print("❌ Error de servidor. Código: ", response_code, " Respuesta: ", respuesta_cruda)
		emit_signal("error_operacion", "El servidor rechazó la solicitud.")
		return

	if error_parseo != OK:
		emit_signal("error_operacion", "Error al leer los datos del servidor.")
		return

	var datos_recibidos = json.data

	match operacion_actual:
		"REGISTRAR_USUARIO":
			# Supabase devuelve un Array con el usuario creado
			if datos_recibidos is Array and datos_recibidos.size() > 0:
				var nuevo_usuario = datos_recibidos[0]
				var nuevo_id_int8 = int(nuevo_usuario["id"]) # Capturamos el ID entero creado
				print("🎉 Usuario registrado con éxito. ID Asignado: ", nuevo_id_int8)
				
				# PASO COMPLEMENTARIO: Crear su fila inicial en la tabla 'registro'
				_crear_fila_inicial_registro(nuevo_id_int8)
			else:
				emit_signal("error_operacion", "No se recibieron datos del nuevo usuario.")

		"CREAR_REGISTRO_INICIAL":
			print("✅ Fila de progreso inicial vinculada con éxito en Supabase.")
			emit_signal("registro_exitoso", usuario_id_temporal)

		"CARGAR_PROGRESO":
			# Si el alumno ya tiene progreso registrado
			if datos_recibidos is Array and datos_recibidos.size() > 0:
				var progreso = datos_recibidos[0]
				var casilla = int(progreso["casilla_actual"])
				var monedas = int(progreso["monedas"])
				
				print("🎉 ¡Progreso cargado! Casilla: ", casilla, " | Monedas: ", monedas)
				emit_signal("login_exitoso", usuario_id_temporal, casilla, monedas)
			else:
				# Si por alguna razón el usuario existe pero no tenía fila en 'registro'
				print("ℹ️ El usuario no tiene fila de progreso. Creando una...")
				_crear_fila_inicial_registro(usuario_id_temporal)

# Función interna de apoyo para inicializar la tabla progreso en 0
func _crear_fila_inicial_registro(id_nino: int):
	operacion_actual = "CREAR_REGISTRO_INICIAL"
	usuario_id_temporal = id_nino
	
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	
	# Inicializamos al niño en la casilla 1 y con 0 monedas
	var datos_progreso_inicial = {
		"usuario_id": id_nino,
		"casilla_actual": 1,
		"monedas": 0
	}
	
	var cuerpo_json = JSON.stringify(datos_progreso_inicial)
	http_request.request(SUPABASE_URL_REGISTRO, headers, HTTPClient.METHOD_POST, cuerpo_json)
