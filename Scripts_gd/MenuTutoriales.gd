# res://Scripts_gd/MenuTutoriales.gd
extends Control

const VIDEOS_TUTORIALES = {
	"suma": {
		"titulo": "¡Aprendiendo a Sumar!",
		"ruta": "res://Videos/tutorial_suma.ogv"
	},
	"resta": {
		"titulo": "¡Aprendiendo a Restar!",
		"ruta": "res://Videos/tutorial_resta.ogv"
	},
	"multi": {
		"titulo": "Multiplicación Paso a Paso",
		"ruta": "res://Videos/tutorial_multiplicacion.ogv"
	},
	"divi": {
		"titulo": "Aprende a Dividir",
		"ruta": "res://Videos/tutorial_division.ogv"
	}
}

# Nodos dentro del CanvasLayer Modal
@onready var modal_video: Control = $ReproductorCanvas/ModalVideo
@onready var video_player: VideoStreamPlayer = $ReproductorCanvas/ModalVideo/VideoPlayer
@onready var btn_cerrar: TextureButton = $ReproductorCanvas/ModalVideo/BtnCerrar
@onready var btn_play_pausa: Button = $ReproductorCanvas/ModalVideo/BarraControles/BtnPlayPausa
@onready var btn_reiniciar: Button = $ReproductorCanvas/ModalVideo/BarraControles/BtnReiniciar

# Botones de la interfaz principal
@onready var btn_volver: TextureButton = $FondoEscolar/BtnVolver
@onready var btn_suma: TextureButton = $MarginContainer/VBoxContainerPrincipal/ContenidoDividido/PanelCategorias/BtnSuma
@onready var btn_resta: TextureButton = $MarginContainer/VBoxContainerPrincipal/ContenidoDividido/PanelCategorias/BtnResta
@onready var btn_multi: TextureButton = $MarginContainer/VBoxContainerPrincipal/ContenidoDividido/PanelCategorias/BtnMulti
@onready var btn_divi: TextureButton = $MarginContainer/VBoxContainerPrincipal/ContenidoDividido/PanelCategorias/BtnDivi

func _ready():
	# Iniciar oculto el popup de video
	modal_video.visible = false
	modal_video.modulate.a = 0.0

	# Conexión de botones del menú
	if btn_suma: btn_suma.pressed.connect(func(): abrir_video("suma"))
	if btn_resta: btn_resta.pressed.connect(func(): abrir_video("resta"))
	if btn_multi: btn_multi.pressed.connect(func(): abrir_video("multi"))
	if btn_divi: btn_divi.pressed.connect(func(): abrir_video("divi"))
	if btn_volver: btn_volver.pressed.connect(_volver_al_menu)

	# Conexión de controles del reproductor modal
	if btn_cerrar: btn_cerrar.pressed.connect(cerrar_video)
	if btn_play_pausa: btn_play_pausa.pressed.connect(_toggle_play_pausa)
	if btn_reiniciar: btn_reiniciar.pressed.connect(_reiniciar_video)

func abrir_video(clave_operacion: String):
	if not VIDEOS_TUTORIALES.has(clave_operacion): return
	
	var datos = VIDEOS_TUTORIALES[clave_operacion]
	var stream = load(datos["ruta"])
	
	if stream and video_player:
		video_player.stream = stream
		
		# 1. Hacer visible la ventana e iniciar la transición suave
		modal_video.visible = true
		var tween = create_tween()
		tween.tween_property(modal_video, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
		
		# 2. Esperar 1 segundo completo antes de darle play al video
		await get_tree().create_timer(1.0).timeout
		
		# 3. Iniciar reproducción si el usuario no cerró la ventana mientras esperaba
		if modal_video.visible:
			video_player.play()
			if btn_play_pausa:
				btn_play_pausa.text = "Pausa"

func cerrar_video():
	if video_player:
		video_player.stop()
		video_player.stream = null
	
	# Transición de salida suave
	var tween = create_tween()
	tween.tween_property(modal_video, "modulate:a", 0.0, 0.2)
	await tween.finished
	modal_video.visible = false

func _toggle_play_pausa():
	if video_player and video_player.is_playing():
		video_player.paused = not video_player.paused
		if btn_play_pausa:
			btn_play_pausa.text = "Reproducir" if video_player.paused else "Pausa"

func _reiniciar_video():
	if video_player:
		video_player.stop()
		video_player.play()
		video_player.paused = false
		if btn_play_pausa: btn_play_pausa.text = "Pausa"

func _volver_al_menu():
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Menu.tscn")
