extends CanvasLayer

@onready var label = $Panel/Label
@onready var button = $Panel/Button

func set_winner(winner: String):
	if winner == "draw":
		label.text = "Empate!"
	else:
		label.text = "Jogador %s venceu!" % winner


func _on_button_pressed():
	get_tree().reload_current_scene()
	# Alternativa: emitir um sinal para o BoardManager reiniciar
	# queue_free()
