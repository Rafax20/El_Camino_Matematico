# res://Escenas/Minijuegos/ObjetoFlotante.gd
extends Area2D

signal objeto_tocado(valor)

@export var velocidad: float = 140.0
var valor_numero: int = 0

@onready var sprite = $Sprite2D
@onready var label_numero = $Sprite2D/Label

# 🎨 Colores EXCLUSIVOS para el globo (sin tonos oscuros)
var paleta_globos: Array[Color] = [
	Color("#ff3366"), # Rojo brillante
	Color("#33cc33"), # Verde
	Color("#3399ff"), # Azul
	Color("#ffcc00"), # Amarillo brillante
	Color("#ff9900"), # Naranja
	Color("#cc33ff"), # Morado
	Color("#00ffff"), # Cian claro
	Color("#ffffff")  # Blanco puro
]

# 🖊️ Color gris oscuro reservado EXCLUSIVAMENTE para el texto sobre globos claros
var color_texto_oscuro: Color = Color("#333333")

func _ready():
	input_event.connect(_on_input_event)

func configurar(numero: int, textura_imagen: Texture2D, vel_inicial: float):
	valor_numero = numero
	velocidad = vel_inicial
	
	if label_numero:
		label_numero.text = str(numero)
		
	if sprite and textura_imagen:
		sprite.texture = textura_imagen
		
		# 1. Seleccionamos un color vistoso para el globo
		var color_elegido = paleta_globos.pick_random()
		sprite.self_modulate = color_elegido
		
		# 2. CALCULAMOS EL CONTRASTE PARA EL TEXTO:
		#var luminancia = (0.299 * color_elegido.r) + (0.587 * color_elegido.g) + (0.114 * color_elegido.b)
		#
		#if label_numero:
			#if luminancia > 0.5:
				## ☀️ Globo claro / blanco -> Usamos tu gris oscuro (#333333)
				#label_numero.add_theme_color_override("font_color", color_texto_oscuro)
			#else:
				## 🌙 Globo oscuro / saturado -> Texto blanco para que resalte
				#label_numero.add_theme_color_override("font_color", Color.WHITE)
		label_numero.add_theme_color_override("font_color", color_texto_oscuro)

func _process(delta):
	position.y -= velocidad * delta
	if position.y < -120:
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	var es_clic = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var es_toque = event is InputEventScreenTouch and event.pressed

	if es_clic or es_toque:
		_explotar()

func _explotar():
	objeto_tocado.emit(valor_numero)
	queue_free()
