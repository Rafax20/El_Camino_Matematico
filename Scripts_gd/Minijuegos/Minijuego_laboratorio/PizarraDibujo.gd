extends Control

var trazados: Array = []
var trazo_actual: Array = []
var dibujando: bool = false
var color_lapiz: Color = Color(0.15, 0.15, 0.2, 1.0)
var grosor_lapiz: float = 4.0

func _ready():
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dibujando = true
			trazo_actual = [_limitar_posicion(event.position)]
			accept_event()
		else:
			if dibujando:
				if trazo_actual.size() > 1:
					trazados.append({
						"puntos": trazo_actual.duplicate(),
						"color": color_lapiz,
						"grosor": grosor_lapiz
					})
				dibujando = false
				trazo_actual = []
				queue_redraw()
				accept_event()

	elif event is InputEventMouseMotion and dibujando:
		trazo_actual.append(_limitar_posicion(event.position))
		queue_redraw()
		accept_event()

func _limitar_posicion(pos: Vector2) -> Vector2:
	return Vector2(clamp(pos.x, 0.0, size.x), clamp(pos.y, 0.0, size.y))

func _draw():
	for linea in trazados:
		if linea["puntos"].size() > 1:
			draw_polyline(linea["puntos"], linea["color"], linea["grosor"], true)
			
	if trazo_actual.size() > 1:
		draw_polyline(trazo_actual, color_lapiz, grosor_lapiz, true)

func limpiar_pizarra():
	trazados.clear()
	trazo_actual.clear()
	queue_redraw()
