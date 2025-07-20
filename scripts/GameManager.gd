extends Node

# SIGNALS
signal kill_count_changed(new_count: int)
signal player_spawned(player: Node)
signal fps_phase_ended(won: bool) # Sinaliza o fim de uma fase FPS
signal game_state_changed(new_state: GameState) # Sinaliza mudança de estado do jogo
signal board_updated(board_state: Array[Array]) # Sinaliza atualização do tabuleiro
signal turn_changed(player_side: PlayerSide) # Sinaliza mudança de turno
signal start_fps_level() # Sinal para o Level.gd iniciar a fase FPS

# GAMEPLAY LOOP
enum PlayerSide {
	NONE = 0, # Para estado inicial ou célula vazia
	X = 1,    # Jogador X
	O = 2     # Jogador O
}

enum GameState {
	MENU,              # Tela inicial, escolha X/O
	TIC_TAC_TOE_TURN,  # Jogador escolhe célula no tabuleiro
	FPS_PHASE,         # Fase de combate FPS
	ROUND_END,         # Resultado da fase FPS, atualiza tabuleiro
	GAME_OVER          # Jogo da velha finalizado (vitória/derrota/empate)
}

var current_game_state: GameState = GameState.MENU # Estado inicial
var tic_tac_toe_board: Array[Array] = [] # Será inicializado em _ready
var current_player_side: PlayerSide = PlayerSide.X
var last_chosen_cell: Vector2i = Vector2i(-1, -1) # Armazena a célula escolhida antes da fase FPS

# FPS PHASE
var kill_count: int = 0
var enemies_in_current_round: int = 0 # Rastreia o total de inimigos para o round FPS atual
var player_choices_counter: int = 0 # Controlar o número de jogadas (para empate)

func _ready() -> void:
	fps_phase_ended.connect(_on_fps_phase_ended)
	_set_game_state(GameState.MENU)
	# _start_new_game()

# Função para inicializar/reiniciar o jogo
func _start_new_game() -> void:
	# Inicializa o tabuleiro 3x3 com PlayerSide.NONE (vazio)
	tic_tac_toe_board.clear()
	for i in range(3):
		tic_tac_toe_board.append([PlayerSide.NONE, PlayerSide.NONE, PlayerSide.NONE])

	current_player_side = PlayerSide.X # Começa com X
	player_choices_counter = 0 # Reseta o contador de jogadas

	_set_game_state(GameState.TIC_TAC_TOE_TURN) # Inicia no turno do jogo da velha
	turn_changed.emit(current_player_side) # Notifica a HUD sobre o turno
	board_updated.emit(tic_tac_toe_board) # Notifica a HUD sobre o tabuleiro

 # Função para mudar o estado do jogo
func _set_game_state(new_state: GameState) -> void:
	current_game_state = new_state
	game_state_changed.emit(new_state)

# Chamado pela HUD quando o jogador escolhe uma célula no tabuleiro
func choose_tic_tac_toe_cell(row: int, col: int) -> void:
	if current_game_state != GameState.TIC_TAC_TOE_TURN:
		print("DEBUG: Não é o turno do jogo da velha para escolher uma célula.")
		return
	if row < 0 or row > 2 or col < 0 or col > 2:
		printerr("ERROR: Célula inválida: (", row, ", ", col, ")")
		return
	if tic_tac_toe_board[row][col] != PlayerSide.NONE:
		print("DEBUG: Célula já ocupada: (", row, ", ", col, ")")
		return

	last_chosen_cell = Vector2i(row, col) # Armazena a célula para marcar depois da fase FPS
	_set_game_state(GameState.FPS_PHASE)
	start_fps_level.emit() # Sinaliza para o Level.gd iniciar a fase FPS


# Marca uma célula no tabuleiro
func mark_tic_tac_toe_cell(row: int, col: int, player_id: PlayerSide) -> void:
	if row >= 0 and row < 3 and col >= 0 and col < 3 and tic_tac_toe_board[row][col] == PlayerSide.NONE:
		tic_tac_toe_board[row][col] = player_id
		player_choices_counter += 1
		board_updated.emit(tic_tac_toe_board)
	else:
		printerr("ERROR: Tentativa de marcar célula inválida ou já ocupada: (", row, ", ", col, ") com ", player_id)


# Verifica se o jogador atual venceu o jogo da velha
func check_tic_tac_toe_win(player_id: PlayerSide) -> bool:
	# Verificar linhas
	for r in range(3):
		if tic_tac_toe_board[r][0] == player_id and tic_tac_toe_board[r][1] == player_id and tic_tac_toe_board[r][2] == player_id:
			return true
	# Verificar colunas
	for c in range(3):
		if tic_tac_toe_board[0][c] == player_id and tic_tac_toe_board[1][c] == player_id and tic_tac_toe_board[2][c] == player_id:
			return true
	# Verificar diagonais
	if tic_tac_toe_board[0][0] == player_id and tic_tac_toe_board[1][1] == player_id and tic_tac_toe_board[2][2] == player_id:
		return true
	if tic_tac_toe_board[0][2] == player_id and tic_tac_toe_board[1][1] == player_id and tic_tac_toe_board[2][0] == player_id:
		return true
	return false

# Verifica se o jogo da velha empatou
func check_tic_tac_toe_draw() -> bool:
	return player_choices_counter == 9 and not (check_tic_tac_toe_win(PlayerSide.X) or check_tic_tac_toe_win(PlayerSide.O))

func add_kill() -> void:
	kill_count += 1
	kill_count_changed.emit(kill_count)

	# Verifica se todos os inimigos foram derrotados no round
	if enemies_in_current_round > 0 and kill_count >= enemies_in_current_round:
		fps_phase_ended.emit(true)
		reset_fps_round()

# novo round
func start_new_fps_round(total_enemies: int) -> void:
	enemies_in_current_round = total_enemies
	print(enemies_in_current_round)
	kill_count = 0 # Resetar kill_count para o novo round
	kill_count_changed.emit(kill_count) # Garantir que a HUD seja atualizada para 0 kills

 # Chamado quando o jogador morre
func player_died() -> void:
	print("GameManager: Player died in FPS phase. Resetting round.") # Novo print para depuração
	fps_phase_ended.emit(false)
	reset_fps_round()

# Função auxiliar para resetar contadores do round
func reset_fps_round() -> void:
	enemies_in_current_round = 0
	kill_count = 0
	kill_count_changed.emit(kill_count)

# Função para lidar com o fim de uma fase FPS e AGORA a lógica do Jogo da Velha
func _on_fps_phase_ended(won: bool) -> void:
	_set_game_state(GameState.ROUND_END) # Muda para estado de fim de round

	if won:
		print("GameManager: Fase FPS Vencida!")
		mark_tic_tac_toe_cell(last_chosen_cell.x, last_chosen_cell.y, current_player_side) # Marca a célula

		if check_tic_tac_toe_win(current_player_side):
			_set_game_state(GameState.GAME_OVER)
			print("GameManager: Jogo da Velha FINALIZADO! Vencedor: ", current_player_side)
		elif check_tic_tac_toe_draw():
			_set_game_state(GameState.GAME_OVER)
			print("GameManager: Jogo da Velha FINALIZADO! EMPATE.")
		else:
			# Passa a vez e prepara para o próximo turno do jogo da velha
			_switch_player_turn()
			_set_game_state(GameState.TIC_TAC_TOE_TURN)

			print("GameManager: Turno do Jogo da Velha. Próximo jogador: ", current_player_side)
			if current_player_side == PlayerSide.O:
				_process_ai_turn()
	else: # Perdeu a fase FPS
		print("GameManager: Fase FPS Perdida!")
		_switch_player_turn() # Apenas passa a vez (não marca a célula)
		_set_game_state(GameState.TIC_TAC_TOE_TURN)
		# Se o próximo turno for da IA, ela joga automaticamente
		print("GameManager: Turno do Jogo da Velha. Próximo jogador: ", current_player_side)
		if current_player_side == PlayerSide.O:
			_process_ai_turn()

# Função auxiliar para trocar o turno
func _switch_player_turn() -> void:
	current_player_side = PlayerSide.X if current_player_side == PlayerSide.O else PlayerSide.O
	turn_changed.emit(current_player_side) # Notifica a HUD


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

func _process_ai_turn() -> void:
	# Garante que a IA só jogue se for o turno dela e o estado estiver correto
	if current_game_state != GameState.TIC_TAC_TOE_TURN or current_player_side != PlayerSide.O:
		return

	print("GameManager: Turno da IA (O).")

	# Opcional: Pequeno delay para simular que a IA está "pensando"
	await get_tree().create_timer(0.5).timeout

	var empty_cells: Array[Vector2i] = []
	# Encontra todas as células vazias no tabuleiro
	for r in range(3):
		for c in range(3):
			if tic_tac_toe_board[r][c] == PlayerSide.NONE:
				empty_cells.append(Vector2i(r, c))

	if not empty_cells.is_empty():
		# IA escolhe uma célula vazia aleatoriamente
		var chosen_cell = empty_cells[randi() % empty_cells.size()]
		mark_tic_tac_toe_cell(chosen_cell.x, chosen_cell.y, PlayerSide.O) # IA marca a célula
		print("IA marcou: ", chosen_cell)

		# Após a IA marcar, verifica se o jogo terminou (vitória da IA ou empate)
		if check_tic_tac_toe_win(current_player_side):
			_set_game_state(GameState.GAME_OVER)
			print("GameManager: Jogo da Velha FINALIZADO! Vencedor: IA (O)")
		elif check_tic_tac_toe_draw():
			_set_game_state(GameState.GAME_OVER)
			print("GameManager: Jogo da Velha FINALIZADO! EMPATE.")
		else:
			# Se o jogo não terminou, passa a vez de volta para o jogador (X)
			_switch_player_turn()
			_set_game_state(GameState.TIC_TAC_TOE_TURN)
			print("GameManager: Turno do Jogo da Velha. Próximo jogador: ", current_player_side)
	else:
		# Isso só deve acontecer se o tabuleiro já estiver cheio e for um empate (ou já houve um vencedor)
		print("IA: Nenhuma célula vazia encontrada.")
		if check_tic_tac_toe_draw():
			_set_game_state(GameState.GAME_OVER)
			print("GameManager: Jogo da Velha FINALIZADO! EMPATE.")
