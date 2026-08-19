extends CharacterBody2D

@export var velocidad: float = 180.0

@onready var sprite: AnimatedSprite2D = $Animacion
@onready var linterna: PointLight2D = $PointLight2D

# 🔒 Desactivado por defecto: El tablero NO permite mover al personaje
var movimiento_bloqueado: bool = true

func _physics_process(_delta):
	# Si está bloqueado, reseteamos velocidad y animación
	if movimiento_bloqueado:
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite:
			sprite.stop()
			sprite.frame = 0
		return

	var direccion = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	
	velocity = direccion * velocidad
	move_and_slide()

	if direccion != Vector2.ZERO:
		if direccion.x > 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = -90
			_reproducir_animacion("caminar_derecha")
		elif direccion.x < 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = 90
			_reproducir_animacion("caminar_izquierda")
		elif direccion.y < 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = 180
			_reproducir_animacion("caminar_arriba")
		elif direccion.y > 0:
			linterna.position.x = sprite.position.x
			linterna.position.y = sprite.position.y
			linterna.rotation_degrees = 0
			_reproducir_animacion("caminar_abajo")
	else:
		sprite.stop()
		sprite.frame = 0

func activar_movimiento():
	movimiento_bloqueado = false

func desactivar_movimiento():
	movimiento_bloqueado = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.stop()
		sprite.frame = 0

func _reproducir_animacion(nombre_animacion: String) -> void:
	if sprite and sprite.sprite_frames.has_animation(nombre_animacion):
		if sprite.animation != nombre_animacion or not sprite.is_playing():
			sprite.play(nombre_animacion)
