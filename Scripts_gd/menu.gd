# res://Scripts_gd/menu.gd
extends Node2D

@onready var ventana_como_jugar = $CanvasLayer/Menu/VentanaComoJugar
@onready var ventana_logros = $CanvasLayer/Menu/Ventana_Logros

func _on_boton_jugar_pressed():
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Tablero2.tscn")

func _on_boton_iniciar_sesion_pressed():
	$CanvasLayer/Menu/Ventana_Autenticacion.aparecer()

func _on_boton_logros_pressed():
	if ventana_logros:
		ventana_logros.aparecer()

func _on_boton_como_jugar_pressed():
	if ventana_como_jugar:
		ventana_como_jugar.aparecer()
	else:
		NavegacionGlobal.abrir_chatbot()
