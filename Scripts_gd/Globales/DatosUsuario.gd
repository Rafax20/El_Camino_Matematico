extends Node

# --- VARIABLES GLOBALES DEL JUGADOR ---
var esta_conectado_a_la_nube: bool = false
var usuario_id_db: int = 0
var usuario_uuid: String = ""
var nombre_usuario: String = ""
var casilla_actual_db: int = 0
var pregunta_pendiente_db: bool = false
var pregunta_actual_guardada: Dictionary = {}
var id_pregunta_pendiente_db: int = 0
var dificultad_actual: int = 0 # 0 = Fácil, 1 = Media, 2 = Difícil
var rol: String = "estudiante" # Puede ser "estudiante" o "maestro"
var en_examen_final: bool = false
var examen_correctas: int = 0
var examen_preguntas_respondidas: int = 0
# Cada elemento guardará: {"operacion": String, "es_correcta": bool, "respuesta_correcta": Any}
var historial_examen: Array = []
# ⚽ Guardará los IDs de las láminas que posee el niño (ej: [1, 5, 11])
var laminas_poseidas: Array = []

# ⚡ CATALOGO_LAMINAS OPTIMIZADO: Almacena directamente la textura en RAM
var CATALOGO_LAMINAS: Dictionary = {
	1: load("res://assets/Album/Venezuela/ven_escudo.png"),
	2: load("res://assets/Album/Venezuela/ven_jugador1.png"),
	3: load("res://assets/Album/Venezuela/ven_jugador2.png"),
	4: load("res://assets/Album/Venezuela/ven_jugador3.png"),
	5: load("res://assets/Album/Venezuela/ven_jugador4.png"),
	6: load("res://assets/Album/Venezuela/ven_jugador5.png"),
	7: load("res://assets/Album/Venezuela/ven_jugador6.png"),
	8: load("res://assets/Album/Venezuela/ven_jugador7.png"),
	9: load("res://assets/Album/Venezuela/ven_jugador8.png"),
	10: load("res://assets/Album/Venezuela/ven_jugador9.png"),
	11: load("res://assets/Album/Venezuela/ven_jugador10.png"),
	12: load("res://assets/Album/Venezuela/ven_jugador11.png"),
	13: load("res://assets/Album/Venezuela/ven_jugador12.png"),
	14: load("res://assets/Album/Venezuela/ven_jugador13.png"),
	15: load("res://assets/Album/Venezuela/ven_jugador14.png"),
	16: load("res://assets/Album/Venezuela/ven_jugador15.png"),
	17: load("res://assets/Album/Venezuela/ven_jugador16.png"),
	18: load("res://assets/Album/Venezuela/ven_jugador17.png"),
	19: load("res://assets/Album/Argentina/arg_escudo.png"),
	20: load("res://assets/Album/Argentina/arg_jugador1.png"),
	21: load("res://assets/Album/Argentina/arg_jugador2.png"),
	22: load("res://assets/Album/Argentina/arg_jugador3.png"),
	23: load("res://assets/Album/Argentina/arg_jugador4.png"),
	24: load("res://assets/Album/Argentina/arg_jugador5.png"),
	25: load("res://assets/Album/Argentina/arg_jugador6.png"),
	26: load("res://assets/Album/Argentina/arg_jugador7.png"),
	27: load("res://assets/Album/Argentina/arg_jugador8.png"),
	28: load("res://assets/Album/Argentina/arg_jugador9.png"),
	29: load("res://assets/Album/Argentina/arg_jugador10.png"),
	30: load("res://assets/Album/Argentina/arg_jugador11.png"),
	31: load("res://assets/Album/Argentina/arg_jugador12.png"),
	32: load("res://assets/Album/Argentina/arg_jugador13.png"),
	33: load("res://assets/Album/Argentina/arg_jugador14.png"),
	34: load("res://assets/Album/Argentina/arg_jugador15.png"),
	35: load("res://assets/Album/Argentina/arg_jugador16.png"),
	36: load("res://assets/Album/Argentina/arg_jugador17.png"),
	37: load("res://assets/Album/Portugal/por_escudo.png"),
	38: load("res://assets/Album/Portugal/por_jugador1.png"),
	#39: "res://assets/Album/Argentina/arg_jugador2.png",
	#40: "res://assets/Album/Argentina/arg_jugador3.png",
	#41: "res://assets/Album/Argentina/arg_jugador4.png",
	#42: "res://assets/Album/Argentina/arg_jugador5.png",
	#43: "res://assets/Album/Argentina/arg_jugador6.png",
	#44: "res://assets/Album/Argentina/arg_jugador7.png",
	#45: "res://assets/Album/Argentina/arg_jugador8.png",
	#46: "res://assets/Album/Argentina/arg_jugador9.png",
	#47: "res://assets/Album/Argentina/arg_jugador10.png",
	#48: "res://assets/Album/Argentina/arg_jugador11.png",
	#49: "res://assets/Album/Argentina/arg_jugador12.png",
	#50: "res://assets/Album/Argentina/arg_jugador13.png",
	#51: "res://assets/Album/Argentina/arg_jugador15.png",
	#52: "res://assets/Album/Argentina/arg_jugador16.png",
	#53: "res://assets/Album/Argentina/arg_jugador17.png",
	#54: "res://assets/Album/Argentina/arg_jugador18.png",
	55: load("res://assets/Album/España/esp_escudo.png"),
	56: load("res://assets/Album/España/esp_jugador1.png"),
	#57: "res://assets/Album/Argentina/arg_jugador2.png",
	#58: "res://assets/Album/Argentina/arg_jugador3.png",
	#59: "res://assets/Album/Argentina/arg_jugador4.png",
	#60: "res://assets/Album/Argentina/arg_jugador5.png",
	#61: "res://assets/Album/Argentina/arg_jugador6.png",
	#62: "res://assets/Album/Argentina/arg_jugador7.png",
	#63: "res://assets/Album/Argentina/arg_jugador8.png",
	#64: "res://assets/Album/Argentina/arg_jugador9.png",
	#65: "res://assets/Album/Argentina/arg_jugador10.png",
	#66: "res://assets/Album/Argentina/arg_jugador11.png",
	#67: "res://assets/Album/Argentina/arg_jugador12.png",
	#68: "res://assets/Album/Argentina/arg_jugador13.png",
	#69: "res://assets/Album/Argentina/arg_jugador15.png",
	#70: "res://assets/Album/Argentina/arg_jugador16.png",
	#71: "res://assets/Album/Argentina/arg_jugador17.png",
	#72: "res://assets/Album/Argentina/arg_jugador18.png",
	73: load("res://assets/Album/Inglaterra/ing_escudo.png")
	#74: "res://assets/Album/Argentina/arg_jugador1.png",
	#75: "res://assets/Album/Argentina/arg_jugador2.png",
	#76: "res://assets/Album/Argentina/arg_jugador3.png",
	#77: "res://assets/Album/Argentina/arg_jugador4.png",
	#78: "res://assets/Album/Argentina/arg_jugador5.png",
	#79: "res://assets/Album/Argentina/arg_jugador6.png",
	#80: "res://assets/Album/Argentina/arg_jugador7.png",
	#81: "res://assets/Album/Argentina/arg_jugador8.png",
	#82: "res://assets/Album/Argentina/arg_jugador9.png",
	#83: "res://assets/Album/Argentina/arg_jugador10.png",
	#84: "res://assets/Album/Argentina/arg_jugador11.png",
	#85: "res://assets/Album/Argentina/arg_jugador12.png",
	#86: "res://assets/Album/Argentina/arg_jugador13.png",
	#87: "res://assets/Album/Argentina/arg_jugador15.png",
	#88: "res://assets/Album/Argentina/arg_jugador16.png",
	#89: "res://assets/Album/Argentina/arg_jugador17.png",
	#90: "res://assets/Album/Argentina/arg_jugador18.png",
}

# Método para resetear la sesión si el niño sale al menú principal
func cerrar_sesion():
	esta_conectado_a_la_nube = false
	usuario_id_db = 0
	usuario_uuid = ""
	nombre_usuario = ""
