extends Node2D

@onready var path_follow = $Path2D/PathFollow2D
# 🚀 NUEVO: Referencia a tu botón del dado (Ajusta la ruta según tu escena)
@onready var boton_dado = $BotonDado 

var total_casillas = 23
var casilla_actual = 0

# --- VARIABLES DE CONTROL Y RED ---
var esta_conectado_a_la_nube : bool = false
var usuario_uuid : String = ""
var lista_preguntas: Array = []
var pregunta_actual_indice: int = 0

# 🌟 NUEVA BANDERA: Controla si el juego puede empezar o no
var servidor_listo: bool = false

func _ready():
	await get_tree().process_frame
	
	# Desactivamos el botón del dado visual y lógicamente al empezar
	servidor_listo = false
	boton_dado.disabled = true 
	print("⏳ Esperando respuesta del servidor de Supabase...")
	
	# 1. Descargamos las preguntas
	descargar_preguntas_del_servidor()

func descargar_preguntas_del_servidor():
	var consulta = SupabaseQuery.new().from("preguntas").select()
	var tarea = Supabase.database.query(consulta)
	var resultado = await tarea.completed

	if resultado.error == null:
		lista_preguntas = resultado.data
		lista_preguntas.shuffle()
		
		print("✅ Preguntas descargadas con éxito. Cantidad: ", lista_preguntas.size())
		
		if lista_preguntas.size() > 0:
			print("ESTRUCTURA REAL DE TU PREGUNTA: ", lista_preguntas[0])
			
			# 🌟 ¡EL SERVIDOR YA RESPONDIÓ CON DATOS! Activamos el juego
			servidor_listo = true
			boton_dado.disabled = false
			print("🎮 ¡Juego listo! Botón del dado activado.")
			
			# Mostramos la primera pregunta de inicio
			mostrar_pregunta_en_pantalla()
		else:
			print("⚠️ Alerta: El servidor respondió pero la tabla 'preguntas' está vacía.")
		
	else:
		print("❌ Error al traer las preguntas: ", resultado.error.message)
		# 💡 TIP EXTRA: Aquí podrías activar un "Modo Offline de Emergencia" 
		# cargando preguntas desde un archivo JSON local si falla el internet.

func _on_boton_dado_pressed():
	# 🛡️ PROTECCIÓN DE SEGURIDAD: Si por alguna razón el botón se presiona
	# antes de cargar (o si hubo error de red), salimos de la función inmediatamente.
	if not servidor_listo or lista_preguntas.size() == 0:
		print("🚫 Espera un momento... Las preguntas aún se están cargando.")
		return
		
	var resultado = randi_range(1, 6)
	print("Salió un: ", resultado)
	
	avanzar_casillas(resultado)
	
	if esta_conectado_a_la_nube:
		enviar_puntuacion("Jugador1", casilla_actual)
	else:
		print("ℹ️ Modo Local: Posición avanzada a ", casilla_actual)

func avanzar_casillas(cantidad):
	# Si el niño saca un número que lo pasa de la meta, lo dejamos en la casilla final
	if casilla_actual + cantidad > total_casillas:
		print("¡Llegaste a la meta!")
		casilla_actual = total_casillas
	else:
		casilla_actual += cantidad
	
	var casilla_destino = [0.0537, 0.107, 0.1521, 0.1972, 0.2423, 0.2874, 0.3407, 0.3776, 0.4145, 0.4473,
	0.4924, 0.5293, 0.5744, 0.6113, 0.6646, 0.7097, 0.7548, 0.7999, 0.8368, 0.8737, 0.9106, 0.9557, 1]
	
	# 🛡️ PROTECCIÓN EXTRA: Evita errores de índice desbordado (Index out of bounds)
	var indice_casilla = clampi(casilla_actual - 1, 0, casilla_destino.size() - 1)
	
	var tween = create_tween()
	tween.tween_property(path_follow, "progress_ratio", casilla_destino[indice_casilla], 1.0).set_trans(Tween.TRANS_SINE)

# [El resto de tus funciones de red e interfaz se quedan exactamente igual])

# --- LÓGICA DE RED ---

func enviar_puntuacion(nombre_usuario: String, puntos: int):
	# Esta función solo se ejecuta si 'esta_conectado_a_la_nube' es true
	var datos = {
		"user_id": usuario_uuid, # El UUID del jugador conectado
		"nombre": nombre_usuario, 
		"casilla": puntos
	}
	
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	var tarea = Supabase.database.query(consulta)
	var resultado = await tarea.completed
	
	if resultado.error == null:
		print("✅ ¡Puntuación guardada en la nube!")
	else:
		print("❌ Error al guardar: ", resultado.error.message)

func mostrar_pregunta_en_pantalla():
	if lista_preguntas.size() == 0: 
		print("⚠️ Base de datos vacía")
		return

	if pregunta_actual_indice < lista_preguntas.size():
		var datos_pregunta = lista_preguntas[pregunta_actual_indice]
		
		# 🚀 ¡Le pasamos el paquete de Supabase a la interfaz en una sola línea!
		$Interfaz.actualizar_datos_pantalla(datos_pregunta)
		
		pregunta_actual_indice += 1
	else:
		print("¡Se acabaron las preguntas! Mezclando de nuevo...")
		lista_preguntas.shuffle()
		pregunta_actual_indice = 0
		mostrar_pregunta_en_pantalla()
	
#func login ():
	#esta_conectado_a_la_nube = true


func _on_interfaz_respuesta_completada(es_correcta: Variant) -> void:
	if es_correcta:
		print("¡El niño acertó! Ahora puede lanzar el dado o avanzar automáticamente")
		_on_boton_dado_pressed() 
	else:
		# Falló, puedes restarle un intento o simplemente no dejarlo avanzar
		pass
