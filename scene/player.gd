extends CharacterBody3D
@onready var pistol = $Head/Pistol
@onready var footsteps_sfx: AudioStreamPlayer3D = $Footsteps
@onready var land_sfx: AudioStreamPlayer3D = $LandingSound
@onready var health_component = $HealthComponent
@onready var hud: Control = null

var footstep_sounds: Array[AudioStream] = []

const SPEED = 4.5
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.7
const FOOTSTEP_INTERVAL = 0.4

var step_timer = 0.0
var was_on_floor = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	footstep_sounds = [
		preload("res://scene/st1-footstep-sfx-323053.mp3"),
		preload("res://ui_ux/sounds/st2-footstep-sfx-323055.mp3"),
		preload("res://ui_ux/sounds/st3-footstep-sfx-323056.mp3"),
	]

	hud = get_tree().get_root().find_child("HUD", true, false)
	if hud:
		if health_component:
			hud.set_player_health_component(health_component)

	if health_component:
		health_component.died.connect(_on_died)

func _input(event) -> void:
	if Input.is_key_pressed(KEY_E):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion :
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		pistol.rotation_degrees.y = rotation_degrees.y

	if event.is_action_pressed("cheat_spawn_enemies"):
		GameManager.teleport_cheat_enemies_in_front(global_position, -global_transform.basis.z) # Passa posição e direção à frente


func _physics_process(delta: float) -> void:
	if health_component and health_component.is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Add the gravity.
	_apply_gravity(delta)

	_handle_jump()
	_detect_landing()

	_handle_movement(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# Handle jump.
func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _detect_landing() -> void:
	if not was_on_floor and is_on_floor():
		land_sfx.play()
	was_on_floor = is_on_floor()

# Get the input direction and handle the movement/deceleration.
func _handle_movement(delta: float) -> void:
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.1 and is_on_floor():
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		_handle_footsteps(delta)
	else:
		step_timer = 0.0
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _handle_footsteps(delta: float) -> void:
	step_timer -= delta
	if step_timer <= 0.0:
		if not footstep_sounds.is_empty(): # Adição da verificação
			footsteps_sfx.stream = footstep_sounds[randi() % footstep_sounds.size()]
			footsteps_sfx.pitch_scale = randf_range(0.9, 1.1)
			footsteps_sfx.play()
		step_timer = FOOTSTEP_INTERVAL

func take_damage(amount: int):
	if health_component:
		health_component.take_damage(amount)
		# print("Player tomou " + str(amount) + " de dano. HP: " + str(health_component.current_hp))

func _on_died():
	print("GAME OVER")
	velocity = Vector3.ZERO
	set_physics_process(false)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	GameManager.player_died()
