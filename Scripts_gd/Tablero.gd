extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
@onready var boton_dado = $BotonDado 
@onready var cliente_http = $ClienteHTTP

var total_casillas = 23
var casilla_actual = 0
var casilla_anterior = 0 # 👈 NUEVA: Guarda dónde estaba antes de lanzar

var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

const SUPABASE_URL = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/preguntas?select=*"
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

func _ready():
	await get_tree().process_frame
	servidor_listo = false
	boton_dado.disabled = true # 🔒 Bloqueado al inicio
	
	# Ocultar la interfaz de preguntas al arrancar el mapa
	$Interfaz.visible = false
	
	cliente_http.request_completed.connect(_on_peticion_http_completada)
	descargar_preguntas_nativo()

func descargar_preguntas_nativo():
	print("⏳ Descargando banco de preguntas de Supabase...")
	cliente_http.accept_gzip = false
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	cliente_http.request(SUPABASE_URL, headers, HTTPClient.METHOD_GET)

func _on_peticion_http_completada(result, response_code, headers, body):
	var respuesta_cruda = body.get_string_from_utf8()
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(respuesta_cruda) == OK:
			lista_preguntas = json.data
			print("🎉 ¡Preguntas cargadas! Servidor listo.")
			lista_preguntas.shuffle()
			servidor_listo = true
			
			# 🔍 CONSULTAMOS EL PROGRESO REAL DE ESTE USUARIO EN LA NUBE
			pedir_progreso_usuario()
	else:
		print("❌ Error de red al bajar preguntas: ", response_code)

func pedir_progreso_usuario():
	var http_get = HTTPRequest.new()
	add_child(http_get)
	http_get.accept_gzip = false
	http_get.request_completed.connect(_on_progreso_recibido)
	
	# Usamos str() para convertir el ID numérico a texto para la URL
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY
	]
	http_get.request(url, headers, HTTPClient.METHOD_GET)

func _on_progreso_recibido(_result, response_code, _headers, body):
	var respuesta = body.get_string_from_utf8()
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(respuesta) == OK:
			var datos = json.data
			if datos is Array and datos.size() > 0:
				print("✅ ¡Encontré progreso en la base de datos!")
				
				# --- AQUÍ ESTABA EL BLOQUEO ---
				# Si no hay pregunta pendiente, desbloqueamos el botón
				var fila = datos[0]
				var tiene_pendiente = fila.get("pregunta_pendiente", false)
				
				if tiene_pendiente:
					print("🚨 Pregunta pendiente detectada. Botón bloqueado.")
					# Aquí tu lógica para mostrar la interfaz de pregunta
					mostrar_pregunta_en_pantalla()
				else:
					print("✅ Progreso limpio. ¡Desbloqueando botón!")
					boton_dado.disabled = false # <--- ¡ESTA ES LA LÍNEA QUE TE FALTA!
					
			else:
				print("🆕 No encontré progreso, ¡es un usuario nuevo! Creando fila...")
				crear_fila_inicial_progreso()

func crear_fila_inicial_progreso():
	var http_insert = HTTPRequest.new()
	add_child(http_insert)
	http_insert.accept_gzip = false
	
	# ¡AQUÍ ESTÁ LA CLAVE! Conectamos el resultado de la petición
	http_insert.request_completed.connect(_on_creacion_progreso_completada)
	
	var url = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso"
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	
	var nuevo_registro = {
		"usuario_id": DatosUsuario.usuario_id_db,
		"monedas": 0,
		"casilla_actual": 0,
		"tablero_actual": "Tablero_1",
		"pregunta_pendiente": false
	}
	
	http_insert.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(nuevo_registro))

func _on_boton_dado_pressed():
	if not servidor_listo or lista_preguntas.size() == 0: return
		
	boton_dado.disabled = true
	casilla_anterior = casilla_actual
	
	var resultado = randi_range(1, 6)
	print("🎲 Salió un: ", resultado)
	
	if casilla_actual + resultado > total_casillas:
		casilla_actual = total_casillas
	else:
		casilla_actual += resultado
		
	# 🌐 MANDAMOS EL CANDADO A SUPABASE INMEDIATAMENTE
	actualizar_progreso_en_nube(casilla_actual, true)
	
	# La ficha se mueve de forma normal
	var casilla_destino = [0.0537, 0.107, 0.1521, 0.1972, 0.2423, 0.2874, 0.3407, 0.3776, 0.4145, 0.4473,
	0.4924, 0.5293, 0.5744, 0.6113, 0.6646, 0.7097, 0.7548, 0.7999, 0.8368, 0.8737, 0.9106, 0.9557, 1]
	var indice_casilla = clampi(casilla_actual - 1, 0, casilla_destino.size() - 1)
	
	var tween = create_tween()
	tween.tween_property(path_follow, "progress_ratio", casilla_destino[indice_casilla], 1.0).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	mostrar_pregunta_en_pantalla()

func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: return

	if pregunta_actual_indice < lista_preguntas.size():
		var datos_pregunta = lista_preguntas[pregunta_actual_indice]
		
		# Hacemos visible la interfaz y cargamos la operación
		$Interfaz.visible = true
		$Interfaz.actualizar_datos_pantalla(datos_pregunta)
		pregunta_actual_indice += 1
	else:
		lista_preguntas.shuffle()
		pregunta_actual_indice = 0
		mostrar_pregunta_en_pantalla()

# ==========================================
# ⚙️ RESPUESTA DEL NIÑO DESDE LA INTERFAZ
# ==========================================
func _on_interfaz_respuesta_completada(es_correcta: Variant) -> void:
	if es_correcta:
		print("🎯 ¡Respuesta Correcta! Salvando estado libre en Supabase.")
		
		# Guardamos que ya no debe preguntas
		actualizar_progreso_en_nube(casilla_actual, false)
		
		$Interfaz.visible = false
		boton_dado.disabled = false
	else:
		print("❌ ¡Incorrecta! Regresando a casilla anterior: ", casilla_anterior)
		casilla_actual = casilla_anterior
		
		# Guardamos la posición penalizada y liberamos el candado
		actualizar_progreso_en_nube(casilla_actual, false)
		
		# Animación de regreso de la ficha
		var casilla_destino = [0.0537, 0.107, 0.1521, 0.1972, 0.2423, 0.2874, 0.3407, 0.3776, 0.4145, 0.4473,
		0.4924, 0.5293, 0.5744, 0.6113, 0.6646, 0.7097, 0.7548, 0.7999, 0.8368, 0.8737, 0.9106, 0.9557, 1]
		var tween_regreso = create_tween()
		if casilla_actual == 0:
			tween_regreso.tween_property(path_follow, "progress_ratio", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
		else:
			var indice = clampi(casilla_actual - 1, 0, casilla_destino.size() - 1)
			tween_regreso.tween_property(path_follow, "progress_ratio", casilla_destino[indice], 0.8).set_trans(Tween.TRANS_SINE)
			
		await tween_regreso.finished
		$Interfaz.visible = false
		boton_dado.disabled = false

func enviar_puntuacion(nombre_jugador: String, puntos: int):
	var datos = {
		"user_id": DatosUsuario.usuario_id_db,
		"nombre": nombre_jugador, 
		"casilla": puntos
	}
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	Supabase.database.query(consulta)
	
func actualizar_progreso_en_nube(casilla: int, pendiente: bool):
	if not DatosUsuario.esta_conectado_a_la_nube: return
	
	# Usamos un nuevo nodo HTTP temporal para no interrumpir las descargas de preguntas
	var http_update = HTTPRequest.new()
	add_child(http_update)
	http_update.accept_gzip = false
	
	# Pasamos los campos de tu tabla exacta
	var datos_a_guardar = {
		"casilla_actual": casilla,
		"pregunta_pendiente": pendiente
	}
	
	var cuerpo_json = JSON.stringify(datos_a_guardar)
	var url_update = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
	
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json",
		"Prefer: return=minimal" # Evita sobrecargar la respuesta del servidor
	]
	
	http_update.request(url_update, headers, HTTPClient.METHOD_PATCH, cuerpo_json)
	print("📡 [Sincronización Nube] Actualizando casilla a ", casilla, " | Pendiente: ", pendiente)
	
func _on_creacion_progreso_completada(_result, response_code, _headers, _body):
	print("📡 Respuesta al crear fila inicial: ", response_code)
	# Si es 201 (Created) o 200, significa que todo salió bien
	if response_code == 201 or response_code == 200:
		print("✅ Fila creada en Supabase. ¡Desbloqueando botón!")
		boton_dado.disabled = false
	else:
		# Si falla, imprimimos el error pero desbloqueamos para que el niño pueda jugar
		print("❌ Error al crear fila en Supabase. Código: ", response_code)
		boton_dado.disabled = false
