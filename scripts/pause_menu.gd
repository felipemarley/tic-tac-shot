extends CanvasLayer

@onready var hud_main = $".."

func _on_voltar_pressed() -> void:
	hud_main.pauseMenu()

func _on_opções_pressed() -> void:
	pass # Replace with function body.


func _on_sair_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
