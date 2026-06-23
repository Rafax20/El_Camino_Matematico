extends Node

# --- VARIABLES GLOBALES DEL JUGADOR ---
var esta_conectado_a_la_nube: bool = false
var usuario_id_db: int = 0
var usuario_uuid: String = ""
var nombre_usuario: String = ""
var casilla_actual_db: int = 0
var pregunta_pendiente_db : bool = false

# Método para resetear la sesión si el niño sale al menú principal
func cerrar_sesion():
	esta_conectado_a_la_nube = false
	usuario_id_db = 0
	usuario_uuid = ""
	nombre_usuario = ""
