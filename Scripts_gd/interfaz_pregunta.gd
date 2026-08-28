extends CanvasLayer

# Usamos @onready con la ruta jerárquica real de tu árbol de escenas
@onready var label_operacion: RichTextLabel = $Panel/RichTextLabel
@onready var boton1: TextureButton = $Panel/GridContainer/Boton1
@onready var boton2: TextureButton = $Panel/GridContainer/Boton2
@onready var boton3: TextureButton = $Panel/GridContainer/Boton3
@onready var boton4: TextureButton = $Panel/GridContainer/Boton4
@onready var label1: Label = $Panel/GridContainer/Boton1/Resultado1
@onready var label2: Label = $Panel/GridContainer/Boton2/Resultado2
@onready var label3: Label = $Panel/GridContainer/Boton3/Resultado3
@onready var label4: Label = $Panel/GridContainer/Boton4/Resultado4

var respuesta_correcta = 0
var tiempo_inicio: float = 0.0
signal respuesta_completada(es_correcta, tiempo_tardado)

func _ready():
	# 🛡️ ASEGURAR QUE LOS TEXTOS Y ETIQUETAS NUNCA BLOQUEEN LOS CLICKS
	if label_operacion:
		label_operacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	for btn in [boton1, boton2, boton3, boton4]:
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
			
	for lbl in [label1, label2, label3, label4]:
		if lbl:
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)

func actualizar_datos_pantalla(datos_pregunta: Dictionary):
	boton1.disabled = false
	boton2.disabled = false
	boton3.disabled = false
	boton4.disabled = false
	
	label_operacion.text = str("¿Cuánto es " + datos_pregunta["operacion"] + "?")
	GestionAudio.decir_frase(label_operacion.text)
	label_operacion.modulate = Color(0.0, 0.0, 0.0, 1.0)
	respuesta_correcta = datos_pregunta["respuesta_correcta"]
	
	var opciones = [
		datos_pregunta["respuesta_correcta"],
		datos_pregunta["opcion_falsa1"],
		datos_pregunta["opcion_falsa2"],
		datos_pregunta["opcion_falsa3"]
	]
	opciones.shuffle()
	
	label1.text = str(int(opciones[0]))
	label2.text = str(int(opciones[1]))
	label3.text = str(int(opciones[2]))
	label4.text = str(int(opciones[3]))
	
	tiempo_inicio = Time.get_ticks_msec()
	print("Tiempo transcurrido para tiempo_inicio: ", tiempo_inicio)

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
	var segundos_tardados = (tiempo_final - tiempo_inicio) / 1000.0
	
	if int(texto_boton) == respuesta_correcta:
		print("¡Correcto! 🎉")
		label_operacion.text = "¡Excelente! "
		label_operacion.modulate = Color(0.2, 1, 0.2)
		await get_tree().create_timer(1.2).timeout
		respuesta_completada.emit(true, segundos_tardados)
	else:
		print("Incorrecto... ")
		label_operacion.text = "¡Oh, no! Ocurrió un error "
		label_operacion.modulate = Color(1, 0.2, 0.2)
		await get_tree().create_timer(1.2).timeout
		respuesta_completada.emit(false, segundos_tardados)
