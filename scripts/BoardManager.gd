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
@export var player_faction: String = "O"
@export var ai_faction: String = "X"
@export var first_turn: String = "ai"

var board = []
var current_arena: Node3D = null
var game_active: bool = true
var current_battle_position: Vector2i = Vector2i(-1, -1)
var player_turn: bool = true
var board_visible: bool = true

func _ready():
	initialize_board()
	player_turn = (first_turn == "player")
	turn_changed.emit(player_turn)
	if !player_turn:
		call_deferred("start_ai_turn")

func initialize_board():
	board = []
	for i in range(grid_size):
		var row = []
		for j in range(grid_size):
			row.append({
				"owner": null,
				"position": Vector2i(i, j),
				"completed": false
			})
		board.append(row)

func set_board_visibility(visible: bool):
	if board_visible == visible:
		return
	
	board_visible = visible
	board_visibility_changed.emit(visible)

func start_battle(cell_position: Vector2i):
	if not game_active or !player_turn:
		return

	if cell_position.x < 0 or cell_position.y < 0 or cell_position.x >= grid_size or cell_position.y >= grid_size:
		push_error("Invalid position: ", cell_position)
		return
	
	var cell = board[cell_position.x][cell_position.y]
	if cell["owner"] != null:
		push_warning("Cell already conquered")
		return
	
	current_battle_position = cell_position
	set_board_visibility(false)
	load_arena(true)  # Player attacks

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
			"attack"
		)
	
	if current_arena.has_signal("arena_completed"):
		if current_arena.arena_completed.is_connected(_on_arena_completed):
			current_arena.arena_completed.disconnect(_on_arena_completed)
		current_arena.arena_completed.connect(_on_arena_completed)

func _on_arena_completed(victory: bool):
	set_board_visibility(true)
	
	if current_battle_position.x < 0 or current_battle_position.y < 0:
		push_error("Invalid battle position")
		return
	
	var winner = player_faction if (victory == player_turn) else ai_faction
	board[current_battle_position.x][current_battle_position.y]["owner"] = winner
	cell_conquered.emit(current_battle_position, winner)

	check_game_over()

	if game_active:
		switch_turns()

	current_battle_position = Vector2i(-1, -1)

func switch_turns():
	player_turn = !player_turn
	turn_changed.emit(player_turn)

	if !player_turn and game_active:
		start_ai_turn()

func start_ai_turn():
	var best_move = find_best_move()
	if best_move.x >= 0 and best_move.y >= 0:
		current_battle_position = best_move
		ai_cell_selected.emit(best_move)  # Animação será chamada pelo BoardUI
	else:
		push_error("AI couldn't find valid move")
		check_game_over()

# NOVA FUNÇÃO: chamada pelo BoardUI após a animação
func on_ai_cell_animation_finished(pos: Vector2i):
	set_board_visibility(false)
	load_arena(false)  # AI ataca, jogador defende

func find_best_move() -> Vector2i:
	var empty_cells = get_empty_cells()
	if empty_cells.size() == 0:
		return Vector2i(-1, -1)

	for cell in empty_cells:
		if would_complete_line(cell, ai_faction):
			return cell

	for cell in empty_cells:
		if would_complete_line(cell, player_faction):
			return cell

	if is_board_empty():
		var center = Vector2i(grid_size / 2, grid_size / 2)
		if board[center.x][center.y]["owner"] == null:
			return center

	return empty_cells.pick_random()

func get_empty_cells() -> Array:
	var empty_cells = []
	for i in range(grid_size):
		for j in range(grid_size):
			if board[i][j]["owner"] == null:
				empty_cells.append(Vector2i(i, j))
	return empty_cells

func is_board_empty() -> bool:
	for i in range(grid_size):
		for j in range(grid_size):
			if board[i][j]["owner"] != null:
				return false
	return true

func would_complete_line(position: Vector2i, faction: String) -> bool:
	var temp_board = []
	for i in range(grid_size):
		var row = []
		for j in range(grid_size):
			row.append(board[i][j].duplicate())
		temp_board.append(row)
	temp_board[position.x][position.y]["owner"] = faction
	return check_winner(temp_board) != ""

func check_game_over():
	var winner = check_winner(board)
	if winner:
		game_over.emit(winner)
		game_active = false
	elif is_board_full():
		game_over.emit("draw")
		game_active = false

func check_winner(board_state) -> String:
	for i in range(grid_size):
		var row_winner = board_state[i][0]["owner"]
		if row_winner != null and board_state[i].all(func(cell): return cell["owner"] == row_winner):
			return row_winner
	
	for j in range(grid_size):
		var col_winner = board_state[0][j]["owner"]
		if col_winner != null:
			var win = true
			for i in range(1, grid_size):
				if board_state[i][j]["owner"] != col_winner:
					win = false
					break
			if win:
				return col_winner

	var diag1_winner = board_state[0][0]["owner"]
	if diag1_winner != null:
		var win = true
		for i in range(1, grid_size):
			if board_state[i][i]["owner"] != diag1_winner:
				win = false
				break
		if win: return diag1_winner

	var diag2_winner = board_state[0][grid_size - 1]["owner"]
	if diag2_winner != null:
		var win = true
		for i in range(1, grid_size):
			if board_state[i][grid_size - 1 - i]["owner"] != diag2_winner:
				win = false
				break
		if win: return diag2_winner

	return ""

func is_board_full() -> bool:
	for i in range(grid_size):
		for j in range(grid_size):
			if board[i][j]["owner"] == null:
				return false
	return true

func reset_game():
	game_active = true
	player_turn = (first_turn == "player")
	turn_changed.emit(player_turn)
	initialize_board()
	current_battle_position = Vector2i(-1, -1)

	if current_arena:
		current_arena.queue_free()
		current_arena = null

	set_board_visibility(true)

	if !player_turn:
		call_deferred("start_ai_turn")
		
func player_lost_battle():
	# Marca a célula atual com a vitória da IA
	if current_battle_position.x < 0 or current_battle_position.y < 0:
		push_error("Posição inválida para marcar derrota do jogador")
		return

	board[current_battle_position.x][current_battle_position.y]["owner"] = ai_faction
	cell_conquered.emit(current_battle_position, ai_faction)

	check_game_over()
	if game_active:
		switch_turns()

	current_battle_position = Vector2i(-1, -1)
