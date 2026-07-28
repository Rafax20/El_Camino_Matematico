# res://Scripts_gd/NavegacionGlobal.gd
extends Node

var ruta_escena_previa: String = ""
var escena_destino: String = ""
var progreso_carga: Array = []

func abrir_chatbot():
	var escena_actual = get_tree().current_scene
	if escena_actual:
		ruta_escena_previa = escena_actual.scene_file_path
		print("📌 Ruta previa guardada automáticamente: ", ruta_escena_previa)
	
	get_tree().change_scene_to_file("res://Escenas/Chatbox.tscn")

func volver_a_pantalla_previa():
	if ruta_escena_previa == "":
		get_tree().change_scene_to_file("res://Escenas/Menu.tscn")
		return

	if "Menu" in ruta_escena_previa or "Album" in ruta_escena_previa:
		print("⚡ Regresando directamente a: ", ruta_escena_previa)
		get_tree().change_scene_to_file(ruta_escena_previa)
	else:
		print("⏳ Cargando escena mediante pantalla de carga: ", ruta_escena_previa)
		cambiar_escena_con_carga(ruta_escena_previa)

# 🛠️ CAMBIO CLAVE 1: Iniciar carga en segundo plano
func cambiar_escena_con_carga(nueva_escena: String):
	escena_destino = nueva_escena
	# ⚡ Cambio instantáneo sin procesar nada pesado todavía:
	get_tree().change_scene_to_file("res://Escenas/PantallaCarga.tscn")

# 🛠️ CAMBIO CLAVE 2: Obtener el estado actual (para usarlo en PantallaCarga.gd)
func obtener_estado_carga() -> float:
	var estado = ResourceLoader.load_threaded_get_status(escena_destino, progreso_carga)
	if progreso_carga.size() > 0:
		return progreso_carga[0] # Retorna un float de 0.0 a 1.0
	return 0.0

func esta_lista_la_escena() -> bool:
	return ResourceLoader.load_threaded_get_status(escena_destino) == ResourceLoader.THREAD_LOAD_LOADED

func finalizar_cambio_escena():
	var escena_empaquetada = ResourceLoader.load_threaded_get(escena_destino)
	get_tree().change_scene_to_packed(escena_empaquetada)
