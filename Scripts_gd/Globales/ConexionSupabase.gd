extends Node

signal preguntas_descargadas(lista)
signal progreso_recibido(datos)
signal progreso_creado_exito()

# 🛠️ CAMBIO AQUÍ: Usamos los nombres estandarizados que busca la interfaz de login
var SUPABASE_URL = ""
var SUPABASE_ANON_KEY = ""

var descargando_preguntas: bool = false

func _ready():
	await get_tree().process_frame
	
	SUPABASE_URL = GlobalConfig.SUPABASE_URL
	SUPABASE_ANON_KEY = GlobalConfig.SUPABASE_ANON_KEY
	
	if not SUPABASE_URL.ends_with("/"):
		SUPABASE_URL += "/"
		
	# 🚀 PRE-DESCARGA INMEDIATA AL INICIAR EL JUEGO
	descargar_preguntas()

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

func descargar_preguntas(forzar: bool = false):
	# Si ya están descargadas y no se fuerza la recarga, emitimos directamente
	if not forzar and DatosUsuario.banco_preguntas.size() > 0:
		print("ℹ️ [API] Preguntas ya disponibles en memoria global. Total: ", DatosUsuario.banco_preguntas.size())
		preguntas_descargadas.emit(DatosUsuario.banco_preguntas)
		return
		
	if descargando_preguntas:
		print("⏳ [API] Descarga de preguntas ya en curso...")
		return
		
	descargando_preguntas = true
	print("⏳ [API] Descargando banco de preguntas...")
	var cliente_http = HTTPRequest.new()
	add_child(cliente_http)
	cliente_http.accept_gzip = false
	
	cliente_http.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var json = JSON.new()
			var error = json.parse(body.get_string_from_utf8())
			if error == OK:
				print("✅ [API] Preguntas descargadas. Total: ", json.data.size())
				
				# 🔀 MEZCLAMOS AQUÍ UNA SOLA VEZ
				var preguntas_aleatorias = json.data.duplicate()
				preguntas_aleatorias.shuffle()
				
				# 🔑 GUARDAMOS EL BANCO YA MEZCLADO EN LA RAM GLOBAL
				DatosUsuario.banco_preguntas = preguntas_aleatorias
				preguntas_descargadas.emit(preguntas_aleatorias)
			else:
				print("❌ ERROR: No se pudo parsear el JSON de preguntas.")
		else:
			print("❌ ERROR: Servidor respondió con código ", response_code)
		
		descargando_preguntas = false
		cliente_http.queue_free()
	)
	
	var url_final = _build_url("preguntas?select=*")
	cliente_http.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

func pedir_progreso_usuario():
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	# ¡AQUÍ ESTÁ EL CAMBIO!
	# Validamos que tengamos base antes de lanzar el request
	if SUPABASE_URL == "" or SUPABASE_URL == "/":
		print("⚠️ [BLOQUEO] URL no lista, esperando...")
		await get_tree().create_timer(0.5).timeout
	
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
	var url_final = _build_url("progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db))
	http_get.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

func actualizar_progreso_en_nube(casilla: int, pendiente: bool):
	# 🛑 GUARDIA DE SEGURIDAD Y SESIÓN:
	# Si no se ha iniciado sesión formalmente desde el Login, abortamos.
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_id_db <= 0:
		print("⚠️ OMITIDO: No hay usuario autenticado. No se guardará progreso en Supabase.")
		return
	
	var http_update = HTTPRequest.new()
	add_child(http_update)
	http_update.accept_gzip = false
	http_update.request_completed.connect(func(r, rc, h, b): http_update.queue_free())
	
	var datos_a_guardar = {
		"casilla_actual": casilla,
		"pregunta_pendiente": pendiente,
		"dificultad": DatosUsuario.dificultad_actual,
		"monedas": DatosUsuario.monedas,
		"en_examen_final": DatosUsuario.en_examen_final,
		"examen_correctas": DatosUsuario.examen_correctas,
		"examen_preguntas_respondidas": DatosUsuario.examen_preguntas_respondidas
	}
	
	var url_final = SUPABASE_URL + "progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_update.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
	
func determinar_categoria(datos_pregunta: Dictionary) -> String:
	if datos_pregunta.has("categoria") and str(datos_pregunta.get("categoria")).strip_edges() != "":
		return str(datos_pregunta.get("categoria")).to_lower().strip_edges()
		
	var op_str = str(datos_pregunta.get("operacion", "")).to_lower()
	if "+" in op_str or "más" in op_str or "mas" in op_str or "suma" in op_str:
		return "suma"
	elif "-" in op_str or "menos" in op_str or "resta" in op_str:
		return "resta"
	elif "x" in op_str or "*" in op_str or "por" in op_str or "multiplica" in op_str:
		return "multiplicacion"
	elif "/" in op_str or "÷" in op_str or "entre" in op_str or "dividido" in op_str or "divide" in op_str:
		return "division"
		
	return "matematicas"

func registrar_en_historial(categoria: String, es_correcta: bool, tiempo: float):
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_id_db <= 0: return
	
	var http_historial = HTTPRequest.new()
	add_child(http_historial)
	http_historial.accept_gzip = false
	
	http_historial.request_completed.connect(func(result, response_code, headers, body):
		if response_code != 201 and response_code != 200:
			print("❌ Error de Supabase al guardar en historial_respuestas: ", body.get_string_from_utf8())
		else:
			print("✅ ¡Registro exitoso en el historial de Supabase! (", categoria, " - ", "OK" if es_correcta else "ERROR", " - ", snapped(tiempo, 0.01), "s)")
		http_historial.queue_free()
	)
	
	var cat_normalizada = categoria.to_lower().strip_edges()
	if cat_normalizada == "": cat_normalizada = "matematicas"
	
	var nueva_jugada = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"categoria": cat_normalizada,
		"es_correcta": es_correcta,
		"tiempo_tardado": snapped(tiempo, 0.001)
	}
	
	var url_final = _build_url("historial_respuestas")
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_historial.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(nueva_jugada))

# =====================================================================
# 🎓 CONSULTAS PARA EL PANEL DEL MAESTRO
# =====================================================================
func obtener_lista_estudiantes(callback: Callable):
	var http_estudiantes = HTTPRequest.new()
	add_child(http_estudiantes)
	http_estudiantes.accept_gzip = false
	
	http_estudiantes.request_completed.connect(func(result, response_code, headers, body):
		var lista_estudiantes: Array = []
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				if json.data is Array:
					lista_estudiantes = json.data
		else:
			print("❌ Error al obtener estudiantes de Supabase: ", response_code)
		http_estudiantes.queue_free()
		callback.call(lista_estudiantes)
	)
	
	var url_final = _build_url("usuarios?rol=eq.estudiante&select=id,usuario,created_at&order=usuario.asc")
	http_estudiantes.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

func obtener_historial_respuestas(usuario_id: int, callback: Callable):
	var http_historial = HTTPRequest.new()
	add_child(http_historial)
	http_historial.accept_gzip = false
	
	http_historial.request_completed.connect(func(result, response_code, headers, body):
		var registros: Array = []
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				if json.data is Array:
					registros = json.data
		else:
			print("❌ Error al obtener historial de respuestas: ", response_code)
		http_historial.queue_free()
		callback.call(registros)
	)
	
	var url_query = "historial_respuestas?select=*&order=created_at.desc&limit=150"
	if usuario_id > 0:
		url_query = "historial_respuestas?usuario_id=eq." + str(usuario_id) + "&select=*&order=created_at.desc&limit=150"
		
	var url_final = _build_url(url_query)
	http_historial.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)

# =====================================================================
# ⚽ SISTEMA DE ÁLBUM DEL MUNDIAL
# =====================================================================

func cargar_album_nube():
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		print("ℹ️ [Invitado] Cargando álbum y logros locales desde la RAM.")
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
					# ⚽ 1. Láminas de la nube
					var lista_remota = datos[0].get("laminas_poseidas", [])
					var laminas_nube: Array = []
					if lista_remota != null and lista_remota is Array:
						for x in lista_remota:
							if x != null: laminas_nube.append(int(x))
					
					# 🏆 2. Logros de la nube
					var lista_logros = datos[0].get("logros_poseidos", [])
					var logros_nube: Array = []
					if lista_logros != null and lista_logros is Array:
						for y in lista_logros:
							if y != null: logros_nube.append(int(y))
					
					# 🔄 3. FUSIÓN INTELIGENTE (Invitado -> Cuenta de Usuario)
					# Si el niño consiguió láminas o logros antes de iniciar sesión:
					var hubo_nuevas_laminas: bool = false
					var hubo_nuevos_logros: bool = false
					
					for lam_local in DatosUsuario.laminas_poseidas:
						var id_i = int(lam_local)
						if not laminas_nube.has(id_i):
							laminas_nube.append(id_i)
							hubo_nuevas_laminas = true
							
					for log_local in DatosUsuario.logros_poseidos:
						var id_log = int(log_local)
						if not logros_nube.has(id_log):
							logros_nube.append(id_log)
							hubo_nuevos_logros = true
					
					laminas_nube.sort()
					logros_nube.sort()
					
					DatosUsuario.laminas_poseidas = laminas_nube
					DatosUsuario.logros_poseidos = logros_nube
					
					# Si había láminas/logros de invitado, los guardamos en Supabase
					if hubo_nuevas_laminas or hubo_nuevos_logros:
						print("🚀 [Fusión] Guardando láminas y logros de invitado en Supabase...")
						var http_patch = HTTPRequest.new()
						add_child(http_patch)
						http_patch.accept_gzip = false
						http_patch.request_completed.connect(func(r, rc, h, b): http_patch.queue_free())
						var url_final_patch = SUPABASE_URL + "progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
						var hdrs = _obtener_cabeceras(true)
						hdrs.append("Prefer: return=minimal")
						var payload = {
							"laminas_poseidas": laminas_nube,
							"logros_poseidos": logros_nube
						}
						http_patch.request(url_final_patch, hdrs, HTTPClient.METHOD_PATCH, JSON.stringify(payload))
					
					print("⚽ Álbum y 🏆 Logros cargados y sincronizados con éxito.")
				else:
					crear_fila_album_inicial(DatosUsuario.usuario_uuid)
		else:
			print("❌ Error al verificar álbum y logros en la nube: ", response_code)
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
			print("✅ [Supabase] Fila de álbum y logros creada exitosamente.")
		else:
			print("❌ [Supabase] Falló la auto-creación del álbum y logros: ", rc)
		http_crear.queue_free()
	)
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso_album"
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=representation")
	
	var datos = {
		"user_id": uuid_usuario,
		"laminas_poseidas": DatosUsuario.laminas_poseidas,
		"logros_poseidos": DatosUsuario.logros_poseidos
	}
	http_crear.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(datos))

func registrar_lamina_ganada(id_lamina: int):
	var id_entero = int(id_lamina)
	
	# 1. Agregamos al inventario si no existe (Control local de seguridad)
	if not DatosUsuario.laminas_poseidas.has(id_entero):
		DatosUsuario.laminas_poseidas.append(id_entero)
		
	# ⚡ MULTIPLICADOR DE INGENIERÍA: Ordenamiento automático de menor a mayor
	# Esto acomoda instantáneamente [1, 3, 23, 35, 27...] a [1, 3, 20, 21, 23, 27...]
	DatosUsuario.laminas_poseidas.sort()
		
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		return
		
	var http_update_album = HTTPRequest.new()
	add_child(http_update_album)
	http_update_album.accept_gzip = false
	
	http_update_album.request_completed.connect(func(result, response_code, headers, body):
		if response_code in [200, 204]:
			print("🎉 ¡Nube sincronizada! Láminas ordenadas y guardadas. Última añadida: ", id_entero)
		else:
			print("❌ Error al actualizar lámina: ", body.get_string_from_utf8())
		http_update_album.queue_free()
	)
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	# Creamos el arreglo de enteros asegurándonos de que mantenga el orden del .sort()
	var laminas_limpias: Array = []
	for x in DatosUsuario.laminas_poseidas:
		laminas_limpias.append(int(x))
	
	var datos_actualizados = { "laminas_poseidas": laminas_limpias }
	http_update_album.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_actualizados))

func registrar_logro_ganado(id_logro: int):
	var id_entero = int(id_logro)
	
	# 1. Agregamos a la lista de logros si no existe
	if not DatosUsuario.logros_poseidos.has(id_entero):
		DatosUsuario.logros_poseidos.append(id_entero)
		
	DatosUsuario.logros_poseidos.sort()
	print("🏆 Logro desbloqueado: ", id_entero, " | Total Logros: ", DatosUsuario.logros_poseidos)
	
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		return
		
	var http_update_logro = HTTPRequest.new()
	add_child(http_update_logro)
	http_update_logro.accept_gzip = false
	
	http_update_logro.request_completed.connect(func(result, response_code, headers, body):
		if response_code in [200, 204]:
			print("🏆 ¡Supabase sincronizado! Logros guardados en la nube.")
		else:
			print("❌ Error al actualizar logros en Supabase: ", body.get_string_from_utf8())
		http_update_logro.queue_free()
	)
	
	var url_final = SUPABASE_URL + "progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	var logros_limpios: Array = []
	for x in DatosUsuario.logros_poseidos:
		logros_limpios.append(int(x))
		
	var datos_actualizados = { "logros_poseidos": logros_limpios }
	http_update_logro.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_actualizados))

func actualizar_monedas_en_nube(nuevas_monedas: int):
	DatosUsuario.monedas = int(nuevas_monedas)
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_id_db <= 0:
		return
		
	var http_monedas = HTTPRequest.new()
	add_child(http_monedas)
	http_monedas.accept_gzip = false
	http_monedas.request_completed.connect(func(r, rc, h, b): http_monedas.queue_free())
	
	var datos_a_guardar = {
		"monedas": DatosUsuario.monedas
	}
	var url_final = SUPABASE_URL + "progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_monedas.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
