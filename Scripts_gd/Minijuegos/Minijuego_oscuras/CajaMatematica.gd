# res://Escenas/Minijuegos/Minijuego_oscuras/CajaMatematica.gd
extends Area2D

signal solicitar_operacion(caja_ref)

@export var contiene_gema: bool = true
var ya_abierta: bool = false
var jugador_cerca: bool = false

@onready var sprite = $Sprite2D
@onready var indicador_tecla = $Sprite2D/IndicadorTecla

# Referencia al botón táctil en el HUD global o minijuego
var btn_interactuar_touch: TouchScreenButton = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if indicador_tecla: 
		indicador_tecla.visible = false
		
	# Buscar el botón de interacción en la escena
	var hud_touch = get_tree().get_nodes_in_group("boton_interactuar_touch")
	if not hud_touch.is_empty():
		btn_interactuar_touch = hud_touch[0]
		if btn_interactuar_touch.is_connected("pressed", _on_boton_touch_presionado):
			btn_interactuar_touch.disconnect("pressed", _on_boton_touch_presionado)
		btn_interactuar_touch.pressed.connect(_on_boton_touch_presionado)

func _unhandled_input(event):
	if jugador_cerca and not ya_abierta:
		var es_accion = event.is_action_pressed("ui_accept") or event.is_action_pressed("interactuar")
		if es_accion:
			get_viewport().set_input_as_handled()
			_interactuar()

func _on_body_entered(body):
	if body.is_in_group("jugador") and not ya_abierta:
		jugador_cerca = true
		
		# Mostrar la tecla si existe el nodo
		if indicador_tecla: 
			indicador_tecla.visible = true
			
		# Activar el botón móvil de manera independiente si la plataforma lo requiere
		if (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()) and btn_interactuar_touch:
			btn_interactuar_touch.visible = true

func _on_body_exited(body):
	if body.is_in_group("jugador"):
		jugador_cerca = false
		if indicador_tecla: 
			indicador_tecla.visible = false
		if btn_interactuar_touch:
			btn_interactuar_touch.visible = false

func _on_boton_touch_presionado():
	if jugador_cerca and not ya_abierta:
		_interactuar()

func _interactuar():
	if btn_interactuar_touch:
		btn_interactuar_touch.visible = false
	solicitar_operacion.emit(self)

func abrir_caja():
	ya_abierta = true
	jugador_cerca = false
	if indicador_tecla: 
		indicador_tecla.visible = false
	if btn_interactuar_touch:
		btn_interactuar_touch.visible = false
	sprite.modulate = Color(0.4, 0.4, 0.4, 0.8)
