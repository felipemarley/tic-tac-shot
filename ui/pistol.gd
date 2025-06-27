extends Node3D

@onready var animation : AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("Idle")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		animation.play("Shoot")
		


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Shoot":
		animation.play("Idle")
