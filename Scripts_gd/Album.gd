extends Control

@onready var grid_laminas = $GridLaminas
@onready var label_titulo_pais = $Titulo_pais

@onready var boton_anterior = $BotonAnterior
@onready var boton_siguiente = $BotonSiguiente

# 📌 Estructura de navegación sin duplicar rutas de imágenes
var paginas_mundial: Array = [
	{ "pais": "Venezuela", "inicio": 1, "fin": 18 },
	{ "pais": "Argentina", "inicio": 19, "fin": 36 },
	{ "pais": "Portugal", "inicio": 37, "fin": 54 },
	{ "pais": "España", "inicio": 55, "fin": 62 },
	{ "pais": "Inglaterra", "inicio": 63, "fin": 80 },
]

var pagina_actual_indice: int = 0

func _ready():
	pagina_actual_indice = 0
	await ConexionSupabase.cargar_album_nube()
	_mostrar_pagina(pagina_actual_indice, "derecha")

var is_animating: bool = false # 🔒 Bandera de bloqueo

func _mostrar_pagina(indice: int, direccion: String):
	# 🔒 1. PROTECCIÓN: Si ya hay una animación en curso, salimos
	if is_animating: 
		return
		
	is_animating = true
	
	# Deshabilitamos botones para evitar interrupciones durante la transición
	boton_anterior.disabled = true
	boton_siguiente.disabled = true
	
	var datos_pais = paginas_mundial[indice]
	label_titulo_pais.text = "Colección " + datos_pais["pais"] + " - Edición Especial"
	
	# 🎬 2. ANIMACIÓN DE SALIDA
	var tween = create_tween().set_parallel(true)
	var offset_salida = -300 if direccion == "derecha" else 300
	tween.tween_property(grid_laminas, "position:x", grid_laminas.position.x + offset_salida, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(grid_laminas, "modulate:a", 0.0, 0.25)
	
	await tween.finished
	
	# 🛠️ 3. CONSTRUCCIÓN DINÁMICA
	for hijo in grid_laminas.get_children():
		hijo.queue_free()
		
	var escena_ranura = preload("res://Escenas/RanuraLamina.tscn")
	for id in range(datos_pais["inicio"], datos_pais["fin"] + 1):
		var nueva_ranura = escena_ranura.instantiate()
		grid_laminas.add_child(nueva_ranura)
		nueva_ranura.id_lamina = id
		
		# Referencia al catálogo centralizado en DatosUsuario
		if DatosUsuario.CATALOGO_LAMINAS.has(id):
			nueva_ranura.textura_jugador = load(DatosUsuario.CATALOGO_LAMINAS[id])
		else:
			nueva_ranura.textura_jugador = null
			
		nueva_ranura.actualizar_estado()
		
	# Actualizamos visibilidad de botones
	boton_anterior.visible = (indice > 0)
	boton_siguiente.visible = (indice < paginas_mundial.size() - 1)
	
	# 🎬 4. ANIMACIÓN DE ENTRADA
	var posicion_original_x = (size.x - grid_laminas.size.x) / 2
	var offset_entrada = 300 if direccion == "derecha" else -300
	
	grid_laminas.position.x = posicion_original_x + offset_entrada
	
	var tween_entrada = create_tween().set_parallel(true)
	tween_entrada.tween_property(grid_laminas, "position:x", posicion_original_x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_entrada.tween_property(grid_laminas, "modulate:a", 1.0, 0.3)
	
	await tween_entrada.finished
	
	# 🔓 5. REINICIO: Reactivamos botones y liberamos el bloqueo
	boton_anterior.disabled = false
	boton_siguiente.disabled = false
	is_animating = false

func _on_boton_siguiente_pressed():
	if pagina_actual_indice < paginas_mundial.size() - 1:
		pagina_actual_indice += 1
		_mostrar_pagina(pagina_actual_indice, "derecha")

func _on_boton_anterior_pressed():
	if pagina_actual_indice > 0:
		pagina_actual_indice -= 1
		_mostrar_pagina(pagina_actual_indice, "izquierda")
