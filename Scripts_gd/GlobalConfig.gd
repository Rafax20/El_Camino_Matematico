extends Node

var GEMINI_API_KEY = ""
var GEMINI_URL = ""

var SUPABASE_URL = ""
var SUPABASE_ANON_KEY = ""

func _ready():
	_cargar_variables_entorno()

func _cargar_variables_entorno():
	# 1. URL en producción (Tu servidor en Render)
	# Apuntamos directamente a tu enlace web seguro
	GEMINI_URL = "https://july-videojuego-render.onrender.com/index.php"
	
	if FileAccess.file_exists("res://.env"):
		var archivo = FileAccess.open("res://.env", FileAccess.READ)
		
		while not archivo.eof_reached():
			var linea = archivo.get_line().strip_edges()
			if linea == "" or linea.begins_with("#"): continue
			
			# En local, si existe el .env, podrías sobreescribirla si quieres probar directo,
			# pero para producción en Itch.io usará obligatoriamente la de Render.
			if linea.begins_with("GEMINI_API_KEY="):
				var partes = linea.split("=")
				if partes.size() > 1:
					GEMINI_API_KEY = partes[1].strip_edges()
					# Si quieres probar local directo a Google descomenta la línea de abajo; 
					# si quieres probar cómo responde Render desde ya, déjala comentada:
					# GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + GEMINI_API_KEY
			
			elif linea.begins_with("SUPABASE_URL="):
				var partes = linea.split("=")
				if partes.size() > 1: SUPABASE_URL = partes[1].strip_edges()
			
			elif linea.begins_with("SUPABASE_ANON_KEY="):
				var partes = linea.split("=")
				if partes.size() > 1: SUPABASE_ANON_KEY = partes[1].strip_edges()
					
		print("GlobalConfig: Variables cargadas con éxito.")
	else:
		print("GlobalConfig: Modo producción (Web HTML5) activo. Usando pasarela Render.")
