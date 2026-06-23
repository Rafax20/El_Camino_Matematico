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
	http_get.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				progreso_recibido.emit(json.data)
		else:
			progreso_recibido.emit([]) # Retorna vacío si falla
		http_get.queue_free()
	)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY]
	http_get.request(url, headers, HTTPClient.METHOD_GET)

func crear_fila_inicial_progreso():
	var http_insert = HTTPRequest.new()
	add_child(http_insert)
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
		"pregunta_pendiente": false
	}
	http_insert.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(nuevo_registro))

func actualizar_progreso_en_nube(casilla: int, pendiente: bool):
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	var http_update = HTTPRequest.new()
	add_child(http_update)
	http_update.request_completed.connect(func(r, rc, h, b): http_update.queue_free())
	
	var datos_a_guardar = {"casilla_actual": casilla, "pregunta_pendiente": pendiente}
	var url_update = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = ["apikey: " + SUPABASE_ANON_KEY, "Authorization: Bearer " + SUPABASE_ANON_KEY, "Content-Type: application/json", "Prefer: return=minimal"]
	
	http_update.request(url_update, headers, HTTPClient.METHOD_PATCH, JSON.stringify(datos_a_guardar))
