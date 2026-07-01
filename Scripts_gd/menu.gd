extends Node2D

func _on_boton_jugar_pressed():
	get_tree().change_scene_to_file("res://Escenas/Tablero.tscn")

func _on_boton_iniciar_sesion_pressed():
	# En lugar de cambiar de escena, hacemos aparecer el Pop-up
	$CanvasLayer/Menu/Ventana_Autenticacion.aparecer()

func _on_boton_logros_pressed():
	get_tree().change_scene_to_file("res://Escenas/Album.tscn")
