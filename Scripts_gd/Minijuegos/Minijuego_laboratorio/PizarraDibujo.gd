extends Control

# --- CONFIGURACIÓN DE PINTURA ---
var trazados: Array = []
var trazo_actual: Array = []
var dibujando: bool = false
var color_lapiz: Color = Color(0.1, 0.1, 0.1, 1.0) # Gris oscuro
var grosor_lapiz: float = 5.0

@onready var btn_borrar: Button = $"../BtnBorrar"
@onready var btn_cerrar: Button = $"../BtnCerrar"

func _ready():
	# Permitir que el Control detecte eventos de entrada directamente
	mouse_filter = MOUSE_FILTER_STOP
	
	if btn_borrar and not btn_borrar.pressed.is_connected(limpiar_pizarra):
		btn_borrar.pressed.connect(limpiar_pizarra)
	if btn_cerrar and not btn_cerrar.pressed.is_connected(_cerrar_pizarra):
		btn_cerrar.pressed.connect(_cerrar_pizarra)

func _gui_input(event: InputEvent):
	# Se activa solo cuando haces clic DENTRO del área delimitada por LienzoDibujo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dibujando = true
			trazo_actual = [event.position]
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
		trazo_actual.append(event.position)
		queue_redraw()
		accept_event()

func _draw():
	# Dibujar trazos guardados
	for linea in trazados:
		var pts = linea["puntos"]
		if pts.size() > 1:
			draw_polyline(pts, linea["color"], linea["grosor"], true)
			
	# Dibujar trazo en tiempo real
	if trazo_actual.size() > 1:
		draw_polyline(trazo_actual, color_lapiz, grosor_lapiz, true)

func limpiar_pizarra():
	trazados.clear()
	trazo_actual.clear()
	queue_redraw()

func _cerrar_pizarra():
	var padre = get_parent()
	if padre is Control:
		padre.hide()
	else:
		hide()
