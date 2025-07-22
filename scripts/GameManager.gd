extends Node

# SIGNALS
signal kill_count_changed(new_count: int)
signal player_spawned(player: Node)
signal fps_phase_ended(wonPlay: bool, wonAi: bool, player: PlayerSide)  # Modificado para incluir o jogador
signal game_state_changed(new_state: GameState)
signal board_updated(board_state: Array[Array])
signal turn_changed(player_side: PlayerSide)
signal start_fps_level()
signal animate_cell( x : int, y : int )



# GAMEPLAY LOOP
enum PlayerSide {
	NONE = 0,
	X = 1,
	O = 2
}

enum GameState {
	MENU,
	TIC_TAC_TOE_TURN,
	FPS_PHASE,
	ROUND_END,
	GAME_OVER
}

var current_game_state: GameState = GameState.MENU
var tic_tac_toe_board: Array[Array] = []
var current_player_side: PlayerSide = PlayerSide.X
var last_chosen_cell: Vector2i = Vector2i(-1, -1)

# FPS PHASE
var kill_count: int = 0
var enemies_in_current_round: int = 0
var player_choices_counter: int = 0

func _ready() -> void:
	fps_phase_ended.connect(_on_fps_phase_ended)
	_set_game_state(GameState.MENU)

func _start_new_game() -> void:
	tic_tac_toe_board.clear()
	for i in range(3):
		tic_tac_toe_board.append([PlayerSide.NONE, PlayerSide.NONE, PlayerSide.NONE])

	current_player_side = PlayerSide.X
	player_choices_counter = 0
	_set_game_state(GameState.TIC_TAC_TOE_TURN)
	turn_changed.emit(current_player_side)
	board_updated.emit(tic_tac_toe_board)

func _set_game_state(new_state: GameState) -> void:
	current_game_state = new_state
	game_state_changed.emit(new_state)

func choose_tic_tac_toe_cell(row: int, col: int) -> void:
	if current_game_state != GameState.TIC_TAC_TOE_TURN:
		return
	if row < 0 or row > 2 or col < 0 or col > 2:
		return
	if tic_tac_toe_board[row][col] != PlayerSide.NONE:
		return

	last_chosen_cell = Vector2i(row, col)
	_set_game_state(GameState.FPS_PHASE)
	start_fps_level.emit()

func mark_tic_tac_toe_cell(row: int, col: int, player_id: PlayerSide) -> void:
	if row >= 0 and row < 3 and col >= 0 and col < 3 and tic_tac_toe_board[row][col] == PlayerSide.NONE:
		tic_tac_toe_board[row][col] = player_id
		player_choices_counter += 1
		board_updated.emit(tic_tac_toe_board)

func check_tic_tac_toe_win(player_id: PlayerSide) -> bool:
	# Verifica linhas, colunas e diagonais
	for i in range(3):
		if tic_tac_toe_board[i][0] == player_id and tic_tac_toe_board[i][1] == player_id and tic_tac_toe_board[i][2] == player_id:
			return true
		if tic_tac_toe_board[0][i] == player_id and tic_tac_toe_board[1][i] == player_id and tic_tac_toe_board[2][i] == player_id:
			return true
	if tic_tac_toe_board[0][0] == player_id and tic_tac_toe_board[1][1] == player_id and tic_tac_toe_board[2][2] == player_id:
		return true
	if tic_tac_toe_board[0][2] == player_id and tic_tac_toe_board[1][1] == player_id and tic_tac_toe_board[2][0] == player_id:
		return true
	return false

func check_tic_tac_toe_draw() -> bool:
	return player_choices_counter == 9 and not (check_tic_tac_toe_win(PlayerSide.X) or check_tic_tac_toe_win(PlayerSide.O))

func add_kill() -> void:
	kill_count += 1
	kill_count_changed.emit(kill_count)
	if enemies_in_current_round > 0 and kill_count >= enemies_in_current_round:
		fps_phase_ended.emit(true, false, current_player_side)
		print("Turno atual: ", current_player_side)
		reset_fps_round()

func start_new_fps_round(total_enemies: int) -> void:
	enemies_in_current_round = total_enemies
	kill_count = 0
	kill_count_changed.emit(kill_count)

func player_died() -> void:
	print("Turno atual: ", current_player_side)

	fps_phase_ended.emit(false, true, current_player_side)

	reset_fps_round()

func reset_fps_round() -> void:
	enemies_in_current_round = 0
	kill_count = 0
	kill_count_changed.emit(kill_count)

func _on_fps_phase_ended(wonPlayer: bool, wonAi : bool, player: PlayerSide) -> void:
	_set_game_state(GameState.ROUND_END)

	print("FPS Phase Result - \n won player? : ", wonPlayer, " | Player: ", player, " | Current Turn: ", current_player_side)
	print("FPS Phase Result - \n won Ai? : ", wonAi, " | Player: ", player, " | Current Turn: ", current_player_side)

	if wonPlayer and not wonAi and player == current_player_side and player != PlayerSide.O:
		print("Jogador venceu, marcando célula para: ", current_player_side)
		mark_tic_tac_toe_cell(last_chosen_cell.x, last_chosen_cell.y, player)

	elif wonAi and not wonPlayer and player == current_player_side and player != PlayerSide.X:
		print("IA venceu, marcando célula para: ", current_player_side)
		mark_tic_tac_toe_cell(last_chosen_cell.x, last_chosen_cell.y, player)

	_switch_player_turn()
	_set_game_state(GameState.TIC_TAC_TOE_TURN)
	
	if current_player_side == PlayerSide.O:
		_process_ai_turn()

func _switch_player_turn() -> void:
	current_player_side = PlayerSide.X if current_player_side == PlayerSide.O else PlayerSide.O
	turn_changed.emit(current_player_side)

func _process_ai_turn() -> void:
	if current_game_state != GameState.TIC_TAC_TOE_TURN or current_player_side != PlayerSide.O:
		return

	await get_tree().create_timer(0.5).timeout

	var best_move := find_best_move(PlayerSide.O, PlayerSide.X)
	if best_move != Vector2i(-1, -1):
		last_chosen_cell = best_move
		
		animate_cell.emit(best_move.x, best_move.y)
		
		# Aguarda tempo suficiente para a animação terminar (ex: 3 segundos)
		await get_tree().create_timer(3.0).timeout
		
		_set_game_state(GameState.FPS_PHASE)
		start_fps_level.emit()

func find_best_move(ai: PlayerSide, opponent: PlayerSide) -> Vector2i:
	# 1. Verifica se pode vencer
	for r in range(3):
		for c in range(3):
			if tic_tac_toe_board[r][c] == PlayerSide.NONE:
				tic_tac_toe_board[r][c] = ai
				if check_tic_tac_toe_win(ai):
					tic_tac_toe_board[r][c] = PlayerSide.NONE
					return Vector2i(r, c)
				tic_tac_toe_board[r][c] = PlayerSide.NONE

	# 2. Verifica se precisa bloquear
	for r in range(3):
		for c in range(3):
			if tic_tac_toe_board[r][c] == PlayerSide.NONE:
				tic_tac_toe_board[r][c] = opponent
				if check_tic_tac_toe_win(opponent):
					tic_tac_toe_board[r][c] = PlayerSide.NONE
					return Vector2i(r, c)
				tic_tac_toe_board[r][c] = PlayerSide.NONE

	# 3. Pega centro se disponível
	if tic_tac_toe_board[1][1] == PlayerSide.NONE:
		return Vector2i(1, 1)

	# 4. Pega cantos se disponíveis
	var corners := [Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2)]
	for corner in corners:
		if tic_tac_toe_board[corner.x][corner.y] == PlayerSide.NONE:
			return corner

	# 5. Qualquer célula vazia
	for r in range(3):
		for c in range(3):
			if tic_tac_toe_board[r][c] == PlayerSide.NONE:
				return Vector2i(r, c)

	# Sem jogada possível
	return Vector2i(-1, -1)
	
func teleport_cheat_enemies_in_front(player_pos: Vector3, player_forward_dir: Vector3) -> void: # <--- FUNÇÃO RENOMEADA
	var teleport_distance: float = 5.0 # Distância na frente do player
	var spread_radius: float = 2.0  # Raio para espalhar os inimigos
	var teleported_enemies_count = 0

	# Pega todos os inimigos ativos na cena (assumindo que estão no grupo "enemies")
	var existing_enemies = get_tree().get_nodes_in_group("enemies")

	if existing_enemies.is_empty():
		print("Cheat: No enemies found in scene to teleport!")
		return

	for enemy in existing_enemies:
		# Verifica se o inimigo ainda está vivo antes de teleportar
		# Assumimos que o inimigo tem um HealthComponent e uma propriedade 'is_dead'
		if enemy.has_node("HealthComponent") and enemy.get_node("HealthComponent").is_dead:
			continue # Não teleporte inimigos mortos

		# Calcula a nova posição na frente do player com um pequeno espalhamento
		var spawn_offset_x = randf_range(-spread_radius, spread_radius)
		var spawn_offset_z = randf_range(-spread_radius, spread_radius)
		# A posição Y pode precisar de ajuste dependendo do seu setup
		var teleport_position = player_pos + (player_forward_dir * teleport_distance) + Vector3(spawn_offset_x, 0.5, spawn_offset_z) # Adicionei 0.5 em Y para levitar um pouco

		enemy.global_position = teleport_position # TELEPORTA o inimigo
		teleported_enemies_count += 1

	print("Cheat: Teleported " + str(teleported_enemies_count) + " existing enemies to player front.")
	# Não precisamos ajustar enemies_in_current_round aqui, pois estamos teleportando os existentes,
	# e eles já contam na contagem original do round.
