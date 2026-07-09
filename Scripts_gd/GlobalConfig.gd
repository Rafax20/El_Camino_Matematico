extends Node

# --- CREDENCIALES DINÁMICAS (Se llenan solas en Local o en la Web) ---
var GEMINI_API_KEY: String = ""
var GEMINI_URL: String = ""
var SUPABASE_URL: String = ""
var SUPABASE_ANON_KEY: String = ""

# 🌍 TU ÚNICA URL BASE DE RENDER (Asegúrate de que coincida con tu servicio Live)
const RENDER_SERVER_URL = "https://july-videojuego-render.onrender.com"

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
		print("🚀 GlobalConfig: Modo producción (Web HTML5) activo. Solicitando credenciales a Render...")
		
		GEMINI_URL = RENDER_SERVER_URL + "index.php"
		
		var http_client = HTTPRequest.new()
		add_child(http_client)
		http_client.accept_gzip = false
		
		http_client.request_completed.connect(func(result, response_code, headers, body):
			print("🚨 [HTTP COMPLETADO] CÓDIGO DE RESPUESTA DE RENDER: ", response_code)
			
			if response_code == 200:
				var texto_plano = body.get_string_from_utf8()
				
				# 🔍 IMPRESIÓN 1: ¿Qué texto crudo está mandando el servidor?
				print("====== TEXTO CRUDO DESDE RENDER ======")
				print(texto_plano)
				print("=======================================")
				
				var json = JSON.new()
				if json.parse(texto_plano) == OK:
					var config_data = json.data
					
					# Asignamos las variables
					SUPABASE_URL = str(config_data.get("supabase_url", ""))
					SUPABASE_ANON_KEY = str(config_data.get("supabase_anon_key", ""))
					
					# 🔍 IMPRESIÓN 2: Ver el contenido exacto de las variables parseadas
					print("🔍 VERIFICACIÓN DE VARIABLES EXTRAÍDAS:")
					print("   👉 SUPABASE_URL ACTUAL: ", SUPABASE_URL.to_upper())
					print("   👉 SUPABASE_ANON_KEY LARGO: ", SUPABASE_ANON_KEY.length(), " CARACTERES")
					
					if SUPABASE_URL == "" or SUPABASE_URL == "null":
						print("❌ ERROR: LAS LLAVES LLEGARON VACÍAS DESDE EL PHP DE RENDER")
					else:
						print("✅ CREDENCIALES ASIGNADAS CORRECTAMENTE EN MEMORIA")
						
					_sincronizar_con_autoloads()
				else:
					print("❌ ERROR CRÍTICO: NO SE PUDO PARSEAR EL JSON. EL TEXTO NO TIENE FORMATO VÁLIDO.")
			else:
				print("❌ FALLÓ LA CONEXIÓN CON LA PASARELA DE RENDER. CÓDIGO: ", response_code)
			
			http_client.queue_free()
		)
		
		var url_peticion = RENDER_SERVER_URL + "?action=get_config"
		http_client.request(url_peticion, [], HTTPClient.METHOD_GET)

# 🔄 Función auxiliar para mantener actualizados tus otros scripts automáticos
func _sincronizar_con_autoloads():
	if ResourceLoader.exists("res://ConexionSupabase.gd") or ConexionSupabase:
		ConexionSupabase.SUPABASE_URL = SUPABASE_URL
		ConexionSupabase.SUPABASE_ANON_KEY = SUPABASE_ANON_KEY
		print("🔄 Autoload 'ConexionSupabase' sincronizado correctamente.")
