extends TextureButton

var valor_numero: int = 0

@export var texturas_baterias: Array[Texture2D]

func configurar(valor: int):
	valor_numero = valor

	if has_node("LabelNumero"):
		$LabelNumero.text = str(valor)
		$LabelNumero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if texturas_baterias.size() > 0:
		texture_normal = texturas_baterias.pick_random()
	
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	custom_minimum_size = Vector2(72, 107)
	
	mouse_filter = Control.MOUSE_FILTER_STOP

func _get_drag_data(_at_position: Vector2):
	var data = {
		"tipo": "ficha_matematica",
		"valor": valor_numero
	}
	
	# 📏 1. Definir un tamaño más pequeño para el drag preview (ejemplo: 45 x 67)
	var tamano_reducido = Vector2(45, 67)
	
	# 2. Crear el contenedor visual con el nuevo tamaño
	var preview_control = Control.new()
	preview_control.custom_minimum_size = tamano_reducido
	preview_control.size = tamano_reducido
	
	var preview_tex = TextureRect.new()
	preview_tex.texture = texture_normal
	preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var lbl_preview = Label.new()
	lbl_preview.text = str(valor_numero)
	lbl_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 🔤 Ajustar la fuente proporcionalmente al tamaño pequeño
	lbl_preview.add_theme_font_size_override("font_size", 22)
	lbl_preview.add_theme_constant_override("outline_size", 4)
	
	preview_control.add_child(preview_tex)
	preview_control.add_child(lbl_preview)
	
	# 🎯 Centrar la vista previa reducida bajo el cursor/dedo
	preview_control.position = -tamano_reducido / 2.0
	
	var preview_pivot = Control.new()
	preview_pivot.add_child(preview_control)
	
	set_drag_preview(preview_pivot)
	
	return data
