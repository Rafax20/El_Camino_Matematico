extends Node

# --- VARIABLES GLOBALES DEL JUGADOR ---
var banco_preguntas: Array = [] # 🧠 AQUÍ SE GUARDAN TODAS LAS PREGUNTAS EN RAM
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
# 🏆 Guardará los IDs de los logros que posee el niño (ej: [1, 2, 5])
var logros_poseidos: Array = []
# 🪙 Monedas del jugador para comprar sobres en la tienda
var monedas: int = 0
# 🪐 Indica si el niño desbloqueó el atajo derecho en la casilla 12
var tomo_camino_corto: bool = false
# 🎲 Registro de tiro previo y valor del dado para retrocesos y sincronización
var casilla_anterior: int = 0
var ultimo_dado: int = 0

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
	39: load("res://assets/Album/Portugal/por_jugador2.png"),
	40: load("res://assets/Album/Portugal/por_jugador3.png"),
	41: load("res://assets/Album/Portugal/por_jugador4.png"),
	42: load("res://assets/Album/Portugal/por_jugador5.png"),
	43: load("res://assets/Album/Portugal/por_jugador6.png"),
	44: load("res://assets/Album/Portugal/por_jugador7.png"),
	45: load("res://assets/Album/Portugal/por_jugador8.png"),
	46: load("res://assets/Album/Portugal/por_jugador9.png"),
	47: load("res://assets/Album/Portugal/por_jugador10.png"),
	48: load("res://assets/Album/Portugal/por_jugador11.png"),
	49: load("res://assets/Album/Portugal/por_jugador12.png"),
	50: load("res://assets/Album/Portugal/por_jugador13.png"),
	51: load("res://assets/Album/Portugal/por_jugador14.png"),
	52: load("res://assets/Album/Portugal/por_jugador15.png"),
	53: load("res://assets/Album/Portugal/por_jugador16.png"),
	54: load("res://assets/Album/Portugal/por_jugador17.png"),
	55: load("res://assets/Album/España/esp_escudo.png"),
	56: load("res://assets/Album/España/esp_jugador1.png"),
	57: load("res://assets/Album/España/esp_jugador2.png"),
	58: load("res://assets/Album/España/esp_jugador3.png"),
	59: load("res://assets/Album/España/esp_jugador4.png"),
	60: load("res://assets/Album/España/esp_jugador5.png"),
	61: load("res://assets/Album/España/esp_jugador6.png"),
	62: load("res://assets/Album/España/esp_jugador7.png"),
	63: load("res://assets/Album/España/esp_jugador8.png"),
	64: load("res://assets/Album/España/esp_jugador9.png"),
	65: load("res://assets/Album/España/esp_jugador10.png"),
	66: load("res://assets/Album/España/esp_jugador11.png"),
	67: load("res://assets/Album/España/esp_jugador12.png"),
	68: load("res://assets/Album/España/esp_jugador13.png"),
	69: load("res://assets/Album/España/esp_jugador14.png"),
	70: load("res://assets/Album/España/esp_jugador15.png"),
	71: load("res://assets/Album/España/esp_jugador16.png"),
	72: load("res://assets/Album/España/esp_jugador17.png"),
	73: load("res://assets/Album/Inglaterra/ing_escudo.png"),
	74: load("res://assets/Album/Inglaterra/ing_jugador1.png"),
	75: load("res://assets/Album/Inglaterra/ing_jugador2.png"),
	76: load("res://assets/Album/Inglaterra/ing_jugador3.png"),
	77: load("res://assets/Album/Inglaterra/ing_jugador4.png"),
	78: load("res://assets/Album/Inglaterra/ing_jugador5.png"),
	79: load("res://assets/Album/Inglaterra/ing_jugador6.png"),
	80: load("res://assets/Album/Inglaterra/ing_jugador7.png"),
	81: load("res://assets/Album/Inglaterra/ing_jugador8.png"),
	82: load("res://assets/Album/Inglaterra/ing_jugador9.png"),
	83: load("res://assets/Album/Inglaterra/ing_jugador10.png"),
	84: load("res://assets/Album/Inglaterra/ing_jugador11.png"),
	85: load("res://assets/Album/Inglaterra/ing_jugador12.png"),
	86: load("res://assets/Album/Inglaterra/ing_jugador13.png"),
	87: load("res://assets/Album/Inglaterra/ing_jugador14.png"),
	88: load("res://assets/Album/Inglaterra/ing_jugador15.png"),
	89: load("res://assets/Album/Inglaterra/ing_jugador16.png"),
	90: load("res://assets/Album/Inglaterra/ing_jugador17.png"),
	91: load("res://assets/Album/Brasil/bra_escudo.png"),
	92: load("res://assets/Album/Brasil/bra_jugador1.png"),
	93: load("res://assets/Album/Brasil/bra_jugador2.png"),
	94: load("res://assets/Album/Brasil/bra_jugador3.png"),
	95: load("res://assets/Album/Brasil/bra_jugador4.png"),
	96: load("res://assets/Album/Brasil/bra_jugador5.png"),
	97: load("res://assets/Album/Brasil/bra_jugador6.png"),
	98: load("res://assets/Album/Brasil/bra_jugador7.png"),
	99: load("res://assets/Album/Brasil/bra_jugador8.png"),
	100: load("res://assets/Album/Brasil/bra_jugador9.png"),
	101: load("res://assets/Album/Brasil/bra_jugador10.png"),
	102: load("res://assets/Album/Brasil/bra_jugador11.png"),
	103: load("res://assets/Album/Brasil/bra_jugador12.png"),
	104: load("res://assets/Album/Brasil/bra_jugador13.png"),
	105: load("res://assets/Album/Brasil/bra_jugador14.png"),
	106: load("res://assets/Album/Brasil/bra_jugador15.png"),
	107: load("res://assets/Album/Brasil/bra_jugador16.png"),
	108: load("res://assets/Album/Brasil/bra_jugador17.png")
}

var CATALOGO_LOGROS: Dictionary = {
	1: load("res://assets/Logros/Tablero_Completado.png"),
	2: load("res://assets/Logros/Logro_Asteroides.png"),
	3: load("res://assets/Logros/Logro_Buscador.png"),
	4: load("res://assets/Logros/Logro_Laboratorio.png"),
	5: load("res://assets/Logros/Logro_Balanza.png"),
	6: load("res://assets/Logros/Logro_Clasificador.png"),
	7: load("res://assets/Logros/Logro_Circuitos.png")
}

# Método para resetear la sesión si el niño sale al menú principal
func cerrar_sesion():
	esta_conectado_a_la_nube = false
	usuario_id_db = 0
	usuario_uuid = ""
	nombre_usuario = ""
	monedas = 0
	casilla_actual_db = 0
	casilla_anterior = 0
	ultimo_dado = 0
	pregunta_pendiente_db = false
	pregunta_actual_guardada.clear()
	en_examen_final = false
	examen_correctas = 0
	examen_preguntas_respondidas = 0
	historial_examen.clear()
	laminas_poseidas.clear()
	logros_poseidos.clear()
	tomo_camino_corto = false
