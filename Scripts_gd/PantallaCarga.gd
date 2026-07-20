# res://Scripts_gd/PantallaCarga.gd
extends Control

var ruta_destino: String = ""

func _ready():
	# Leemos la ruta que guardó NavegacionGlobal
	ruta_destino = NavegacionGlobal.escena_destino
	
	if ruta_destino != "":
		# Empezamos a cargar la escena elegida en segundo plano
		ResourceLoader.load_threaded_request(ruta_destino)

func _process(_delta):
	if ruta_destino == "": return
	
	# Revisamos si ya terminó de cargar
	var estado = ResourceLoader.load_threaded_get_status(ruta_destino)
	
	if estado == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		# Cambiamos a la escena destino ya cargada
		var escena_cargada = ResourceLoader.load_threaded_get(ruta_destino)
		get_tree().change_scene_to_packed(escena_cargada)
