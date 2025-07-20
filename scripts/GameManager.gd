extends Node

signal kill_count_changed(new_count: int)
signal player_spawned(player: Node)
signal fps_phase_ended(won: bool) # Sinaliza o fim de uma fase FPS

var kill_count: int = 0
var enemies_in_current_round: int = 0 # Rastreia o total de inimigos para o round FPS atual

func _ready() -> void:
	fps_phase_ended.connect(_on_fps_phase_ended)

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

# NOVO: Função para lidar com o fim de uma fase FPS e recarregar a cena
func _on_fps_phase_ended(won: bool) -> void:
	if won:
		print("GameManager: Fase FPS Vencida! Recarregando cena...")
	else:
		print("GameManager: Fase FPS Perdida! Recarregando cena...")

	# Dar um pequeno delay antes de recarregar, para que o print seja visível
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
	# O mouse mode também deve ser resetado, pois a cena será recarregada
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Define de volta para modo capturado para o novo round
