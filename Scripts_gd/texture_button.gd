extends TextureButton

# Esta función se ejecuta cuando el ratón entra en el botón
func _on_mouse_entered() -> void:
	# Hacemos que el libro "tiemble" un poco alterando su rotación
	# y su escala de forma secuencial. ¡Ojo, esto es un ejemplo muy básico!

	# Primero lo rotamos 3 grados a la izquierda
	rotation_degrees = -3
	# Esperamos un instante muy corto (usando un temporizador)
	await get_tree().create_timer(0.05).timeout
	# Ahora lo rotamos 3 grados a la derecha y lo agrandamos un poquito (1.1x)
	rotation_degrees = 3
	scale = Vector2(1.1, 1.1)
	await get_tree().create_timer(0.05).timeout
	# Volvemos a la normalidad
	rotation_degrees = 0
	scale = Vector2(1, 1)

# Esta función se ejecuta cuando el ratón sale del botón
func _on_mouse_exited() -> void:
	# Al salir, nos aseguramos de que el libro vuelva a su estado original
	rotation_degrees = 0
	scale = Vector2(1, 1)
