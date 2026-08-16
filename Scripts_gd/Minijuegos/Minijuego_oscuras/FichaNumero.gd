# res://Escenas/Minijuegos/Minijuego_oscuras/FichaNumero.gd
extends TextureButton

var valor_numero: int = 0

# Texturas precalculadas de los tanques/baterías
@export var texturas_baterias: Array[Texture2D]

func configurar(valor: int):
	valor_numero = valor

	if has_node("LabelNumero"):
		$LabelNumero.text = str(valor)
		
	if texturas_baterias.size() > 0:
		texture_normal = texturas_baterias.pick_random()
	
	# Permite estirar/reducir la textura libremente
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	
	# Le defines el tamaño exacto en píxeles que quieres que tenga
	custom_minimum_size = Vector2(72, 107)
	

# 🖐️ Al iniciar el arrastre Drag & Drop
func _get_drag_data(_at_position):
	var data = {
		"tipo": "ficha_matematica",
		"valor": valor_numero
	}
	
	# 🎬 VISTA PREVIA: Creamos un TextureRect para que flote LA BATERÍA ENTERA mientras arrastra
	var preview = TextureRect.new()
	preview.texture = texture_normal
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(50, 70) # Tamaño cómodo de la cápsula flotando
	
	# Opcional: Agregar el número flotando sobre la cápsula de preview
	var lbl_preview = Label.new()
	lbl_preview.text = str(valor_numero)
	lbl_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_preview.add_theme_font_size_override("font_size", 25)
	lbl_preview.add_theme_constant_override("outline_size", 4)
	preview.add_child(lbl_preview)
	
	# Centrar el preview bajo el ratón/dedo
	var control_contenedor = Control.new()
	control_contenedor.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2.0
	
	set_drag_preview(control_contenedor)
	
	return data
