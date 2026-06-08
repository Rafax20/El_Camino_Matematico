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
		respuesta_completada.emit(true)
	else:
		print("Incorrecto... ❌ Inténtalo de nuevo.")
		respuesta_completada.emit(false)
