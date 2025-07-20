extends Control

@onready var start_game_button: Button = $VBoxContainer/StartGameButton # Arraste seu botão aqui no editor

func _ready():
	# mouse livre para interagir com o menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_game_button.pressed.connect(self._on_start_game_button_pressed)

func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://scene/level.tscn")
