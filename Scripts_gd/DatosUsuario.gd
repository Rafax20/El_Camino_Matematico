extends Node

# --- VARIABLES GLOBALES DEL JUGADOR ---
var esta_conectado_a_la_nube: bool = false
var usuario_id_db: int = 0
var usuario_uuid: String = ""
var nombre_usuario: String = ""
var casilla_actual_db: int = 0
var pregunta_pendiente_db: bool = false
var id_pregunta_pendiente_db: int = 0
var dificultad_actual: int = 0 # 0 = Fácil, 1 = Media, 2 = Difícil
var rol: String = "estudiante" # Puede ser "estudiante" o "maestro"
# ⚽ Guardará los IDs de las láminas que posee el niño (ej: [1, 5, 11])
var laminas_poseidas: Array = []

# En DatosUsuario.gd
const CATALOGO_LAMINAS = {
	1: "res://assets/Album/Venezuela/ven_escudo.png",
	2: "res://assets/Album/Venezuela/ven_jugador1.png",
	3: "res://assets/Album/Venezuela/ven_jugador2.png",
	4: "res://assets/Album/Venezuela/ven_jugador3.png",
	5: "res://assets/Album/Venezuela/ven_jugador1.png",
	6: "res://assets/Album/Venezuela/ven_jugador1.png",
	7: "res://assets/Album/Venezuela/ven_jugador1.png",
	8: "res://assets/Album/Venezuela/ven_jugador1.png",
	9: "res://assets/Album/Venezuela/ven_jugador1.png",
	10: "res://assets/Album/Venezuela/ven_jugador1.png",
	11: "res://assets/Album/Venezuela/ven_jugador1.png",
	12: "res://assets/Album/Venezuela/ven_jugador1.png",
	13: "res://assets/Album/Venezuela/ven_jugador1.png",
	14: "res://assets/Album/Venezuela/ven_jugador1.png",
	15: "res://assets/Album/Venezuela/ven_jugador1.png",
	16: "res://assets/Album/Venezuela/ven_jugador1.png",
	17: "res://assets/Album/Venezuela/ven_jugador1.png",
	18: "res://assets/Album/Venezuela/ven_jugador1.png",
	19: "res://assets/Album/Argentina/arg_escudo.png",
	20: "res://assets/Album/Argentina/arg_jugador1.png",
	21: "res://assets/Album/Argentina/arg_jugador2.png",
	22: "res://assets/Album/Argentina/arg_jugador3.png",
	23: "res://assets/Album/Argentina/arg_jugador4.png",
	24: "res://assets/Album/Argentina/arg_jugador5.png",
	25: "res://assets/Album/Argentina/arg_jugador6.png",
	26: "res://assets/Album/Argentina/arg_jugador7.png",
	27: "res://assets/Album/Argentina/arg_jugador8.png",
	28: "res://assets/Album/Argentina/arg_jugador9.png",
	29: "res://assets/Album/Argentina/arg_jugador10.png",
	30: "res://assets/Album/Argentina/arg_jugador11.png",
	31: "res://assets/Album/Argentina/arg_jugador12.png",
	32: "res://assets/Album/Argentina/arg_jugador13.png",
	33: "res://assets/Album/Argentina/arg_jugador15.png",
	34: "res://assets/Album/Argentina/arg_jugador16.png",
	35: "res://assets/Album/Argentina/arg_jugador17.png",
	36: "res://assets/Album/Argentina/arg_jugador18.png",
}

# Método para resetear la sesión si el niño sale al menú principal
func cerrar_sesion():
	esta_conectado_a_la_nube = false
	usuario_id_db = 0
	usuario_uuid = ""
	nombre_usuario = ""
