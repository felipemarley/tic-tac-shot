extends Node3D

@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var hit_box : Area3D = $Hit
@export_node_path("Camera3D") var cam_path
@onready var shoot: AudioStreamPlayer = $Shoot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("Idle")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		animation.play("Shoot")
		shoot.play()
		check_and_shoot()

func check_and_shoot():
	var enemies = check_raycast_query()
	if enemies:
		var hit_collider = enemies.collider
		if hit_collider.is_in_group("enemies"):
			if hit_collider.has_node("HealthComponent"):
				print("atingido")
				var health_comp = hit_collider.get_node("HealthComponent")
				health_comp.take_damage(1)

		else:
			print("NOT SHOOT")

func check_raycast_query() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin = get_node(cam_path).global_position
	var end = get_node(cam_path).global_position + -get_node(cam_path).global_transform.basis.z * 5
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result : Dictionary = space_state.intersect_ray(query)
	return result

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Shoot":
		animation.play("Idle")
