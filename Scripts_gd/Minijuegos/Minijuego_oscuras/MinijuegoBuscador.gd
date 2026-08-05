# res://Escenas/Minijuegos/Minijuego_oscuras/MinijuegoBuscador.gd
extends Node2D

signal minijuego_finalizado(es_correcto)

@onready var nivel = $Nivel
@onready var jugador = $Nivel/Jugador
@onready var HUD = $HUD
@onready var interfaz_pregunta = $HUD/InterfazPregunta
@onready var label_operacion = $HUD/InterfazPregunta/LabelOperacion
@onready var line_edit_respuesta = $HUD/InterfazPregunta/LineEditRespuesta
@onready var label_gemas = $HUD/LabelGemas
@onready var contenedor_corazones = $HUD/ContenedorCorazones
@onready var luz_iluminacion_global = $Nivel/CanvasModulate # Controla la oscuridad

@export var escena_caja: PackedScene # 👈 Asigna CajaMatematica.tscn en el Inspector
@export var cantidad_cajas_a_generar: int = 4 # Genera 4 cajas de entre todos los puntos

@onready var puntos_spawn = $Nivel/PuntosSpawn
@onready var contenedor_cajas = $Nivel/ContenedorCajas

var textura_corazon_lleno = preload("res://assets/Imagenes/corazon_lleno.png")
var textura_corazon_vacio = preload("res://assets/Imagenes/corazon_vacio.png")

var gemas_obtenidas: int = 0
var gemas_requeridas: int = 2
var vidas_actuales: int = 3
var juego_activo: bool = false

var respuesta_correcta_actual: int = 0
var caja_actual_interactuando: Node = null

func iniciar_minijuego(datos_pregunta: Dictionary, tema: String = "espacio"):
	gemas_obtenidas = 0
	vidas_actuales = 3
	juego_activo = true
	nivel.visible = true
	HUD.visible = true
	
	# 🎲 Spawnea las cajas en ubicaciones distintas
	generar_cajas_aleatorias()
	
	_actualizar_hud_gemas()
	_actualizar_interfaz_corazones()
	
	if interfaz_pregunta: 
		interfaz_pregunta.visible = false
	
	if luz_iluminacion_global:
		luz_iluminacion_global.color = Color(0.08, 0.08, 0.15, 1.0)

func _on_caja_solicitar_operacion(caja_ref):
	if not juego_activo: return
	
	caja_actual_interactuando = caja_ref
	
	# Obtenemos una pregunta del banco global o parámetro
	var pregunta = _obtener_datos_operacion()
	respuesta_correcta_actual = int(pregunta.get("respuesta_correcta", 4))
	
	if label_operacion:
		label_operacion.text = str(pregunta.get("operacion", "2 + 2"))
		
	if line_edit_respuesta:
		line_edit_respuesta.text = ""
		
	if interfaz_pregunta:
		interfaz_pregunta.visible = true
		if line_edit_respuesta: line_edit_respuesta.grab_focus()

# Se activa al presionar "Aceptar" en la interfaz de la caja
func _on_boton_responder_pressed():
	if not caja_actual_interactuando or not juego_activo: return
	
	var respuesta_usuario = int(line_edit_respuesta.text.strip_edges())
	
	if respuesta_usuario == respuesta_correcta_actual:
		print("🎉 ¡Respuesta correcta! Gema obtenida.")
		gemas_obtenidas += 1
		_actualizar_hud_gemas()
		
		caja_actual_interactuando.abrir_caja()
		interfaz_pregunta.visible = false
		
		if gemas_obtenidas >= gemas_requeridas:
			print("🚪 ¡Has recolectado las 2 gemas! La puerta se abre.")
			_finalizar_juego(true)
	else:
		print("❌ Respuesta incorrecta.")
		vidas_actuales -= 1
		_actualizar_interfaz_corazones()
		interfaz_pregunta.visible = false
		
		if vidas_actuales <= 0:
			print("💀 Sin vidas. Minijuego fallado.")
			_finalizar_juego(false)

func _actualizar_hud_gemas():
	if label_gemas:
		label_gemas.text = "Gemas: " + str(gemas_obtenidas) + "/" + str(gemas_requeridas)

func _actualizar_interfaz_corazones():
	if not contenedor_corazones: return
	var corazones = contenedor_corazones.get_children()
	for i in range(corazones.size()):
		if corazones[i] is TextureRect:
			corazones[i].modulate = Color.WHITE
			if i < vidas_actuales:
				if textura_corazon_lleno: corazones[i].texture = textura_corazon_lleno
			else:
				if textura_corazon_vacio: 
					corazones[i].texture = textura_corazon_vacio
				else: 
					corazones[i].modulate = Color(0.2, 0.2, 0.2, 0.4)

func _finalizar_juego(es_exito: bool):
	juego_activo = false
	visible = false
	HUD.visible = false
	minijuego_finalizado.emit(es_exito)

func _obtener_datos_operacion() -> Dictionary:
	# Retorna una operación aleatoria según el nivel actual de DatosUsuario
	var lista = ConexionSupabase.lista_preguntas_local if "lista_preguntas_local" in ConexionSupabase else []
	if lista.size() > 0:
		return lista.pick_random()
	return {"operacion": "5 + 3", "respuesta_correcta": 8}
	
func generar_cajas_aleatorias():
	# 🧹 Limpiar cajas anteriores si existen
	for caja in contenedor_cajas.get_children():
		caja.queue_free()
		
	var posiciones_disponibles = puntos_spawn.get_children()
	if posiciones_disponibles.size() == 0 or not escena_caja:
		push_error("❌ No hay Marker2D en PuntosSpawn o no se asignó escena_caja")
		return

	# Mezclar las posiciones posibles para que varíen en cada partida
	posiciones_disponibles.shuffle()
	
	# Determinar cuántas cajas instanciar sin exceder los puntos de spawn
	var total_a_crear = mini(cantidad_cajas_a_generar, posiciones_disponibles.size())
	
	for i in range(total_a_crear):
		var nueva_caja = escena_caja.instantiate()
		var punto_marcador: Marker2D = posiciones_disponibles[i]
		
		# Posicionamos la caja en las coordenadas del Marker2D
		nueva_caja.position = punto_marcador.position
		
		# Conectamos la señal de la caja recién creada
		nueva_caja.solicitar_operacion.connect(_on_caja_solicitar_operacion)
		
		# Agregamos la caja al contenedor
		contenedor_cajas.add_child(nueva_caja)
