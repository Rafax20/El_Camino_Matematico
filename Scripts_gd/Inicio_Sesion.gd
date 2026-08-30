extends Control

# --- NODOS DE INTERFAZ ---
@onready var contenedor = $ContenedorPopup
@onready var input_usuario = $ContenedorPopup/Panel/Ventana/Fondo_Usuario/InputUsuario
@onready var input_clave = $ContenedorPopup/Panel/Ventana/Fondo_Clave/InputClave
@onready var texto_titulo = $ContenedorPopup/Panel/Ventana/Titulo

# --- REFERENCIA AL SCRIPT DE SUPABASE (CONEXIÓN NATIVA) ---
@onready var http_request = $HTTPRequest 

var operacion_actual: String = ""

func _ready():
	self.modulate.a = 0
	contenedor.scale = Vector2(0.5, 0.5)
	contenedor.pivot_offset = contenedor.size / 2 
	self.visible = false
	
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	http_request.accept_gzip = false
	
	# Espera máxima de 2 segundos si estamos en Web; de lo contrario, continúa con el respaldo
	if not FileAccess.file_exists("res://.env"):
		var tiempo_espera = 0.0
		while GlobalConfig.SUPABASE_URL == "" and tiempo_espera < 2.0:
			await get_tree().create_timer(0.1).timeout
			tiempo_espera += 0.1
		print("✨ InterfazLogin: Listo para operar con URL: ", GlobalConfig.SUPABASE_URL)

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

# 🛠️ FUNCIÓN AUXILIAR PARA ASEGURAR UNA RUTA LIMPIA
func _obtener_url_tabla(tabla: String) -> String:
	var url_base = GlobalConfig.SUPABASE_URL
	
	# Fallback de seguridad si GlobalConfig aún no tiene una URL absoluta válida (empieza con http/https)
	if not url_base.begins_with("http://") and not url_base.begins_with("https://"):
		print("⚠️ URL inválida en GlobalConfig ('", url_base, "'). Aplicando fallback de respaldo...")
		url_base = "https://zwgiwmspfuebqvbsttto.supabase.co/rest/v1/"
	
	if not url_base.ends_with("/"):
		url_base += "/"
		
	return url_base + tabla

func _on_boton_entrar_pressed() -> void:
	if operacion_actual == "LOGIN": return # Evita spam de clicks si ya está conectando
	
	var usuario = input_usuario.text.to_lower().strip_edges()
	var clave = input_clave.text.strip_edges()
	
	if usuario == "" or clave == "":
		animar_error_infantil("¡Faltan datos por escribir!")
		return
		
	texto_titulo.text = "Conectando... "
	texto_titulo.modulate = Color(1.0, 1.0, 1.0, 1.0)
	operacion_actual = "LOGIN"
	print("🔍 Intentando iniciar sesión con Usuario: '" + usuario + "'")
	
	var url_base_usuarios = _obtener_url_tabla("usuarios")
	print("URL-BASE-USUARIOS: " + url_base_usuarios)
	var url_peticion = url_base_usuarios + "?usuario=eq." + usuario + "&clave=eq." + clave
	
	enviar_peticion_supabase(url_peticion, HTTPClient.METHOD_GET, "")

func _on_boton_registrar_pressed() -> void:
	if operacion_actual == "REGISTRO": return # Evita duplicar registros por clicks rápidos
	
	var usuario = input_usuario.text.to_lower().strip_edges()
	var clave = input_clave.text.strip_edges()
	
	if usuario == "" or clave == "":
		animar_error_infantil("¡Escribe un nombre y clave!")
		return
		
	operacion_actual = "REGISTRO"
	print("📝 Intentando registrar al Usuario: '" + usuario + "'")
	
	var datos = { 
		"usuario": usuario, 
		"clave": clave,
		"rol": "estudiante"
	}
	
	var url_base_usuarios = _obtener_url_tabla("usuarios")
	print("URL-BASE-USUARIOS: " + url_base_usuarios)
	enviar_peticion_supabase(url_base_usuarios, HTTPClient.METHOD_POST, JSON.stringify(datos))

func enviar_peticion_supabase(url: String, metodo: int, cuerpo: String):
	print("📡 [HTTP ENVIANDO] URL Final: ", url) 
	
	# Extraemos la llave oficial inyectada desde Render
	var anon_key_global = GlobalConfig.SUPABASE_ANON_KEY
	
	var headers = [
		"apikey: " + anon_key_global,
		"Authorization: Bearer " + anon_key_global,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	
	var error = http_request.request(url, headers, metodo, cuerpo)
	if error != OK:
		print("❌ Error inmediato al levantar HTTPRequest")
		operacion_actual = ""
		animar_error_infantil("¡Error de red interno!")

# ==========================================
# ⚙️ RESPUESTAS DEL SERVIDOR Y VALIDACIÓN
# ==========================================
func _on_request_completed(result, response_code, headers, body):
	var respuesta = body.get_string_from_utf8()
	print("📡 Servidor respondió con código: " + str(response_code))
	
	# 🛠️ Manejo de fallos silenciosos en HTML5 (CORS o desconexión)
	if response_code == 0:
		print("❌ ERROR CRÍTICO: Código 0 recibido. Esto suele ser un bloqueo de CORS en el navegador o URL caída.")
		operacion_actual = ""
		animar_error_infantil("¡Bloqueo de conexión Web!")
		return

	var json = JSON.new()
	if json.parse(respuesta) != OK:
		print("❌ Error al parsear JSON. Respuesta cruda: " + respuesta)
		operacion_actual = ""
		animar_error_infantil("¡Error de datos!")
		return
		
	if response_code != 200 and response_code != 201:
		print("❌ Error de comunicación con la API. Respuesta: " + respuesta)
		operacion_actual = ""
		animar_error_infantil("¡Error de conexión!")
		return

	var datos_recibidos = json.data

	if operacion_actual == "LOGIN":
		if datos_recibidos is Array and datos_recibidos.size() > 0:
			var user_data = datos_recibidos[0]
			
			DatosUsuario.esta_conectado_a_la_nube = true
			DatosUsuario.usuario_id_db = int(user_data.get("id", 0))
			DatosUsuario.usuario_uuid = str(user_data.get("user_id", ""))
			DatosUsuario.nombre_usuario = str(user_data.get("usuario", ""))
			DatosUsuario.dificultad_actual = int(user_data.get("dificultad", 0))
			DatosUsuario.rol = str(user_data.get("rol", "estudiante"))
			
			print("👤 Usuario validado con rol: " + DatosUsuario.rol)
			
			if DatosUsuario.rol == "maestro":
				_on_boton_cerrar_pressed()
				get_tree().change_scene_to_file("res://Escenas/PanelMaestro.tscn")
			else:
				operacion_actual = "PROGRESO"
				var url_progreso = _obtener_url_tabla("progreso") + "?usuario_id=eq." + str(DatosUsuario.usuario_id_db)
				enviar_peticion_supabase(url_progreso, HTTPClient.METHOD_GET, "")
		else:
			print("❌ Login fallido: Credenciales incorrectas.")
			operacion_actual = ""
			animar_error_infantil("¡Usuario o Clave incorrectos!")

	elif operacion_actual == "PROGRESO":
		if datos_recibidos is Array and datos_recibidos.size() > 0:
			var progreso_data = datos_recibidos[0]
			DatosUsuario.pregunta_pendiente_db = bool(progreso_data.get("pregunta_pendiente", false))
			DatosUsuario.casilla_actual_db = int(progreso_data.get("casilla_actual", 0))
			DatosUsuario.dificultad_actual = int(progreso_data.get("dificultad", 0))
			
			# 🪙 Sincronización de monedas: Si acumuló monedas como invitado antes de loguearse, se conservan y suman
			var monedas_db = int(progreso_data.get("monedas", 0))
			var monedas_invitado = DatosUsuario.monedas
			DatosUsuario.monedas = monedas_db + monedas_invitado
			
			DatosUsuario.en_examen_final = bool(progreso_data.get("en_examen_final", false))
			DatosUsuario.examen_correctas = int(progreso_data.get("examen_correctas", 0))
			DatosUsuario.examen_preguntas_respondidas = int(progreso_data.get("examen_preguntas_respondidas", 0))
			
			# 🪐 Restaurar ruta/camino de Saturno
			if progreso_data.has("tomo_camino_corto"):
				DatosUsuario.tomo_camino_corto = bool(progreso_data.get("tomo_camino_corto", false))
			elif progreso_data.has("ruta_actual"):
				DatosUsuario.tomo_camino_corto = (str(progreso_data.get("ruta_actual", "")).to_lower() == "derecha")
			elif progreso_data.has("camino_actual"):
				DatosUsuario.tomo_camino_corto = (str(progreso_data.get("camino_actual", "")).to_lower() == "derecha")
			
			# Si traía monedas como invitado, actualizamos la base de datos con el nuevo saldo combinado
			if monedas_invitado > 0:
				ConexionSupabase.actualizar_monedas_en_nube(DatosUsuario.monedas)
				
			ConexionSupabase.cargar_album_nube()
			_abrir_interfaz_bienvenida()
		else:
			print("🆕 Inicializando tabla de progreso...")
			var es_migracion = (DatosUsuario.casilla_actual_db > 0 or DatosUsuario.laminas_poseidas.size() > 0 or DatosUsuario.monedas > 0)
			ConexionSupabase.inicializar_progreso_nuevo_usuario(es_migracion)
			_abrir_interfaz_bienvenida()

	elif operacion_actual == "REGISTRO":
		print("🎉 ¡Registro exitoso en la nube!")
		operacion_actual = "" # Limpiamos para permitir la llamada inmediata del login
		_on_boton_entrar_pressed()

# ==========================================
# 💥 ANIMACIÓN INFANTIL DE ERROR
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
	texto_titulo.text = "Bienvenido de Nuevo " + str(DatosUsuario.nombre_usuario)
	texto_titulo.modulate = Color(0.375, 0.677, 0.218, 1.0)
	await get_tree().create_timer(2.0).timeout
	_on_boton_cerrar_pressed()
