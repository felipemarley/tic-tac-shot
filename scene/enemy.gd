class_name Enemy
extends CharacterBody3D

@onready var navigation : NavigationAgent3D = $NavigationAgent3D
@onready var health_component = $HealthComponent
var player_ref : CharacterBody3D = null
const MOVE_SPEED : float = 10

func _ready():
	if health_component:
		health_component.died.connect(_on_died)
	# Para ser detectado pelo raycast da pistola
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if health_component and health_component.is_dead:
		return

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

# Morte
func _on_died():
	print("MORREU")
	velocity = Vector3.ZERO
	get_tree().get_current_scene().add_kill()

	queue_free()
