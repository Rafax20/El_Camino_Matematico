# res://Scripts_gd/VentanaAjustesAudio.gd
extends Control

@onready var panel_marco = $PanelMarco
@onready var btn_cerrar = $BtnCerrar

# Sliders
@onready var slider_master = $PanelMarco/VBoxContainer/GridSliders/SliderMaster
@onready var lbl_val_master = $PanelMarco/VBoxContainer/GridSliders/LblValMaster

@onready var slider_musica = $PanelMarco/VBoxContainer/GridSliders/SliderMusica
@onready var lbl_val_musica = $PanelMarco/VBoxContainer/GridSliders/LblValMusica

@onready var slider_voz = $PanelMarco/VBoxContainer/GridSliders/SliderVoz
@onready var lbl_val_voz = $PanelMarco/VBoxContainer/GridSliders/LblValVoz
@onready var btn_probar_voz = $PanelMarco/VBoxContainer/GridSliders/BtnProbarVoz

@onready var slider_sfx = $PanelMarco/VBoxContainer/GridSliders/SliderSFX
@onready var lbl_val_sfx = $PanelMarco/VBoxContainer/GridSliders/LblValSFX
@onready var btn_probar_sfx = $PanelMarco/VBoxContainer/GridSliders/BtnProbarSFX

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	
	if btn_cerrar:
		btn_cerrar.pressed.connect(desaparecer)
		
	# Conexiones de sliders
	slider_master.value_changed.connect(_on_slider_master_changed)
	slider_musica.value_changed.connect(_on_slider_musica_changed)
	slider_voz.value_changed.connect(_on_slider_voz_changed)
	slider_sfx.value_changed.connect(_on_slider_sfx_changed)
	
	if btn_probar_voz:
		btn_probar_voz.pressed.connect(_on_probar_voz_pressed)
	if btn_probar_sfx:
		btn_probar_sfx.pressed.connect(_on_probar_sfx_pressed)

func aparecer() -> void:
	_sincronizar_valores()
	visible = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	
	if panel_marco:
		panel_marco.pivot_offset = panel_marco.size / 2.0
		panel_marco.scale = Vector2(0.7, 0.7)
		tween.tween_property(panel_marco, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func desaparecer() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	if panel_marco:
		tween.tween_property(panel_marco, "scale", Vector2(0.7, 0.7), 0.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	visible = false

func _sincronizar_valores() -> void:
	if not GestionAudio:
		return
	var m = int(round(GestionAudio.volumen_master * 100))
	var mu = int(round(GestionAudio.volumen_musica * 100))
	var v = int(round(GestionAudio.volumen_voz * 100))
	var s = int(round(GestionAudio.volumen_sfx * 100))
	
	slider_master.set_value_no_signal(m)
	lbl_val_master.text = "%d%%" % m
	
	slider_musica.set_value_no_signal(mu)
	lbl_val_musica.text = "%d%%" % mu
	
	slider_voz.set_value_no_signal(v)
	lbl_val_voz.text = "%d%%" % v
	
	slider_sfx.set_value_no_signal(s)
	lbl_val_sfx.text = "%d%%" % s

func _on_slider_master_changed(val: float) -> void:
	lbl_val_master.text = "%d%%" % int(val)
	if GestionAudio:
		GestionAudio.establecer_volumen_master(val / 100.0)

func _on_slider_musica_changed(val: float) -> void:
	lbl_val_musica.text = "%d%%" % int(val)
	if GestionAudio:
		GestionAudio.establecer_volumen_musica(val / 100.0)

func _on_slider_voz_changed(val: float) -> void:
	lbl_val_voz.text = "%d%%" % int(val)
	if GestionAudio:
		GestionAudio.establecer_volumen_voz(val / 100.0)

func _on_slider_sfx_changed(val: float) -> void:
	lbl_val_sfx.text = "%d%%" % int(val)
	if GestionAudio:
		GestionAudio.establecer_volumen_sfx(val / 100.0)

func _on_probar_voz_pressed() -> void:
	if GestionAudio:
		GestionAudio.probar_voz()

func _on_probar_sfx_pressed() -> void:
	if GestionAudio:
		GestionAudio.probar_sfx()
