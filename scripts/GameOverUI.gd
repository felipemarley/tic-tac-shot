extends CanvasLayer

@onready var label : Label = $Panel/VBoxContainer/Label
@onready var button : Button = $Panel/VBoxContainer/Button
@onready var richTextLabel : RichTextLabel = $Panel/VBoxContainer/RichTextLabel


func _ready():
	var test_label = find_child("Label", true, false)
	print("Label encontrado:", test_label)


func set_winner(winner: String):
	if winner == "draw":
		print("ganhador" + winner)

		#label.text = "Empate!"
	else:
		print("ganhador" + winner)
		#label.text = "Você venceu!"
		#richTextLabel.add_text("Você venceu!")


func _on_button_pressed():
	get_tree().change_scene_to_file("res://ui_ux/BoardUI.tscn")
	# Alternativa: emitir um sinal para o BoardManager reiniciar
	# queue_free()
