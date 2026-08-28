# res://Scripts_gd/RanuraLamina.gd
extends TextureRect

# 🆔 ID de la lámina o logro que representa esta casilla
@export var id_lamina: int = 0
@export var es_logro: bool = false

# 🖼️ La foto original a color del jugador/país/logro para esta casilla
@export var textura_jugador: Texture2D

func actualizar_estado():
	var id_a_buscar = int(id_lamina)
	var lista = DatosUsuario.logros_poseidos if es_logro else DatosUsuario.laminas_poseidas
	if lista.has(id_a_buscar):
		texture = textura_jugador
		modulate = Color(1, 1, 1, 1) # Color original (Desbloqueado)
	else:
		texture = textura_jugador
		modulate = Color(0.12, 0.12, 0.15, 0.75) # Silueta oscura (Bloqueado)
