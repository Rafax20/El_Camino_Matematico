extends Node2D

@onready var path_follow = $Path2D/PathFollow2D

var total_casillas = 23
var casilla_actual = 0

func _ready():
	
	await get_tree().process_frame
	
	# Ahora sí, intentamos la consulta
	var consulta = SupabaseQuery.new().from("puntuaciones").select()
	var tarea = Supabase.database.query(consulta)
	var resultado = await tarea.completed

	if resultado.error == null:
		print("✅ Conexión exitosa: ¡Godot está conectado a Supabase!")
	else:
		print("❌ Error de conexión: ", resultado.error.message)

func _on_boton_dado_pressed():
	# 1. Generar resultado del dado
	var resultado = randi_range(1, 6)
	print("Salió un: ", resultado)
	
	# 2. Mover la ficha
	avanzar_casillas(resultado)
	
	# 3. ENVIAR A LA BASE DE DATOS
	# Aquí enviamos el nombre del usuario y su nueva posición
	enviar_puntuacion("Jugador1", casilla_actual)

func avanzar_casillas(cantidad):
	if casilla_actual + cantidad > total_casillas:
		print("¡Llegaste a la meta!")
		casilla_actual = total_casillas
	else:
		casilla_actual += cantidad
	
	var casilla_destino = [0.0537, 0.107, 0.1521, 0.1972, 0.2423, 0.2874, 0.3407, 0.3776, 0.4145, 0.4473,
	0.4924, 0.5293, 0.5744, 0.6113, 0.6646, 0.7097, 0.7548, 0.7999, 0.8368, 0.8737, 0.9106, 0.9557, 1]
	var tween = create_tween()
	tween.tween_property(path_follow, "progress_ratio", casilla_destino[casilla_actual-1], 1.0).set_trans(Tween.TRANS_SINE)

# --- LÓGICA DE RED ---

func enviar_puntuacion(nombre_usuario: String, puntos: int):
	var datos = {
		"nombre": nombre_usuario, 
		"casilla": puntos
	}
	
	var consulta = SupabaseQuery.new().from("puntuaciones").insert([datos])
	
	var tarea = Supabase.database.query(consulta)
	var resultado = await tarea.completed
	
	if resultado.error == null:
		print("✅ ¡Puntuación guardada en la nube con éxito!")
	else:
		print("❌ Error al guardar: ", resultado.error.message)
	
