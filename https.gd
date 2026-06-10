extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
@onready var boton_dado = $BotonDado 
@onready var cliente_http = $ClienteHTTP # 👈 Tu nuevo nodo nativo de red

var total_casillas = 23
var casilla_actual = 0

# --- VARIABLES DE CONTROL Y RED ---
var esta_conectado_a_la_nube : bool = false
var usuario_uuid : String = ""
var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

# --- CONFIGURACIÓN DE TU ENDPOINT DE SUPABASE ---
const SUPABASE_URL = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/preguntas?select=*"

# 🔑 PEGA AQUÍ TU API KEY ANÓNIMA (La larga que empieza por eyJ...)
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

func _ready():
	await get_tree().process_frame
	
	# Desactivamos el dado al iniciar hasta que bajen los datos
	servidor_listo = false
	boton_dado.disabled = true 
	
	# Conectamos la señal del nodo HTTP nativo a su función de procesamiento
	cliente_http.request_completed.connect(_on_peticion_http_completada)
	
	# Arrancamos la descarga limpia
	descargar_preguntas_nativo()

func descargar_preguntas_nativo():
	print("⏳ Conectando directamente a Supabase mediante HTTP REST nativo...")
	
	# 🛠️ LA SOLUCIÓN REQUERIDA: Le prohibimos al nodo HTTPRequest aceptar Gzip por software.
	# Esto evita por completo que se ejecute el "stream_peer_gzip.cpp" en la Web.
	cliente_http.accept_gzip = false
	
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	
	var error = cliente_http.request(SUPABASE_URL, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("❌ Error inmediato de red al intentar lanzar la petición HTTP: ", error)

# Se ejecuta automáticamente cuando Supabase responde a través de la red web
func _on_peticion_http_completada(result, response_code, headers, body):
	# Imprimimos lo que llegó del servidor en la consola web
	var respuesta_cruda = body.get_string_from_utf8()
	print("📡 RESPUESTA DEL SERVIDOR: ", respuesta_cruda)

	if response_code == 200:
		var json = JSON.new()
		var error_parseo = json.parse(respuesta_cruda)
		
		if error_parseo == OK:
			lista_preguntas = json.data
			print("🎉 ¡ÉXITO! Preguntas obtenidas: ", lista_preguntas.size())
			
			if lista_preguntas.size() > 0:
				lista_preguntas.shuffle()
				servidor_listo = true
				boton_dado.disabled = false
				mostrar_pregunta_en_pantalla()
		else:
			print("❌ Error de parseo: El formato JSON recibido está corrupto.")
	else:
		print("❌ Solicitud rechazada. Código HTTP: ", response_code)

func _on_boton_dado_pressed():
	if not servidor_listo or lista_preguntas.size() == 0:
		print("🚫 Espera un momento... Las preguntas aún se están cargando.")
		return
		
	var resultado = randi_range(1, 6)
	print("Salió un: ", resultado)
	
	avanzar_casillas(resultado)
	
	if esta_conectado_a_la_nube:
		enviar_puntuacion("Jugador1", casilla_actual)
	else:
		print("ℹ️ Modo Local: Posición avanzada a ", casilla_actual)

func avanzar_casillas(cantidad):
	if casilla_actual + cantidad > total_casillas:
		print("¡Llegaste a la meta!")
		casilla_actual = total_casillas
	else:
		casilla_actual += cantidad
	
	var casilla_destino = [0.0537, 0.107, 0.1521, 0.1972, 0.2423, 0.2874, 0.3407, 0.3776, 0.4145, 0.4473,
	0.4924, 0.5293, 0.5744, 0.6113, 0.6646, 0.7097, 0.7548, 0.7999, 0.8368, 0.8737, 0.9106, 0.9557, 1]
	
	var indice_casilla = clampi(casilla_actual - 1, 0, casilla_destino.size() - 1)
	
	var tween = create_tween()
	tween.tween_property(path_follow, "progress_ratio", casilla_destino[indice_casilla], 1.0).set_trans(Tween.TRANS_SINE)

func enviar_puntuacion(nombre_usuario: String, puntos: int):
	var datos = {
		"user_id": usuario_uuid,
		"nombre": nombre_usuario, 
		"casilla": puntos
	}
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	Supabase.database.query(consulta)

func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: 
		print("⚠️ Base de datos vacía")
		return

	if pregunta_actual_indice < lista_preguntas.size():
		var datos_pregunta = lista_preguntas[pregunta_actual_indice]
		$Interfaz.actualizar_datos_pantalla(datos_pregunta)
		pregunta_actual_indice += 1
	else:
		print("¡Se acabaron las preguntas! Mezclando de nuevo...")
		lista_preguntas.shuffle()
		pregunta_actual_indice = 0
		mostrar_pregunta_en_pantalla()

func _on_interfaz_respuesta_completada(es_correcta: Variant) -> void:
	if es_correcta:
		print("¡El niño acertó! Lanzando dado...")
		_on_boton_dado_pressed() 
	else:
		print("Respuesta incorrecta.")
