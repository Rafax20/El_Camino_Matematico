extends Control

@onready var contenedor = $ContenedorPopup
@onready var fondo_oscuro = $OscurecerFondo

func _ready():
	# Al empezar, la ventana es invisible y pequeña
	self.modulate.a = 0
	contenedor.scale = Vector2(0.5, 0.5)
	contenedor.pivot_offset = contenedor.size / 2 # Para que crezca desde el centro
	self.visible = false

# Esta función la llamas desde tu Menú Principal cuando den clic en "Empezar"
func aparecer():
	self.visible = true
	
	# Creamos un "Tween" para las animaciones
	var tween = create_tween().set_parallel(true)
	
	# 1. Efecto Fade-in (Aparece la transparencia)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	# 2. Efecto Pop-up (Crece con un pequeño rebote)
	tween.tween_property(contenedor, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func desaparecer():
	var tween = create_tween().set_parallel(true)
	
	# Desvanecer y encoger
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(contenedor, "scale", Vector2(0.7, 0.7), 0.2)
	
	# Al terminar la animación, ocultamos el nodo
	await tween.finished
	self.visible = false
