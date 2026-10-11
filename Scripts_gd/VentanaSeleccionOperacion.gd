# res://Scripts_gd/VentanaSeleccionOperacion.gd
extends Control

signal seleccion_completada(operacion: String, modo: String)

# Referencias a sub-vistas del panel
@onready var panel_marco: Control = $PanelMarco
@onready var btn_cerrar: TextureButton = $BtnCerrar

@onready var vista_operaciones: Control = $PanelMarco/VistaOperaciones
@onready var vista_submodo: Control = $PanelMarco/VistaSubmodo
@onready var vista_diagnostico: Control = $PanelMarco/VistaDiagnostico

# Botones de Vista 1: Operaciones
@onready var btn_sumas: TextureButton = $PanelMarco/VistaOperaciones/VBoxLista/BtnSumas
@onready var btn_restas: TextureButton = $PanelMarco/VistaOperaciones/VBoxLista/BtnRestas
@onready var btn_mult: TextureButton = $PanelMarco/VistaOperaciones/VBoxLista/BtnMultiplicacion
@onready var btn_div: TextureButton = $PanelMarco/VistaOperaciones/VBoxLista/BtnDivision

# Botones de Vista 2: Submodo
@onready var lbl_submodo_titulo: Label = $PanelMarco/VistaSubmodo/TituloSubmodo
@onready var btn_solo: TextureButton = $PanelMarco/VistaSubmodo/HBoxSubmodo/BtnSolo
@onready var btn_todas: TextureButton = $PanelMarco/VistaSubmodo/HBoxSubmodo/BtnTodas
@onready var btn_volver_submodo: Button = $PanelMarco/VistaSubmodo/BtnVolverSubmodo

# Elementos de Vista 3: Diagnóstico
@onready var lbl_diag_titulo: Label = $PanelMarco/VistaDiagnostico/TituloDiagnostico
@onready var lbl_diag_detalle: Label = $PanelMarco/VistaDiagnostico/LabelDetalle
@onready var lbl_diag_progreso: Label = $PanelMarco/VistaDiagnostico/LabelProgreso
@onready var lbl_diag_pregunta: Label = $PanelMarco/VistaDiagnostico/PanelPregunta/LabelPregunta
@onready var contenedor_opciones: GridContainer = $PanelMarco/VistaDiagnostico/GridOpciones
@onready var lbl_diag_feedback: Label = $PanelMarco/VistaDiagnostico/LabelFeedback
@onready var panel_acciones_fallo: HBoxContainer = $PanelMarco/VistaDiagnostico/PanelAccionesFallo
@onready var btn_repasar: Button = $PanelMarco/VistaDiagnostico/PanelAccionesFallo/BtnRepasar
@onready var btn_reintentar: Button = $PanelMarco/VistaDiagnostico/PanelAccionesFallo/BtnReintentar
@onready var btn_volver_diagnostico: Button = $PanelMarco/VistaDiagnostico/BtnVolverDiagnostico

# Variables de estado interno
var operacion_elegida: String = "suma"
var modo_elegido: String = "solo"

# Cola de diagnóstico: [{"cat": "suma", "nombre": "Suma"}, ...]
var lista_requisitos: Array = []
var indice_requisito_actual: int = 0
var pregunta_diagnostico_actual: Dictionary = {}
var respuesta_correcta_str: String = ""
var botones_opcion: Array = []

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	
	# Conexión de botones principales
	btn_cerrar.pressed.connect(desaparecer)
	
	btn_sumas.pressed.connect(func(): _on_operacion_seleccionada("suma"))
	btn_restas.pressed.connect(func(): _on_operacion_seleccionada("resta"))
	btn_mult.pressed.connect(func(): _on_operacion_seleccionada("multiplicacion"))
	btn_div.pressed.connect(func(): _on_operacion_seleccionada("division"))
	
	btn_solo.pressed.connect(func(): _on_submodo_seleccionado("solo"))
	btn_todas.pressed.connect(func(): _on_submodo_seleccionado("todas"))
	btn_volver_submodo.pressed.connect(_mostrar_vista_operaciones)
	
	if btn_volver_diagnostico:
		btn_volver_diagnostico.pressed.connect(_mostrar_vista_operaciones)
	if btn_repasar:
		btn_repasar.pressed.connect(_on_repasar_nivel_anterior)
	if btn_reintentar:
		btn_reintentar.pressed.connect(_iniciar_evaluacion_diagnostica)

	# Cache de botones de opciones
	if contenedor_opciones:
		for hijo in contenedor_opciones.get_children():
			if hijo is Button:
				botones_opcion.append(hijo)
				hijo.pressed.connect(func(): _on_opcion_respondida(hijo))

func aparecer() -> void:
	visible = true
	_mostrar_vista_operaciones()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	
	if panel_marco:
		panel_marco.pivot_offset = panel_marco.size / 2.0
		panel_marco.scale = Vector2(0.7, 0.7)
		tween.tween_property(panel_marco, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func desaparecer() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	visible = false

# --- TRANSICIÓN DE VISTAS ---
func _mostrar_vista_operaciones() -> void:
	vista_operaciones.visible = true
	vista_submodo.visible = false
	vista_diagnostico.visible = false

func _on_operacion_seleccionada(op: String) -> void:
	operacion_elegida = op
	var nombre_mostrado = _obtener_nombre_operacion(op).to_upper()
	
	lbl_submodo_titulo.text = "¿CÓMO QUIERES PRACTICAR " + nombre_mostrado + "?"
	
	vista_operaciones.visible = false
	vista_submodo.visible = true
	vista_diagnostico.visible = false
	
	# 🎙️ Voz de July: 'Elige cómo deseas aprender'
	if GestionAudio:
		GestionAudio.reproducir_audio_local("elige_como_aprender")

func _on_submodo_seleccionado(modo: String) -> void:
	modo_elegido = modo
	
	# Jerarquía pedagógica:
	# Sumas (Nivel 1): Sin requisito previo, pasa directo.
	# Restas (Nivel 2): 1 pregunta diagnóstica de Suma.
	# Multiplicación (Nivel 3): 1 de Suma + 1 de Resta.
	# División (Nivel 4): 1 de Suma + 1 de Resta + 1 de Multiplicación.
	lista_requisitos.clear()
	match operacion_elegida:
		"suma":
			# Acceso directo al nivel base
			_iniciar_partida()
			return
		"resta":
			lista_requisitos = [
				{"cat": "suma", "nombre": "Sumas"}
			]
		"multiplicacion":
			lista_requisitos = [
				{"cat": "suma", "nombre": "Sumas"},
				{"cat": "resta", "nombre": "Restas"}
			]
		"division":
			lista_requisitos = [
				{"cat": "suma", "nombre": "Sumas"},
				{"cat": "resta", "nombre": "Restas"},
				{"cat": "multiplicacion", "nombre": "Multiplicación"}
			]
			
	_iniciar_evaluacion_diagnostica()

func _iniciar_evaluacion_diagnostica() -> void:
	indice_requisito_actual = 0
	vista_operaciones.visible = false
	vista_submodo.visible = false
	vista_diagnostico.visible = true
	if panel_acciones_fallo: panel_acciones_fallo.visible = false
	if lbl_diag_feedback: lbl_diag_feedback.text = ""
	
	_cargar_siguiente_pregunta_diagnostico()

func _cargar_siguiente_pregunta_diagnostico() -> void:
	if panel_acciones_fallo: panel_acciones_fallo.visible = false
	if lbl_diag_feedback: lbl_diag_feedback.text = ""
	
	var req = lista_requisitos[indice_requisito_actual]
	var total_req = lista_requisitos.size()
	var paso_actual = indice_requisito_actual + 1
	
	lbl_diag_titulo.text = "¡COMPROBEMOS TUS PODERES MATEMÁTICOS!"
	lbl_diag_detalle.text = "Responde correctamente para desbloquear: %s" % _obtener_nombre_operacion(operacion_elegida)
	lbl_diag_progreso.text = "Desafío %d de %d: %s" % [paso_actual, total_req, req["nombre"]]
	
	# Extraer 1 pregunta pedagógica del banco
	var preguntas = DatosUsuario.obtener_preguntas_diagnostico(req["cat"], 1)
	if preguntas.is_empty():
		# Seguro si no hay
		pregunta_diagnostico_actual = {"operacion": "10 + 5", "respuesta_correcta": "15", "opcion_falsa1": "12", "opcion_falsa2": "14", "opcion_falsa3": "16"}
	else:
		pregunta_diagnostico_actual = preguntas[0]
		
	var texto_op = str(pregunta_diagnostico_actual.get("operacion", pregunta_diagnostico_actual.get("pregunta", "2 + 2")))
	lbl_diag_pregunta.text = texto_op + " = ?"
	
	respuesta_correcta_str = str(pregunta_diagnostico_actual.get("respuesta_correcta", pregunta_diagnostico_actual.get("opcion_correcta", "4"))).strip_edges()
	var falsa1 = str(pregunta_diagnostico_actual.get("opcion_falsa1", "3")).strip_edges()
	var falsa2 = str(pregunta_diagnostico_actual.get("opcion_falsa2", "5")).strip_edges()
	var falsa3 = str(pregunta_diagnostico_actual.get("opcion_falsa3", "6")).strip_edges()
	
	var opciones = [respuesta_correcta_str, falsa1, falsa2, falsa3]
	opciones.shuffle()
	
	for i in range(botones_opcion.size()):
		var btn = botones_opcion[i] as Button
		if i < opciones.size():
			btn.visible = true
			btn.disabled = false
			btn.text = opciones[i]
			btn.modulate = Color.WHITE
		else:
			btn.visible = false

func _on_opcion_respondida(boton_presionado: Button) -> void:
	# Bloquear interacción
	for btn in botones_opcion:
		btn.disabled = true
		
	var respuesta_jugador = boton_presionado.text.strip_edges()
	var es_correcta = (respuesta_jugador == respuesta_correcta_str)
	
	if es_correcta:
		boton_presionado.modulate = Color(0.3, 1.0, 0.4) # Verde éxito
		if GestionAudio:
			GestionAudio.reproducir_elogio()
			
		lbl_diag_feedback.text = "🎉 ¡Excelente! ¡Respuesta correcta!"
		lbl_diag_feedback.modulate = Color(0.3, 1.0, 0.4)
		
		await get_tree().create_timer(1.3).timeout
		indice_requisito_actual += 1
		
		if indice_requisito_actual >= lista_requisitos.size():
			# Completó todos los requisitos con éxito
			lbl_diag_feedback.text = "🚀 ¡Felicidades! ¡Estás listo para dominar %s!" % _obtener_nombre_operacion(operacion_elegida)
			await get_tree().create_timer(1.2).timeout
			_iniciar_partida()
		else:
			_cargar_siguiente_pregunta_diagnostico()
	else:
		boton_presionado.modulate = Color(1.0, 0.35, 0.35) # Rojo error
		for btn in botones_opcion:
			if btn.text.strip_edges() == respuesta_correcta_str:
				btn.modulate = Color(0.3, 1.0, 0.4) # Mostrar la correcta
				
		if GestionAudio:
			var animos = ["animo1", "animo2", "animo3"]
			GestionAudio.reproducir_audio_local("Animos/" + animos.pick_random())
			
		var req_fallado = lista_requisitos[indice_requisito_actual]
		lbl_diag_feedback.text = "💡 La respuesta correcta era: %s\nTe recomendamos repasar %s antes de avanzar." % [respuesta_correcta_str, req_fallado["nombre"]]
		lbl_diag_feedback.modulate = Color(1.0, 0.85, 0.35)
		
		# Mostrar opciones pedagógicas
		if panel_acciones_fallo:
			panel_acciones_fallo.visible = true
			if btn_repasar:
				btn_repasar.text = "Repasar " + req_fallado["nombre"]

func _on_repasar_nivel_anterior() -> void:
	var req_fallado = lista_requisitos[indice_requisito_actual]
	operacion_elegida = req_fallado["cat"]
	modo_elegido = "solo"
	print("🔄 [Pedagógico] Redirigiendo a repasar nivel anterior: ", operacion_elegida)
	_iniciar_partida()

func _iniciar_partida() -> void:
	DatosUsuario.configurar_modo_operacion(operacion_elegida, modo_elegido)
	seleccion_completada.emit(operacion_elegida, modo_elegido)
	await desaparecer()
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Tablero2.tscn")

func _obtener_nombre_operacion(op: String) -> String:
	match op:
		"suma": return "Sumas"
		"resta": return "Restas"
		"multiplicacion": return "Multiplicación"
		"division": return "División"
		_: return "Operaciones"
