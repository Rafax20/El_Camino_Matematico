## res://Scripts_gd/Album.gd
#extends Control
#
#@onready var grid_laminas = $GridLaminas
#@onready var label_titulo_pais = $TituloPais # Un Label para mostrar el nombre del país actual
#
## 📌 Diccionario de configuración de las páginas del álbum
#var paginas_mundial = {
	#"Venezuela": {"inicio": 1, "fin": 4, "fotos": {
		#1: preload("res://Assets/Album/ven_escudo.png"),
		#2: preload("res://Assets/Album/ven_jugador1.png"),
		#3: preload("res://Assets/Album/ven_jugador2.png"),
		#4: preload("res://Assets/Album/ven_jugador3.png")
	#}},
	#"Argentina": {"inicio": 5, "fin": 8, "fotos": {
		#5: preload("res://Assets/Album/arg_escudo.png"),
		#6: preload("res://Assets/Album/arg_jugador1.png"),
		#7: preload("res://Assets/Album/arg_jugador2.png"),
		#8: preload("res://Assets/Album/arg_jugador3.png")
	#}}
#}
#
## Variable que define qué país estamos viendo actualmente (Se puede setear al cambiar de escena)
#var pais_actual: String = "Venezuela"
#
#func _ready():
	#label_titulo_pais.text = "Álbum: " + pais_actual
	#
	## ⏳ Traemos los datos frescos de Supabase
	#await ConexionSupabase.cargar_album_nube()
	#
	## 🛠️ Generamos dinámicamente las ranuras en la cuadrícula
	#_construir_pagina_album()
#
#func _construir_pagina_album():
	## Limpiamos cualquier ranura vieja por si acaso
	#for hijo in grid_laminas.get_children():
		#hijo.queue_free()
		#
	#var datos_pais = paginas_mundial[pais_actual]
	#var escena_ranura = preload("res://Escenas/RanuraLamina.tscn")
	#
	## Creamos los nodos correspondientes al rango de IDs de este país
	#for id in range(datos_pais["inicio"], datos_pais["fin"] + 1):
		#var nueva_ranura = escena_ranura.instantiate()
		#grid_laminas.add_child(nueva_ranura)
		#
		## Le inyectamos su ID y su textura correspondiente desde el diccionario
		#nueva_ranura.id_lamina = id
		#nueva_ranura.textura_jugador = datos_pais["fotos"][id]
		#
		## Forzamos a la ranura a evaluar si el niño la posee o se queda en silueta
		#nueva_ranura.actualizar_estado()
