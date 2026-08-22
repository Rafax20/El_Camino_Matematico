# res://Escenas/LogrosTablero.gd
extends Control

# Capacidad máxima de elementos que caben visualmente en tu GridLaminas por página
const LOGROS_POR_PAGINA: int = 18

@onready var grid_laminas = $GridLaminas
@onready var label_titulo_pais = $Titulo_pais
@onready var boton_anterior = $BotonAnterior
@onready var boton_siguiente = $BotonSiguiente

# 📌 Arreglo único y plano de logros. Simplemente agregas los IDs que quieras aquí.
var lista_total_logros: Array = [
	101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
	111, 112, 113, 114, 115, 116, 117, 118, 119, 120 # 20 logros = 2 páginas automáticas
]

var pagina_actual_indice: int = 0
var total_paginas: int = 1
var posicion_original_y: float = 0.0
var posicion_original_x: float = 0.0
var is_animating: bool = false

func _ready():
	pagina_actual_indice = 0
	posicion_original_y = grid_laminas.position.y
	posicion_original_x = grid_laminas.position.x
	
	if ConexionSupabase.has_method("cargar_album_nube"):
		await ConexionSupabase.cargar_album_nube()
		
	_calcular_total_paginas()
	_mostrar_pagina(pagina_actual_indice, "derecha")

# 🧮 Calcula la cantidad de páginas necesarias en función de los logros que tengas
func _calcular_total_paginas():
	if lista_total_logros.size() == 0:
		total_paginas = 1
	else:
		total_paginas = ceil(float(lista_total_logros.size()) / float(LOGROS_POR_PAGINA))

func _mostrar_pagina(indice: int, direccion: String):
	if is_animating: 
		return
		
	is_animating = true
	
	boton_anterior.disabled = true
	boton_siguiente.disabled = true
	
	if label_titulo_pais:
		label_titulo_pais.text = "Mis Logros (Página %d de %d)" % [indice + 1, total_paginas]
	
	# 🎬 ANIMACIÓN DE SALIDA
	var tween = create_tween().set_parallel(true)
	var offset_salida = -300 if direccion == "derecha" else 300
	tween.tween_property(grid_laminas, "position:x", grid_laminas.position.x + offset_salida, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(grid_laminas, "modulate:a", 0.0, 0.25)
	
	await tween.finished
	
	# 🛠️ CONSTRUCCIÓN DINÁMICA DE LA PÁGINA ACTUAL
	for hijo in grid_laminas.get_children():
		hijo.queue_free()
		
	var escena_ranura = preload("res://Escenas/RanuraLamina.tscn")
	
	# Obtener solo la porción (slice) de logros que pertenecen a esta página
	var inicio = indice * LOGROS_POR_PAGINA
	var fin = min(inicio + LOGROS_POR_PAGINA, lista_total_logros.size())
	var logros_pagina = lista_total_logros.slice(inicio, fin)
	
	for id_logro in logros_pagina:
		var nueva_ranura = escena_ranura.instantiate()
		grid_laminas.add_child(nueva_ranura)
		nueva_ranura.id_lamina = id_logro
		
		if DatosUsuario.CATALOGO_LAMINAS.has(id_logro):
			nueva_ranura.textura_jugador = DatosUsuario.CATALOGO_LAMINAS[id_logro]
		else:
			nueva_ranura.textura_jugador = null
			
		nueva_ranura.actualizar_estado()
		
	# 🔘 VISIBILIDAD INTELIGENTE DE BOTONES
	boton_anterior.visible = (indice > 0)
	boton_siguiente.visible = (indice < total_paginas - 1)
	
	# 🎬 ANIMACIÓN DE ENTRADA
	var offset_entrada = 300 if direccion == "derecha" else -300
	grid_laminas.position.x = posicion_original_x + offset_entrada
	grid_laminas.position.y = posicion_original_y 

	var tween_entrada = create_tween().set_parallel(true)
	tween_entrada.tween_property(grid_laminas, "position:x", posicion_original_x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_entrada.tween_property(grid_laminas, "modulate:a", 1.0, 0.3)

	await tween_entrada.finished
	
	boton_anterior.disabled = false
	boton_siguiente.disabled = false
	is_animating = false

func _on_boton_siguiente_pressed():
	if pagina_actual_indice < total_paginas - 1:
		pagina_actual_indice += 1
		_mostrar_pagina(pagina_actual_indice, "derecha")

func _on_boton_anterior_pressed():
	if pagina_actual_indice > 0:
		pagina_actual_indice -= 1
		_mostrar_pagina(pagina_actual_indice, "izquierda")
