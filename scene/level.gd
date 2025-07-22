extends Node3D

class_name Level

signal enemies_spawned_for_round(count: int)
signal dungeon_ready(y : int)

@onready var dun_gen = $DunGen
@onready var player_scene : PackedScene = preload("res://scene/player.tscn") # Renomeado para evitar conflito com 'player_instance'
@onready var enemy_scene : PackedScene = preload("res://scene/enemy.tscn") # Renomeado para evitar conflito com 'e'
var player_instance : CharacterBody3D = null


func _ready() -> void:
	# Conecta o sinal do GameManager para iniciar a fase FPS
	GameManager.start_fps_level.connect(self._on_start_fps_level)
	enemies_spawned_for_round.connect(GameManager.start_new_fps_round)

	GameManager.game_state_changed.connect(self._on_game_state_changed_from_manager)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_hide_fps_world()

	GameManager._start_new_game()

func _on_start_fps_level() -> void:
	# Esconde o mouse e captura-o para a visão FPS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Garante que o dun_gen está limpo e reconecta o sinal
	if dun_gen.is_connected("dungeon_ready", Callable(self, "on_dungeon_ready")):
		dun_gen.dungeon_ready.disconnect(on_dungeon_ready)
	dun_gen.dungeon_ready.connect(on_dungeon_ready)

	_clear_all_enemies()

	dun_gen.visible = false
	dun_gen.generate()

func on_dungeon_ready() -> void:
	print("Level: Dungeon pronto, spawnando player e inimigos.") # Para depuração

	var positions : PackedVector3Array = dun_gen.room_positions
	var index : int = randi() % positions.size()
	var spawn : Vector3 = positions.get(index)
	spawn.y += 1.4

	if not is_instance_valid(player_instance):
		player_instance = player_scene.instantiate()
		add_child(player_instance)
		# Se você não quer que o player seja recriado, mova-o em vez de instanciar
	player_instance.global_position = spawn

	player_instance.visible = true
	player_instance.set_physics_process(true)
	
	#dungeon_ready.emit(1)
	
	# Reseta a vida do jogador quando ele é posicionado para uma nova rodada
	if player_instance.has_node("HealthComponent"): # Verifica se tem o HealthComponent
		player_instance.get_node("HealthComponent").reset_health()

	enemy_spawn(15)
	dun_gen.grid_map.clear()

	dun_gen.visible = true
	adjust_enemies_y(1.1)

	GameManager.player_spawned.emit(player_instance)
	
func adjust_enemies_y(new_y: float) -> void:
	var adjusted_count := 0
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_node("HealthComponent") and enemy.get_node("HealthComponent").is_dead:
			continue

		var pos = enemy.global_position
		pos.y = new_y
		enemy.global_position = pos
		adjusted_count += 1

	print("Altura ajustada de", adjusted_count, "inimigos para Y =", new_y)

func enemy_spawn(min_required) -> void:
	var spawned_enemy_count : int = 0
	for cell in dun_gen.grid_map.get_used_cells():
		for tile in dun_gen.room_tiles:
			randomize()
			var spawn_enemy_chanc : int = randi_range(1, (tile.size()/2))
			if(spawn_enemy_chanc < tile.size() / 2 and spawn_enemy_chanc > min_required/24):
				continue
			if tile.has(cell):
				var e = enemy_scene.instantiate()
				add_child(e)
				e.global_position = Vector3(cell) + Vector3(0.5, 1, 0.5)

				e.died_and_killed.connect(GameManager.add_kill)
				spawned_enemy_count += 1

	print("Inimigos gerados:", spawned_enemy_count, "| Requerido:", min_required)
	#enemies_spawned_for_round.emit(spawned_enemy_count-10)
	enemies_spawned_for_round.emit(spawned_enemy_count)



# Função para ocultar o mundo FPS
func _hide_fps_world() -> void:
	dun_gen.visible = false
	if is_instance_valid(player_instance):
		player_instance.queue_free()
		("print limpando player da cena")
		player_instance.visible = false
		player_instance.set_physics_process(false)

	# Garante que os inimigos sejam removidos ao ocultar o mundo FPS
	_clear_all_enemies()

# Função para reagir às mudanças de estado do GameManager
func _on_game_state_changed_from_manager(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.FPS_PHASE:
			pass
		GameManager.GameState.TIC_TAC_TOE_TURN, GameManager.GameState.ROUND_END, GameManager.GameState.GAME_OVER:
			_hide_fps_world()

# Função para limpar todos os inimigos da cena
func _clear_all_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free() # Remove o inimigo da cena
