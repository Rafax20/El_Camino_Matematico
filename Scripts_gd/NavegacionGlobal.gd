# res://Scripts_gd/NavegacionGlobal.gd
extends Node

var ruta_escena_previa: String = ""
var escena_destino: String = ""

func abrir_chatbot():
	# 🎯 DETECCIÓN AUTOMÁTICA Y PRECISA:
	# Guardamos la escena activa justo antes de cambiar al Chatbot.
	var escena_actual = get_tree().current_scene
	if escena_actual:
		ruta_escena_previa = escena_actual.scene_file_path
		print("📌 Ruta previa guardada automáticamente: ", ruta_escena_previa)
	
	# Cambiamos al Chatbot
	get_tree().change_scene_to_file("res://Escenas/Chatbox.tscn")


func volver_a_pantalla_previa():
	if ruta_escena_previa == "":
		get_tree().change_scene_to_file("res://Escenas/Menu.tscn")
		return

	# Detección inteligente para no usar pantalla de carga si volvemos al Menú o Álbum
	if "Menu" in ruta_escena_previa or "Album" in ruta_escena_previa:
		print("⚡ Regresando directamente a: ", ruta_escena_previa)
		get_tree().change_scene_to_file(ruta_escena_previa)
	else:
		print("⏳ Cargando escena mediante pantalla de carga: ", ruta_escena_previa)
		cambiar_escena_con_carga(ruta_escena_previa)


func cambiar_escena_con_carga(nueva_escena: String):
	escena_destino = nueva_escena
	get_tree().change_scene_to_file("res://Escenas/PantallaCarga.tscn")
