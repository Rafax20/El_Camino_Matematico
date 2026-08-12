# res://Scripts_gd/SistemaExperto.gd
extends Node

# --- BASE DE CONOCIMIENTOS (Estados del Sistema) ---
enum Dificultad { FACIL, MEDIA, DIFICIL }

# Umbrales de tiempo pedagógicos (en segundos) para niños de 4to grado
const TIEMPO_RAPIDO = 12.0  # Menos de 10s: Domina el tema
const TIEMPO_LENTO = 25.0   # Más de 25s: Le cuesta procesar el problema

# --- MOTOR DE INFERENCIA ---
# Esta función analiza la Memoria de Trabajo (es_correcta, tiempo) 
# y aplica las Reglas de Producción para devolver la nueva dificultad.
func evaluar_desempeno(dificultad_actual: int, es_correcta: bool, tiempo_tardado: float) -> int:
	var nueva_dificultad = dificultad_actual
	
	if es_correcta:
		# REGLA 1: Si es correcta y muy rápido, sube dificultad (Evita aburrimiento)
		if tiempo_tardado <= TIEMPO_RAPIDO:
			if dificultad_actual == Dificultad.FACIL:
				nueva_dificultad = Dificultad.MEDIA
				print("🧠 SE: ¡Excelente desempeño! Subiendo a dificultad MEDIA.")
			elif dificultad_actual == Dificultad.MEDIA:
				nueva_dificultad = Dificultad.DIFICIL
				print("🧠 SE: ¡Dominio total! Subiendo a dificultad DIFICIL.")
				
		# REGLA 2: Si es correcta pero tardó mucho, se mantiene (Necesita consolidar)
		elif tiempo_tardado > TIEMPO_LENTO:
			print("🧠 SE: Respuesta correcta pero con esfuerzo. Se mantiene dificultad.")
			
		# REGLA 3: Si está en el tiempo intermedio, se mantiene igual
		else:
			print("🧠 SE: Ritmo adecuado. Se mantiene la dificultad actual.")
			
	else:
		# REGLA 4: Si es incorrecta y además tardó mucho, baja dificultad (Evita frustración)
		if tiempo_tardado >= TIEMPO_LENTO:
			if dificultad_actual == Dificultad.DIFICIL:
				nueva_dificultad = Dificultad.MEDIA
				print("🧠 SE: Frustración detectada. Bajando a dificultad MEDIA.")
			elif dificultad_actual == Dificultad.MEDIA:
				nueva_dificultad = Dificultad.FACIL
				print("🧠 SE: Alumno requiere refuerzo. Bajando a dificultad FÁCIL.")
				
		# REGLA 5: Si es incorrecta pero respondió rápido, pudo ser un error por distracción
		else:
			print("🧠 SE: Respuesta incorrecta rápida. Posible distracción, se mantiene dificultad.")
			
	return nueva_dificultad
