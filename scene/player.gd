extends CharacterBody3D
@onready var pistol = $Head/Pistol
@onready var footsteps_sfx = $Footsteps

const SPEED = 4.5
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.7


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event) -> void:
	if Input.is_key_pressed(KEY_E):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion :
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		pistol.rotation_degrees.y = rotation_degrees.y

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		footsteps_sfx.play()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		footsteps_sfx.stop()
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
