# res://Scripts_gd/RanuraLamina.gd
extends TextureRect

# 🆔 ID de la lámina que representa esta casilla (ej: 1 para Messi, 2 para Vinicius...)
@export var id_lamina: int = 0

# 🖼️ La foto original a color del jugador/país para esta casilla
@export var textura_jugador: Texture2D

func actualizar_estado():
	# Si el array global en la RAM tiene este ID, el niño ya la ganó
	if DatosUsuario.laminas_poseidas.has(id_lamina):
		texture = textura_jugador
		modulate = Color(1, 1, 1, 1) # Se muestra a todo color
	else:
		# Si no la tiene, le ponemos la misma foto pero oscura como una silueta
		texture = textura_jugador
		modulate = Color(0.1, 0.1, 0.1, 0.8) # Silueta oscura (estilo candado)
