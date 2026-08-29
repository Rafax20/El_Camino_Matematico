# res://Scripts_gd/PantallaCarga.gd
extends Control

var ruta_destino: String = ""
var lista_progreso: Array = []
@onready var barra_progreso: TextureProgressBar = $BarraProgreso
@onready var label_estado: Label = $Label

var progreso_visual: float = 0.0

func _ready():
	ruta_destino = NavegacionGlobal.escena_destino
	
	if barra_progreso:
		barra_progreso.value = 0
		
	if label_estado:
		label_estado.text = "CARGANDO... 0%\nCONECTANDO CON EL MÓDULO DEL COMPAÑERO...\nESPERANDO PREGUNTAS DEL ESPACIO..."
	
	# 🚀 Si las preguntas aún no están en RAM, iniciamos la descarga asíncrona de inmediato
	if DatosUsuario.banco_preguntas.size() == 0:
		ConexionSupabase.descargar_preguntas()
	
	# ⏳ Espera de 2 cuadros para asegurar renderizado en pantalla
	await get_tree().process_frame
	await get_tree().process_frame

	# Iniciar carga de la escena en segundo plano
	if ruta_destino != "":
		ResourceLoader.load_threaded_request(ruta_destino)

func _process(delta):
	if ruta_destino == "": return
	
	# Monitoreamos el estado de carga en segundo plano
	var estado = ResourceLoader.load_threaded_get_status(ruta_destino, lista_progreso)
	var progreso_real = 0.0
	if lista_progreso.size() > 0:
		progreso_real = lista_progreso[0] * 100.0
	
	# Interpolación suave para que los asteroides se vayan pintando progresivamente
	progreso_visual = move_toward(progreso_visual, progreso_real, delta * 80.0)
	
	if barra_progreso:
		barra_progreso.value = progreso_visual
		
	if label_estado:
		var p_int = int(progreso_visual)
		var fase_texto = "CONECTANDO CON EL MÓDULO DEL COMPAÑERO..."
		if p_int > 30 and p_int <= 70:
			fase_texto = "CALIBRANDO BANCO DE PREGUNTAS Y GALAXIAS..."
		elif p_int > 70:
			fase_texto = "¡PREPARANDO SISTEMAS DE NAVEGACIÓN!"
			
		label_estado.text = "CARGANDO... %d%%\n%s\nESPERANDO PREGUNTAS DEL ESPACIO..." % [p_int, fase_texto]
	
	# Validamos si las preguntas ya están en RAM (o si estamos offline)
	var preguntas_listas = DatosUsuario.banco_preguntas.size() > 0 or not DatosUsuario.esta_conectado_a_la_nube
	
	# Cuando la escena esté 100% lista, el progreso visual haya llegado a la meta y las preguntas estén listas
	if estado == ResourceLoader.THREAD_LOAD_LOADED and progreso_visual >= 95.0 and preguntas_listas:
		set_process(false)
		if barra_progreso: barra_progreso.value = 100
		if label_estado:
			label_estado.text = "CARGANDO... 100%\n¡MISIÓN LISTA PARA EL DESPEGUE!\nESPERANDO PREGUNTAS DEL ESPACIO..."
			
		await get_tree().create_timer(0.3).timeout
		var escena_cargada = ResourceLoader.load_threaded_get(ruta_destino)
		get_tree().change_scene_to_packed(escena_cargada)
