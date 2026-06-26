## res://Scripts_gd/ArbolDecisionMaestro.gd
#extends Node
#
## Esta función representa nuestro Árbol de Decisión Inteligente
#func procesar_diagnostico(aciertos: int, fallas: int, tiempo_promedio: float) -> String:
	#var total_preguntas = aciertos + fallas
	#
	## Control de seguridad si el niño no ha jugado
	#if total_preguntas == 0:
		#return "El estudiante aún no registra actividad en el tablero."
		#
	#var porcentaje_exito = (float(aciertos) / float(total_preguntas)) * 100.0
	#var diagnostico = ""
	#
	## === NODO RAÍZ: ¿El estudiante aprueba el umbral básico (70%)? ===
	#if porcentaje_exito >= 70.0:
		## Ramificación A: Alto rendimiento
		## Sub-nodo: Evaluación de Fluidez por Tiempo
		#if tiempo_promedio <= 12.0:
			#diagnostico = "Dominio Sobresaliente: El alumno resuelve los problemas con alta precisión y automatización cognitiva (procesamiento rápido). Está listo para desafíos de lógica avanzada."
		#else:
			#diagnostico = "Dominio Preciso pero Lento: El alumno comprende los conceptos y responde correctamente, pero requiere un tiempo elevado de cálculo mental. Se sugiere practicar velocidad."
	#else:
		## Ramificación B: Rendimiento bajo el promedio (Requiere atención)
		## Sub-nodo: Analizar si el fallo es por frustración o distracción
		#if tiempo_promedio >= 25.0:
			#diagnostico = "🚨 Alerta de Rezago Cognitivo: El alumno presenta serias dificultades. Tarda mucho tiempo y la mayoría de sus respuestas son incorrectas. Requiere intervención pedagógica urgente y tutoría personalizada."
		#elif tiempo_promedio <= 8.0:
			#diagnostico = "⚠️ Patrón de Impulsividad/Distracción: El estudiante responde de forma incorrecta pero sumamente rápido. Este comportamiento indica falta de lectura o respuestas al azar, más que incapacidad matemática."
		#else:
			#diagnostico = "Refuerzo Requerido: El alumno trabaja a un ritmo normal pero confunde los procedimientos operativos. Se recomienda repasar las bases de las operaciones en las que falló."
			#
	#return diagnostico
