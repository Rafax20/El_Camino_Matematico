# res://Escenas/VentanaLogros.gd
extends Control

@onready var panel_marco: Control = $PanelMarco
@onready var btn_album: TextureButton = $PanelMarco/VBoxContainer/HBoxContainer/BtnAlbum
@onready var btn_logros_tablero: TextureButton = $PanelMarco/VBoxContainer/HBoxContainer/BtnLogrosTablero
@onready var btn_cerrar: TextureButton = $BtnCerrar

func _ready():
	visible = false
	modulate.a = 0.0
	
	# Conectar señales
	if btn_album: btn_album.pressed.connect(_on_btn_album_pressed)
	if btn_logros_tablero: btn_logros_tablero.pressed.connect(_on_btn_logros_tablero_pressed)
	if btn_cerrar: btn_cerrar.pressed.connect(desaparecer)

func aparecer():
	visible = true
	var tween = create_tween().set_parallel(true)
	# Transición de opacidad
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	
	# Efecto Pop-Up
	if panel_marco:
		panel_marco.pivot_offset = panel_marco.size / 2.0
		panel_marco.scale = Vector2(0.7, 0.7)
		tween.tween_property(panel_marco, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func desaparecer():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	visible = false

func _on_btn_album_pressed():
	await desaparecer()
	# Cambia a la escena de tu álbum de estampas/cartas
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Album.tscn")

func _on_btn_logros_tablero_pressed():
	await desaparecer()
	# Cambia a la nueva escena de trofeos/tableros completados
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/LogrosTablero.tscn")
