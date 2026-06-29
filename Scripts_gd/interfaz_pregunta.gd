extends CanvasLayer

# Usamos @onready con la ruta jerárquica real de tu árbol de escenas
@onready var label_operacion = $Panel/Label
@onready var boton1 = $Panel/GridContainer/Boton1
@onready var boton2 = $Panel/GridContainer/Boton2
@onready var boton3 = $Panel/GridContainer/Boton3
@onready var boton4 = $Panel/GridContainer/Boton4
@onready var label1 = $Panel/GridContainer/Boton1/Resultado1
@onready var label2 = $Panel/GridContainer/Boton2/Resultado2
@onready var label3 = $Panel/GridContainer/Boton3/Resultado3
@onready var label4 = $Panel/GridContainer/Boton4/Resultado4


var respuesta_correcta = 0
var tiempo_inicio: float = 0.0
signal respuesta_completada(es_correcta)

func actualizar_datos_pantalla(datos_pregunta: Dictionary):
	boton1.disabled = false
	boton2.disabled = false
	boton3.disabled = false
	boton4.disabled = false
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
	
	label1.text = str(opciones[0])
	label2.text = str(opciones[1])
	label3.text = str(opciones[2])
	label4.text = str(opciones[3])
	
	tiempo_inicio = Time.get_ticks_msec() # Guarda el milisegundo exacto de inicio
	print("Tiempo transcurrido para tiempo_inicio: ", tiempo_inicio)

# Funciones de clicks limpias usando las variables en caché
func _on_boton_1_pressed(): verificar_respuesta(label1.text)
func _on_boton_2_pressed(): verificar_respuesta(label2.text)
func _on_boton_3_pressed(): verificar_respuesta(label3.text)
func _on_boton_4_pressed(): verificar_respuesta(label4.text)

func verificar_respuesta(texto_boton: String):
	boton1.disabled = true
	boton2.disabled = true
	boton3.disabled = true
	boton4.disabled = true
	var tiempo_final = Time.get_ticks_msec()
	print("Tiempo transcurrido al presionar respuesta: ", tiempo_final)
	var segundos_tardados = (tiempo_final - tiempo_inicio) / 1000.0
	print("Segundos transcurridos para responder: ", int(segundos_tardados))
	
	if int(texto_boton) == respuesta_correcta:
		print("¡Correcto! 🎉")
		
		# 🥳 FEEDBACK INFANTIL VISUAL DIRECTO EN EL TITULO
		label_operacion.text = "¡Excelente! 🎉🎯"
		label_operacion.modulate = Color(0.2, 1, 0.2) # Verde alegre
		
		# Esperamos un segundo para que el niño lea el logro
		await get_tree().create_timer(1.2).timeout
		
		# Restauramos el color original blanco y avisamos al tablero
		label_operacion.modulate = Color(1, 1, 1)
		respuesta_completada.emit(true, segundos_tardados)
	else:
		print("Incorrecto... ❌")
		
		label_operacion.text = "¡Oh, no! Ocurrió un error ❌"
		label_operacion.modulate = Color(1, 0.2, 0.2) # Rojo advertencia
		
		await get_tree().create_timer(1.2).timeout
		
		label_operacion.modulate = Color(1, 1, 1)
		respuesta_completada.emit(false, segundos_tardados)
