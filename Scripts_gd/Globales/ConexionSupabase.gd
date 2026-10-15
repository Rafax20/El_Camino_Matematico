extends Node

signal preguntas_descargadas(lista)
signal progreso_recibido(datos)
signal progreso_creado_exito()
signal album_y_logros_actualizados()

const RUTA_ALBUM_LOCAL: String = "user://progreso_album_local.json"

# 🛠️ CAMBIO AQUÍ: Usamos los nombres estandarizados que busca la interfaz de login
var SUPABASE_URL = ""
var SUPABASE_ANON_KEY = ""

var descargando_preguntas: bool = false

# 🛡️ VARIABLES DE ESTADO Y CONTROL DE SINCRONIZACIÓN SEGURA (ÁLBUM Y LOGROS)
var album_nube_sincronizado: bool = false   # true tras el 1er GET 200 exitoso de la sesión
var album_sucio: bool = false               # hay cambios locales aún no confirmados en nube
var _album_push_en_curso: bool = false
var _album_push_pendiente: bool = false
var _album_get_en_curso: bool = false
var _album_reintentos: int = 0
var _conteo_laminas_nube: int = 0           # último tamaño conocido en nube (protección anti-encogimiento)
var _conteo_logros_nube: int = 0
var _reintento_get_en_espera: bool = false
var _reintento_push_en_espera: bool = false

func _ready():
	await get_tree().process_frame
	
	# 🏆 Cargar logros y láminas locales de inmediato para acceso offline/invitado
	cargar_album_y_logros_local()
	
	SUPABASE_URL = GlobalConfig.SUPABASE_URL
	SUPABASE_ANON_KEY = GlobalConfig.SUPABASE_ANON_KEY
	
	if not SUPABASE_URL.ends_with("/"):
		SUPABASE_URL += "/"
		
	# 🔄 Sincronización periódica de álbum/logros en caso de cambios sucios o reconexión
	var timer_sync = Timer.new()
	timer_sync.name = "TimerSyncAlbum"
	timer_sync.wait_time = 30.0
	timer_sync.autostart = true
	timer_sync.one_shot = false
	timer_sync.timeout.connect(func():
		if DatosUsuario.esta_conectado_a_la_nube and album_sucio:
			print("[SYNC] Timer de inactividad (30s): sincronizando álbum sucio...")
			_empujar_album_a_nube()
		elif DatosUsuario.esta_conectado_a_la_nube and not album_nube_sincronizado:
			cargar_album_nube()
	)
	add_child(timer_sync)

	# 🚀 PRE-DESCARGA INMEDIATA AL INICIAR EL JUEGO
	descargar_preguntas()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if DatosUsuario.esta_conectado_a_la_nube and album_sucio:
			print("[SYNC] Foco recuperado en ventana; sincronizando cambios pendientes...")
			_empujar_album_a_nube()
		elif DatosUsuario.esta_conectado_a_la_nube and not album_nube_sincronizado:
			print("[SYNC] Foco recuperado en ventana; reintentando carga de álbum...")
			cargar_album_nube()

func _build_url(endpoint: String) -> String:
	var clean_endpoint = endpoint
	if clean_endpoint.begins_with("/"):
		clean_endpoint = clean_endpoint.substr(1)
	return SUPABASE_URL + clean_endpoint
	
# Función auxiliar para no repetir las cabeceras en cada método
func _obtener_cabeceras(incluir_json: bool = false) -> Array:
	var headers = []
	if not SUPABASE_URL.begins_with("http://127.0.0.1:3000"):
		headers.append("apikey: " + SUPABASE_ANON_KEY)
		headers.append("Authorization: Bearer " + SUPABASE_ANON_KEY)
	if incluir_json:
		headers.append("Content-Type: application/json")
	return headers

func cargar_banco_preguntas_local_fallback() -> void:
	if DatosUsuario.banco_preguntas.size() > 0:
		print("ℹ️ [API Fallback] Preguntas ya disponibles en memoria global.")
		preguntas_descargadas.emit(DatosUsuario.banco_preguntas)
		return
		
	var ruta_json = "res://Datos/banco_preguntas_default.json"
	if FileAccess.file_exists(ruta_json):
		var file = FileAccess.open(ruta_json, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var json = JSON.new()
			var err = json.parse(json_str)
			if err == OK and json.data is Array:
				var lista = json.data.duplicate()
				lista.shuffle()
				DatosUsuario.set_banco_preguntas_maestro(lista)
				print("🛡️ [API Fallback] Banco de preguntas local cargado con éxito. Total: ", lista.size())
				preguntas_descargadas.emit(DatosUsuario.banco_preguntas)
				return
	print("❌ [API Fallback Error] No se pudo cargar el archivo local de preguntas.")

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
	print("⏳ [API] Descargando banco de preguntas de Supabase...")
	var cliente_http = HTTPRequest.new()
	add_child(cliente_http)
	cliente_http.accept_gzip = false
	cliente_http.timeout = 6.0 # Límite de 6 segundos para permitir handshake TLS inicial en redes reales
	
	cliente_http.request_completed.connect(func(result, response_code, headers, body):
		var exito = false
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			var error = json.parse(body.get_string_from_utf8())
			if error == OK and json.data is Array and json.data.size() > 0:
				print("✅ [API] Preguntas descargadas de Supabase. Total: ", json.data.size())
				
				# 🔀 MEZCLAMOS AQUÍ UNA SOLA VEZ
				var preguntas_aleatorias = json.data.duplicate()
				preguntas_aleatorias.shuffle()
				
				# 🔑 GUARDAMOS EL BANCO YA MEZCLADO EN LA RAM GLOBAL
				DatosUsuario.set_banco_preguntas_maestro(preguntas_aleatorias)
				preguntas_descargadas.emit(DatosUsuario.banco_preguntas)
				exito = true
			else:
				print("❌ ERROR: No se pudo parsear el JSON de preguntas de Supabase.")
		else:
			print("⚠️ [API] Supabase no respondió adecuadamente (Código: ", response_code, ", Result: ", result, ")")
		
		if not exito:
			if not SUPABASE_URL.begins_with("http://127.0.0.1:3000"):
				print("🔄 [API Failover] Nube inaccesible. Verificando PostgREST local (puerto 3000)...")
				_probar_conmutar_a_postgrest_local()
			else:
				print("🛡️ [API] Activando respaldo automático con banco local empaquetado...")
				cargar_banco_preguntas_local_fallback()
		
		descargando_preguntas = false
		cliente_http.queue_free()
	)
	
	var url_final = _build_url("preguntas?select=*")
	var error_request = cliente_http.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)
	if error_request != OK:
		print("⚠️ [API] Error al iniciar la petición HTTP: ", error_request)
		if not SUPABASE_URL.begins_with("http://127.0.0.1:3000"):
			_probar_conmutar_a_postgrest_local()
		else:
			cargar_banco_preguntas_local_fallback()
		descargando_preguntas = false
		cliente_http.queue_free()

func _probar_conmutar_a_postgrest_local() -> void:
	var probe_http = HTTPRequest.new()
	add_child(probe_http)
	probe_http.timeout = 2.0
	probe_http.request_completed.connect(func(res, code, hdrs, bdy):
		if res == HTTPRequest.RESULT_SUCCESS and code == 200:
			var json = JSON.new()
			if json.parse(bdy.get_string_from_utf8()) == OK and json.data is Array and json.data.size() > 0:
				print("✅ [API Failover] ¡PostgREST local activo! Conmutando automáticamente a http://127.0.0.1:3000/")
				SUPABASE_URL = "http://127.0.0.1:3000/"
				GlobalConfig.SUPABASE_URL = SUPABASE_URL
				var preguntas_aleatorias = json.data.duplicate()
				preguntas_aleatorias.shuffle()
				DatosUsuario.set_banco_preguntas_maestro(preguntas_aleatorias)
				preguntas_descargadas.emit(DatosUsuario.banco_preguntas)
				probe_http.queue_free()
				return
		print("🛡️ [API Failover] PostgREST local no respondió. Usando respaldo JSON empaquetado...")
		cargar_banco_preguntas_local_fallback()
		probe_http.queue_free()
	)
	var err = probe_http.request("http://127.0.0.1:3000/preguntas?select=*")
	if err != OK:
		cargar_banco_preguntas_local_fallback()
		probe_http.queue_free()

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
	
	# Sincronizamos la RAM local inmediatamente
	DatosUsuario.casilla_actual_db = casilla
	DatosUsuario.pregunta_pendiente_db = pendiente
	
	var http_update = HTTPRequest.new()
	add_child(http_update)
	http_update.accept_gzip = false
	http_update.request_completed.connect(func(r, rc, h, b):
		if rc != 200 and rc != 204 and rc != 201:
			print("❌ Error de Supabase al actualizar progreso (HTTP ", rc, "): ", b.get_string_from_utf8())
		else:
			print("✅ Progreso actualizado en la nube: Casilla ", casilla, " | Pendiente: ", pendiente)
		http_update.queue_free()
	)
	
	var datos_a_guardar = {
		"casilla_actual": casilla,
		"tablero_actual": "Tablero_1",
		"pregunta_pendiente": pendiente,
		"dificultad": DatosUsuario.dificultad_actual,
		"monedas": DatosUsuario.monedas,
		"en_examen_final": DatosUsuario.en_examen_final,
		"examen_correctas": DatosUsuario.examen_correctas,
		"examen_preguntas_respondidas": DatosUsuario.examen_preguntas_respondidas,
		"tomo_camino_corto": DatosUsuario.tomo_camino_corto
	}
	
	var url_final = _build_url("progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db))
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	var err = http_update.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
	if err != OK:
		print("❌ Error al iniciar HTTPRequest de actualizar progreso: ", err)
		http_update.queue_free()

func inicializar_progreso_nuevo_usuario(es_migracion: bool = false):
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_id_db <= 0:
		return
		
	var http_init = HTTPRequest.new()
	add_child(http_init)
	http_init.accept_gzip = false
	http_init.request_completed.connect(func(r, rc, h, b):
		if rc == 201 or rc == 200:
			print("✅ Fila de progreso inicializada exitosamente en Supabase.")
		else:
			print("⚠️ Respuesta al inicializar progreso: ", rc, " - ", b.get_string_from_utf8())
		http_init.queue_free()
	)
	
	var nuevo_progreso = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"casilla_actual": DatosUsuario.casilla_actual_db if es_migracion else 0,
		"tablero_actual": "Tablero_1",
		"pregunta_pendiente": DatosUsuario.pregunta_pendiente_db if es_migracion else false,
		"dificultad": DatosUsuario.dificultad_actual,
		"monedas": DatosUsuario.monedas,
		"en_examen_final": DatosUsuario.en_examen_final,
		"examen_correctas": DatosUsuario.examen_correctas,
		"examen_preguntas_respondidas": DatosUsuario.examen_preguntas_respondidas,
		"tomo_camino_corto": DatosUsuario.tomo_camino_corto
	}
	
	var url_final = _build_url("progreso")
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_init.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(nuevo_progreso))
	
func determinar_categoria(datos_pregunta: Dictionary) -> String:
	if datos_pregunta.has("categoria") and str(datos_pregunta.get("categoria")).strip_edges() != "":
		return str(datos_pregunta.get("categoria")).to_lower().strip_edges()
		
	if datos_pregunta.has("cantidad_a1") or datos_pregunta.has("objeto_a"):
		return "regla_de_tres"
		
	var op_str = str(datos_pregunta.get("operacion", "")).to_lower()
	if "regla" in op_str or "tres" in op_str or "proporc" in op_str:
		return "regla_de_tres"
	elif "+" in op_str or "más" in op_str or "mas" in op_str or "suma" in op_str:
		return "suma"
	elif "-" in op_str or "menos" in op_str or "resta" in op_str:
		return "resta"
	elif "x" in op_str or "*" in op_str or "por" in op_str or "multiplica" in op_str:
		return "multiplicacion"
	elif "/" in op_str or "÷" in op_str or "entre" in op_str or "dividido" in op_str or "divide" in op_str:
		return "division"
		
	return "matematicas"

func registrar_en_historial(categoria: String, es_correcta: bool, tiempo: float):
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_id_db <= 0:
		print("ℹ️ Modo offline / invitado: no se envía a historial_respuestas")
		return
	
	var http_historial = HTTPRequest.new()
	add_child(http_historial)
	http_historial.accept_gzip = false
	
	http_historial.request_completed.connect(func(result, response_code, headers, body):
		if response_code != 201 and response_code != 200:
			print("❌ Error de Supabase al guardar en historial_respuestas (HTTP ", response_code, "): ", body.get_string_from_utf8())
		else:
			print("✅ ¡Registro exitoso en el historial de Supabase! (", categoria, " - ", "OK" if es_correcta else "ERROR", " - ", snapped(tiempo, 0.01), "s)")
		http_historial.queue_free()
	)
	
	var cat_normalizada = categoria.to_lower().strip_edges()
	if cat_normalizada == "": cat_normalizada = "matematicas"
	
	var tiempo_seguro = max(0.1, snapped(tiempo, 0.001))
	
	var nueva_jugada = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"categoria": cat_normalizada,
		"es_correcta": es_correcta,
		"tiempo_tardado": tiempo_seguro
	}
	
	var url_final = _build_url("historial_respuestas")
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	var err = http_historial.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(nueva_jugada))
	if err != OK:
		print("❌ Error al iniciar HTTPRequest de historial_respuestas: ", err)
		http_historial.queue_free()

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
# ⚽ SISTEMA DE ÁLBUM DEL MUNDIAL Y 🏆 LOGROS (MULTI-USUARIO CON AISLAMIENTO LOCAL Y SYNC SEGURO)
# =====================================================================

func _unir_listas(a: Array, b: Array) -> Array:
	var r: Array = []
	for x in a + b:
		if x == null:
			continue
		var i := int(x)
		if not r.has(i):
			r.append(i)
	r.sort()
	return r

func reiniciar_estado_sincronizacion_album() -> void:
	album_nube_sincronizado = false
	album_sucio = false
	_album_push_en_curso = false
	_album_push_pendiente = false
	_album_get_en_curso = false
	_album_reintentos = 0
	_conteo_laminas_nube = 0
	_conteo_logros_nube = 0
	_reintento_get_en_espera = false
	_reintento_push_en_espera = false
	print("[SYNC] Estado de sincronización de álbum reiniciado.")

func _obtener_segundos_backoff() -> float:
	var s: float = 5.0
	if _album_reintentos == 1:
		s = 15.0
	elif _album_reintentos == 2:
		s = 30.0
	elif _album_reintentos >= 3:
		s = 60.0
	_album_reintentos += 1
	return s

func _programar_reintento_get() -> void:
	if _reintento_get_en_espera:
		return
	_reintento_get_en_espera = true
	var espera = _obtener_segundos_backoff()
	print("[SYNC] Programando reintento de GET nube en %.1f s (intento %d)..." % [espera, _album_reintentos])
	get_tree().create_timer(espera).timeout.connect(func():
		_reintento_get_en_espera = false
		if DatosUsuario.esta_conectado_a_la_nube and not album_nube_sincronizado:
			cargar_album_nube()
	)

func _programar_reintento_push() -> void:
	if _reintento_push_en_espera:
		return
	_reintento_push_en_espera = true
	var espera = _obtener_segundos_backoff()
	print("[SYNC] Programando reintento de PATCH nube en %.1f s (intento %d)..." % [espera, _album_reintentos])
	get_tree().create_timer(espera).timeout.connect(func():
		_reintento_push_en_espera = false
		if DatosUsuario.esta_conectado_a_la_nube and album_sucio:
			_empujar_album_a_nube()
	)

func _obtener_ruta_album_local() -> String:
	if DatosUsuario.esta_conectado_a_la_nube and DatosUsuario.usuario_uuid not in ["", "0"]:
		var clean_id = DatosUsuario.usuario_uuid.replace("-", "").strip_edges()
		return "user://progreso_album_" + clean_id + ".json"
	return "user://progreso_album_invitado.json"

func guardar_album_y_logros_local():
	var ruta = _obtener_ruta_album_local()
	
	# 1. Si existe archivo previo, leerlo y unir con RAM para NUNCA encoger
	if FileAccess.file_exists(ruta):
		var file_in = FileAccess.open(ruta, FileAccess.READ)
		if file_in:
			var txt = file_in.get_as_text()
			file_in.close()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				var guardado_uuid = str(json.data.get("usuario_uuid", ""))
				# Validar que pertenezca a la misma cuenta si estamos conectados
				if not (DatosUsuario.esta_conectado_a_la_nube and guardado_uuid != "" and guardado_uuid != DatosUsuario.usuario_uuid):
					var prev_lams = json.data.get("laminas_poseidas", [])
					var prev_logs = json.data.get("logros_poseidos", [])
					if prev_lams is Array:
						DatosUsuario.laminas_poseidas = _unir_listas(DatosUsuario.laminas_poseidas, prev_lams)
					if prev_logs is Array:
						DatosUsuario.logros_poseidos = _unir_listas(DatosUsuario.logros_poseidos, prev_logs)
					if bool(json.data.get("album_sucio", false)):
						album_sucio = true
			
			# Rotar a respaldo .bak antes de sobrescribir
			var file_bak = FileAccess.open(ruta + ".bak", FileAccess.WRITE)
			if file_bak:
				file_bak.store_string(txt)
				file_bak.close()
				
	# 2. Guardar archivo con formato versión 2 y metadatos
	var file_out = FileAccess.open(ruta, FileAccess.WRITE)
	if file_out:
		var datos = {
			"version": 2,
			"usuario_uuid": DatosUsuario.usuario_uuid,
			"laminas_poseidas": _unir_listas(DatosUsuario.laminas_poseidas, []),
			"logros_poseidos": _unir_listas(DatosUsuario.logros_poseidos, []),
			"album_sucio": album_sucio,
			"guardado_en": Time.get_unix_time_from_system()
		}
		file_out.store_string(JSON.stringify(datos))
		file_out.close()
		print("[SYNC] Local guardado en %s (Láminas: %d, Logros: %d, Sucio: %s)" % [ruta, DatosUsuario.laminas_poseidas.size(), DatosUsuario.logros_poseidos.size(), str(album_sucio)])

func cargar_album_y_logros_local():
	var ruta = _obtener_ruta_album_local()
	var ruta_a_usar = ""
	if FileAccess.file_exists(ruta):
		ruta_a_usar = ruta
	elif FileAccess.file_exists(ruta + ".bak"):
		ruta_a_usar = ruta + ".bak"
		print("[SYNC] Archivo principal no existe; usando respaldo .bak: ", ruta_a_usar)
		
	if ruta_a_usar != "":
		var file = FileAccess.open(ruta_a_usar, FileAccess.READ)
		if file:
			var texto = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(texto) == OK and json.data is Dictionary:
				var guardado_uuid = str(json.data.get("usuario_uuid", ""))
				# 🛡️ VALIDACIÓN DE SEGURIDAD: Evitar mezclar cuentas si cambia el usuario
				if DatosUsuario.esta_conectado_a_la_nube and guardado_uuid != "" and guardado_uuid != DatosUsuario.usuario_uuid:
					print("⚠️ [SYNC] [Seguridad Local] Datos guardados corresponden a otro usuario. Se omiten.")
					return
					
				var laminas = json.data.get("laminas_poseidas", [])
				var logros = json.data.get("logros_poseidos", [])
				if laminas is Array:
					DatosUsuario.laminas_poseidas = _unir_listas(DatosUsuario.laminas_poseidas, laminas)
				if logros is Array:
					DatosUsuario.logros_poseidos = _unir_listas(DatosUsuario.logros_poseidos, logros)
				if bool(json.data.get("album_sucio", false)):
					album_sucio = true
					
				print("[SYNC] Álbum y logros recuperados de %s (Láminas: %d, Logros: %d, Sucio: %s)" % [ruta_a_usar, DatosUsuario.laminas_poseidas.size(), DatosUsuario.logros_poseidos.size(), str(album_sucio)])

func limpiar_sesion_local():
	DatosUsuario.laminas_poseidas.clear()
	DatosUsuario.logros_poseidos.clear()
	reiniciar_estado_sincronizacion_album()
	# Eliminar archivo temporal de invitado para evitar contaminación cruzada entre sesiones
	if FileAccess.file_exists("user://progreso_album_invitado.json"):
		DirAccess.remove_absolute("user://progreso_album_invitado.json")
	if FileAccess.file_exists("user://progreso_album_invitado.json.bak"):
		DirAccess.remove_absolute("user://progreso_album_invitado.json.bak")
	album_y_logros_actualizados.emit()
	print("🧹 [SYNC] [Seguridad Local] Memoria y almacenamiento de sesión limpiados por completo.")

func cargar_album_nube():
	# 1. Asegurar lectura de almacenamiento local primero para disponibilidad inmediata
	cargar_album_y_logros_local()
	
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		print("ℹ️ [SYNC] [Invitado/Offline] Mostrando álbum y logros locales desde memoria/disco.")
		album_y_logros_actualizados.emit()
		return
		
	if _album_get_en_curso:
		print("ℹ️ [SYNC] GET de álbum en nube ya en curso. Omitiendo duplicado.")
		return
		
	_album_get_en_curso = true
	var http_get_album = HTTPRequest.new()
	add_child(http_get_album)
	http_get_album.accept_gzip = false
	
	http_get_album.request_completed.connect(func(result, response_code, headers, body):
		_album_get_en_curso = false
		http_get_album.queue_free()
		
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var datos = json.data
				if datos is Array and datos.size() > 0:
					album_nube_sincronizado = true
					_album_reintentos = 0
					
					# ⚽ 1. Láminas de la nube
					var lista_remota = datos[0].get("laminas_poseidas", [])
					var laminas_nube: Array = []
					if lista_remota != null and lista_remota is Array:
						for x in lista_remota:
							if x != null:
								laminas_nube.append(int(x))
					
					# 🏆 2. Logros de la nube
					var lista_logros = datos[0].get("logros_poseidos", [])
					var logros_nube: Array = []
					if lista_logros != null and lista_logros is Array:
						for y in lista_logros:
							if y != null:
								logros_nube.append(int(y))
					
					# Guardar conteo base de la nube para protección anti-encogimiento
					_conteo_laminas_nube = laminas_nube.size()
					_conteo_logros_nube = logros_nube.size()
					
					# 🔄 3. FUSIÓN INTELIGENTE (Unión matemática estricta: Nube ∪ RAM)
					var union_laminas = _unir_listas(DatosUsuario.laminas_poseidas, laminas_nube)
					var union_logros = _unir_listas(DatosUsuario.logros_poseidos, logros_nube)
					
					var hay_novedades = (union_laminas.size() > _conteo_laminas_nube or union_logros.size() > _conteo_logros_nube)
					
					DatosUsuario.laminas_poseidas = union_laminas
					DatosUsuario.logros_poseidos = union_logros
					
					# Persistir copia fusionada en archivo local
					guardar_album_y_logros_local()
					if FileAccess.file_exists("user://progreso_album_invitado.json"):
						DirAccess.remove_absolute("user://progreso_album_invitado.json")
					if FileAccess.file_exists("user://progreso_album_invitado.json.bak"):
						DirAccess.remove_absolute("user://progreso_album_invitado.json.bak")
					
					print("[SYNC] GET exitoso. Nube tenía (L:%d, Log:%d), fusionado es (L:%d, Log:%d). Novedades: %s, Sucio: %s" % [_conteo_laminas_nube, _conteo_logros_nube, union_laminas.size(), union_logros.size(), str(hay_novedades), str(album_sucio)])
					
					# Si la unión tiene elementos que la nube no tenía, o teníamos cambios pendientes locales
					if hay_novedades or album_sucio:
						_empujar_album_a_nube()
					
					album_y_logros_actualizados.emit()
				else:
					# Fila no existe aún para este usuario en progreso_album
					print("[SYNC] GET 200 pero tabla vacía para este usuario. Creando fila inicial...")
					crear_fila_album_inicial(DatosUsuario.usuario_uuid)
					album_y_logros_actualizados.emit()
			else:
				print("[SYNC] Error al parsear JSON del GET de álbum.")
				album_nube_sincronizado = false
				album_y_logros_actualizados.emit()
				_programar_reintento_get()
		else:
			print("[SYNC] ❌ Error/Sin respuesta al verificar álbum y logros en la nube (result: %d, code: %d)" % [result, response_code])
			album_nube_sincronizado = false
			album_y_logros_actualizados.emit()
			_programar_reintento_get()
	)
	
	# CONCATENACIÓN DINÁMICA
	var url_final = SUPABASE_URL + "progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	var err = http_get_album.request(url_final, _obtener_cabeceras(), HTTPClient.METHOD_GET)
	if err != OK:
		_album_get_en_curso = false
		album_nube_sincronizado = false
		album_y_logros_actualizados.emit()
		http_get_album.queue_free()
		_programar_reintento_get()

func crear_fila_album_inicial(uuid_usuario: String):
	var http_crear = HTTPRequest.new()
	add_child(http_crear)
	http_crear.accept_gzip = false
	
	http_crear.request_completed.connect(func(r, rc, h, b):
		http_crear.queue_free()
		if rc in [200, 201]:
			print("✅ [SYNC] [Supabase] Fila de álbum y logros creada exitosamente.")
			album_nube_sincronizado = true
			_conteo_laminas_nube = DatosUsuario.laminas_poseidas.size()
			_conteo_logros_nube = DatosUsuario.logros_poseidos.size()
			album_sucio = false
			guardar_album_y_logros_local()
		elif rc == 409:
			print("⚠️ [SYNC] 409 Conflicto al crear fila inicial (ya existía). Reintentando GET...")
			cargar_album_nube()
		else:
			print("❌ [SYNC] [Supabase] Falló la auto-creación del álbum y logros (code: %d): %s" % [rc, b.get_string_from_utf8()])
			album_nube_sincronizado = false
			_programar_reintento_get()
	)
	
	var url_final = SUPABASE_URL + "progreso_album"
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=representation")
	
	var lam_inicial = _unir_listas(DatosUsuario.laminas_poseidas, [])
	var log_inicial = _unir_listas(DatosUsuario.logros_poseidos, [])
	var datos = {
		"user_id": uuid_usuario,
		"laminas_poseidas": lam_inicial,
		"logros_poseidos": log_inicial
	}
	var err = http_crear.request(url_final, headers, HTTPClient.METHOD_POST, JSON.stringify(datos))
	if err != OK:
		http_crear.queue_free()
		_programar_reintento_get()

func _empujar_album_a_nube() -> void:
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		return
		
	album_sucio = true
	guardar_album_y_logros_local()
	
	if not album_nube_sincronizado:
		print("[SYNC] Push diferido: aún no se ha obtenido la primera lectura exitosa de la nube. Intentando GET...")
		cargar_album_nube()
		return
		
	if _album_push_en_curso:
		_album_push_pendiente = true
		print("[SYNC] Push ya en curso; cambio marcado como pendiente para enviar al finalizar.")
		return
		
	var lam := _unir_listas(DatosUsuario.laminas_poseidas, [])
	var log := _unir_listas(DatosUsuario.logros_poseidos, [])
	
	if lam.size() < _conteo_laminas_nube or log.size() < _conteo_logros_nube:
		push_error("[SYNC] Abortado: el PATCH encogería la nube (lam: %d < %d, log: %d < %d). Re-sincronizando..." % [lam.size(), _conteo_laminas_nube, log.size(), _conteo_logros_nube])
		album_nube_sincronizado = false
		cargar_album_nube()
		return
		
	_album_push_en_curso = true
	var http_patch = HTTPRequest.new()
	add_child(http_patch)
	http_patch.accept_gzip = false
	
	http_patch.request_completed.connect(func(result, response_code, headers, body):
		_album_push_en_curso = false
		http_patch.queue_free()
		
		if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 204]:
			print("[SYNC] 🎉 PATCH exitoso en Supabase. Láminas: %d, Logros: %d" % [lam.size(), log.size()])
			album_sucio = false
			_conteo_laminas_nube = lam.size()
			_conteo_logros_nube = log.size()
			_album_reintentos = 0
			guardar_album_y_logros_local()
			
			if _album_push_pendiente:
				_album_push_pendiente = false
				_empujar_album_a_nube()
		else:
			print("[SYNC] ❌ Error en PATCH a Supabase (result: %d, code: %d): %s" % [result, response_code, body.get_string_from_utf8()])
			_programar_reintento_push()
	)
	
	var url_final = _build_url("progreso_album?user_id=eq." + DatosUsuario.usuario_uuid)
	var hdrs = _obtener_cabeceras(true)
	hdrs.append("Prefer: return=minimal")
	var payload = {
		"laminas_poseidas": lam,
		"logros_poseidos": log
	}
	var err = http_patch.request(url_final, hdrs, HTTPClient.METHOD_PATCH, JSON.stringify(payload))
	if err != OK:
		_album_push_en_curso = false
		http_patch.queue_free()
		_programar_reintento_push()

func registrar_lamina_ganada(id_lamina: int):
	var id_entero = int(id_lamina)
	DatosUsuario.laminas_poseidas = _unir_listas(DatosUsuario.laminas_poseidas, [id_entero])
	guardar_album_y_logros_local()
	album_y_logros_actualizados.emit()
	print("⚽ [SYNC] Lámina registrada: %d | Total poseídas: %d" % [id_entero, DatosUsuario.laminas_poseidas.size()])
	_empujar_album_a_nube()

func registrar_laminas_ganadas(ids: Array) -> void:
	if ids.is_empty():
		return
	var nuevos: Array = []
	for x in ids:
		if x != null:
			nuevos.append(int(x))
	DatosUsuario.laminas_poseidas = _unir_listas(DatosUsuario.laminas_poseidas, nuevos)
	guardar_album_y_logros_local()
	album_y_logros_actualizados.emit()
	print("⚽ [SYNC] Láminas registradas en lote: %s | Total poseídas: %d" % [str(nuevos), DatosUsuario.laminas_poseidas.size()])
	_empujar_album_a_nube()

func guardar_laminas_poseidas_en_nube():
	_empujar_album_a_nube()

func registrar_logro_ganado(id_logro: int):
	var id_entero = int(id_logro)
	DatosUsuario.logros_poseidos = _unir_listas(DatosUsuario.logros_poseidos, [id_entero])
	guardar_album_y_logros_local()
	album_y_logros_actualizados.emit()
	print("🏆 [SYNC] Logro desbloqueado: %d | Total Logros: %s" % [id_entero, str(DatosUsuario.logros_poseidos)])
	_empujar_album_a_nube()

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
	var url_final = _build_url("progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db))
	var headers = _obtener_cabeceras(true)
	headers.append("Prefer: return=minimal")
	
	http_monedas.request(url_final, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
