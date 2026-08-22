# res://Escenas/VentanaComoJugar.gd (o la ruta donde guardes tus scripts de interfaz)
extends Control

signal abrir_tutoriales_solicitado

@onready var panel_marco: Control = $PanelMarco
@onready var btn_chatbot: TextureButton = $PanelMarco/VBoxContainer/HBoxContainer/BtnChatbot
@onready var btn_tutoriales: TextureButton = $PanelMarco/VBoxContainer/HBoxContainer/BtnTutoriales
@onready var btn_cerrar: TextureButton = $BtnCerrar

func _ready():
	visible = false
	modulate.a = 0.0
	
	# Conectar señales
	btn_chatbot.pressed.connect(_on_btn_chatbot_pressed)
	btn_tutoriales.pressed.connect(_on_btn_tutoriales_pressed)
	btn_cerrar.pressed.connect(desaparecer)

func aparecer():
	visible = true
	var tween = create_tween().set_parallel(true)
	# Transición suave de opacidad
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	
	# Animación Pop-Up de la ventana centrada
	if panel_marco:
		panel_marco.pivot_offset = panel_marco.size / 2.0
		panel_marco.scale = Vector2(0.7, 0.7)
		tween.tween_property(panel_marco, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func desaparecer():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	visible = false

func _on_btn_chatbot_pressed():
	await desaparecer()
	NavegacionGlobal.abrir_chatbot()

func _on_btn_tutoriales_pressed():
	await desaparecer()
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Menu_Tutoriales.tscn")
