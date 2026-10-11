# res://Scripts_gd/SistemaExperto.gd
extends Node

# --- BASE DE CONOCIMIENTOS (Estados del Sistema) ---
enum Dificultad { FACIL, MEDIA, DIFICIL }

# Umbrales de tiempo pedagógicos (en segundos) para niños de 4to grado de educación básica
const TIEMPO_RAPIDO = 5.0   # Menos de 5s: Domina y automatizó el cálculo con fluidez
const TIEMPO_LENTO = 11.0   # Más de 11s: Demora excesiva, esfuerzo cognitivo alto o fatiga

# Variables de seguimiento para la inferencia pedagógica adaptativa
var respuestas_lentas_consecutivas: int = 0
var errores_consecutivos: int = 0

# --- MOTOR DE INFERENCIA PEDAGÓGICO ---
# Esta función analiza la Memoria de Trabajo (es_correcta, tiempo) 
# y aplica las Reglas de Producción pedagógicas para devolver la nueva dificultad adaptativa.
func evaluar_desempeno(dificultad_actual: int, es_correcta: bool, tiempo_tardado: float) -> int:
	var nueva_dificultad = dificultad_actual
	
	# -------------------------------------------------------------------------
	# REGLA 1: DETECCIÓN DE DEMORA EXCESIVA (PREVENCIÓN DE FRUSTRACIÓN)
	# Si el estudiante tarda mucho (>= TIEMPO_LENTO), independientemente de si acertó
	# con mucho esfuerzo o falló, se reduce el nivel para ofrecer preguntas más
	# sencillas y evitar bloqueo mental o fatiga.
	# -------------------------------------------------------------------------
	if tiempo_tardado >= TIEMPO_LENTO:
		respuestas_lentas_consecutivas += 1
		
		if dificultad_actual == Dificultad.DIFICIL:
			nueva_dificultad = Dificultad.MEDIA
			print("🧠 SE [Anti-Frustración]: Demora detectada (%.1fs). Bajando de DIFÍCIL a MEDIA para aliviar la carga cognitiva." % tiempo_tardado)
		elif dificultad_actual == Dificultad.MEDIA:
			nueva_dificultad = Dificultad.FACIL
			print("🧠 SE [Anti-Frustración]: Demora detectada (%.1fs). Bajando de MEDIA a FÁCIL para motivar con problemas más sencillos." % tiempo_tardado)
		else:
			print("🧠 SE [Anti-Frustración]: Demora detectada (%.1fs). El estudiante ya está en nivel FÁCIL, manteniéndolo para afianzar seguridad." % tiempo_tardado)
			
		return nueva_dificultad

	# Si respondió en tiempo normal o rápido, reseteamos el contador de lentitud
	respuestas_lentas_consecutivas = 0

	# -------------------------------------------------------------------------
	# REGLA 2: RESPUESTA CORRECTA EN TIEMPO ÁGIL O ADECUADO
	# -------------------------------------------------------------------------
	if es_correcta:
		errores_consecutivos = 0
		
		# Si respondió muy rápido (<= TIEMPO_RAPIDO), domina el nivel y sube dificultad
		if tiempo_tardado <= TIEMPO_RAPIDO:
			if dificultad_actual == Dificultad.FACIL:
				nueva_dificultad = Dificultad.MEDIA
				print("🧠 SE [Aceleración]: ¡Excelente agilidad (%.1fs)! Subiendo a dificultad MEDIA." % tiempo_tardado)
			elif dificultad_actual == Dificultad.MEDIA:
				nueva_dificultad = Dificultad.DIFICIL
				print("🧠 SE [Aceleración]: ¡Dominio total y veloz (%.1fs)! Subiendo a dificultad DIFÍCIL." % tiempo_tardado)
			else:
				print("🧠 SE: Desempeño sobresaliente en nivel DIFÍCIL (%.1fs). Máximo nivel alcanzado." % tiempo_tardado)
		else:
			# Tiempo entre TIEMPO_RAPIDO y TIEMPO_LENTO: ritmo óptimo, se consolida el nivel
			print("🧠 SE [Consolidación]: Ritmo adecuado (%.1fs) y respuesta correcta. Manteniendo dificultad actual (%d)." % [tiempo_tardado, dificultad_actual])

	# -------------------------------------------------------------------------
	# REGLA 3: RESPUESTA INCORRECTA EN TIEMPO NO LENTO
	# -------------------------------------------------------------------------
	else:
		errores_consecutivos += 1
		
		# Si estaba en difícil y se equivoca, bajamos a media para evitar frustración
		if dificultad_actual == Dificultad.DIFICIL:
			nueva_dificultad = Dificultad.MEDIA
			print("🧠 SE [Ajuste]: Error en nivel DIFÍCIL. Bajando a MEDIA para reajustar reto.")
		# Si acumula 2 errores o estaba en media con error, facilitamos a fácil
		elif dificultad_actual == Dificultad.MEDIA and errores_consecutivos >= 2:
			nueva_dificultad = Dificultad.FACIL
			print("🧠 SE [Refuerzo]: Errores acumulados en nivel MEDIO. Bajando a FÁCIL para recuperar confianza.")
		else:
			print("🧠 SE: Error puntual rápido (%.1fs). Posible distracción momentánea, manteniendo nivel (%d)." % [tiempo_tardado, dificultad_actual])

	return nueva_dificultad

# Método auxiliar para reiniciar métricas de sesión cuando cambia de partida o usuario
func reiniciar_metricas_sesion() -> void:
	respuestas_lentas_consecutivas = 0
	errores_consecutivos = 0
	print("🧠 SE: Métricas de sesión pedagógica reiniciadas.")
