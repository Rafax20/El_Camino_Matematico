# res://Scripts_gd/Tablero.gd
extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
@onready var boton_dado = $BotonDado 

var total_casillas = 23
var casilla_actual = 0
var casilla_anterior = 0

var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0
var servidor_listo: bool = false

# Coordenadas de ratio de tu Path2D para cada casilla
var casilla_destino = [
	0.0537, 0.107, 0.1521, 0.1972, 0.2423, 0.2874, 0.3407, 0.3776, 0.4145, 0.4473,
	0.4924, 0.5293, 0.5744, 0.6113, 0.6646, 0.7097, 0.7548, 0.7999, 0.8368, 0.8737, 
	0.9106, 0.9557, 1
]

func _ready():
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
	if not servidor_listo or lista_preguntas.size() == 0: return
	
	boton_dado.disabled = true
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
	
	if pregunta_actual_indice >= lista_preguntas.size():
		lista_preguntas.shuffle()
		pregunta_actual_indice = 0
		
	var datos_pregunta = lista_preguntas[pregunta_actual_indice]
	$Interfaz.visible = true
	$Interfaz.actualizar_datos_pantalla(datos_pregunta)
	pregunta_actual_indice += 1

# ==========================================
# ⚙️ RESPUESTA DEL NIÑO DESDE LA INTERFAZ
# ==========================================
func _on_interfaz_respuesta_completada(es_correcta: bool, tiempo_tardado: float) -> void:
	$Interfaz.visible = false
	
	# Guardamos que ya no debe preguntas en local
	DatosUsuario.pregunta_pendiente_db = false
	
	if es_correcta:
		print("🎯 ¡Correcta! El niño tardó: ", tiempo_tardado, " segundos.")
		
		# 🧠 AQUÍ PODRÁS LLAMAR A TU IA PRÓXIMAMENTE:
		# var nueva_dificultad = calcular_proxima_dificultad(es_correcta, tiempo_tardado)
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		boton_dado.disabled = false
	else:
		print("❌ ¡Incorrecta! Regresando a casilla anterior: ", casilla_anterior)
		casilla_actual = casilla_anterior
		DatosUsuario.casilla_actual_db = casilla_actual
		
		ConexionSupabase.actualizar_progreso_en_nube(casilla_actual, false)
		
		# Animación regresando la ficha físicamente
		await _mover_ficha_visualmente(casilla_actual, false)
		boton_dado.disabled = false

func enviar_puntuacion(nombre_jugador: String, puntos: int):
	var datos = {
		"user_id": DatosUsuario.usuario_id_db,
		"nombre": nombre_jugador, 
		"casilla": puntos
	}
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	Supabase.database.query(consulta)
