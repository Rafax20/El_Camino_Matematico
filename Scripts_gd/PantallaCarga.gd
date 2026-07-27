# res://Scripts_gd/PantallaCarga.gd
extends Control

var ruta_destino: String = ""
var lista_progreso: Array = []
@onready var barra_progreso = $BarraProgreso # Si tienes una ProgressBar o TextureProgressBar (opcional)

func _ready():
	ruta_destino = NavegacionGlobal.escena_destino
	
	# ⏳ PASO CRÍTICO PARA WEB/ITCH.IO:
	# Forzamos una espera de 2 cuadros para asegurar que el navegador 
	# haya dibujado completamente la interfaz de la pantalla de carga.
	await get_tree().process_frame
	await get_tree().process_frame

func _process(_delta):
	if ruta_destino == "": return
	
	# Monitoreamos el estado de la carga en segundo plano
	var estado = ResourceLoader.load_threaded_get_status(ruta_destino, lista_progreso)
	
	# Opcional: Si tienes una barra de progreso, actualízala aquí
	if barra_progreso and lista_progreso.size() > 0:
		barra_progreso.value = lista_progreso[0] * 100
	
	# Cuando el estado indica que la escena está 100% cargada en RAM:
	if estado == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false) # Desactivamos el _process para evitar llamadas dobles
		
		# ⏳ Tiempo mínimo de cortesía (0.5 segundos) para que la pantalla 
		# no desaparezca de golpe si la carga fue ultra rápida
		await get_tree().create_timer(0.5).timeout
		
		# Cambiamos a la escena destino empaquetada
		var escena_cargada = ResourceLoader.load_threaded_get(ruta_destino)
		get_tree().change_scene_to_packed(escena_cargada)
