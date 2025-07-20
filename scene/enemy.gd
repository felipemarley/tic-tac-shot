class_name Enemy
extends CharacterBody3D

signal damaged(amount: int)
signal died_and_killed()

@onready var navigation : NavigationAgent3D = $NavigationAgent3D
@onready var health_component = $HealthComponent
var player_ref : CharacterBody3D = null
const MOVE_SPEED : float = 10

@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 0.9 # Distância para o inimigo atacar o player
var attack_timer: Timer = null # Será inicializado no _ready

func _ready():
	if health_component:
		health_component.died.connect(_on_died)

	# quando alguém emitir damaged, health_component aplica o dano.
	damaged.connect(health_component.take_damage)

	# Para ser detectado pelo raycast da pistola
	add_to_group("enemies")

	# Configura o Timer de ataque
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.one_shot = true # O timer só roda uma vez, depois precisa ser iniciado de novo
	attack_timer.wait_time = attack_cooldown
	# attack_timer.timeout.connect(func(): _on_attack_cooldown_finished()) # Conecta ao novo método


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

		if global_position.distance_to(player_ref.global_position) <= attack_range and attack_timer.is_stopped():
			_deal_damage_to_player()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_ref = body
		# if attack_timer.is_stopped():
		# 	_deal_damage_to_player()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		# player_ref = null
		attack_timer.stop()

func _deal_damage_to_player():
	if is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
		attack_timer.start() # Inicia o timer de cooldown

# SEM USOS ATUALMENTE
# timer chamará quando o cooldown acabar
#func _on_attack_cooldown_finished():
	# print(name + ": Cooldown de ataque finalizado. Pronto para atacar de novo.")

# Morte
func _on_died():
	# print("MORREU")
	velocity = Vector3.ZERO
	died_and_killed.emit()

	queue_free()
