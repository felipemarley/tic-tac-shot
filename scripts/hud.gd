extends Control
@onready var board_manager: BoardManager
@onready var hp_label: Label = $HpLabel
@onready var kill_label: Label = $VBoxContainer/KillLabel
@onready var enemies_label: Label = $VBoxContainer/EnemiesLabel

var player_health_component: Node = null
var total_enemies: int = 0
var killed_enemies: int = 0

func _ready():
	if board_manager:
		board_manager.board_visibility_changed.connect(_on_board_visibility_changed)
	# Ensure proper processing mode
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Verify nodes exist
	if not hp_label:
		push_error("HpLabel not found at path: ", $HpLabel.get_path())
	if not kill_label:
		push_error("KillLabel not found at path: ", $VBoxContainer/KillLabel.get_path())
	if not enemies_label:
		push_error("EnemiesLabel not found at path: ", $VBoxContainer/EnemiesLabel.get_path())

	# Connect signals
	GameManager.kill_count_changed.connect(update_kill_count)
	GameManager.player_spawned.connect(_on_player_spawned)
	GameManager.enemies_count_updated.connect(update_enemies_count)
	
	# Initial update
	update_kill_count(GameManager.kill_count)
	update_enemies_count(GameManager.total_enemies, GameManager.kill_count)

func update_kill_count(current_kills: int):
	killed_enemies = current_kills
	if kill_label:
		kill_label.text = "Mortos: %d" % current_kills
	update_enemies_display()

func update_enemies_count(total: int, killed: int):
	total_enemies = total
	killed_enemies = killed
	update_enemies_display()

func update_enemies_display():
	if enemies_label:
		enemies_label.text = "Inimigos: %d/%d" % [killed_enemies, total_enemies]
		# Color based on progress
		if total_enemies > 0:
			var progress = float(killed_enemies) / total_enemies
			if progress >= 0.75:
				enemies_label.modulate = Color.GREEN
			elif progress >= 0.5:
				enemies_label.modulate = Color.YELLOW
			else:
				enemies_label.modulate = Color.RED

func _on_player_spawned(player: Node):
	if player and player.has_node("HealthComponent"):
		set_player_health_component(player.get_node("HealthComponent"))

func set_player_health_component(health_comp: Node):
	# Disconnect previous if exists
	if player_health_component and player_health_component.health_changed.is_connected(_on_player_health_changed):
		player_health_component.health_changed.disconnect(_on_player_health_changed)
	
	player_health_component = health_comp
	
	if player_health_component:
		player_health_component.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player_health_component.current_hp)

func _on_player_health_changed(new_hp: int):
	if not hp_label or not player_health_component:
		return
	
	var max_hp = player_health_component.max_hp
	hp_label.text = "HP: %d/%d" % [new_hp, max_hp]
	
	var hp_percentage = float(new_hp) / max_hp
	if new_hp <= 0:
		hp_label.modulate = Color.RED
		hp_label.text = "MORTO"
	elif hp_percentage <= 0.2:
		hp_label.modulate = Color.RED
	elif hp_percentage <= 0.5:
		hp_label.modulate = Color.YELLOW
	else:
		hp_label.modulate = Color.GREEN
		
func _on_board_visibility_changed(visible: bool):
	# Implement fade/show/hide effects here
	modulate.a = 1.0 if visible else 0.0
