extends CanvasLayer


@onready var options = $"."

func _on_button_pressed() -> void:
		options.visible = false


func _on_hsdx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value/5)


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
