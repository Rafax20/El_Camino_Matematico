extends Control

# --- NODOS DE INTERFAZ ---
@onready var contenedor = $ContenedorPopup
@onready var input_usuario = $ContenedorPopup/Panel/Ventana/Fondo_Usuario/InputUsuario
@onready var input_clave = $ContenedorPopup/Panel/Ventana/Fondo_Clave/InputClave
@onready var texto_titulo = $ContenedorPopup/Panel/Ventana/Titulo

# --- REFERENCIA AL SCRIPT DE SUPABASE (CONEXIÓN NATIVA) ---
@onready var http_request = $HTTPRequest 

const SUPABASE_URL_USUARIOS = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/usuarios"
const SUPABASE_URL_PROGRESO = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/progreso"
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Z2l3bXNwZnVlYnF2YnN0dHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODg2MjMsImV4cCI6MjA5NDE2NDYyM30.tkM_AYmXhLEqfCLgvpTczRMigV-hL44bpHCs5Z-sHuc"

var operacion_actual: String = ""

func _ready():
	self.modulate.a = 0
	contenedor.scale = Vector2(0.5, 0.5)
	contenedor.pivot_offset = contenedor.size / 2 
	self.visible = false
	
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	http_request.accept_gzip = false

func aparecer():
	self.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(contenedor, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_boton_cerrar_pressed() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(contenedor, "scale", Vector2(0.7, 0.7), 0.2)
	await tween.finished
	self.visible = false

func _on_boton_entrar_pressed() -> void:
	var usuario = input_usuario.text.to_lower().strip_edges()
	var clave = input_clave.text.strip_edges()
	
	if usuario == "" or clave == "":
		animar_error_infantil("¡Faltan datos por escribir!")
		return
		
	texto_titulo.text = "Conectando... "
	texto_titulo.modulate = Color(1.0, 1.0, 1.0, 1.0)
	operacion_actual = "LOGIN"
	print("🔍 Intentando iniciar sesión con Usuario: '" + usuario + "'")
	
	var url = SUPABASE_URL_USUARIOS + "?usuario=eq." + usuario + "&clave=eq." + clave
	enviar_peticion_supabase(url, HTTPClient.METHOD_GET, "")

func _on_boton_registrar_pressed() -> void:
	var usuario = input_usuario.text.to_lower().strip_edges()
	var clave = input_clave.text.strip_edges()
	
	if usuario == "" or clave == "":
		animar_error_infantil("¡Escribe un nombre y clave!")
		return
		
	operacion_actual = "REGISTRO"
	print("📝 Intentando registrar al Usuario: '" + usuario + "'")
	
	# 🛠️ CORRECCIÓN AQUÍ: Añadimos el rol limpio sin agregados de Postgres
	var datos = { 
		"usuario": usuario, 
		"clave": clave,
		"rol": "estudiante" # 👈 Mandamos la palabra limpia
	}
	enviar_peticion_supabase(SUPABASE_URL_USUARIOS, HTTPClient.METHOD_POST, JSON.stringify(datos))

func enviar_peticion_supabase(url: String, metodo: int, cuerpo: String):
	var headers = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	var error = http_request.request(url, headers, metodo, cuerpo)
	if error != OK:
		print("❌ Error al levantar la conexión HTTPRequest")
		animar_error_infantil("¡Error de red interno!")

# ==========================================
# ⚙️ RESPUESTAS DEL SERVIDOR Y VALIDACIÓN
# ==========================================
func _on_request_completed(result, response_code, headers, body):
	var respuesta = body.get_string_from_utf8()
	print("📡 Servidor respondió con código: " + str(response_code))
	
	var json = JSON.new()
	if json.parse(respuesta) != OK:
		print("❌ Error al parsear JSON")
		return
		
	if response_code != 200 and response_code != 201:
		print("❌ Error de comunicación con la API. Respuesta: " + respuesta)
		animar_error_infantil("¡Error de conexión!")
		return

	var datos_recibidos = json.data

	if operacion_actual == "LOGIN":
		if datos_recibidos is Array and datos_recibidos.size() > 0:
			var user_data = datos_recibidos[0]
			
			print("🚨 [DIAGNÓSTICO LOGIN] Todo lo que llegó del usuario: ", user_data) # 👈 AÑADE ESTO
			
			DatosUsuario.esta_conectado_a_la_nube = true
			DatosUsuario.usuario_id_db = int(user_data.get("id", 0))
			DatosUsuario.usuario_uuid = str(user_data.get("user_id", ""))
			
			
			
			DatosUsuario.esta_conectado_a_la_nube = true
			DatosUsuario.usuario_id_db = int(user_data.get("id", 0))
			DatosUsuario.usuario_uuid = str(user_data.get("user_id", ""))
			DatosUsuario.nombre_usuario = str(user_data.get("usuario", ""))
			DatosUsuario.dificultad_actual = int(user_data.get("dificultad", 0))
			DatosUsuario.rol = str(user_data.get("rol", "estudiante"))
			
			print("👤 Usuario validado. Buscando su progreso en la base de datos...")
			print("👤 Usuario validado con rol: " + DatosUsuario.rol)
			
			if DatosUsuario.rol == "maestro":
				print("👨‍🏫 Bienvenido Maestro. Abriendo Panel de Analítica...")
				_on_boton_cerrar_pressed()
				get_tree().change_scene_to_file("res://Escenas/PanelMaestro.tscn") # 👈 Tu futura escena de maestro
			else:
				print("🎒 Bienvenido Estudiante. Buscando progreso...")
				operacion_actual = "PROGRESO"
				var url_progreso = SUPABASE_URL_PROGRESO + "?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
				enviar_peticion_supabase(url_progreso, HTTPClient.METHOD_GET, "")
		else:
			print("❌ Login fallido: Credenciales incorrectas.")
			animar_error_infantil("¡Usuario o Clave incorrectos!")

	elif operacion_actual == "PROGRESO":
		if datos_recibidos is Array and datos_recibidos.size() > 0:
			var progreso_data = datos_recibidos[0]
			
			DatosUsuario.pregunta_pendiente_db = bool(progreso_data.get("pregunta_pendiente", false))
			DatosUsuario.casilla_actual_db = int(progreso_data.get("casilla_actual", 0))
			DatosUsuario.dificultad_actual = int(progreso_data.get("dificultad", 0))
			
			print("🎉 ¡Sesión y progreso guardados con éxito en Globales!")
			
			# ⚽ ¡AQUÍ ESTÁ LA CLAVE!: Forzamos a cargar o auto-crear el álbum desde la red
			ConexionSupabase.cargar_album_nube()
			
			_abrir_interfaz_bienvenida()
		else:
			print("🆕 El usuario no tiene fila de progreso en la nube. Inicializando tabla...")
			var es_migracion = (DatosUsuario.casilla_actual_db > 0 or DatosUsuario.laminas_poseidas.size() > 0)
			ConexionSupabase.inicializar_progreso_nuevo_usuario(es_migracion)
			_abrir_interfaz_bienvenida()

	elif operacion_actual == "REGISTRO":
		print("🎉 ¡Registro exitoso en la nube!")
		_on_boton_entrar_pressed()

# ==========================================
# 💥 ANIMACIÓN INFANTIL DE ERROR_
# ==========================================
func animar_error_infantil(mensaje: String):
	texto_titulo.text = mensaje
	texto_titulo.modulate = Color(1, 0.3, 0.3)
	
	var posicion_original = contenedor.position
	var tween_shake = create_tween()
	
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x - 15, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x + 15, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x - 10, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", Vector2(posicion_original.x + 10, posicion_original.y), 0.05)
	tween_shake.tween_property(contenedor, "position", posicion_original, 0.05)
	
	var tween_scale = create_tween()
	contenedor.pivot_offset = contenedor.size / 2
	tween_scale.tween_property(contenedor, "scale", Vector2(0.9, 0.9), 0.1)
	tween_scale.tween_property(contenedor, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK)
	tween_scale.tween_property(contenedor, "scale", Vector2(1.0, 1.0), 0.1)

func _abrir_interfaz_bienvenida():
	texto_titulo.text = "Bienvenido de Nuevo estudiante " + str(DatosUsuario.nombre_usuario)
	texto_titulo.modulate = Color(0.375, 0.677, 0.218, 1.0)
	await get_tree().create_timer(2.0).timeout
	_on_boton_cerrar_pressed()
