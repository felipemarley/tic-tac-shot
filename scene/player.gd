extends CharacterBody3D

@onready var pistol = $Head/Pistol
@onready var footsteps_sfx: AudioStreamPlayer3D = $Footsteps
@onready var land_sfx: AudioStreamPlayer3D = $LandingSound
@onready var health_component = $HealthComponent
@onready var hud: Control = null

var footstep_sounds: Array[AudioStream] = []

const WALK_SPEED = 4.5
const SPRINT_SPEED = 6.0  # Velocidade aumentada para corrida
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.7
const FOOTSTEP_INTERVAL_WALK = 0.4
const FOOTSTEP_INTERVAL_SPRINT = 0.3  # Passos mais rápidos ao correr
const STAMINA_MAX = 100.0
const STAMINA_DEPLETION_RATE = 20.0  # Quanto stamina gasta por segundo correndo
const STAMINA_RECOVERY_RATE = 15.0   # Quanto stamina recupera por segundo

var current_speed = WALK_SPEED
var step_timer = 0.0
var was_on_floor = false
var camera_paused: bool = false
var is_sprinting: bool = false
var stamina: float = STAMINA_MAX
var can_sprint: bool = true

func _ready() -> void:
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
	if GameManager.current_game_state != GameManager.GameState.FPS_PHASE:
		pistol.visible = false
		pistol.set_process_mode(Node.PROCESS_MODE_DISABLED)
		return

	pistol.visible = true
	pistol.set_process_mode(Node.PROCESS_MODE_ALWAYS)

	if Input.is_key_pressed(KEY_E):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and not camera_paused:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		pistol.rotation_degrees.y = rotation_degrees.y

	if event.is_action_pressed("cheat_spawn_enemies"):
		GameManager.teleport_cheat_enemies_in_front(global_position, -global_transform.basis.z)

func _physics_process(delta: float) -> void:
	if health_component and health_component.is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if GameManager.current_game_state != GameManager.GameState.FPS_PHASE:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Atualiza sistema de stamina
	_update_stamina(delta)
	
	# Verifica se está tentando correr
	_handle_sprint_input()

	# Add the gravity.
	_apply_gravity(delta)

	_handle_jump()
	_detect_landing()

	_handle_movement(delta)
	move_and_slide()

func _update_stamina(delta: float) -> void:
	if is_sprinting:
		# Gasta stamina ao correr
		stamina = max(0.0, stamina - STAMINA_DEPLETION_RATE * delta)
		if stamina <= 0.0:
			can_sprint = false
			is_sprinting = false
			current_speed = WALK_SPEED
	else:
		# Recupera stamina quando não está correndo
		stamina = min(STAMINA_MAX, stamina + STAMINA_RECOVERY_RATE * delta)
		if stamina >= STAMINA_MAX * 0.3:  # Recupera a capacidade de correr com 30% de stamina
			can_sprint = true

func _handle_sprint_input() -> void:
	# Verifica se o jogador está pressionando o botão de sprint (Shift por padrão)
	if Input.is_action_pressed("sprint") and can_sprint and is_on_floor():
		is_sprinting = true
		current_speed = SPRINT_SPEED
	else:
		is_sprinting = false
		current_speed = WALK_SPEED

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_sprinting = false  # Interrompe a corrida ao pular

func _detect_landing() -> void:
	if not was_on_floor and is_on_floor():
		land_sfx.play()
	was_on_floor = is_on_floor()

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.1 and is_on_floor():
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		_handle_footsteps(delta)
	else:
		step_timer = 0.0
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

func _handle_footsteps(delta: float) -> void:
	step_timer -= delta
	var footstep_interval = FOOTSTEP_INTERVAL_SPRINT if is_sprinting else FOOTSTEP_INTERVAL_WALK
	
	if step_timer <= 0.0 and not footstep_sounds.is_empty():
		footsteps_sfx.stream = footstep_sounds[randi() % footstep_sounds.size()]
		footsteps_sfx.pitch_scale = randf_range(0.9, 1.1)
		if is_sprinting:
			footsteps_sfx.pitch_scale *= 1.2  # Passos mais agudos ao correr
		footsteps_sfx.play()
		step_timer = footstep_interval

func take_damage(amount: int):
	if health_component:
		health_component.take_damage(amount)

func _on_died():
	print("GAME OVER")
	velocity = Vector3.ZERO
	set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.player_died()
