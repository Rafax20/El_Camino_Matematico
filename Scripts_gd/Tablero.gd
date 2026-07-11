# res://Scripts_gd/Tablero.gd
extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
@onready var boton_dado = $BotonDado 
@onready var Menu_Volver =  $Tablero/Volver_Menu

var total_casillas = 23
var casilla_actual = 0
var casilla_anterior = 0

var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

var pregunta_actual: Dictionary = {}

# Coordenadas de ratio de tu Path2D para cada casilla
var casilla_destino = [
	0.0577, 0.107, 0.154, 0.201, 0.249, 0.295, 0.338, 0.371, 0.409, 0.45,
	0.493, 0.532, 0.575, 0.615, 0.667, 0.715, 0.754, 0.797, 0.839, 0.875, 
	0.914, 0.955, 1
]

func _ready():
	$Path2D.visible = true
	$Path2D/PathFollow2D/Sprite2D.visible = true
	await get_tree().process_frame
	servidor_listo = false
	boton_dado.disabled = true # Bloqueado momentáneamente mientras bajan las preguntas
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

func _on_boton_dado_pressed():
	print("DEBUG: ¡El botón dado fue presionado!") # 👈 ESTO ES CLAVE
	if not servidor_listo or lista_preguntas.size() == 0: return
	
	boton_dado.disabled = true
	Menu_Volver.disabled = true
	casilla_anterior = casilla_actual
	
	var resultado = randi_range(1, 6)
	print("🎲 Salió un: ", resultado)
	
	casilla_actual = clampi(casilla_actual + resultado, 0, total_casillas)
	
	# Sincronizamos la memoria global y mandamos el candado a la nube (si aplica) en background
	DatosUsuario.casilla_actual_db = casilla_actual
	DatosUsuario.pregunta_pendiente_db = true
	ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, true)
	
	# Animación normal de avance
	await _mover_ficha_visualmente(casilla_actual, false)
	mostrar_pregunta_en_pantalla()

func _mover_ficha_visualmente(casilla: int, instantaneo: bool):
	if casilla == 0:
		path_follow.progress_ratio = 0.0
		return
	
	var indice = clampi(casilla - 1, 0, casilla_destino.size() - 1)
	
	if instantaneo:
		path_follow.progress_ratio = casilla_destino[indice]
	else:
		var tween = create_tween()
		tween.tween_property(path_follow, "progress_ratio", casilla_destino[indice], 1.0).set_trans(Tween.TRANS_SINE)
		await tween.finished

func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: return
	
	# 1. 🧭 FILTRADO: Creamos la sublista con la dificultad del niño
	var preguntas_filtradas = lista_preguntas.filter(func(pregunta):
		return int(pregunta.get("dificultad", 0)) == DatosUsuario.dificultad_actual
	)
	
	# Control de seguridad por si las moscas
	if preguntas_filtradas.size() == 0:
		print("⚠️ No hay preguntas para la dificultad: ", DatosUsuario.dificultad_actual)
		preguntas_filtradas = lista_preguntas

	# 2. 🔄 CONTROL DEL MAZO: ¿Se acabaron las preguntas de esta dificultad?
	if pregunta_actual_indice >= preguntas_filtradas.size():
		print("🔄 [Mazo Agotado] El niño respondió todas las preguntas de nivel ", DatosUsuario.dificultad_actual, ". Reiniciando mazo...")
		pregunta_actual_indice = 0
		# Barajamos la lista principal para que el nuevo ciclo sea totalmente aleatorio
		lista_preguntas.shuffle()
		
		# Re-filtramos para asegurarnos de tener el mazo fresco y barajado
		preguntas_filtradas = lista_preguntas.filter(func(pregunta):
			return int(pregunta.get("dificultad", 0)) == DatosUsuario.dificultad_actual
		)

	# 3. 🎯 ASIGNACIÓN: Tomamos la pregunta usando el índice correlativo
	pregunta_actual = preguntas_filtradas[pregunta_actual_indice]
	
	# 4. 📈 AVANCE: Incrementamos el índice para la siguiente casilla
	pregunta_actual_indice += 1
	
	# 5. 📺 INTERFAZ: Mostramos en pantalla
	$Interfaz.visible = true
	$Interfaz.actualizar_datos_pantalla(pregunta_actual)
	
	

# ==========================================
# ⚙️ RESPUESTA DEL NIÑO DESDE LA INTERFAZ
# ==========================================
func _on_interfaz_respuesta_completada(es_correcta: bool, tiempo_tardado: float) -> void:
	# 🚨 REMOVIDO: Ya no cerramos la interfaz aquí arriba de golpe.
	DatosUsuario.pregunta_pendiente_db = false
	
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
		# --- SISTEMA DE PREMIACIÓN VISUAL ---
		if randf() < 0.80:
			var id_ganado = randi_range(19, 36) 
			
			# 🔍 REVISIÓN: ¿Ya la tiene en su lista global?
			var es_repetida: bool = DatosUsuario.laminas_poseidas.has(id_ganado)
			
			if DatosUsuario.CATALOGO_LAMINAS.has(id_ganado):
				# 1. Asignamos la textura correspondiente de la lámina
				
				
				# 2. 🔀 Modificamos el texto del Label y filtramos el registro en Supabase
				if es_repetida:
					print("LAMINA REPETIDA: " + str(id_ganado) + " | No se registra en la base de datos.")
				else:
					$CapaLogro/Control/TextureRect.texture = load(DatosUsuario.CATALOGO_LAMINAS[id_ganado])
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

func enviar_puntuacion(nombre_jugador: String, puntos: int):
	var datos = {
		"user_id": DatosUsuario.usuario_id_db,
		"nombre": nombre_jugador, 
		"casilla": puntos
	}
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	Supabase.database.query(consulta)
