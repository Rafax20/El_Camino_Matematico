# res://Scripts_gd/Tablero.gd
extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
@onready var path_alternativo = $Path2D_Derecha
@onready var boton_dado = $Panel/BotonDado 
@onready var Menu_Volver =  $Tablero2/Volver_Menu
@onready var boton_chat = $Preguntar_ChatBox
@onready var minijuego = $MinijuegoAsteroides

var total_casillas = 30
var casilla_actual = 0
var casilla_anterior = 0

var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

var pregunta_actual: Dictionary = {}

# Coordenadas de ratio de tu Path2D para cada casilla
var casilla_destino = [
	0.037, 0.078, 0.106, 0.132, 0.164, 0.194, 0.232, 0.276, 0.314, 0.345,
	0.376, 0.406, #Casilla 12
	0.445, 0.475, 0.51, 0.551, 0.594, 0.634, 0.66, 0.692, 0.726, 0.757, 0.789,
	0.825, 0.86, 0.894, 0.917, 0.944, 0.972, 1.0
]


func _ready():
	$Panel.play()
	$Path2D.visible = true
	$Path2D/PathFollow2D/Animacion.visible = true
	#await get_tree().process_frame
	servidor_listo = false
	boton_dado.disabled = true # Bloqueado momentáneamente mientras bajan las preguntas
	boton_chat.disabled = true
	$Interfaz.visible = false
	
	# 🧭 CONTROL GLOBAL: Leemos los datos que cargó el menú directamente de la memoria RAM
	casilla_actual = DatosUsuario.casilla_actual_db
	casilla_anterior = casilla_actual
	
	# Teletransportamos la ficha de golpe a donde le corresponde estar
	_mover_ficha_visualmente(casilla_actual, true)
	
	# Conectamos la descarga de preguntas en background
	ConexionSupabase.preguntas_descargadas.connect(_on_preguntas_cargadas)
	ConexionSupabase.descargar_preguntas()

func _on_preguntas_cargadas(lista):
	lista_preguntas = lista
	print("🎉 ¡Preguntas cargadas y listas en memoria!")
	lista_preguntas.shuffle()
	servidor_listo = true
	
	# Evaluamos el candado usando la variable global pre-cargada
	if DatosUsuario.pregunta_pendiente_db:
		print("🚨 El usuario tenía una pregunta pendiente. Abriendo interfaz...")
		mostrar_pregunta_en_pantalla()
	else:
		print("✅ Camino libre. ¡Desbloqueando botón del dado!")
		boton_dado.disabled = false
		boton_chat.disabled = false

func _on_boton_dado_pressed():
	print("DEBUG: ¡El botón dado fue presionado!") # 👈 ESTO ES CLAVE
	if not servidor_listo or lista_preguntas.size() == 0: return
	
	boton_dado.disabled = true
	Menu_Volver.disabled = true
	casilla_anterior = casilla_actual
	
	var resultado = randi_range(1, 5)
	print("🎲 Salió un: ", resultado)
	$Panel/BotonDado/Numero_Dado.clear()
	$Panel/BotonDado/Numero_Dado.add_text(str(resultado))
	
	casilla_actual = clampi(casilla_actual + resultado, 0, total_casillas)
	
	# Sincronizamos la memoria global y mandamos el candado a la nube (si aplica) en background
	DatosUsuario.casilla_actual_db = casilla_actual
	DatosUsuario.pregunta_pendiente_db = true
	ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, true)
	
	# Animación normal de avance
	await $Path2D/PathFollow2D/Animacion.Animar_Movimiento(true)
	await _mover_ficha_visualmente(casilla_actual, false)
	await get_tree().create_timer(2.5).timeout
	await $Path2D/PathFollow2D/Animacion.Animar_Caida(true)
	await get_tree().create_timer(1.2).timeout
	if casilla_actual == total_casillas:
		mostrar_pregunta_en_pantalla()
	else:
		lanzar_minijuego_casilla()

func _mover_ficha_visualmente(casilla: int, instantaneo: bool):
	if casilla == 0:
		path_follow.progress_ratio = 0.0
		return
	
	var indice = clampi(casilla - 1, 0, casilla_destino.size() - 1)
	
	if instantaneo:
		path_follow.progress_ratio = casilla_destino[indice]
	else:
		var tween = create_tween()
		tween.tween_property(path_follow, "progress_ratio", casilla_destino[indice], 4.0).set_trans(Tween.TRANS_SINE)
	

func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: return
	
	# 🟢 1. REUTILIZAR PREGUNTA: Si ya había una pregunta asignada y pendiente, mostramos ESA MISMA
	if not DatosUsuario.pregunta_actual_guardada.is_empty():
		print("📌 Cargando la misma pregunta pendiente de la memoria...")
		pregunta_actual = DatosUsuario.pregunta_actual_guardada
	else:
		# 🧭 2. FILTRADO POR DIFICULTAD
		var preguntas_filtradas = lista_preguntas.filter(func(pregunta):
			return int(pregunta.get("dificultad", 0)) == DatosUsuario.dificultad_actual
		)
		
		if preguntas_filtradas.size() == 0:
			preguntas_filtradas = lista_preguntas

		# 🔄 3. CONTROL DEL MAZO AGOTADO
		if pregunta_actual_indice >= preguntas_filtradas.size():
			pregunta_actual_indice = 0
			lista_preguntas.shuffle()
			preguntas_filtradas = lista_preguntas.filter(func(pregunta):
				return int(pregunta.get("dificultad", 0)) == DatosUsuario.dificultad_actual
			)

		# 🎯 4. NUEVA ASIGNACIÓN Y GUARDADO GLOBAL
		pregunta_actual = preguntas_filtradas[pregunta_actual_indice]
		DatosUsuario.pregunta_actual_guardada = pregunta_actual # 👈 Guardamos la referencia
		pregunta_actual_indice += 1
	
	# 📺 5. MOSTRAR EN PANTALLA
	$Interfaz.visible = true
	$Interfaz.actualizar_datos_pantalla(pregunta_actual)
	
	

# ==========================================
# ⚙️ RESPUESTA DEL NIÑO DESDE LA INTERFAZ
# ==========================================
func _on_interfaz_respuesta_completada(es_correcta: bool, tiempo_tardado: float) -> void:
	# 🚨 REMOVIDO: Ya no cerramos la interfaz aquí arriba de golpe.
	DatosUsuario.pregunta_pendiente_db = false
	
	# 🧹 LIMPIEZA: Liberamos la pregunta guardada para que la siguiente casilla genere una nueva
	DatosUsuario.pregunta_actual_guardada = {}
	
	# 1. 🧠 EVALUACIÓN DEL SISTEMA EXPERTO
	var dificultad_anterior = DatosUsuario.dificultad_actual
	DatosUsuario.dificultad_actual = SistemaExperto.evaluar_desempeno(
		dificultad_anterior, 
		es_correcta, 
		tiempo_tardado
	)
	
	if DatosUsuario.dificultad_actual != dificultad_anterior:
		print("🧠 Tablero: El Sistema Experto cambió el nivel. Reiniciando pregunta_actual_indice a 0.")
		pregunta_actual_indice = 0
	
	# 2. 📊 REGISTRO EN LA TABLA DE HISTORIAL INDEPENDIENTE
	var categoria_actual = "matematicas"
	if pregunta_actual.has("categoria"):
		categoria_actual = str(pregunta_actual.get("categoria"))
		
	ConexionSupabase.registrar_en_historial(categoria_actual, es_correcta, tiempo_tardado)
	
	# 3. 💾 MANEJO DE RESPUESTA, AUDIOS Y FLUJO VISUAL
	# 3. 💾 MANEJO DE RESPUESTA, AUDIOS Y FLUJO VISUAL
	if es_correcta:
		print("🎯 ¡Correcta! El niño tardó: ", tiempo_tardado, " segundos.")
		GestionAudio.reproducir_audio_local("Elogios/" + ["elogio1", "elogio2", "elogio3"].pick_random())
		
		# --- SISTEMA DE PREMIACIÓN VISUAL ---
		if randf() < 0.80:
			var id_ganado = randi_range(1, 38) 
			
			# 🔍 REVISIÓN: ¿Ya la tiene en su lista global?
			var es_repetida: bool = DatosUsuario.laminas_poseidas.has(id_ganado)
			
			if DatosUsuario.CATALOGO_LAMINAS.has(id_ganado):
				# 1. Asignamos la textura correspondiente de la lámina
				
				# 2. 🔀 Modificamos el texto del Label y filtramos el registro en Supabase
				if es_repetida:
					print("LAMINA REPETIDA: " + str(id_ganado) + " | No se registra en la base de datos.")
				else:
					$CapaLogro/Control/TextureRect.texture = DatosUsuario.CATALOGO_LAMINAS[id_ganado]
					$CapaLogro/Control/TextureRect/Label.text = "¡Ganaste una nueva lámina!"
					print("¡NUEVA LAMINA!: " + str(id_ganado) + " | Registrando en Supabase...")
					
					# ☁️ SOLO REGISTRAMOS EN LA NUBE SI ES NUEVA
					ConexionSupabase.registrar_lamina_ganada(id_ganado)
					# La agregamos al inventario local de inmediato
					DatosUsuario.laminas_poseidas.append(id_ganado)
					# 3. Activamos la visibilidad y la animación de escala
					$CapaLogro.visible = true
					$CapaLogro/Control.scale = Vector2.ZERO
					var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property($CapaLogro/Control, "scale", Vector2.ONE, 0.4)
				
				# ⏳ Esperamos 3 segundos para que el niño vea su lámina y lea el cartel
				await get_tree().create_timer(3.0).timeout
				$CapaLogro.visible = false
		else:
			# Si contestó bien pero no ganó lámina (20% de probabilidad), esperamos 2s para que procese el éxito
			await get_tree().create_timer(2.0).timeout
		
		# Cerramos la ventana de la pregunta y liberamos los controles del tablero
		$Interfaz.visible = false
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		boton_dado.disabled = false
		Menu_Volver.disabled = false
		
	else:
		# ❌ LOGICA DE RESPUESTA INCORRECTA (¡Recuperada!)
		print("❌ ¡Incorrecta! Regresando a casilla anterior: ", casilla_anterior)
		
		# 🗣️ Mandamos a reproducir el ánimo pedagógico
		var animos = ["animo1", "animo2", "animo3"]
		GestionAudio.reproducir_audio_local("Animos/" + animos.pick_random())
		
		# ⏳ Esperamos 2 segundos para que escuche el mensaje de aliento antes de mover la ficha
		await get_tree().create_timer(2.0).timeout
		
		# 📺 Cerramos la ventana de la pregunta
		$Interfaz.visible = false
		
		# Ajustamos coordenadas de la memoria y hacemos el movimiento de retroceso visual
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		await _mover_ficha_visualmente(casilla_actual, false)
		
		# Desbloqueamos el tablero para el siguiente turno
		boton_dado.disabled = false
		Menu_Volver.disabled = false

func lanzar_minijuego_casilla():
	# 1. Seleccionamos una pregunta del banco precargado
	var pregunta_para_minijuego = _obtener_pregunta_actual()
	
	# 2. Conectamos la señal de término si no está conectada
	if not minijuego.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
		minijuego.minijuego_finalizado.connect(_on_minijuego_resuelto)
	
	# 3. Iniciamos el minijuego pasándole la pregunta y el tema ("colegio" o "espacio")
	minijuego.iniciar_minijuego(pregunta_para_minijuego, "colegio")


func _obtener_pregunta_actual() -> Dictionary:
	if lista_preguntas.size() == 0:
		# Respaldo alineado con las columnas de tu tabla en Supabase
		return {"operacion": "2 más 2", "respuesta_correcta": 4}
		
	var preguntas_filtradas = lista_preguntas.filter(func(p):
		return int(p.get("dificultad", 0)) == DatosUsuario.dificultad_actual
	)
	if preguntas_filtradas.size() == 0:
		preguntas_filtradas = lista_preguntas
		
	return preguntas_filtradas.pick_random()


# Callback cuando el niño explota el globo correcto
func _on_minijuego_resuelto(es_correcto: bool):
	if es_correcto:
		print("🎉 ¡Minijuego superado exitosamente!")
		
		# Liberamos el candado de la pregunta y actualizamos progreso
		DatosUsuario.pregunta_pendiente_db = false
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		
		# Habilitamos el dado para el siguiente turno
		boton_dado.disabled = false
		Menu_Volver.disabled = false
		
func enviar_puntuacion(nombre_jugador: String, puntos: int):
	var datos = {
		"user_id": DatosUsuario.usuario_id_db,
		"nombre": nombre_jugador, 
		"casilla": puntos
	}
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	Supabase.database.query(consulta)


func _on_preguntar_chat_box_pressed() -> void:
	NavegacionGlobal.abrir_chatbot()
