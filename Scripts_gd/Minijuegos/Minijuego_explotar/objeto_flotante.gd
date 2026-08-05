# res://Escenas/Minijuegos/ObjetoFlotante.gd
extends Area2D

signal objeto_tocado(valor)

@export var velocidad: float = 140.0
var valor_numero: int = 0
var vel_rotacion: float = 0.0 # 🔄 Velocidad de giro para asteroides

@onready var sprite = $Sprite2D
@onready var label_numero = $Sprite2D/Label

# 🎨 Colores EXCLUSIVOS para el globo (se usan solo en tema 'colegio')
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

# 🖊️ Color gris oscuro fijo para el texto
var color_texto_oscuro: Color = Color("#333333")
var ya_tocado: bool = false # 🛡️ Candado anti doble clic

func _ready():
	input_event.connect(_on_input_event)

func configurar(numero: int, textura_imagen: Texture2D, vel_inicial: float, tema: String = "colegio"):
	valor_numero = numero
	velocidad = vel_inicial
	ya_tocado = false # 🔄 Reiniciamos el estado por si se reutiliza
	
	if label_numero:
		label_numero.text = str(numero)
		# 🖊️ SIEMPRE en gris oscuro/negro, sin calcular luminancia
		label_numero.add_theme_color_override("font_color", color_texto_oscuro)
		
	if sprite and textura_imagen:
		sprite.texture = textura_imagen
		
		# 🌌 MODO ESPACIO (ASTEROIDES)
		if tema == "espacio":
			vel_rotacion = randf_range(-1.8, 1.8)
			sprite.self_modulate = Color.WHITE
				
		# 🎈 MODO COLEGIO (GLOBOS)
		else:
			vel_rotacion = 0.0
			sprite.rotation = 0.0
			var color_elegido = paleta_globos.pick_random()
			sprite.self_modulate = color_elegido

func _process(delta):
	# Flota hacia arriba
	position.y -= velocidad * delta
	
	# 🔄 Rotación del asteroide (solo la imagen)
	if vel_rotacion != 0.0 and sprite:
		sprite.rotation += vel_rotacion * delta
	
	if position.y < -120:
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if ya_tocado: return # 🛑 Si ya se procesó, ignora cualquier otro evento
	
	var es_clic = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var es_toque = event is InputEventScreenTouch and event.pressed

	if es_clic or es_toque:
		# 🔒 2. Marcamos inmediatamente la variable ANTES de cualquier otra acción
		ya_tocado = true 
		
		# 🛑 3. Consumimos el evento en el viewport para que no pase a otros nodos
		get_viewport().set_input_as_handled()
		
		# 🔌 4. Desconectamos la señal para evitar invocaciones tardías del motor
		if input_event.is_connected(_on_input_event):
			input_event.disconnect(_on_input_event)
		_explotar()

func _explotar():
	objeto_tocado.emit(valor_numero)
	queue_free()
