extends CanvasLayer

@onready var hud_main = $".."
@onready var options = $OptionsMenu

func _on_voltar_pressed() -> void:
	hud_main.pauseMenu()

func _on_opções_pressed() -> void:
	options.visible = true


func _on_sair_pressed() -> void:
	# Vai para o menu
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
