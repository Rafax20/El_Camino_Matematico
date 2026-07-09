extends Node

# --- CREDENCIALES DINÁMICAS (Se llenan solas en Local o en la Web) ---
var GEMINI_API_KEY: String = ""
var GEMINI_URL: String = ""
var SUPABASE_URL: String = ""
var SUPABASE_ANON_KEY: String = ""

# 🌍 TU ÚNICA URL BASE DE RENDER (Asegúrate de que coincida con tu servicio Live)
const RENDER_SERVER_URL = "https://july-videojuego-render.onrender.com/"

func _ready():
	_inicializar_configuracion()

func _inicializar_configuracion():
	# 🖥️ CASO 1: MODO LOCAL (Si existe el archivo .env en tu PC)
	if FileAccess.file_exists("res://.env"):
		print("🏠 GlobalConfig: Detectado entorno local. Cargando archivo .env...")
		var archivo = FileAccess.open("res://.env", FileAccess.READ)
		
		while not archivo.eof_reached():
			var linea = archivo.get_line().strip_edges()
			if linea == "" or linea.begins_with("#"): continue
			
			var partes = linea.split("=")
			if partes.size() > 1:
				var llave = partes[0].strip_edges()
				var valor = partes[1].strip_edges()
				
				match llave:
					"GEMINI_API_KEY":
						GEMINI_API_KEY = valor
						# En local, le pega directo a Google de forma rápida
						GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + GEMINI_API_KEY
					"SUPABASE_URL":
						SUPABASE_URL = valor
					"SUPABASE_ANON_KEY":
						SUPABASE_ANON_KEY = valor
						
		print("✅ GlobalConfig: Variables locales cargadas con éxito.")
		_sincronizar_con_autoloads()

	# 🌐 CASO 2: MODO PRODUCCIÓN (Web HTML5 - No existe .env)
	else:
		print("🚀 GlobalConfig: Modo producción activo. Solicitando credenciales a Render...")
		var http_client = HTTPRequest.new()
		add_child(http_client)
		
		http_client.request_completed.connect(func(result, response_code, headers, body):
			var texto_plano = body.get_string_from_utf8()
			var json = JSON.new()
			var parse_result = json.parse(texto_plano)
			
			print("📡 [DEBUG RENDER] Código recibido: ", response_code)
			print("📡 [DEBUG RENDER] Longitud del cuerpo: ", texto_plano.length())
			print("📡 [DEBUG RENDER] Primeros 100 caracteres recibidos: ", texto_plano.substr(0, 100))
	
	# Comprobar si el inicio es correcto (debería empezar con '{')
			if texto_plano.length() > 0 and texto_plano[0] != "{":
				print("❌ ERROR: El servidor NO envió un JSON. Empezó con: ", texto_plano[0])
				
				if json.parse(texto_plano) == OK:
					print("TODO PIOLA")
				else:
					print("❌ ERROR CRÍTICO DE PARSEO: El texto no es JSON válido.")
			
			if response_code == 200 and parse_result == OK:
				var data = json.data
				if data.has("supabase_url") and data["supabase_url"] != "":
					SUPABASE_URL = data["supabase_url"]
					SUPABASE_ANON_KEY = data["supabase_anon_key"]
					print("✅ [Render] Credenciales cargadas con éxito.")
				else:
					_activar_respaldo("JSON inválido o campos vacíos")
			else:
				_activar_respaldo("Render devolvió código " + str(response_code))
			
			_sincronizar_con_autoloads()
			http_client.queue_free()
		)
		
		# Solicitud con Timeout corto
		http_client.request(RENDER_SERVER_URL + "index.php?action=get_config")

# NUEVA FUNCIÓN DE RESPALDO (El Plan B)
func _activar_respaldo(motivo):
	print("⚠️ [ADVERTENCIA] Fallo en Render: ", motivo, ". Cargando credenciales fijas.")
	SUPABASE_URL = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/"
	SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc" # PEGA AQUÍ TU LLAVE REAL

# 🔄 Función auxiliar para mantener actualizados tus otros scripts automáticos
func _sincronizar_con_autoloads():
	if ResourceLoader.exists("res://ConexionSupabase.gd") or ConexionSupabase:
		ConexionSupabase.SUPABASE_URL = SUPABASE_URL
		ConexionSupabase.SUPABASE_ANON_KEY = SUPABASE_ANON_KEY
		print("🔄 Autoload 'ConexionSupabase' sincronizado correctamente.")
