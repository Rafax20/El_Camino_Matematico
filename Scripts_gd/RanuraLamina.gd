# res://Scripts_gd/RanuraLamina.gd
extends TextureRect

# 🆔 ID de la lámina o logro que representa esta casilla
@export var id_lamina: int = 0
@export var es_logro: bool = false

# 🖼️ La foto original a color del jugador/país/logro para esta casilla
@export var textura_jugador: Texture2D

signal logro_hovered(id_logro: int, desbloqueado: bool)
signal logro_unhovered()

func _ready():
	if es_logro:
		custom_minimum_size = Vector2(150, 150)
	else:
		custom_minimum_size = Vector2(120, 160)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_PASS
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if es_logro:
		var desbloqueado = DatosUsuario.logros_poseidos.has(int(id_lamina))
		logro_hovered.emit(int(id_lamina), desbloqueado)
		pivot_offset = size / 2.0
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if es_logro:
		logro_unhovered.emit()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)

# 📱 Soporte táctil para pantallas de móviles / tablets
func _gui_input(event: InputEvent):
	if es_logro and (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)):
		if event.is_pressed():
			var desbloqueado = DatosUsuario.logros_poseidos.has(int(id_lamina))
			logro_hovered.emit(int(id_lamina), desbloqueado)
			pivot_offset = size / 2.0
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_delay(0.1).set_trans(Tween.TRANS_SINE)

func actualizar_estado():
	if es_logro:
		custom_minimum_size = Vector2(150, 150)
	else:
		custom_minimum_size = Vector2(120, 160)
	var id_a_buscar = int(id_lamina)
	var lista = DatosUsuario.logros_poseidos if es_logro else DatosUsuario.laminas_poseidas
	if lista.has(id_a_buscar):
		texture = textura_jugador
		modulate = Color(1, 1, 1, 1) # Color original (Desbloqueado)
	else:
		texture = textura_jugador
		modulate = Color(0.12, 0.12, 0.15, 0.75) # Silueta oscura (Bloqueado)
