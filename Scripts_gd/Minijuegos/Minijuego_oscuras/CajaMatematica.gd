# res://Escenas/Minijuegos//Minijuego_oscuras/CajaMatematica.gd
extends Area2D

signal solicitar_operacion(caja_ref)

@export var contiene_gema: bool = true
var ya_abierta: bool = false
var jugador_cerca: bool = false

@onready var sprite = $Sprite2D
@onready var indicador_tecla = $Sprite2D/IndicadorTecla # Un Label o Sprite con "E" o "Tocar"

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if indicador_tecla: indicador_tecla.visible = false

func _unhandled_input(event):
	if jugador_cerca and not ya_abierta:
		var es_accion = event.is_action_pressed("ui_accept") or event.is_action_pressed("interactuar")
		if es_accion:
			get_viewport().set_input_as_handled()
			solicitar_operacion.emit(self)

func _on_body_entered(body):
	if body.is_in_group("jugador") and not ya_abierta:
		jugador_cerca = true
		if indicador_tecla: indicador_tecla.visible = true

func _on_body_exited(body):
	if body.is_in_group("jugador"):
		jugador_cerca = false
		if indicador_tecla: indicador_tecla.visible = false

func abrir_caja():
	ya_abierta = true
	jugador_cerca = false
	if indicador_tecla: indicador_tecla.visible = false
	# Cambia la modulación o la textura a caja abierta
	sprite.modulate = Color(0.4, 0.4, 0.4, 0.8)
