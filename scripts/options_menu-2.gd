extends CanvasLayer


@onready var options = $"."
@onready var volume = $Panel/VBoxContainer2/VBoxContainer/volumeSlider

func _ready():
	# Define o valor inicial do slider para 50 (50%)
	volume.value = 50.0
	# Aplica o volume correspondente (calcula -13.75 dB)
	_on_hsdx_value_changed(50.0)  # Força a atualização do volume
	
func _on_button_pressed() -> void:
		options.visible = false

func _on_hsdx_value_changed(value: float) -> void:
	# Mapeia 0 → -80 dB e 100 → 0 dB
	var min_db = -30.0
	var max_db = 2.5
	var volume_db = min_db + (max_db - min_db) * (value / 100.0)
	AudioServer.set_bus_volume_db(0, volume_db)


#func _on_option_button_item_selected(index: int) -> void:
	#match index:
		#0:
			#DisplayServer.window_set_size(Vector2i(1928, 1080))
		#1:
			#DisplayServer.window_set_size(Vector2i(1600, 1900))
		#2:
			#DisplayServer.window_set_size(Vector2i(1280, 720))	
	
	
func _on_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)
