extends Node

signal preguntas_descargadas(lista)
signal progreso_recibido(datos)
signal progreso_creado_exito()

const SUPABASE_URL = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/preguntas?select=*"
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

func descargar_preguntas():
	print("⏳ [API] Descargando banco de preguntas...")
	var cliente_http = HTTPRequest.new()
	add_child(cliente_http)
	cliente_http.accept_gzip = false
	cliente_http.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				preguntas_descargadas.emit(json.data)
		else:
			print("❌ Error de red al bajar preguntas: ", response_code)
		cliente_http.queue_free()
	)
	
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY]
	cliente_http.request(SUPABASE_URL, headers, HTTPClient.METHOD_GET)

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
				# ⚽ ¡OJO AQUÍ!: Si el progreso se leyó bien, mandamos a cargar su álbum de inmediato
				cargar_album_nube()
		else:
			progreso_recibido.emit([]) 
		http_get.queue_free()
	)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY]
	http_get.request(url, headers, HTTPClient.METHOD_GET)


func actualizar_progreso_en_nube(casilla: int, pendiente: bool):
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	var http_update = HTTPRequest.new()
	add_child(http_update)
	http_update.accept_gzip = false # ✅ Protegido para la Web
	http_update.request_completed.connect(func(r, rc, h, b): http_update.queue_free())
	
	var datos_a_guardar = {
		"casilla_actual": casilla, 
		"pregunta_pendiente": pendiente,
		"dificultad": DatosUsuario.dificultad_actual
		}
	var url_update = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY, "Content-Type: application/json", "Prefer: return=minimal"]
	
	http_update.request(url_update, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
	
func registrar_en_historial(categoria: String, es_correcta: bool, tiempo: float):
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	var http_historial = HTTPRequest.new()
	add_child(http_historial)
	http_historial.accept_gzip = false # Enfoque web seguro
	
	# Al terminar la petición, simplemente liberamos el nodo de la memoria
	http_historial.request_completed.connect(func(result, response_code, headers, body):
		print("📡 --- DIAGNÓSTICO HISTORIAL ---")
		print("Código de Respuesta HTTP: ", response_code)
		if response_code != 201 and response_code != 200:
			print("❌ Error de Supabase: ", body.get_string_from_utf8())
		else:
			print("✅ ¡Registro exitoso en el historial de Supabase!")
		print("---------------------------------")
		http_historial.queue_free()
	)
	
	# El cuerpo del JSON con los datos que definimos para la tabla
	var nueva_jugada = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"categoria": categoria,
		"es_correcta": es_correcta,
		"tiempo_tardado": tiempo
	}
	
	var url_historial = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/historial_respuestas"
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY, 
		"Authorization: Bearer " + SUPABASE_ANON_KEY, 
		"Content-Type: application/json", 
		"Prefer: return=minimal"
	]
	
	http_historial.request(url_historial, headers, HTTPClient.METHOD_POST, JSON.stringify(nueva_jugada))

# =====================================================================
# ⚽ SISTEMA DE ÁLBUM DEL MUNDIAL (CORREGIDO)
# =====================================================================

# 1. 📂 CARGAR ÁLBUM: Descarga la lista de láminas del niño desde la nube
# 1. 📂 CARGAR ÁLBUM: Descarga la lista de láminas del niño desde la nube
func cargar_album_nube():
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		print("ℹ️ [Invitado] Cargando álbum local desde la RAM. Láminas actuales: ", DatosUsuario.laminas_poseidas)
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
					# Caso A: El usuario ya tiene su fila del álbum creada. Sincronizamos sus láminas.
					var lista_remota = datos[0].get("laminas_poseidas", [])
					
					# 🧹 LIMPIEZA DE TIPOS: Forzamos a que los floats de la nube (1.0) pasen a ser enteros puros (1)
					var laminas_enteras: Array = []
					for x in lista_remota:
						if x != null:
							laminas_enteras.append(int(x))
							
					DatosUsuario.laminas_poseidas = laminas_enteras
					print("⚽ [Supabase] Álbum cargado con éxito desde la nube. Láminas (Enteros): ", DatosUsuario.laminas_poseidas)
				else:
					# Caso B: El usuario existe en el juego pero NO tiene fila en 'progreso_album'. ¡Se la creamos!
					print("⚠️ [Supabase] El usuario no tiene fila en progreso_album. Creando una ahora...")
					crear_fila_album_inicial(DatosUsuario.usuario_uuid)
		else:
			print("❌ Error al verificar álbum en la nube: ", response_code)
		http_get_album.queue_free()
	)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY]
	http_get_album.request(url, headers, HTTPClient.METHOD_GET)

# 🆕 Función auxiliar para inyectar la fila faltante en caliente
func crear_fila_album_inicial(uuid_usuario: String):
	var http_crear = HTTPRequest.new()
	add_child(http_crear)
	http_crear.accept_gzip = false
	
	http_crear.request_completed.connect(func(r, rc, h, b):
		if rc in [200, 201]:
			print("✅ [Supabase] Fila de álbum creada exitosamente para el usuario existente.")
		else:
			print("❌ [Supabase] Falló la auto-creación del álbum: ", rc, " -> ", b.get_string_from_utf8())
		http_crear.queue_free()
	)
	
	var url_album = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso_album"
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY, 
		"Authorization: Bearer " + SUPABASE_ANON_KEY, 
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	var datos = {
		"user_id": uuid_usuario,
		"laminas_poseidas": DatosUsuario.laminas_poseidas # Mandará el array como lo tenga en RAM
	}
	http_crear.request(url_album, headers, HTTPClient.METHOD_POST, JSON.stringify(datos))

func registrar_lamina_ganada(id_lamina: int):
	print("⚽ [Álbum] Intentando registrar lámina ganada ID: ", id_lamina)
	
	# Forzamos a que se guarde como entero puro en la RAM
	var id_entero = int(id_lamina)
	if not DatosUsuario.laminas_poseidas.has(id_entero):
		DatosUsuario.laminas_poseidas.append(id_entero)
		
	if not DatosUsuario.esta_conectado_a_la_nube or DatosUsuario.usuario_uuid in ["", "0"]:
		print("🎉 [Invitado] Lámina ganada localmente. No se sube a la nube.")
		return
		
	var http_update_album = HTTPRequest.new()
	add_child(http_update_album)
	http_update_album.accept_gzip = false
	
	http_update_album.request_completed.connect(func(result, response_code, headers, body):
		print("📡 --- DIAGNÓSTICO ACTUALIZAR ÁLBUM ---")
		print("Código de Respuesta HTTP Álbum: ", response_code)
		if response_code in [200, 204]:
			print("🎉 ¡Nube sincronizada! El niño guardó la lámina ID: ", id_entero)
		else:
			print("❌ Error de Supabase al actualizar lámina: ", body.get_string_from_utf8())
		print("---------------------------------------")
		http_update_album.queue_free()
	)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso_album?user_id=eq." + DatosUsuario.usuario_uuid
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY, 
		"Authorization: Bearer " + SUPABASE_ANON_KEY, 
		"Content-Type: application/json",
		"Prefer: return=minimal"
	]
	
	# 🧹 LIMPIEZA ABSOLUTA: Creamos un array nuevo asegurando que TODO sea int() estricto
	var laminas_limpias: Array = []
	for x in DatosUsuario.laminas_poseidas:
		laminas_limpias.append(int(x))
	
	var datos_actualizados = { "laminas_poseidas": laminas_limpias }
	
	print("📡 Enviando PATCH al álbum con datos limpios: ", JSON.stringify(datos_actualizados))
	http_update_album.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_actualizados))
