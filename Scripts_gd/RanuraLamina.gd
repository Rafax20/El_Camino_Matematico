# res://Scripts_gd/RanuraLamina.gd
extends TextureRect

# 🆔 ID de la lámina que representa esta casilla (ej: 1 para Messi, 2 para Vinicius...)
@export var id_lamina: int = 0

# 🖼️ La foto original a color del jugador/país para esta casilla
@export var textura_jugador: Texture2D

func actualizar_estado():
	var id_a_buscar = int(id_lamina)
	if DatosUsuario.laminas_poseidas.has(id_a_buscar):
		texture = textura_jugador
		modulate = Color(1, 1, 1, 1) # Color original
	else:
		texture = textura_jugador
		modulate = Color(0.1, 0.1, 0.1, 0.8) # Silueta oscura
