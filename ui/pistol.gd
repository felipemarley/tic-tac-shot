extends Node3D

@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var hit_box : Area3D = $Hit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("Idle")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		animation.play("Shoot")
		check_and_shoot()
		
func check_and_shoot():
	var enemies : Array[Area3D] = hit_box.get_overlapping_areas()
	enemies.sort_custom(func(a, b) : return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	for enemy : Area3D in enemies:
		var res = check_raycast_query(enemy.global_position)
		if (res.collider == enemy):
			print("SHOOT")
			break
		else:
			print("NOT SHOOT")
func check_raycast_query(final_pos : Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin = global_position
	var end = final_pos
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result : Dictionary = space_state.intersect_ray(query)
	return result

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Shoot":
		animation.play("Idle")
