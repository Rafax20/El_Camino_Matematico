# res://Escenas/LogrosTablero.gd
extends Control

const LOGROS_POR_PAGINA: int = 8

@onready var grid_laminas = $GridLaminas
@onready var label_titulo_pais = $Titulo_pais
@onready var boton_anterior = $BotonAnterior
@onready var boton_siguiente = $BotonSiguiente
@onready var label_descripcion = $PanelDescripcion/LabelDescripcion

# 📌 Arreglo dinámico (se llenará solo con los logros registrados)
var lista_total_logros: Array = []

var pagina_actual_indice: int = 0
var total_paginas: int = 1
var posicion_original_y: float = 0.0
var posicion_original_x: float = 0.0
var is_animating: bool = false

const TEXTO_DEFAULT = "[center]Toca o pasa el ratón sobre un logro para ver cómo conseguirlo[/center]"

# Catálogo pedagógico y divertido de logros
const DESCRIPCIONES_LOGROS: Dictionary = {
	1: {
		"nombre": "Explorador del Cosmos",
		"desbloqueado": "¡Llegaste a la meta y conquistaste todo el tablero!",
		"bloqueado": "¡Llega hasta la casilla final del tablero para ganar este trofeo!"
	},
	2: {
		"nombre": "Destructor de Asteroides",
		"desbloqueado": "¡Defendiste la galaxia destruyendo asteroides matemáticos!",
		"bloqueado": "¡Gana el minijuego de asteroides resolviendo las operaciones espaciales!"
	},
	3: {
		"nombre": "Cazador de Misterios",
		"desbloqueado": "¡Exploraste las salas y hallaste todas las cajas matemáticas!",
		"bloqueado": "¡Gana el minijuego del buscador encontrando las cajas ocultas!"
	},
	4: {
		"nombre": "Alquimista Numérico",
		"desbloqueado": "¡Creaste la fórmula perfecta en el laboratorio científico!",
		"bloqueado": "¡Supera el minijuego del laboratorio combinando las pociones correctas!"
	},
	5: {
		"nombre": "Maestro del Equilibrio",
		"desbloqueado": "¡Equilibraste la balanza con una precisión asombrosa!",
		"bloqueado": "¡Gana el minijuego de la balanza igualando los pesos y números!"
	},
	6: {
		"nombre": "As de la Clasificación",
		"desbloqueado": "¡Clasificaste todas las figuras y números a la velocidad de la luz!",
		"bloqueado": "¡Supera el minijuego del clasificador ordenando todo rápidamente!"
	},
	7: {
		"nombre": "Genio de la Energía",
		"desbloqueado": "¡Encendiste toda la nave reparando los circuitos eléctricos!",
		"bloqueado": "¡Gana el minijuego de circuitos conectando las sumas correctas!"
	}
}

func _ready():
	pagina_actual_indice = 0
	posicion_original_y = grid_laminas.position.y
	posicion_original_x = grid_laminas.position.x
	
	if label_descripcion:
		label_descripcion.text = TEXTO_DEFAULT
	
	# ⚡ Cargar dinámicamente los IDs desde DatosUsuario.CATALOGO_LOGROS
	lista_total_logros = DatosUsuario.CATALOGO_LOGROS.keys()
	
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
		label_titulo_pais.text = "[center]Mis Logros (Página %d de %d)[/center]" % [indice + 1, total_paginas]
	
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
		nueva_ranura.es_logro = true
		
		# 🔄 Usar CATALOGO_LOGROS
		if DatosUsuario.CATALOGO_LOGROS.has(id_logro):
			nueva_ranura.textura_jugador = DatosUsuario.CATALOGO_LOGROS[id_logro]
		else:
			nueva_ranura.textura_jugador = null
			
		nueva_ranura.actualizar_estado()
		
		# 🖱️ Conectar eventos de cursor
		nueva_ranura.logro_hovered.connect(_on_logro_hovered)
		nueva_ranura.logro_unhovered.connect(_on_logro_unhovered)
		
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

# 🎯 Evento al pasar el ratón sobre un logro
func _on_logro_hovered(id_logro: int, desbloqueado: bool):
	if not label_descripcion:
		return
	
	var info = DESCRIPCIONES_LOGROS.get(id_logro, {
		"nombre": "Misión Secreta #" + str(id_logro),
		"desbloqueado": "¡Logro especial completado!",
		"bloqueado": "¡Juega y supera desafíos en el tablero para descubrir este logro!"
	})
	
	if desbloqueado:
		label_descripcion.text = "[center][color=#80d8ff][b]" + info["nombre"] + ":[/b][/color] [color=#b9f6ca]" + info["desbloqueado"] + "[/color][/center]"
	else:
		label_descripcion.text = "[center][color=#ffd54f][b]" + info["nombre"] + ":[/b][/color] [color=#ffffff]" + info["bloqueado"] + "[/color][/center]"

# 🎯 Evento al retirar el ratón de un logro
func _on_logro_unhovered():
	if label_descripcion:
		label_descripcion.text = TEXTO_DEFAULT

func _on_boton_siguiente_pressed():
	if pagina_actual_indice < total_paginas - 1:
		pagina_actual_indice += 1
		_mostrar_pagina(pagina_actual_indice, "derecha")

func _on_boton_anterior_pressed():
	if pagina_actual_indice > 0:
		pagina_actual_indice -= 1
		_mostrar_pagina(pagina_actual_indice, "izquierda")
