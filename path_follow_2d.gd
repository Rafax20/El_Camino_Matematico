extends PathFollow2D

# Supongamos que tu tablero tiene 20 casillas
var total_casillas = 28
var casilla_actual = 0

func avanzar_casillas(cantidad):
	if casilla_actual + cantidad > total_casillas:
		print("¡Llegaste a la meta!")
		casilla_actual = total_casillas
	else:
		casilla_actual += cantidad
	
	# Calculamos cuánto progreso representa cada casilla
	# progress_ratio va de 0 (inicio) a 1 (final)
	var destino_ratio = float(casilla_actual) / total_casillas
	
	# Animamos el movimiento suavemente
	var tween = create_tween()
	tween.tween_property(self, "progress_ratio", destino_ratio, 1.0).set_trans(Tween.TRANS_SINE)

func _on_lanzar_dado_pressed():
	# Generamos el número aleatorio entre 1 y 6
	var resultado = randi_range(1, 6)
	
	# Imprimimos en consola para verificar (opcional)
	print("Salió un: ", resultado)
	
	# Llamamos a la función de movimiento pasando el resultado
	avanzar_casillas(resultado)
