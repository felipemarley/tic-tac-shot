extends Node
class_name BoardManager

signal cell_conquered(cell_position: Vector2i, conqueror: String, player_lost: bool)
signal game_over(winner: String)
signal arena_loaded(arena_instance: Node3D, battle_type: String)
signal turn_changed(is_player_turn: bool)
signal board_visibility_changed(visible: bool)
signal ai_cell_selected(position: Vector2i)

@export var grid_size: int = 3
@export var arena_scene: PackedScene = preload("res://scene/level.tscn")
@export var player_faction: String = Global.player_symbol
@export var ai_faction: String = Global.ai_symbol

var current_arena: Node3D = null
var game_active: bool = true
var current_battle_position: Vector2i = Vector2i(-1, -1)
var board_visible: bool = true

func _ready():
	Global.board_size = grid_size
	Global.initialize_board()
	
	# Define o turno atual como o que está na variável global
	var player_turn = (Global.turn == "player")
	turn_changed.emit(player_turn)
	if not player_turn:
		call_deferred("start_ai_turn")

func set_board_visibility(visible: bool):
	if board_visible == visible:
		return
	board_visible = visible
	board_visibility_changed.emit(visible)

func start_battle(cell_position: Vector2i):
	if not game_active or Global.turn != "player":
		return

	var cell_id = "%d,%d" % [cell_position.x, cell_position.y]
	if Global.board_state[cell_id] != null:
		push_warning("Cell already conquered")
		return

	current_battle_position = cell_position
	set_board_visibility(false)
	load_arena(true)

func load_arena(is_player_attacking: bool):
	if current_arena:
		current_arena.queue_free()
		await current_arena.tree_exited

	current_arena = arena_scene.instantiate()
	add_child(current_arena)

	var battle_type = "attack" if is_player_attacking else "defense"
	arena_loaded.emit(current_arena, battle_type)

	if current_arena.has_method("initialize_arena"):
		current_arena.initialize_arena(
			player_faction if is_player_attacking else ai_faction,
			battle_type
		)

	if current_arena.has_signal("arena_completed"):
		if current_arena.arena_completed.is_connected(_on_arena_completed):
			current_arena.arena_completed.disconnect(_on_arena_completed)
		current_arena.arena_completed.connect(_on_arena_completed)

func _on_arena_completed(victory: bool):
	set_board_visibility(true)

	if current_battle_position.x < 0:
		return

	var winner = player_faction if (victory == (Global.turn == "player")) else ai_faction
	var cell_id = "%d,%d" % [current_battle_position.x, current_battle_position.y]
	Global.board_state[cell_id] = winner

	cell_conquered.emit(current_battle_position, winner, !victory and (Global.turn == "player"))

	check_game_over()

	if game_active:
		switch_turns()

	current_battle_position = Vector2i(-1, -1)

func switch_turns():
	Global.turn = "ai" if Global.turn == "player" else "player"
	var player_turn = (Global.turn == "player")
	turn_changed.emit(player_turn)
	if not player_turn and game_active:
		start_ai_turn()

func start_ai_turn():
	var best_move = find_best_move()
	if best_move.x >= 0:
		current_battle_position = best_move
		ai_cell_selected.emit(best_move)
	else:
		check_game_over()

func on_ai_cell_animation_finished(pos: Vector2i):
	set_board_visibility(false)
	load_arena(false)

func find_best_move() -> Vector2i:
	var empty_cells = []
	for row in range(Global.board_size):
		for col in range(Global.board_size):
			var id = "%d,%d" % [row, col]
			if Global.board_state[id] == null:
				empty_cells.append(Vector2i(row, col))

	if empty_cells.is_empty():
		return Vector2i(-1, -1)

	return empty_cells.pick_random()

func check_game_over():
	var winner = check_winner()
	if winner != "":
		game_active = false
		game_over.emit(winner)
	elif is_board_full():
		game_active = false
		game_over.emit("draw")

func check_winner() -> String:
	var size = Global.board_size
	var s = Global.board_state

	# Linhas
	for row in range(size):
		var first = s["%d,0" % row]
		if first != null:
			var win = true
			for col in range(1, size):
				if s["%d,%d" % [row, col]] != first:
					win = false
					break
			if win: return first

	# Colunas
	for col in range(size):
		var first = s["0,%d" % col]
		if first != null:
			var win = true
			for row in range(1, size):
				if s["%d,%d" % [row, col]] != first:
					win = false
					break
			if win: return first

	# Diagonal 1
	var diag1 = s["0,0"]
	if diag1 != null:
		var win = true
		for i in range(1, size):
			if s["%d,%d" % [i, i]] != diag1:
				win = false
				break
		if win: return diag1

	# Diagonal 2
	var diag2 = s["0,%d" % (size - 1)]
	if diag2 != null:
		var win = true
		for i in range(1, size):
			if s["%d,%d" % [i, size - 1 - i]] != diag2:
				win = false
				break
		if win: return diag2

	return ""

func is_board_full() -> bool:
	for value in Global.board_state.values():
		if value == null:
			return false
	return true

func reset_game():
	game_active = true
	Global.turn = "player"  # ou "ai", escolha quem começa
	var player_turn = (Global.turn == "player")
	turn_changed.emit(player_turn)
	Global.initialize_board()
	current_battle_position = Vector2i(-1, -1)

	if current_arena:
		current_arena.queue_free()
		current_arena = null

	set_board_visibility(true)

	if not player_turn:
		call_deferred("start_ai_turn")

func player_lost_battle():
	var cell_id = "%d,%d" % [current_battle_position.x, current_battle_position.y]
	Global.board_state[cell_id] = ai_faction
	cell_conquered.emit(current_battle_position, ai_faction, true)

	check_game_over()
	if game_active:
		switch_turns()

	current_battle_position = Vector2i(-1, -1)
