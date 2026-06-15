extends Node2D

#func _on_boton_jugar_pressed():
	## Cambia "res://tablero.tscn" por la ruta exacta de tu escena del tablero
	#get_tree().change_scene_to_file("res://Tablero.tscn")

func _on_boton_jugar_pressed():
	# En lugar de cambiar de escena, hacemos aparecer el Pop-up
	$CanvasLayer/Ventana_Autenticacion.aparecer()
