# res://Scripts_gd/menu.gd
extends Node2D

@onready var ventana_como_jugar = $CanvasLayer/Menu/VentanaComoJugar
@onready var ventana_logros = $CanvasLayer/Menu/Ventana_Logros
@onready var ventana_login = $CanvasLayer/Menu/Ventana_Autenticacion
@onready var texto_sesion = $CanvasLayer/Menu/Texto_Sesion if has_node("CanvasLayer/Menu/Texto_Sesion") else null

func _ready() -> void:
	# 🌌 Iniciar música de fondo global al entrar al menú (persiste entre escenas vía autoload)
	if GestionAudio:
		GestionAudio.iniciar_musica_global(-18.0)
		
	if ventana_login and ventana_login.has_signal("sesion_actualizada"):
		if not ventana_login.sesion_actualizada.is_connected(_on_sesion_cambiada):
			ventana_login.sesion_actualizada.connect(_on_sesion_cambiada)
			
	_actualizar_indicador_sesion()

func _actualizar_indicador_sesion():
	if not texto_sesion: return
	if DatosUsuario.esta_conectado_a_la_nube and DatosUsuario.nombre_usuario != "":
		texto_sesion.text = "[center][b][color=#51b2a3]👤 " + DatosUsuario.nombre_usuario + "[/color][/b]\n[color=#fbc34e]Cerrar Sesión[/color][/center]"
	else:
		texto_sesion.text = "[center][b]Iniciar Sesión[/b][/center]"

func _on_sesion_cambiada(_conectado: bool):
	_actualizar_indicador_sesion()

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
