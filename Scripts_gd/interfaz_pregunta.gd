extends CanvasLayer

# Usamos @onready con la ruta jerárquica real de tu árbol de escenas
@onready var label_operacion = $Panel/Label
@onready var boton1 = $Panel/GridContainer/Button
@onready var boton2 = $Panel/GridContainer/Button2
@onready var boton3 = $Panel/GridContainer/Button3
@onready var boton4 = $Panel/GridContainer/Button4

var respuesta_correcta = 0
signal respuesta_completada(es_correcta)

func actualizar_datos_pantalla(datos_pregunta: Dictionary):
	# Ahora el código es totalmente seguro y mucho más rápido
	label_operacion.text = datos_pregunta["operacion"]
	respuesta_correcta = datos_pregunta["respuesta_correcta"]
	
	var opciones = [
		datos_pregunta["respuesta_correcta"],
		datos_pregunta["opcion_falsa1"],
		datos_pregunta["opcion_falsa2"],
		datos_pregunta["opcion_falsa3"]
	]
	opciones.shuffle()
	
	boton1.text = str(opciones[0])
	boton2.text = str(opciones[1])
	boton3.text = str(opciones[2])
	boton4.text = str(opciones[3])

# Funciones de clicks limpias usando las variables en caché
func _on_button_pressed(): verificar_respuesta(boton1.text)
func _on_button_2_pressed(): verificar_respuesta(boton2.text)
func _on_button_3_pressed(): verificar_respuesta(boton3.text)
func _on_button_4_pressed(): verificar_respuesta(boton4.text)

func verificar_respuesta(texto_boton: String):
	if int(texto_boton) == respuesta_correcta:
		print("¡Correcto! 🎉")
		
		# 🥳 FEEDBACK INFANTIL VISUAL DIRECTO EN EL TITULO
		label_operacion.text = "¡Excelente! 🎉🎯"
		label_operacion.modulate = Color(0.2, 1, 0.2) # Verde alegre
		
		# Esperamos un segundo para que el niño lea el logro
		await get_tree().create_timer(1.2).timeout
		
		# Restauramos el color original blanco y avisamos al tablero
		label_operacion.modulate = Color(1, 1, 1)
		respuesta_completada.emit(true)
	else:
		print("Incorrecto... ❌")
		
		label_operacion.text = "¡Oh, no! Ocurrió un error ❌"
		label_operacion.modulate = Color(1, 0.2, 0.2) # Rojo advertencia
		
		await get_tree().create_timer(1.2).timeout
		
		label_operacion.modulate = Color(1, 1, 1)
		respuesta_completada.emit(false)
