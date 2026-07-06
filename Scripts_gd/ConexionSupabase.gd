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
	http_get.accept_gzip = false # ✅ Protegido para la Web
	http_get.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				progreso_recibido.emit(json.data)
		else:
			progreso_recibido.emit([]) 
		http_get.queue_free()
	)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY]
	http_get.request(url, headers, HTTPClient.METHOD_GET)

func crear_fila_inicial_progreso():
	var http_insert = HTTPRequest.new()
	add_child(http_insert)
	http_insert.accept_gzip = false # ✅ Protegido para la Web
	http_insert.request_completed.connect(func(result, response_code, headers, body):
		if response_code in [200, 201]:
			progreso_creado_exito.emit()
		http_insert.queue_free()
	)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso"
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY, "Content-Type: application/json"]
	var nuevo_registro = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"monedas": 0,
		"casilla_actual": 0,
		"tablero_actual": "Tablero_1",
		"pregunta_pendiente": false,
		"dificultad": 0
	}
	http_insert.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(nuevo_registro))

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

# res://Scripts_gd/ConexionSupabase.gd

# 1. 📂 CARGAR ÁLBUM: Descarga la lista de láminas del niño desde la nube
# res://Scripts_gd/ConexionSupabase.gd

# 1. 📂 CARGAR ÁLBUM: Descarga la lista de láminas del niño desde la nube
func cargar_album_nube():
	var user_id = DatosUsuario.usuario_id_db
	
	# Hacemos la consulta a tu nueva tabla progreso_album
	var query = SupabaseQuery.new().from("progreso_album").select(["laminas_poseidas"]).eq("user_id", user_id)
	var task: DatabaseTask = await Supabase.database.query(query)
	
	# ✅ REPARACIÓN: Accedemos a task.data que es donde está el Array de filas devueltas
	if task.data and task.data.size() > 0:
		# Si ya tiene registro, guardamos sus láminas en la RAM
		DatosUsuario.laminas_poseidas = task.data[0].get("laminas_poseidas", [])
		print("⚽ Álbum cargado con éxito. Láminas del niño: ", DatosUsuario.laminas_poseidas)
	else:
		# Si es un estudiante nuevo y no tiene fila, se la creamos vacía de una vez
		DatosUsuario.laminas_poseidas = []
		var datos_nuevos = {
			"user_id": user_id,
			"laminas_poseidas": [] # Array vacío en Supabase
		}
		var insert_query = SupabaseQuery.new().from("progreso_album").insert([datos_nuevos])
		await Supabase.database.query(insert_query)
		print("⚽ Registro de álbum creado para el nuevo usuario.")

# 2. 🎁 GANAR LÁMINA: Agrega una lámina al array sin duplicarla y actualiza la nube
func registrar_lamina_ganada(id_lamina: int):
	# Evitamos duplicados: si el niño ya la tiene, no hace falta añadirla otra vez
	if not DatosUsuario.laminas_poseidas.has(id_lamina):
		DatosUsuario.laminas_poseidas.append(id_lamina)
		
		var user_id = DatosUsuario.usuario_id_db
		var datos_actualizados = {
			"laminas_poseidas": DatosUsuario.laminas_poseidas
		}
		
		# Hacemos el UPDATE directo en la base de datos
		var query = SupabaseQuery.new().from("progreso_album").update(datos_actualizados).eq("user_id", user_id)
		await Supabase.database.query(query) # Aquí no necesitas guardar el resultado en una variable si no vas a chequear errores
		print("🎉 ¡Nube sincronizada! El niño ganó la lámina ID: ", id_lamina)
	else:
		print("🃏 Lámina repetida (ID: ", id_lamina, "), no se añade al álbum.")
