class_name Enemy
extends CharacterBody3D

@onready var navigation : NavigationAgent3D = $NavigationAgent3D
var player_ref : CharacterBody3D = null
const MOVE_SPEED : float = 10

func _physics_process(delta: float) -> void:
	var direction : Vector3 = Vector3.ZERO
	if player_ref:
		navigation.target_position = player_ref.global_position
		direction = (navigation.get_next_path_position() - global_position).normalized()
		look_at(player_ref.global_position)
		velocity = velocity.lerp(direction * MOVE_SPEED, delta * 0.25)
		move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_ref = body


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_ref = null
