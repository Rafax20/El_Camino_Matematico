# res://Escenas/Minijuegos/ObjetoFlotante.gd
extends Area2D

signal objeto_tocado(valor)

@export var velocidad: float = 140.0
var valor_numero: int = 0

@onready var sprite = $Sprite2D
@onready var label_numero = $Label

func _ready():
	# Conectamos la señal de eventos de entrada por código para asegurar detección nativa
	input_event.connect(_on_input_event)

# 🎨 Cargar imagen y número de forma dinámica desde el Tablero
func configurar(numero: int, textura_imagen: Texture2D, vel_inicial: float):
	valor_numero = numero
	velocidad = vel_inicial
	
	if label_numero:
		label_numero.text = str(numero)
		
	if sprite and textura_imagen:
		sprite.texture = textura_imagen

func _process(delta):
	# Flota hacia arriba de manera constante
	position.y -= velocidad * delta
	
	# Si sale de la pantalla por arriba, se destruye para liberar memoria
	if position.y < -120:
		queue_free()

# 🖐️ Detección unificada para Clic de Ratón y Pantalla Táctil (Móviles/Web)
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Detecta clic izquierdo de ratón
	var es_clic = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	# Detecta toque táctil en pantalla móvil
	var es_toque = event is InputEventScreenTouch and event.pressed

	if es_clic or es_toque:
		_explotar()

func _explotar():
	objeto_tocado.emit(valor_numero)
	# ¡Aquí puedes instanciar un GPUParticles2D de explosión o sonido!
	queue_free()
