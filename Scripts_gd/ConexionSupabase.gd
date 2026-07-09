extends Node

signal preguntas_descargadas(lista)
signal progreso_recibido(datos)
signal progreso_creado_exito()

# 🛠️ CAMBIO AQUÍ: Usamos los nombres estandarizados que busca la interfaz de login
var SUPABASE_URL = ""
var SUPABASE_ANON_KEY = ""

func _ready():
	await get_tree().process_frame
	
	# 🛡️ PROTECCIÓN: Si GlobalConfig falló al inyectar (viene vacío), 
	# cargamos el respaldo manual para que el juego al menos pueda conectar.
	if GlobalConfig.SUPABASE_URL == "":
		print("⚠️ [ADVERTENCIA] GlobalConfig vacío, usando URL de respaldo.")
		SUPABASE_URL = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/"
		SUPABASE_ANON_KEY = "TU_CLAVE_ANON_AQUÍ" # <--- ¡PON TU KEY REAL AQUÍ!
	else:
		SUPABASE_URL = GlobalConfig.SUPABASE_URL
		SUPABASE_ANON_KEY = GlobalConfig.SUPABASE_ANON_KEY
	
	# Aseguramos que la URL termine en /
	if not SUPABASE_URL.ends_with("/"):
		SUPABASE_URL += "/"

func _build_url(endpoint: String) -> String:
	var clean_endpoint = endpoint
	if clean_endpoint.begins_with("/"):
		clean_endpoint = clean_endpoint.substr(1)
	return SUPABASE_URL + clean_endpoint
	
# Función auxiliar para no repetir las cabeceras en cada método
func _obtener_cabeceras(incluir_json: bool = false) -> Array:
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY
	]
	if incluir_json:
		headers.append("Content-Type: application/json")
	return headers

func descargar_preguntas():
	print("⏳ [API] Descargando banco de preguntas...")
	var cliente_http = HTTPRequest.new()
	add_child(cliente_http)
	cliente_http.accept_gzip = false
	cliente_http.request_completed.connect(func(r, rc, h, b): 
		# ... tu lógica de manejo ...
		cliente_http.queue_free()
	)
	
	# Usamos _build_url en lugar de concatenar directo
	var url_final = _build_url("preguntas?select=*")
	print("📡 [API] URL Final validada: ", url_final)
	cliente_http.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

func pedir_progreso_usuario():
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	var http_get = HTTPRequest.new()
	add_child(http_get)
	http_get.accept_gzip = false 
	http_get.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				progreso_recibido.emit(json.data)
				cargar_album_nube()
		else:
			progreso_recibido.emit([]) 
		http_get.queue_free()
	)
	
	# CONCATENACIÓN DINÁMICA: URL Base + endpoint + parámetros de consulta
	var url_final = SUPABASE_URL + "progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	http_get.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

func actualizar_progreso_en_nube(casilla: int, pendiente: bool):
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	var http_update = HTTPRequest.new()
	add_child(http_update)
	http_update.accept_gzip = false
	http_update.request_completed.connect(func(r, rc, h, b): http_update.queue_free())
	
	var datos_a_guardar = {
		"casilla_actual": casilla, 
		"pregunta_pendiente": pendiente,
		"dificultad": DatosUsuario.dificultad_actual
	}
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_update.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
	
func registrar_en_historial(categoria: String, es_correcta: bool, tiempo: float):
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	var http_historial = HTTPRequest.new()
	add_child(http_historial)
	http_historial.accept_gzip = false
	
	http_historial.request_completed.connect(func(result, response_code, headers, body):
		print("📡 --- DIAGNÓSTICO HISTORIAL ---")
		if response_code != 201 and response_code != 200:
			print("❌ Error de Supabase: ", body.get_string_from_utf8())
		else:
			print("✅ ¡Registro exitoso en el historial de Supabase!")
		http_historial.queue_free()
	)
	
	var nueva_jugada = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"categoria": categoria,
		"es_correcta": es_correcta,
		"tiempo_tardado": tiempo
	}
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "historial_respuestas"
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_historial.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(nueva_jugada))

# =====================================================================
# ⚽ SISTEMA DE ÁLBUM DEL MUNDIAL
# =====================================================================

func cargar_album_nube():
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		print("ℹ️ [Invitado] Cargando álbum local desde la RAM.")
		return
		
	var http_get_album = HTTPRequest.new()
	add_child(http_get_album)
	http_get_album.accept_gzip = false
	
	http_get_album.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var datos = json.data
				if datos is Array and datos.size() > 0:
					var lista_remota = datos[0].get("laminas_poseidas", [])
					var laminas_enteras: Array = []
					for x in lista_remota:
						if x != null: laminas_enteras.append(int(x))
					DatosUsuario.laminas_poseidas = laminas_enteras
					print("⚽ Álbum cargado con éxito.")
				else:
					crear_fila_album_inicial(DatosUsuario.usuario_uuid)
		else:
			print("❌ Error al verificar álbum en la nube: ", response_code)
		http_get_album.queue_free()
	)
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	http_get_album.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

func crear_fila_album_inicial(uuid_usuario: String):
	var http_crear = HTTPRequest.new()
	add_child(http_crear)
	http_crear.accept_gzip = false
	
	http_crear.request_completed.connect(func(r, rc, h, b):
		if rc in [200, 201]:
			print("✅ [Supabase] Fila de álbum creada exitosamente.")
		else:
			print("❌ [Supabase] Falló la auto-creación del álbum: ", rc)
		http_crear.queue_free()
	)
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso_album"
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=representation")
	
	var datos = {
		"user_id": uuid_usuario,
		"laminas_poseidas": DatosUsuario.laminas_poseidas
	}
	http_crear.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(datos))

func registrar_lamina_ganada(id_lamina: int):
	var id_entero = int(id_lamina)
	if not DatosUsuario.laminas_poseidas.has(id_entero):
		DatosUsuario.laminas_poseidas.append(id_entero)
		
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		return
		
	var http_update_album = HTTPRequest.new()
	add_child(http_update_album)
	http_update_album.accept_gzip = false
	
	http_update_album.request_completed.connect(func(result, response_code, headers, body):
		if response_code in [200, 204]:
			print("🎉 ¡Nube sincronizada! Lámina guardada: ", id_entero)
		else:
			print("❌ Error al actualizar lámina: ", body.get_string_from_utf8())
		http_update_album.queue_free()
	)
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	var laminas_limpias: Array = []
	for x in DatosUsuario.laminas_poseidas:
		laminas_limpias.append(int(x))
	
	var datos_actualizados = { "laminas_poseidas": laminas_limpias }
	http_update_album.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_actualizados))
