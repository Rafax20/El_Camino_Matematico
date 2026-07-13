extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func Animar_Movimiento(ejecutar: bool):
	if ejecutar:
		# 1. Ejecutamos la primera animación
		play("Saltando_Espacio")
		print("🏃 Saltando...")
		
		
		
		
func Animar_Caida(ejecutar: bool):
	if ejecutar:
		
		# 3. Ejecutamos la segunda animación
		play("Cayendo_Espacio")
		print("🛬 Cayendo...")
		
		# 4. ESPERAMOS a que termine "Cayendo_Espacio"
		await animation_finished
		
		print("✅ Ciclo de animación completado")
