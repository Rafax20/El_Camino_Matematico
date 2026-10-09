# res://Scripts_gd/TutorialTablero.gd
extends CanvasLayer
class_name TutorialTablero

signal tutorial_finalizado

@onready var contenedor = $Contenedor
@onready var fondo_oscuro = $Contenedor/FondoOscuro
@onready var panel_dialogo = $Contenedor/PanelDialogo
@onready var texto_mensaje = $Contenedor/PanelDialogo/VBoxContainer/TextoMensaje
@onready var label_paso = $Contenedor/PanelDialogo/VBoxContainer/HBoxFooter/LabelPaso
@onready var boton_siguiente = $Contenedor/PanelDialogo/VBoxContainer/HBoxFooter/BotonSiguiente
@onready var boton_saltar = $Contenedor/PanelDialogo/VBoxContainer/HBoxHeader/BotonSaltar
@onready var foco_resaltador = $Contenedor/FocoResaltador

var nodo_dado: CanvasItem = null
var nodo_chat: CanvasItem = null
var paso_actual: int = 1
var tween_pulso: Tween = null
var _inicializado: bool = false

const RUTA_CONFIG_TUTORIAL = "user://config_tutorial.json"

static func fue_completado() -> bool:
	if DatosUsuario and DatosUsuario.tutorial_tablero_visto:
		return true
	if FileAccess.file_exists(RUTA_CONFIG_TUTORIAL):
		var file = FileAccess.open(RUTA_CONFIG_TUTORIAL, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				return bool(json.data.get("tutorial_tablero_visto", false))
	return false

func _ready() -> void:
	layer = 25 # Capa superior por encima de la interfaz y casillas del tablero
	
	if boton_siguiente and not boton_siguiente.pressed.is_connected(_on_siguiente_pressed):
		boton_siguiente.pressed.connect(_on_siguiente_pressed)
	if boton_saltar and not boton_saltar.pressed.is_connected(_on_saltar_pressed):
		boton_saltar.pressed.connect(_on_saltar_pressed)
		
	# Si nadie invocó iniciar() en el mismo fotograma, ejecutar paso 1 por defecto de forma diferida
	call_deferred("_verificar_autoarranque")

func _verificar_autoarranque() -> void:
	if not _inicializado:
		_inicializado = true
		_mostrar_paso(1)

func iniciar(dado: CanvasItem = null, chat: CanvasItem = null) -> void:
	_inicializado = true
	nodo_dado = dado
	nodo_chat = chat
	paso_actual = 1
	visible = true
	
	if contenedor:
		contenedor.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(contenedor, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	
	_mostrar_paso(1)

func _mostrar_paso(paso: int) -> void:
	paso_actual = paso
	
	if paso == 1:
		if label_paso: label_paso.text = "Paso 1 de 2"
		if boton_siguiente: boton_siguiente.text = "Siguiente ➔"
		if texto_mensaje:
			texto_mensaje.text = "[b][color=#fbc34e]¡Hola, astronauta! Soy July.[/color][/b]\nPara comenzar tu aventura por el espacio, presiona el [color=#c678dd][b]botón morado del dado[/b][/color] para avanzar por las casillas del tablero."
		
		_enfocar_paso(1)
		if panel_dialogo:
			panel_dialogo.position = Vector2(130, 230)
		
		# Locución oficial de July
		if GestionAudio:
			GestionAudio.reproducir_audio_local("Tutorial/july_tutorial_dado")
			
	elif paso == 2:
		if label_paso: label_paso.text = "Paso 2 de 2"
		if boton_siguiente: boton_siguiente.text = "¡A jugar! 🚀"
		if texto_mensaje:
			texto_mensaje.text = "[b][color=#51b2a3]¡Excelente![/color][/b]\nY si alguna vez tienes dudas con una pregunta o reto matemático, pulsa este botón para [color=#51b2a3][b]hablar conmigo[/b][/color]. ¡Estaré lista para ayudarte! [color=#fbc34e]¡Mucho éxito![/color]"
		
		_enfocar_paso(2)
		if panel_dialogo:
			panel_dialogo.position = Vector2(160, 180)
		
		# Locución oficial de July
		if GestionAudio:
			GestionAudio.reproducir_audio_local("Tutorial/july_tutorial_chat")

func _obtener_rect_nodo(nodo: CanvasItem) -> Rect2:
	if not is_instance_valid(nodo):
		return Rect2()
	if nodo is Control:
		return (nodo as Control).get_global_rect()
	elif nodo is Node2D:
		return Rect2((nodo as Node2D).global_position, Vector2(100, 100))
	return Rect2()

func _enfocar_paso(paso: int) -> void:
	if not foco_resaltador: return
	foco_resaltador.visible = true
	
	if paso == 1:
		var rect_calc = _obtener_rect_nodo(nodo_dado)
		if rect_calc.size.x > 30 and rect_calc.size.y > 30:
			foco_resaltador.position = rect_calc.position - Vector2(12, 10)
			foco_resaltador.size = rect_calc.size + Vector2(24, 20)
		else:
			# Coordenadas calibradas con desplazamiento exacto sobre el botón morado
			foco_resaltador.position = Vector2(750, 405)
			foco_resaltador.size = Vector2(160, 155)
			
	elif paso == 2:
		var rect_calc = _obtener_rect_nodo(nodo_chat)
		if rect_calc.size.x > 30 and rect_calc.size.y > 30:
			foco_resaltador.position = rect_calc.position - Vector2(12, 10)
			foco_resaltador.size = rect_calc.size + Vector2(24, 20)
		else:
			# Coordenadas calibradas que enmarcan el botón superior de July IA
			foco_resaltador.position = Vector2(915, 330)
			foco_resaltador.size = Vector2(200, 140)
	
	# Animación de pulso continuo en el marco
	if tween_pulso:
		tween_pulso.kill()
	tween_pulso = create_tween().set_loops()
	tween_pulso.tween_property(foco_resaltador, "modulate:a", 0.35, 0.5).set_trans(Tween.TRANS_SINE)
	tween_pulso.tween_property(foco_resaltador, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func _on_siguiente_pressed() -> void:
	print("🖱️ [Tutorial] Botón Siguiente presionado. Paso actual: ", paso_actual)
	if paso_actual == 1:
		_mostrar_paso(2)
	else:
		finalizar()

func _on_saltar_pressed() -> void:
	print("🖱️ [Tutorial] Botón Saltar tutorial presionado.")
	finalizar()

func finalizar() -> void:
	print("🏁 [Tutorial] Concluyendo tutorial...")
	# 1. Guardar en memoria global para persistencia garantizada en sesiones Web/HTML5
	if DatosUsuario:
		DatosUsuario.tutorial_tablero_visto = true
		
	# 2. Detener locución si está reproduciéndose
	if GestionAudio and is_instance_valid(GestionAudio.audio_player) and GestionAudio.audio_player.playing:
		GestionAudio.audio_player.stop()
		
	# 3. Persistir en archivo local (user://) para sesiones futuras de escritorio o IndexedDB
	var file = FileAccess.open(RUTA_CONFIG_TUTORIAL, FileAccess.WRITE)
	if file:
		var datos = {"tutorial_tablero_visto": true}
		file.store_string(JSON.stringify(datos))
		file.close()
		print("💾 [Tutorial] Registrado en config_tutorial.json exitosamente.")
		
	if tween_pulso:
		tween_pulso.kill()
		
	if contenedor:
		var tween = create_tween()
		tween.tween_property(contenedor, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
		await tween.finished
		
	tutorial_finalizado.emit()
	queue_free()
