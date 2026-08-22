extends Control

signal pizarra_cerrada

# Rutas actualizadas según la jerarquía real de tu escena:
@onready var lienzo: Control = $MarcoPizarra/PanelFondo/LienzoDibujo
@onready var btn_cerrar: TextureButton = $MarcoPizarra/PanelFondo/BtnCerrar
@onready var btn_borrar: Button = $MarcoPizarra/PanelFondo/BtnBorrar

var tween_pizarra: Tween

func _ready():
	visible = false
	modulate.a = 0.0
	
	if btn_cerrar:
		btn_cerrar.pressed.connect(ocultar_pizarra)
	if btn_borrar and lienzo.has_method("limpiar_pizarra"):
		btn_borrar.pressed.connect(lienzo.limpiar_pizarra)

func toggle_pizarra():
	if visible and modulate.a > 0.5:
		ocultar_pizarra()
	else:
		mostrar_pizarra()

func mostrar_pizarra():
	if tween_pizarra and tween_pizarra.is_running():
		tween_pizarra.kill()
		
	visible = true
	tween_pizarra = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_pizarra.tween_property(self, "modulate:a", 1.0, 0.25)

func ocultar_pizarra():
	if tween_pizarra and tween_pizarra.is_running():
		tween_pizarra.kill()
		
	tween_pizarra = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_pizarra.tween_property(self, "modulate:a", 0.0, 0.25)
	tween_pizarra.finished.connect(func():
		visible = false
		pizarra_cerrada.emit()
	)
