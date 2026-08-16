# res://Scripts_gd/Tablero.gd
extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
#@onready var path_alternativo = $Path2D_Derecha
@onready var dado_objeto = $ContenedorDado/DadoObjeto
@onready var anim_dado = $ContenedorDado/DadoObjeto/AnimationPlayer
@onready var boton_dado = $Panel/BotonDado 
@onready var Menu_Volver =  $Mapa_Tablero_2/Volver_Menu
@onready var boton_chat = $Preguntar_ChatBox
@onready var minijuego_asteroides = $MinijuegoAsteroides
@onready var minijuego_buscador = $MinijuegoBuscador
@onready var minijuego_laboratorio = $CapaMinijuegos/MinijuegoLaboratorio

var total_casillas = 30
var casilla_actual = 0
var casilla_anterior = 0

var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

var pregunta_actual: Dictionary = {}

# Valor: Diccionario con su ratio del Path2D y el tipo de evento
var mapa_casillas: Dictionary = {
	1:  {"ratio": 0.037, "tipo": "asteroides"},
	2:  {"ratio": 0.078, "tipo": "buscador_cajas"},
	3:  {"ratio": 0.106, "tipo": "laboratorio"},
	4:  {"ratio": 0.132, "tipo": "asteroides"},
	5:  {"ratio": 0.164, "tipo": "buscador_cajas"},
	6:  {"ratio": 0.194, "tipo": "laboratorio"},
	7:  {"ratio": 0.232, "tipo": "asteroides"},
	8:  {"ratio": 0.276, "tipo": "buscador_cajas"},
	9:  {"ratio": 0.314, "tipo": "laboratorio"},
	10: {"ratio": 0.345, "tipo": "asteroides"},
	11: {"ratio": 0.376, "tipo": "buscador_cajas"},
	12: {"ratio": 0.406, "tipo": "laboratorio"},
	13: {"ratio": 0.445, "tipo": "asteroides"},
	14: {"ratio": 0.475, "tipo": "buscador_cajas"},
	15: {"ratio": 0.510, "tipo": "laboratorio"},
	16: {"ratio": 0.551, "tipo": "asteroides"},
	17: {"ratio": 0.594, "tipo": "buscador_cajas"},
	18: {"ratio": 0.634, "tipo": "laboratorio"},
	19: {"ratio": 0.660, "tipo": "asteroides"},
	20: {"ratio": 0.692, "tipo": "buscador_cajas"},
	21: {"ratio": 0.726, "tipo": "laboratorio"},
	22: {"ratio": 0.757, "tipo": "asteroides"},
	23: {"ratio": 0.789, "tipo": "buscador_cajas"},
	24: {"ratio": 0.825, "tipo": "laboratorio"},
	25: {"ratio": 0.860, "tipo": "asteroides"},
	26: {"ratio": 0.894, "tipo": "buscador_cajas"},
	27: {"ratio": 0.917, "tipo": "laboratorio"},
	28: {"ratio": 0.944, "tipo": "asteroides"},
	29: {"ratio": 0.972, "tipo": "buscador_cajas"},
	30: {"ratio": 1.000, "tipo": "examen"} # Meta final
}


func _ready():
	$Panel.play()
	$Path2D.visible = true
	$Path2D/PathFollow2D/Animacion.visible = true
	$Nave.Animar_Nave(true) 
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
	# duplicate() crea una copia de trabajo local para poder hacer .shuffle() 
	# sin modificar el arreglo original en la RAM global
	lista_preguntas = lista.duplicate()
	
	print("🎉 ¡Preguntas cargadas y listas en memoria!")
	lista_preguntas.shuffle()
	servidor_listo = true
	
	if DatosUsuario.pregunta_pendiente_db:
		print("🚨 El usuario tenía una pregunta pendiente. Abriendo interfaz...")
		mostrar_pregunta_en_pantalla()
	else:
		print("✅ Camino libre. ¡Desbloqueando botón del dado!")
		boton_dado.disabled = false
		boton_chat.disabled = false

func _on_boton_dado_pressed():
	print("DEBUG: ¡El botón dado fue presionado!")
	if not servidor_listo or lista_preguntas.size() == 0: return
	
	# Bloqueamos la interfaz para evitar doble clic
	boton_dado.disabled = true
	Menu_Volver.disabled = true
	casilla_anterior = casilla_actual
	
	# 1. Calculamos el resultado de Supabase / Random
	var resultado = randi_range(3, 3)
	print("🎲 Salió un: ", resultado)
	
	# 2. 🎲 LANZAR Y MOSTRAR EL DADO EN PANTALLA
	await _animar_lanzamiento_dado(resultado)
	$Panel/BotonDado/Numero_Dado.clear()
	$Panel/BotonDado/Numero_Dado.add_text(str(resultado))
	# 3. Lógica del juego: actualizar posición y progresos
	casilla_actual = clampi(casilla_actual + resultado, 0, total_casillas)
	
	DatosUsuario.casilla_actual_db = casilla_actual
	DatosUsuario.pregunta_pendiente_db = true
	ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, true)
	
	# 4. Continuación de animaciones de mapa
	await $Path2D/PathFollow2D/Animacion.Animar_Movimiento(true)
	await _mover_ficha_visualmente(casilla_actual, false)
	await get_tree().create_timer(2.5).timeout
	await $Path2D/PathFollow2D/Animacion.Animar_Caida(true)
	await get_tree().create_timer(1.2).timeout
	
	if casilla_actual == total_casillas:
		mostrar_pregunta_en_pantalla()
	else:
		boton_chat.disabled = true
		lanzar_minijuego_casilla()


# 🎬 Función auxiliar encargada del efecto de lanzamiento con físicas de rebote y audio
func _animar_lanzamiento_dado(resultado_final: int) -> void:
	var centro_pantalla = get_viewport_rect().size / 2.0
	
	# 1. ESTADO INICIAL (Gigante y cerca de la cámara)
	dado_objeto.global_position = centro_pantalla
	dado_objeto.scale = Vector2(2.2, 2.2)
	dado_objeto.rotation = deg_to_rad(randf_range(-30, 30))
	dado_objeto.visible = true
	
	anim_dado.play("rodar")
	
	# ------------------------------------------------------------------
	# 💥 PRIMER IMPACTO: Caída rápida desde el aire hacia el primer punto
	# ------------------------------------------------------------------
	var punto_impacto_1 = centro_pantalla + Vector2(randf_range(-100, 100), randf_range(-60, 60))
	
	var tween_caida = create_tween().set_parallel(true)
	tween_caida.tween_property(dado_objeto, "scale", Vector2(0.5, 0.5), 0.6)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_caida.tween_property(dado_objeto, "global_position", punto_impacto_1, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_caida.tween_property(dado_objeto, "rotation", deg_to_rad(randf_range(360, 540)), 0.8)
	
	await tween_caida.finished
	
	# ------------------------------------------------------------------
	# 🏀 REBOTE 1: Salto mediano + Desviación de trayectoria
	# ------------------------------------------------------------------
	# Calculamos una nueva dirección en base al punto donde tocó suelo
	var punto_impacto_2 = punto_impacto_1 + Vector2(randf_range(-60, 60), randf_range(-40, 40))
	
	# Salto en el aire (Crece la escala)
	var tween_salto1_subida = create_tween().set_parallel(true)
	tween_salto1_subida.tween_property(dado_objeto, "scale", Vector2(0.75, 0.75), 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_salto1_subida.tween_property(dado_objeto, "global_position", (punto_impacto_1 + punto_impacto_2) / 2.0, 0.15)
	
	await tween_salida1_subida_or_timeout(tween_salto1_subida)
	
	# Caída del primer salto (Se reduce la escala al impactar)
	var tween_salto1_bajada = create_tween().set_parallel(true)
	tween_salto1_bajada.tween_property(dado_objeto, "scale", Vector2(0.5, 0.5), 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_salto1_bajada.tween_property(dado_objeto, "global_position", punto_impacto_2, 0.15)
	tween_salto1_bajada.tween_property(dado_objeto, "rotation", dado_objeto.rotation + deg_to_rad(180), 0.3)
	
	await tween_salto1_bajada.finished
	
	# ------------------------------------------------------------------
	# ⚽ REBOTE 2: Micro-rebote final (Más corto y suave)
	# ------------------------------------------------------------------
	var punto_final = punto_impacto_2 + Vector2(randf_range(-30, 30), randf_range(-20, 20))
	
	var tween_rebote2 = create_tween().set_parallel(true)
	# Subidita ligera
	tween_rebote2.tween_property(dado_objeto, "scale", Vector2(0.6, 0.6), 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_rebote2.tween_property(dado_objeto, "global_position", punto_final, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween_rebote2.finished
	
	# Asentamiento en el suelo
	var tween_asentar = create_tween()
	tween_asentar.tween_property(dado_objeto, "scale", Vector2(0.5, 0.5), 0.08)
	await tween_asentar.finished

	# ------------------------------------------------------------------
	# 🛑 3. FRENO, CARA FINAL Y AUDIO DE JULY
	# ------------------------------------------------------------------
	anim_dado.stop()
	dado_objeto.frame = clampi(resultado_final - 1, 0, 5)
	dado_objeto.rotation = 0.0
	
	await get_tree().create_timer(0.3).timeout
	
	# 🗣️ Voz de July
	GestionAudio.reproducir_audio_local("Voces/numero" + str(resultado_final))
	
	# 🔍 4. ENFOQUE FINAL EN PANTALLA (Zoom de resultado)
	var tween_enfoque = create_tween()
	tween_enfoque.tween_property(dado_objeto, "scale", Vector2(1.5, 1.5), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.4).timeout
	
	# 💨 5. SALIDA
	var tween_salida = create_tween()
	tween_salida.tween_property(dado_objeto, "scale", Vector2.ZERO, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween_salida.finished
	
	dado_objeto.visible = false


# Función auxiliar rápida para esperar la subida del primer salto
func tween_salida1_subida_or_timeout(tw: Tween) -> void:
	await tw.finished

func _mover_ficha_visualmente(casilla: int, instantaneo: bool):
	if casilla == 0:
		path_follow.progress_ratio = 0.0
		return
	
	# Obtenemos la posición asignada a la casilla actual (por defecto 0.0 si no existe)
	var datos_casilla = mapa_casillas.get(casilla, {"ratio": 0.0})
	var ratio_destino = datos_casilla["ratio"]
	
	if instantaneo:
		path_follow.progress_ratio = ratio_destino
	else:
		var tween = create_tween()
		tween.tween_property(path_follow, "progress_ratio", ratio_destino, 4.0).set_trans(Tween.TRANS_SINE)
	

# ==========================================
# 📝 GESTIÓN DE PREGUNTAS Y EXAMEN FINAL
# ==========================================
func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: return
	
	# 🎯 Si estamos en la casilla final o reanudando un examen interrumpido
	if casilla_actual == total_casillas or DatosUsuario.en_examen_final:
		DatosUsuario.en_examen_final = true
		print("📝 MODO EXAMEN: Pregunta ", DatosUsuario.examen_preguntas_respondidas + 1, " de 5")
	
	# 🟢 1. REUTILIZAR PREGUNTA: Si ya había una pregunta asignada y pendiente, mostramos esa misma
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
		DatosUsuario.pregunta_actual_guardada = pregunta_actual
		pregunta_actual_indice += 1
	
	# 📺 5. MOSTRAR EN PANTALLA
	$Interfaz.visible = true
	$Interfaz.actualizar_datos_pantalla(pregunta_actual)
	
	

# ==========================================
# ⚙️ RESPUESTA DEL NIÑO DESDE LA INTERFAZ
# ==========================================
# ==========================================
# ⚙️ RESPUESTA DEL NIÑO DESDE LA INTERFAZ
# ==========================================
func _on_interfaz_respuesta_completada(es_correcta: bool, tiempo_tardado: float) -> void:
	DatosUsuario.pregunta_pendiente_db = false
	DatosUsuario.pregunta_actual_guardada = {}
	
	# 1. 🧠 EVALUACIÓN DEL SISTEMA EXPERTO
	var dificultad_anterior = DatosUsuario.dificultad_actual
	DatosUsuario.dificultad_actual = SistemaExperto.evaluar_desempeno(
		dificultad_anterior, 
		es_correcta, 
		tiempo_tardado
	)
	
	if DatosUsuario.dificultad_actual != dificultad_anterior:
		pregunta_actual_indice = 0
	
	# 2. 📊 REGISTRO EN EL HISTORIAL GENERAL
	var categoria_actual = "matematicas"
	if pregunta_actual.has("categoria"):
		categoria_actual = str(pregunta_actual.get("categoria"))
		
	ConexionSupabase.registrar_en_historial(categoria_actual, es_correcta, tiempo_tardado)
	
	# 3. 🔀 BIFURCACIÓN SEGÚN EL MODO DE JUEGO
	if DatosUsuario.en_examen_final:
		_procesar_respuesta_examen(es_correcta)
	else:
		_procesar_respuesta_casilla_normal(es_correcta, tiempo_tardado)


# ------------------------------------------
# 📝 LÓGICA DEL EXAMEN FINAL (SIN INTERRUPCIÓN)
# ------------------------------------------
func _procesar_respuesta_examen(es_correcta: bool):
	DatosUsuario.examen_preguntas_respondidas += 1
	if es_correcta:
		DatosUsuario.examen_correctas += 1

	# 📌 Guardamos el detalle de la pregunta para el resumen de errores
	DatosUsuario.historial_examen.append({
		"numero": DatosUsuario.examen_preguntas_respondidas,
		"operacion": pregunta_actual.get("operacion", "Operación"),
		"es_correcta": es_correcta,
		"respuesta_correcta": pregunta_actual.get("respuesta_correcta", "")
	})

	# 🏁 Verificar si completó las 5 preguntas del examen
	if DatosUsuario.examen_preguntas_respondidas >= 5:
		$Interfaz.visible = false
		_mostrar_resumen_y_evaluar_examen()
	else:
		# Solo si TODAVÍA quedan preguntas pendientes en el examen actualizamos en true
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, true)
		DatosUsuario.pregunta_pendiente_db = true
		mostrar_pregunta_en_pantalla()


func _mostrar_resumen_y_evaluar_examen():
	print("📊 EXAMEN FINALIZADO. Resultados del alumno:")
	for item in DatosUsuario.historial_examen:
		var estado = "✅ CORRECTA" if item["es_correcta"] else "❌ INCORRECTA (Respuesta: " + str(item["respuesta_correcta"]) + ")"
		print("  P" + str(item["numero"]) + ": " + str(item["operacion"]) + " -> " + estado)
	
	# 🏆 EVALUACIÓN DE NOTA
	if DatosUsuario.examen_correctas == 5:
		print("🎉 ¡APROBADO PERFECTO (5/5)! Victoria total del tablero.")
		_finalizar_examen(true)
	else:
		print("❌ NO APROBADO (", DatosUsuario.examen_correctas, "/5). Mostrando errores...")
		# Aquí puedes desplegar tu ventana emergente o panel con el resumen de errores
		# Ejemplo: $PanelResumenErrores.mostrar(DatosUsuario.historial_examen)
		
		_finalizar_examen(false)


func _finalizar_examen(superado: bool):
	var aciertos = DatosUsuario.examen_correctas
	
	# Limpiamos el estado del examen en la RAM local
	DatosUsuario.en_examen_final = false
	DatosUsuario.examen_preguntas_respondidas = 0
	DatosUsuario.examen_correctas = 0
	DatosUsuario.pregunta_pendiente_db = false # 👈 Limpiar aquí antes de evaluar

	if superado:
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		# 🏆 ¡AQUÍ DESPLEGAS EL DIPLOMA O PANTALLA DE VICTORIA!
	else:
		# Retrocede a la casilla anterior por no aprobar las 5
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		await _mover_ficha_visualmente(casilla_actual, false)
		
		boton_dado.disabled = false
		Menu_Volver.disabled = false


# ------------------------------------------
# 🎲 LÓGICA DE CASILLA NORMAL
# ------------------------------------------
func _procesar_respuesta_casilla_normal(es_correcta: bool, tiempo_tardado: float):
	if es_correcta:
		print("🎯 ¡Correcta! El niño tardó: ", tiempo_tardado, " segundos.")
		GestionAudio.reproducir_audio_local("Elogios/" + ["elogio1", "elogio2", "elogio3"].pick_random())
		
		if randf() < 0.80:
			var id_ganado = randi_range(1, 38) 
			var es_repetida: bool = DatosUsuario.laminas_poseidas.has(id_ganado)
			
			if DatosUsuario.CATALOGO_LAMINAS.has(id_ganado):
				if not es_repetida:
					$CapaLogro/Control/TextureRect.texture = DatosUsuario.CATALOGO_LAMINAS[id_ganado]
					$CapaLogro/Control/TextureRect/Label.text = "¡Ganaste una nueva lámina!"
					ConexionSupabase.registrar_lamina_ganada(id_ganado)
					DatosUsuario.laminas_poseidas.append(id_ganado)
					
					$CapaLogro.visible = true
					$CapaLogro/Control.scale = Vector2.ZERO
					var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property($CapaLogro/Control, "scale", Vector2.ONE, 0.4)
					await get_tree().create_timer(3.0).timeout
					$CapaLogro.visible = false
				else:
					await get_tree().create_timer(1.5).timeout
		else:
			await get_tree().create_timer(2.0).timeout
		
		$Interfaz.visible = false
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		boton_dado.disabled = false
		Menu_Volver.disabled = false
		
	else:
		print("❌ ¡Incorrecta! Regresando a casilla anterior: ", casilla_anterior)
		GestionAudio.reproducir_audio_local("Animos/" + ["animo1", "animo2", "animo3"].pick_random())
		await get_tree().create_timer(2.0).timeout
		
		$Interfaz.visible = false
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		await _mover_ficha_visualmente(casilla_actual, false)
		
		boton_dado.disabled = false
		Menu_Volver.disabled = false

func lanzar_minijuego_casilla():
	# 1. Seleccionamos una pregunta del banco precargado
	var datos_casilla = mapa_casillas.get(casilla_actual, {"tipo": "buscador_cajas"})
	print("MINIJUEGO DETECTADO EN DATOS CASILLA: ", datos_casilla["tipo"])
	match datos_casilla["tipo"]:
		"asteroides":
			lanzar_minijuego_asteroides()
			
		"buscador_cajas":
			lanzar_minijuego_buscador()
			
		"laboratorio":
			lanzar_minijuego_laboratorio()


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


func _on_minijuego_resuelto(es_correcto: bool):
	$CapaMinijuegos.visible = false
	minijuego_laboratorio.visible = false
	if es_correcto:
		print("🎉 ¡Minijuego superado exitosamente!")
		
		# Liberamos el candado de la pregunta y actualizamos progreso
		DatosUsuario.pregunta_pendiente_db = false
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		
		# Habilitamos el dado para el siguiente turno
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
	
	boton_chat.disabled = false
	visible = true
		
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
	
# 🚀 Invocador del minijuego de asteroides
func lanzar_minijuego_asteroides():
	var pregunta = _obtener_pregunta_actual()
	if not minijuego_asteroides.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
		minijuego_asteroides.minijuego_finalizado.connect(_on_minijuego_resuelto)
	minijuego_asteroides.iniciar_minijuego(pregunta, "espacio")

# 🔦 Invocador del minijuego de las cajas en la oscuridad
func lanzar_minijuego_buscador():
	if not minijuego_buscador.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
		minijuego_buscador.minijuego_finalizado.connect(_on_minijuego_resuelto)
	minijuego_buscador.iniciar_minijuego("espacio")
	

# 🧪 Invocador del minijuego de mezcla de laboratorio
func lanzar_minijuego_laboratorio():
	if not minijuego_laboratorio.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
		minijuego_laboratorio.minijuego_finalizado.connect(_on_minijuego_resuelto)
	
	# 👁️ MOSTRAR: Encendemos la capa y/o el minijuego
	$CapaMinijuegos.visible = true
	minijuego_laboratorio.visible = true
	
	# Ejecutamos la lógica del minijuego (esta función interna ya se encarga 
	# de encender sus subpaneles y esperar el frame para calcular las dimensiones)
	minijuego_laboratorio.iniciar_minijuego("espacio")
