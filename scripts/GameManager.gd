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
		print("Cheat: Teleported enemy " + enemy.name + " to " + str(teleport_position))

	print("Cheat: Teleported " + str(teleported_enemies_count) + " existing enemies to player front.")
	# Não precisamos ajustar enemies_in_current_round aqui, pois estamos teleportando os existentes,
	# e eles já contam na contagem original do round.
