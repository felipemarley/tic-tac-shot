extends CanvasLayer

@onready var hud_main = $".."
@onready var options = $OptionsMenu
@onready var bttn_sair = $Panel/VBoxContainer/Sair


#func _ready() -> void:
	#bttn_sair.pressed.connect(GameManager._start_new_game) # Chama a função de reinício no GameManager

func _on_voltar_pressed() -> void:
	hud_main.pauseMenu()

func _on_opções_pressed() -> void:
	options.visible = true

func _on_sair_pressed() -> void:
	#GameManager._start_new_game() # Chama a função de reinício no GameManager
	# Vai para o menu
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
