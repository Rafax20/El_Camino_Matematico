# res://Escenas/Minijuegos/Minijuego_oscuras/FichaNumero.gd
extends Button

var valor_numero: int = 0

func configurar(valor: int):
	valor_numero = valor
	text = str(valor)

# 1. Al iniciar el arrastre con el ratón/móvil
func _get_drag_data(_at_position):
	var data = {
		"tipo": "ficha_matematica",
		"valor": valor_numero # 👈 Corregido
	}
	
	# Vista previa visual mientras arrastras
	var preview = Label.new()
	preview.text = str(valor_numero) # 👈 Corregido
	set_drag_preview(preview)
	
	return data
