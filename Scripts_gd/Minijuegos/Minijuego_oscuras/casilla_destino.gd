# res://Escenas/Minijuegos/Minijuego_oscuras/CasillaDestino.gd
extends Control

signal ficha_depositada(valor)

@onready var label_valor = $LabelValor

func _can_drop_data(_at_position, data) -> bool:
	return data is Dictionary and data.get("tipo") == "ficha_matematica"

func _drop_data(_at_position, data):
	var valor = data.get("valor", 0)
	if label_valor:
		label_valor.text = str(valor)
	ficha_depositada.emit(valor)
