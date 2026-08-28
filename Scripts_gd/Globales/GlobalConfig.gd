extends Node

# --- CREDENCIALES DINÁMICAS ---
var GEMINI_API_KEY: String = ""
var GEMINI_URL: String = ""

# 🛡️ CREDENCIALES POR DEFECTO (Servirán como respaldo inmediato en Web)
var SUPABASE_URL: String = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/"
var SUPABASE_ANON_KEY: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

const RENDER_SERVER_URL = "https://july-videojuego-render.onrender.com/"

func _ready():
	_inicializar_configuracion()

func _inicializar_configuracion():
	# 🖥️ MODO LOCAL (.env)
	if FileAccess.file_exists("res://.env"):
		print("🏠 GlobalConfig: Detectado entorno local. Cargando .env...")
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
						GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + GEMINI_API_KEY
					"SUPABASE_URL":
						SUPABASE_URL = valor
					"SUPABASE_ANON_KEY":
						SUPABASE_ANON_KEY = valor
						
		print("✅ GlobalConfig: Variables locales cargadas.")
		_sincronizar_con_autoloads()

	# 🌐 MODO PRODUCCIÓN (WEB)
	else:
		print("🚀 GlobalConfig: Modo producción. Sincronizando respaldo dinámico...")
		_sincronizar_con_autoloads() # Asigna las credenciales fijas predeterminadas
		
		var http_client = HTTPRequest.new()
		add_child(http_client)
		
		http_client.request_completed.connect(func(result, response_code, headers, body):
			var texto_plano = body.get_string_from_utf8().strip_edges()
			texto_plano = texto_plano.replace("\\/", "/")
			
			var json = JSON.new()
			if response_code == 200 and json.parse(texto_plano) == OK:
				var data = json.data
				if data is Dictionary and data.get("supabase_url", "") != "":
					SUPABASE_URL = str(data["supabase_url"])
					SUPABASE_ANON_KEY = str(data["supabase_anon_key"])
					print("✅ [Render] Credenciales obtenidas exitosamente.")
					_sincronizar_con_autoloads()
				else:
					print("⚠️ JSON incompleto desde Render. Usando credenciales de respaldo.")
			else:
				print("❌ Fallo en comunicación con Render (Código: ", response_code, "). Se mantienen las credenciales de respaldo.")
			
			http_client.queue_free()
		)
		
		var error_peticion = http_client.request(RENDER_SERVER_URL + "index.php?action=get_config")
		if error_peticion != OK:
			print("❌ Error al solicitar configuración a Render.")

func _sincronizar_con_autoloads():
	# Asegurar terminación en /
	if not SUPABASE_URL.ends_with("/"):
		SUPABASE_URL += "/"
		
	if ConexionSupabase:
		ConexionSupabase.SUPABASE_URL = SUPABASE_URL
		ConexionSupabase.SUPABASE_ANON_KEY = SUPABASE_ANON_KEY
		print("🔄 Autoload 'ConexionSupabase' actualizado desde GlobalConfig.")
