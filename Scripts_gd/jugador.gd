extends CharacterBody2D

@export var velocidad: float = 180.0

@onready var sprite = $AnimatedSprite2D
@onready var linterna = $PointLight2D

func _physics_process(_delta):
	# 1. Obtener la dirección según las teclas presionadas (-1, 0, o 1 en cada eje)
	var direccion = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	
	# Si estás usando los controles por defecto de Godot, usa esta línea en su lugar:
	# var direccion = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. Aplicar la velocidad
	velocity = direccion * velocidad
	move_and_slide()

	# 3. Orientar la linterna y las animaciones hacia la dirección donde camina
	if direccion != Vector2.ZERO:
		# Girar el nodo de la luz en la dirección del movimiento
		linterna.rotation = direccion.angle()
		
		# (Opcional) Reproducir animación de caminar si la tienes
		if sprite and sprite.sprite_frames.has_animation("caminar"):
			sprite.play("caminar")
	else:
		if sprite and sprite.sprite_frames.has_animation("quieto"):
			sprite.play("quieto")
