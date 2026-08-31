# res://Scripts_gd/Globales/ArbolDecisionMaestro.gd
extends Node

## Árbol de Decisión Inteligente para Diagnóstico Pedagógico
## Evalúa aciertos, errores, tiempos de respuesta y categorías para orientar al maestro.

func procesar_diagnostico_global(aciertos: int, fallas: int, tiempo_promedio: float, datos_categorias: Dictionary = {}) -> Dictionary:
	var total_preguntas = aciertos + fallas
	
	if total_preguntas == 0:
		return {
			"titulo": "Sin Registros de Actividad",
			"nivel": "neutral",
			"diagnostico": "El estudiante aún no registra intentos en el tablero o minijuegos.",
			"recomendacion": "Motivar al estudiante a ingresar a los minijuegos espaciales para comenzar a recopilar métricas.",
			"icono": ""
		}
		
	var porcentaje_exito = (float(aciertos) / float(total_preguntas)) * 100.0
	var res = {
		"titulo": "",
		"nivel": "",
		"diagnostico": "",
		"recomendacion": "",
		"icono": ""
	}
	
	# === RAMA 1: Alto Desempeño (Precisión >= 75%) ===
	if porcentaje_exito >= 75.0:
		if tiempo_promedio <= 6.0:
			res["titulo"] = "Dominio Sobresaliente y Fluido"
			res["nivel"] = "excelente"
			res["icono"] = ""
			res["diagnostico"] = "El estudiante demuestra automatización cognitiva y excelente velocidad mental. Resuelve operaciones con alta seguridad y precisión matemática."
			res["recomendacion"] = "El alumno está listo para desafíos de mayor dificultad y operaciones combinadas avanzadas."
		else:
			res["titulo"] = "Alta Precisión con Cálculo Pausado"
			res["nivel"] = "bueno"
			res["icono"] = ""
			res["diagnostico"] = "Comprende los conceptos correctamente y acierta casi siempre, pero requiere un tiempo elevado de cálculo mental (superior al promedio)."
			res["recomendacion"] = "Incentivar actividades lúdicas de agilidad mental (ej. minijuego de asteroides) para desarrollar fluidez sin perder precisión."
			
	# === RAMA 2: Desempeño Medio (50% - 74%) ===
	elif porcentaje_exito >= 50.0:
		if tiempo_promedio <= 5.0:
			res["titulo"] = "Patrón de Impulsividad"
			res["nivel"] = "atencion"
			res["icono"] = ""
			res["diagnostico"] = "El estudiante responde con mucha prisa pero comete errores evitables. Su velocidad rápida con fallas sugiere respuestas intuitivas sin verificación previa."
			res["recomendacion"] = "Trabajar en la pausa reflexiva: pedirle que verifique mentalmente antes de pulsar la opción."
		else:
			res["titulo"] = "Consolidación en Proceso"
			res["nivel"] = "regular"
			res["icono"] = ""
			res["diagnostico"] = "El estudiante comprende parte de las operaciones pero muestra dudas en procedimientos específicos."
			res["recomendacion"] = "Revisar la categoría con menor porcentaje de acierto para reforzar las bases operativas."
			
	# === RAMA 3: Desempeño Bajo (< 50%) ===
	else:
		if tiempo_promedio >= 15.0:
			res["titulo"] = "Alerta de Rezago Cognitivo"
			res["nivel"] = "critico"
			res["icono"] = ""
			res["diagnostico"] = "El estudiante tarda mucho tiempo en contestar y la mayoría de sus respuestas son erróneas. Presenta frustración o bloqueo ante los problemas planteados."
			res["recomendacion"] = "Intervención pedagógica personalizada urgente: regresar a representaciones visuales concretas y nivel básico de dificultad."
		elif tiempo_promedio <= 4.0:
			res["titulo"] = "Respuestas al Azar / Desconexión"
			res["nivel"] = "critico"
			res["icono"] = ""
			res["diagnostico"] = "Respuestas sumamente rápidas e incorrectas. Indica que el alumno está pulsando opciones al azar sin leer la pregunta."
			res["recomendacion"] = "Establecer metas guiadas y supervisar la lectura comprensiva de cada enunciado."
		else:
			res["titulo"] = "Dificultad Operativa General"
			res["nivel"] = "bajo"
			res["icono"] = ""
			res["diagnostico"] = "El estudiante muestra bajo índice de acierto a ritmo regular. Requiere afianzar algoritmos aritméticos fundamentales."
			res["recomendacion"] = "Priorizar minijuegos de operaciones simples (ej. Balanza) antes de avanzar a problemas combinados."
			
	# Evaluación complementaria por categorías específicas
	if datos_categorias.size() > 0:
		var debilidades: Array = []
		for cat in datos_categorias.keys():
			var cat_data = datos_categorias[cat]
			var total_c = cat_data.get("aciertos", 0) + cat_data.get("fallas", 0)
			if total_c >= 2:
				var pct_c = (float(cat_data.get("aciertos", 0)) / float(total_c)) * 100.0
				if pct_c < 50.0:
					var nombre_formateado = "Regla de 3" if cat == "regla_de_tres" else cat.capitalize()
					debilidades.append(nombre_formateado)
					
		if debilidades.size() > 0:
			res["recomendacion"] += " [Refuerzo prioritario detectado en: " + ", ".join(debilidades) + "]"
			
	return res
