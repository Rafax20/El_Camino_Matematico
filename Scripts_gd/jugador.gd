extends CharacterBody2D

@export var velocidad: float = 180.0


@onready var sprite: AnimatedSprite2D = $Animacion
@onready var linterna: PointLight2D = $PointLight2D

func _physics_process(_delta):
	var direccion = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	
	velocity = direccion * velocidad
	move_and_slide()

	if direccion != Vector2.ZERO:
		# 1. MOVER A LA DERECHA (Tecla D)
		if direccion.x > 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = -90
			_reproducir_animacion("caminar_derecha")

		# 2. MOVER A LA IZQUIERDA (Tecla A)
		elif direccion.x < 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = 90
			_reproducir_animacion("caminar_izquierda")

		# 3. MOVER ARRIBA / ESPALDA (Tecla W)
		elif direccion.y < 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = 180
			_reproducir_animacion("caminar_arriba")

		# 4. MOVER ABAJO / FRENTE (Tecla S)
		elif direccion.y > 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = 0
			_reproducir_animacion("caminar_abajo")
	else:
		# Al detenerse, mantiene el primer fotograma de la última animación que usó
		sprite.stop()
		sprite.frame = 0

# Función auxiliar para reproducir la animación solo si no se está ejecutando ya
func _reproducir_animacion(nombre_animacion: String) -> void:
	if sprite and sprite.sprite_frames.has_animation(nombre_animacion):
		if sprite.animation != nombre_animacion or not sprite.is_playing():
			sprite.play(nombre_animacion)
