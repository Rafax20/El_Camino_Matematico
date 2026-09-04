# res://Scripts_gd/Tablero.gd
extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
@onready var path_follow_derecha = $Path2D_Derecha/PathFollow2D if has_node("Path2D_Derecha/PathFollow2D") else null
@onready var dado_objeto = $ContenedorDado/DadoObjeto
@onready var anim_dado = $ContenedorDado/DadoObjeto/AnimationPlayer
@onready var boton_dado = $Panel/BotonDado 
@onready var Menu_Volver =  $Mapa_Tablero_2/Volver_Menu
@onready var boton_chat = $Preguntar_ChatBox
@onready var minijuego_asteroides = $CapaMinijuegos/MinijuegoAsteroides
@onready var minijuego_buscador = $MinijuegoBuscador
@onready var minijuego_laboratorio = $CapaMinijuegos/MinijuegoLaboratorio
@onready var minijuego_balanza = $CapaMinijuegos/MinijuegoBalanza
@onready var minijuego_clasificador = $CapaMinijuegos/MinijuegoClasificador
@onready var minijuego_circuitos = $CapaMinijuegos/MinijuegoCircuitos
@onready var minijuego_piloto = $CapaMinijuegos/MinijuegoPilotoNave if has_node("CapaMinijuegos/MinijuegoPilotoNave") else null

var total_casillas = 29
var casilla_actual = 0
var casilla_anterior = 0

var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

var pregunta_actual: Dictionary = {}

# Valor: Diccionario con su ratio del Path2D (Camino Largo Izquierdo)
var mapa_casillas: Dictionary = {
	1:  {"ratio": 0.039, "tipo": "asteroides"},
	2:  {"ratio": 0.078, "tipo": "buscador_cajas"},
	3:  {"ratio": 0.109, "tipo": "laboratorio"},
	4:  {"ratio": 0.137, "tipo": "balanza"},
	5:  {"ratio": 0.174, "tipo": "clasificador"},
	6:  {"ratio": 0.205, "tipo": "circuitos"},
	7:  {"ratio": 0.245, "tipo": "asteroides"},
	8:  {"ratio": 0.284, "tipo": "buscador_cajas"},
	9:  {"ratio": 0.325, "tipo": "laboratorio"},
	10: {"ratio": 0.364, "tipo": "balanza"},
	11: {"ratio": 0.395, "tipo": "clasificador"},
	12: {"ratio": 0.426, "tipo": "piloto_nave"}, # Casilla de bifurcación de la Nave
	13: {"ratio": 0.465, "tipo": "asteroides"},
	14: {"ratio": 0.504, "tipo": "buscador_cajas"},
	15: {"ratio": 0.535, "tipo": "laboratorio"},
	16: {"ratio": 0.58,  "tipo": "balanza"},
	17: {"ratio": 0.624, "tipo": "clasificador"},
	18: {"ratio": 0.657, "tipo": "circuitos"},
	19: {"ratio": 0.688, "tipo": "asteroides"},
	20: {"ratio": 0.719, "tipo": "buscador_cajas"},
	21: {"ratio": 0.758, "tipo": "laboratorio"},
	22: {"ratio": 0.789, "tipo": "balanza"},
	23: {"ratio": 0.828, "tipo": "clasificador"},
	24: {"ratio": 0.865, "tipo": "circuitos"},
	25: {"ratio": 0.89,  "tipo": "asteroides"},
	26: {"ratio": 0.917, "tipo": "buscador_cajas"},
	27: {"ratio": 0.943, "tipo": "laboratorio"},
	28: {"ratio": 0.974, "tipo": "balanza"},
	29: {"ratio": 1.000, "tipo": "examen"} # Meta final
}

# 📌 DICCIONARIO ALTERNATIVO: Ratios para Path2D_Derecha (Atajo de la Casilla 12)
# La primera posición de esta curva es la Casilla 12 (ratio 0.0), avanzando hacia la nave (ratio 1.0)
var mapa_casillas_derecha: Dictionary = {
	12: {"ratio": 0.0000, "tipo": "piloto_nave"},
	13: {"ratio": 0.1094, "tipo": "circuitos"},
	14: {"ratio": 0.1979, "tipo": "asteroides"},
	15: {"ratio": 0.2758, "tipo": "buscador_cajas"},
	16: {"ratio": 0.3643, "tipo": "laboratorio"},
	17: {"ratio": 0.4528, "tipo": "balanza"},
	18: {"ratio": 0.5518, "tipo": "clasificador"},
	19: {"ratio": 0.6403, "tipo": "circuitos"},
	20: {"ratio": 0.7184, "tipo": "asteroides"},
	21: {"ratio": 0.7788, "tipo": "buscador_cajas"},
	22: {"ratio": 0.8569, "tipo": "laboratorio"},
	23: {"ratio": 0.935, "tipo": "balanza"},
	24: {"ratio": 1.0000, "tipo": "examen"} # Meta final del atajo
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
	print("CASILLA CARGADA DONDE DEBERA ESTAR: ", casilla_actual)
	_mover_ficha_visualmente(casilla_actual, true)
	
	# ⚡ VALIDACIÓN INSTANTÁNEA: Si las preguntas ya están en RAM, las usamos de inmediato sin esperar la red
	if DatosUsuario.banco_preguntas.size() > 0:
		print("⚡ [Tablero] Preguntas ya disponibles en memoria global (", DatosUsuario.banco_preguntas.size(), "). Activación instantánea.")
		_on_preguntas_cargadas(DatosUsuario.banco_preguntas)
	else:
		print("⏳ [Tablero] Esperando preguntas de Supabase...")
		if not ConexionSupabase.preguntas_descargadas.is_connected(_on_preguntas_cargadas):
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
		print("🚨 El usuario tenía un minijuego o pregunta pendiente en casilla: ", casilla_actual)
		boton_dado.disabled = true
		boton_chat.disabled = true
		if casilla_actual == total_casillas or DatosUsuario.en_examen_final:
			mostrar_pregunta_en_pantalla()
		else:
			lanzar_minijuego_casilla()
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
	var resultado = randi_range(1, 6)
	print("🎲 Salió un: ", resultado)
	
	# 2. 🎲 LANZAR Y MOSTRAR EL DADO EN PANTALLA
	await _animar_lanzamiento_dado(resultado)
	$Panel/BotonDado/Numero_Dado.clear()
	$Panel/BotonDado/Numero_Dado.add_text(str(resultado))
	# 3. Lógica del juego: actualizar posición y progresos
	var casilla_destino_calculada = casilla_actual + resultado
	var max_casillas = _obtener_total_casillas()
	
	# 🪐 REGLA DE BIFURCACIÓN EN CASILLA 12:
	# Si el jugador viene de una casilla anterior (< 12) y el tiro lo llevaría a superar la 12 (>= 12),
	# se le frena obligatoriamente en la Casilla 12 para resolver el desafío y decidir el camino.
	if casilla_anterior < 12 and casilla_destino_calculada >= 12:
		print("🪐 ¡Bifurcación en Saturno! Frenado obligatorio en Casilla 12 para decidir el camino.")
		casilla_actual = 12
	else:
		casilla_actual = clampi(casilla_destino_calculada, 0, max_casillas)
	
	DatosUsuario.casilla_actual_db = casilla_actual
	DatosUsuario.pregunta_pendiente_db = true
	ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, true)
	
	# 4. Continuación de animaciones de mapa
	var anim_activa = _obtener_animacion_activa()
	if anim_activa and anim_activa.has_method("Animar_Movimiento"):
		anim_activa.Animar_Movimiento(true)
	await _mover_ficha_visualmente(casilla_actual, false)
	if anim_activa and anim_activa.has_method("Animar_Caida"):
		await anim_activa.Animar_Caida(true)
	await get_tree().create_timer(0.3).timeout
	
	if casilla_actual >= max_casillas:
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

func _obtener_animacion_activa() -> Node:
	var usa_derecho = DatosUsuario.tomo_camino_corto and path_follow_derecha != null and casilla_actual >= 12
	if usa_derecho and has_node("Path2D_Derecha/PathFollow2D/Animacion"):
		return $Path2D_Derecha/PathFollow2D/Animacion
	elif has_node("Path2D/PathFollow2D/Animacion"):
		return $Path2D/PathFollow2D/Animacion
	return null

func _mover_ficha_visualmente(casilla: int, instantaneo: bool):
	if casilla == 0:
		if path_follow: 
			path_follow.visible = true
			path_follow.progress_ratio = 0.0
		if path_follow_derecha: 
			path_follow_derecha.visible = false
			path_follow_derecha.progress_ratio = 0.0
		return
	
	# Determinar si se usa el atajo derecho ($Path2D_Derecha) o el camino largo ($Path2D)
	var usa_derecho = DatosUsuario.tomo_camino_corto and path_follow_derecha != null and casilla >= 12
	var target_follow = path_follow_derecha if usa_derecho else path_follow
	var target_mapa = mapa_casillas_derecha if usa_derecho else mapa_casillas
	
	# Visibilidad y sincronización de nodos
	if path_follow_derecha and path_follow:
		path_follow.visible = not usa_derecho
		path_follow_derecha.visible = usa_derecho
	
	# Obtenemos la posición asignada a la casilla actual
	var datos_casilla = target_mapa.get(casilla, {"ratio": 0.0})
	var ratio_destino = datos_casilla["ratio"]
	
	if instantaneo:
		target_follow.progress_ratio = ratio_destino
	else:
		var tween = create_tween()
		tween.tween_property(target_follow, "progress_ratio", ratio_destino, 2.5).set_trans(Tween.TRANS_SINE)
		await tween.finished
	

# ==========================================
# 📝 GESTIÓN DE PREGUNTAS Y EXAMEN FINAL
# ==========================================
func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: return
	
	# 🎯 Si estamos en la casilla final o reanudando un examen interrumpido
	if casilla_actual >= _obtener_total_casillas() or DatosUsuario.en_examen_final:
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
		# 🛑 Bloqueo total e inmediato de controles para evitar re-pulsaciones
		boton_dado.disabled = true
		boton_chat.disabled = true
		Menu_Volver.disabled = true
		
		# 🪙 OTORGAR 30 MONEDAS POR COMPLETAR EL TABLERO
		DatosUsuario.monedas += 30
		print("🪙 ¡+30 Monedas ganadas! Total actual: ", DatosUsuario.monedas)
		
		# 🏆 Verificar si es la primera vez que obtiene el logro 1
		var es_nuevo_logro: bool = not DatosUsuario.logros_poseidos.has(1)
		if es_nuevo_logro:
			ConexionSupabase.registrar_logro_ganado(1) # 🏆 Logro 1: Tablero Completado
			
		# 🔄 RESET TOTAL DE CASILLA A 0 (Local, Global y en Base de Datos)
		casilla_actual = 0
		casilla_anterior = 0
		DatosUsuario.casilla_actual_db = 0
		DatosUsuario.pregunta_pendiente_db = false
		DatosUsuario.tomo_camino_corto = false
		ConexionSupabase.actualizar_progreso_en_nube(0, false)
		
		# 🏆 Reproducir voz/elogio de victoria
		GestionAudio.reproducir_elogio()
		
		# 🌟 Desplegar pantalla de felicitaciones centrada durante 6 segundos y volver al menú
		await _mostrar_pantalla_felicitaciones_victoria(es_nuevo_logro)
	else:
		# Retrocede a la casilla anterior directamente por no aprobar las 5
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		_mover_ficha_visualmente(casilla_actual, true)
		
		boton_dado.disabled = false
		Menu_Volver.disabled = false

func _mostrar_pantalla_felicitaciones_victoria(es_nuevo_logro: bool = true):
	var capa_victoria = CanvasLayer.new()
	capa_victoria.name = "CapaVictoriaFinal"
	capa_victoria.layer = 100
	add_child(capa_victoria)
	
	# Fondo oscuro
	var fondo_oscuro = ColorRect.new()
	fondo_oscuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo_oscuro.color = Color(0.02, 0.04, 0.08, 0.92)
	capa_victoria.add_child(fondo_oscuro)
	
	# Tarjeta central perfectamente centrada
	var tarjeta = Panel.new()
	tarjeta.set_anchors_preset(Control.PRESET_CENTER)
	tarjeta.anchor_left = 0.5
	tarjeta.anchor_top = 0.5
	tarjeta.anchor_right = 0.5
	tarjeta.anchor_bottom = 0.5
	tarjeta.offset_left = -390
	tarjeta.offset_top = -250
	tarjeta.offset_right = 390
	tarjeta.offset_bottom = 250
	tarjeta.pivot_offset = Vector2(390, 250)
	
	var st_tarjeta = StyleBoxFlat.new()
	st_tarjeta.bg_color = Color("#0f172a") # Azul noche profundo
	st_tarjeta.border_color = Color("#f59e0b") # Borde dorado
	st_tarjeta.set_border_width_all(5)
	st_tarjeta.set_corner_radius_all(24)
	st_tarjeta.shadow_color = Color(0.96, 0.62, 0.04, 0.5)
	st_tarjeta.shadow_size = 20
	tarjeta.add_theme_stylebox_override("panel", st_tarjeta)
	capa_victoria.add_child(tarjeta)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	tarjeta.add_child(vbox)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "¡MISIÓN CUMPLIDA, ASTRONAUTA!"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 32)
	lbl_titulo.add_theme_color_override("font_color", Color("#fde047"))
	lbl_titulo.add_theme_color_override("font_outline_color", Color("#78350f"))
	lbl_titulo.add_theme_constant_override("outline_size", 4)
	vbox.add_child(lbl_titulo)
	
	# Mostrar icono del logro solo si es recién ganado
	if es_nuevo_logro:
		var icono_logro = TextureRect.new()
		icono_logro.custom_minimum_size = Vector2(100, 100)
		icono_logro.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono_logro.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists("res://assets/Logros/Tablero_Completado.png"):
			icono_logro.texture = load("res://assets/Logros/Tablero_Completado.png")
		vbox.add_child(icono_logro)
	
	var lbl_desc = Label.new()
	if es_nuevo_logro:
		lbl_desc.text = "¡Has completado con éxito todo el tablero espacial y aprobado el examen final!\n¡Nuevo Logro Desbloqueado: Tablero Completado!"
	else:
		lbl_desc.text = "¡Has completado nuevamente con éxito todo el tablero espacial y aprobado el examen final!"
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_font_size_override("font_size", 18)
	lbl_desc.add_theme_color_override("font_color", Color("#e2e8f0"))
	vbox.add_child(lbl_desc)
	
	# Banner de Recompensa de Monedas con Icono PNG
	var hbox_monedas = HBoxContainer.new()
	hbox_monedas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_monedas.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_monedas)
	
	var ico_moneda_vic = TextureRect.new()
	ico_moneda_vic.custom_minimum_size = Vector2(26, 26)
	ico_moneda_vic.texture = load("res://assets/Iconos_UI/Icono_Moneda.png")
	ico_moneda_vic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico_moneda_vic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox_monedas.add_child(ico_moneda_vic)
	
	var lbl_monedas = Label.new()
	lbl_monedas.text = "¡Has ganado +30 Monedas Espaciales! (Total: %d monedas)" % DatosUsuario.monedas
	lbl_monedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_monedas.add_theme_font_size_override("font_size", 18)
	lbl_monedas.add_theme_color_override("font_color", Color("#fbbf24"))
	hbox_monedas.add_child(lbl_monedas)
	
	var lbl_contador = Label.new()
	lbl_contador.text = "Regresando a la base espacial en 6 segundos..."
	lbl_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_contador.add_theme_font_size_override("font_size", 16)
	lbl_contador.add_theme_color_override("font_color", Color("#38bdf8"))
	vbox.add_child(lbl_contador)
	
	# Animación pop-up
	tarjeta.scale = Vector2(0.5, 0.5)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(tarjeta, "scale", Vector2.ONE, 0.4)
	
	# Cuenta regresiva de 6 segundos
	for s in range(6, 0, -1):
		lbl_contador.text = "Regresando a la base espacial en %d segundos..." % s
		await get_tree().create_timer(1.0).timeout
		
	lbl_contador.text = "¡Despegando hacia el menú principal!"
	await get_tree().create_timer(0.4).timeout
	
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Menu.tscn")


# ------------------------------------------
# 🎲 LÓGICA DE CASILLA NORMAL
# ------------------------------------------
func _procesar_respuesta_casilla_normal(es_correcta: bool, tiempo_tardado: float):
	if es_correcta:
		print("🎯 ¡Correcta! El niño tardó: ", tiempo_tardado, " segundos.")
		
		# 🪐 BIFURCACIÓN EN CASILLA 12: Si acierta la 12, desbloquea el atajo derecho
		if casilla_actual == 12:
			DatosUsuario.tomo_camino_corto = true
			if path_follow_derecha:
				path_follow_derecha.progress_ratio = 0.0
				path_follow_derecha.visible = true
			if path_follow:
				path_follow.visible = false
			print("🌟 ¡Casilla 12 Superada! Se ha activado el Atajo Derecho ($Path2D_Derecha) desde ratio 0.0.")
		
		GestionAudio.reproducir_elogio()
		
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
		
		# 🪐 BIFURCACIÓN EN CASILLA 12: Si se equivoca, se mantiene en el camino largo
		if casilla_actual == 12:
			DatosUsuario.tomo_camino_corto = false
			if path_follow:
				path_follow.visible = true
			if path_follow_derecha:
				path_follow_derecha.visible = false
			print("🛑 Fallo en la Casilla 12. Se debe recorrer el camino largo ($Path2D) alrededor de Saturno.")
			
		GestionAudio.reproducir_audio_local("Animos/" + ["animo1", "animo2", "animo3"].pick_random())
		await get_tree().create_timer(2.0).timeout
		
		$Interfaz.visible = false
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		_mover_ficha_visualmente(casilla_actual, true)
		
		boton_dado.disabled = false
		Menu_Volver.disabled = false

func _obtener_total_casillas() -> int:
	return 24 if DatosUsuario.tomo_camino_corto else 29

func lanzar_minijuego_casilla():
	# 1. Seleccionamos el diccionario del camino actual (Atajo o Principal)
	var usa_derecho = DatosUsuario.tomo_camino_corto and casilla_actual >= 12
	var target_mapa = mapa_casillas_derecha if usa_derecho else mapa_casillas
	var datos_casilla = target_mapa.get(casilla_actual, {"tipo": "buscador_cajas"})
	print("MINIJUEGO DETECTADO EN DATOS CASILLA (Casilla ", casilla_actual, "): ", datos_casilla["tipo"])
	match datos_casilla["tipo"]:
		"asteroides":
			lanzar_minijuego_asteroides()
			
		"buscador_cajas":
			lanzar_minijuego_buscador()
			
		"laboratorio":
			lanzar_minijuego_laboratorio()

		"balanza":
			lanzar_minijuego_balanza()

		"clasificador":
			lanzar_minijuego_clasificador()

		"circuitos":
			lanzar_minijuego_circuitos()

		"piloto_nave":
			lanzar_minijuego_piloto()


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
	if minijuego_asteroides: minijuego_asteroides.visible = false
	if minijuego_buscador: minijuego_buscador.visible = false
	if minijuego_laboratorio: minijuego_laboratorio.visible = false
	if minijuego_balanza: minijuego_balanza.visible = false
	if minijuego_clasificador: minijuego_clasificador.visible = false
	if minijuego_circuitos: minijuego_circuitos.visible = false
	if minijuego_piloto: minijuego_piloto.visible = false

	# 🎥 RESTAURAR CÁMARA DEL TABLERO
	$CamaraTablero.enabled = true
	$CamaraTablero.make_current()

	# 🔄 Reorganizamos la lista del tablero para la siguiente casilla
	lista_preguntas.shuffle()

	if es_correcto:
		print("🎉 ¡Minijuego superado exitosamente!")
		
		# 🪐 BIFURCACIÓN EN CASILLA 12: Si gana el minijuego de la 12, habilita el atajo derecho
		if casilla_actual == 12:
			DatosUsuario.tomo_camino_corto = true
			if path_follow_derecha:
				path_follow_derecha.progress_ratio = 0.0 # Casilla 12 es el inicio del camino derecho
				path_follow_derecha.visible = true
			if path_follow:
				path_follow.visible = false
			print("🌟 ¡Minijuego de Casilla 12 Ganado! Atajo Derecho ($Path2D_Derecha) Activado desde su inicio (0.0).")
			
		DatosUsuario.pregunta_pendiente_db = false
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		
		# 🏆 Otorgar logro según el tipo de minijuego superado (solo si es nuevo)
		var datos_casilla = mapa_casillas.get(casilla_actual, {})
		var tipo_minijuego = datos_casilla.get("tipo", "")
		var id_logro = 0
		match tipo_minijuego:
			"asteroides": id_logro = 2
			"buscador_cajas": id_logro = 3
			"laboratorio": id_logro = 4
			"balanza": id_logro = 5
			"clasificador": id_logro = 6
			"circuitos": id_logro = 7
			
		if id_logro > 0 and not DatosUsuario.logros_poseidos.has(id_logro):
			ConexionSupabase.registrar_logro_ganado(id_logro)
			await _mostrar_popup_nuevo_logro(id_logro)
				
		boton_dado.disabled = false
		Menu_Volver.disabled = false
	else:
		print("❌ ¡Incorrecta! Regresando a casilla anterior: ", casilla_anterior)
		
		# 🪐 BIFURCACIÓN EN CASILLA 12: Si pierde el minijuego de la 12, se queda en el camino largo
		if casilla_actual == 12:
			DatosUsuario.tomo_camino_corto = false
			if path_follow:
				path_follow.visible = true
			if path_follow_derecha:
				path_follow_derecha.visible = false
			print("🛑 Minijuego de Casilla 12 Perdido. Tomando camino largo alrededor de Saturno.")
			
		var animos = ["animo1", "animo2", "animo3"]
		GestionAudio.reproducir_audio_local("Animos/" + animos.pick_random())
		
		await get_tree().create_timer(2.0).timeout
		
		$Interfaz.visible = false
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		DatosUsuario.pregunta_pendiente_db = false
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		_mover_ficha_visualmente(casilla_actual, true)
		
		boton_dado.disabled = false
		Menu_Volver.disabled = false

	boton_chat.disabled = false
	visible = true

func _mostrar_popup_nuevo_logro(id_logro: int):
	if not has_node("CapaLogro"): return
	if DatosUsuario.CATALOGO_LOGROS.has(id_logro):
		$CapaLogro/Control/TextureRect.texture = DatosUsuario.CATALOGO_LOGROS[id_logro]
		$CapaLogro/Control/TextureRect/Label.text = "¡Nuevo Logro Desbloqueado!"
		$CapaLogro.visible = true
		$CapaLogro/Control.scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($CapaLogro/Control, "scale", Vector2.ONE, 0.4)
		await get_tree().create_timer(3.0).timeout
		$CapaLogro.visible = false
		
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
# 🚀 Invocador del minijuego de asteroides
# 🚀 Invocador del minijuego de asteroides
func lanzar_minijuego_asteroides():
	if not minijuego_asteroides.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
		minijuego_asteroides.minijuego_finalizado.connect(_on_minijuego_resuelto)
		
	$CapaMinijuegos.visible = true
	minijuego_asteroides.visible = true
	
	# Solo pasamos el tema. El minijuego se encarga de leer DatosUsuario.banco_preguntas
	minijuego_asteroides.iniciar_minijuego("espacio")

# 🔦 Invocador del minijuego de las cajas en la oscuridad
func lanzar_minijuego_buscador():
	if not minijuego_buscador.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
		minijuego_buscador.minijuego_finalizado.connect(_on_minijuego_resuelto)
	
	minijuego_buscador.visible = true
	
	# Desactivamos momentáneamente la cámara del tablero principal
	$CamaraTablero.enabled = false 
	
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
	
func lanzar_minijuego_balanza():
	if minijuego_balanza == null and has_node("CapaMinijuegos/MinijuegoBalanza"):
		minijuego_balanza = $CapaMinijuegos/MinijuegoBalanza
	if minijuego_balanza:
		if not minijuego_balanza.has_signal("minijuego_finalizado"):
			var scr = load("res://Scripts_gd/Minijuegos/Minijuego_balanza/MinijuegoBalanza.gd")
			minijuego_balanza.set_script(scr)
		if not minijuego_balanza.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
			minijuego_balanza.minijuego_finalizado.connect(_on_minijuego_resuelto)
		$CapaMinijuegos.visible = true
		minijuego_balanza.visible = true
		minijuego_balanza.iniciar_minijuego("espacio")
	
func lanzar_minijuego_clasificador():
	if minijuego_clasificador == null and has_node("CapaMinijuegos/MinijuegoClasificador"):
		minijuego_clasificador = $CapaMinijuegos/MinijuegoClasificador
	if minijuego_clasificador:
		if not minijuego_clasificador.has_signal("minijuego_finalizado"):
			var scr = load("res://Scripts_gd/Minijuegos/Minijuego_clasificador/MinijuegoClasificador.gd")
			minijuego_clasificador.set_script(scr)
		if not minijuego_clasificador.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
			minijuego_clasificador.minijuego_finalizado.connect(_on_minijuego_resuelto)
		$CapaMinijuegos.visible = true
		minijuego_clasificador.visible = true
		minijuego_clasificador.iniciar_minijuego("espacio")
	
func lanzar_minijuego_circuitos():
	if minijuego_circuitos == null and has_node("CapaMinijuegos/MinijuegoCircuitos"):
		minijuego_circuitos = $CapaMinijuegos/MinijuegoCircuitos
	if minijuego_circuitos:
		if not minijuego_circuitos.has_signal("minijuego_finalizado"):
			var scr = load("res://Scripts_gd/Minijuegos/Minijuego_circuitos/MinijuegoCircuitos.gd")
			minijuego_circuitos.set_script(scr)
		if not minijuego_circuitos.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
			minijuego_circuitos.minijuego_finalizado.connect(_on_minijuego_resuelto)
		$CapaMinijuegos.visible = true
		minijuego_circuitos.visible = true
		minijuego_circuitos.iniciar_minijuego("espacio")

# 🚀 Invocador del minijuego de pilotaje de cabina (Bifurcación de Caminos)
func lanzar_minijuego_piloto():
	if minijuego_piloto == null and has_node("CapaMinijuegos/MinijuegoPilotoNave"):
		minijuego_piloto = $CapaMinijuegos/MinijuegoPilotoNave
	if minijuego_piloto:
		if not minijuego_piloto.has_signal("minijuego_finalizado"):
			var scr = load("res://Scripts_gd/Minijuegos/Minijuego_piloto/MinijuegoPilotoNave.gd")
			minijuego_piloto.set_script(scr)
		if not minijuego_piloto.minijuego_finalizado.is_connected(_on_minijuego_resuelto):
			minijuego_piloto.minijuego_finalizado.connect(_on_minijuego_resuelto)
		$CapaMinijuegos.visible = true
		minijuego_piloto.visible = true
		minijuego_piloto.iniciar_minijuego()
