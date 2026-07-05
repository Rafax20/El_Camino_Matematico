#extends LineEdit
#
#func _ready() -> void:
	#focus_entered.connect(_on_focus_entered)

#func _on_focus_entered() -> void:
	## Inserta un espacio y lo borra para forzar la sincronización del teclado móvil
	#insert_text_at_caret(" ")
	#clear()
