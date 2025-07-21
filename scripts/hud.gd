extends Control
@onready var pause_menu = $PauseMenu

@onready var hp_label: Label = $CanvasLayer/HudLayout/HpLabel
@onready var kill_label: Label = $CanvasLayer/Labels/KillLabel

@onready var hud: Sprite2D = $CanvasLayer/HudLayout/hud
@onready var hud2: Sprite2D = $CanvasLayer/HudLayout/hud2
@onready var hud3: Sprite2D = $CanvasLayer/HudLayout/hud3
@onready var arma: Sprite2D = $CanvasLayer/HudLayout/arma
@onready var player_anim: AnimatedSprite2D = $CanvasLayer/HudLayout/PlayerAnim
@onready var health_label: Label = $CanvasLayer/Labels/HealthLabel
@onready var kill_label2: Label = $CanvasLayer/Labels/KillLabel2

# Referências para os elementos do tabuleiro
@onready var tic_tac_toe_board_container: Control = $CanvasLayer/TicTacToeBoardContainer # O PanelContainer que contém o tabuleiro
@onready var tic_tac_toe_grid: GridContainer = $CanvasLayer/TicTacToeBoardContainer/TicTacToeGrid # O GridContainer
@onready var turn_label: Label = $CanvasLayer/Labels/TurnLabel # Label para o turno
@onready var game_status_label: Label = $CanvasLayer/Labels/GameStatusLabel # Label para status geral do jogo
@onready var restart_game_button: Button = $CanvasLayer/RestartGameButton # Botão de reiniciar
@onready var game_status_timer: Timer = $GameStatusTimer

@onready var player = get_tree().get_root().find_child("Player", true, false)


# HealthComponent do Player
var player_health_component: Node = null

var paused = false

func _input(event):
	if event.is_action_pressed("pause"):
		print("clik")
		pauseMenu()
		
		
func pauseMenu():
	if paused:
		print("depausei")
		pause_menu.hide()
		Engine.time_scale = 1
		
		if player:
			player.set_camera_paused(false) # ou false, dependendo do estado do pause
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		print("pausei")
		pause_menu.show()
		if player:
			player.set_camera_paused(true) # ou false, dependendo do estado do pause
		Engine.time_scale = 0

		
	paused = !paused

func _ready():
	pause_menu.hide()

	# HUD está sempre por cima de outros elementos 3D
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

	# Contagem de kills
	GameManager.kill_count_changed.connect(self.update_kill_count)
	update_kill_count(GameManager.kill_count)

	GameManager.player_spawned.connect(self._on_player_spawned)

	# Conectar HUD aos sinais do GameManager para o jogo da velha
	GameManager.game_state_changed.connect(self._on_game_state_changed)
	GameManager.board_updated.connect(self._on_board_updated)
	GameManager.turn_changed.connect(self._on_turn_changed)

	# Conectar os botões das células do tabuleiro
	for r in range(3):
		for c in range(3):
			var cell_button: Button = tic_tac_toe_grid.get_node("Cell_" + str(r) + "_" + str(c))
			if cell_button:
				cell_button.pressed.connect(Callable(self, "_on_cell_button_pressed").bind(r, c))

	# Conectar o botão de reiniciar
	restart_game_button.pressed.connect(GameManager._start_new_game) # Chama a função de reinício no GameManager

	game_status_timer.timeout.connect(self._on_game_status_timer_timeout)

	# Inicializa o estado visual da HUD
	_on_game_state_changed(GameManager.current_game_state) # Define o estado inicial da UI
	_on_turn_changed(GameManager.current_player_side) # Define o turno inicial


func update_kill_count(current_kills: int):
	if kill_label:
		var total_enemies_in_round = GameManager.enemies_in_current_round
		if total_enemies_in_round > 0:
			kill_label.text = str(current_kills) + " / " + str(total_enemies_in_round)
		else:
			kill_label.text = "Kills: " + str(current_kills)

func _on_player_spawned(player: Node) -> void:
	var hc = player.get_node("HealthComponent")
	set_player_health_component(hc)

func set_player_health_component(health_comp: Node):
	if player_health_component:
		# Desconecta o sinal antigo se já houver um componente conectado
		player_health_component.health_changed.disconnect(_on_player_health_changed)

	player_health_component = health_comp
	if player_health_component:
		player_health_component.health_changed.connect(_on_player_health_changed)

		_on_player_health_changed(player_health_component.current_hp)


func _on_player_health_changed(new_hp: int):
	if not hp_label or not player_health_component:
		return

	# Exibir vida como fração (ex: 70/100)
	var max_hp = player_health_component.max_hp
	#hp_label.text = "HP: " + str(new_hp) + " / " + str(max_hp)
	var hp_percentage = float(new_hp) / max_hp
	hp_label.text =  str(new_hp) + "%" 

	# Colore barra de HP
	if new_hp <= 0:
		hp_label.modulate = Color("red") # Vermelho quando morto
		hp_label.text = "GAME OVER" # Mensagem de Game Over
		player_anim.play("die")
	elif hp_percentage <= 0.20: # Abaixo ou igual a 20%
		hp_label.modulate = Color("red") # Vermelho
		player_anim.play("10perc")
	elif hp_percentage <= 0.50: # Abaixo ou igual a 50%
		hp_label.modulate = Color("yellow") # Amarelo
		player_anim.play("50perc")
	else: # Acima de 50%
		hp_label.modulate = Color("green") # Verde
		player_anim.play("normal")



# Chamado quando um botão de célula do tabuleiro é pressionado
func _on_cell_button_pressed(row: int, col: int) -> void:
	GameManager.choose_tic_tac_toe_cell(row, col) # Chama a lógica no GameManager

# Atualiza a exibição do tabuleiro na HUD
func _on_board_updated(board_state: Array[Array]) -> void:
	for r in range(3):
		for c in range(3):
			var cell_button: Button = tic_tac_toe_grid.get_node("Cell_" + str(r) + "_" + str(c))
			if cell_button:
				match board_state[r][c]:
					GameManager.PlayerSide.NONE:
						cell_button.text = "" # Célula vazia
						cell_button.disabled = false # Habilita para interação
					GameManager.PlayerSide.X:
						cell_button.text = "X"
						cell_button.disabled = true # Desabilita após ser marcada
					GameManager.PlayerSide.O:
						cell_button.text = "O"
						cell_button.disabled = true # Desabilita após ser marcada

# Atualiza o label de turno
func _on_turn_changed(player_side: GameManager.PlayerSide) -> void:
	if turn_label:
		match player_side:
			GameManager.PlayerSide.X:
				turn_label.text = "Seu Turno: X"
			GameManager.PlayerSide.O:
				turn_label.text = "Turno da IA: O"
			GameManager.PlayerSide.NONE:
				turn_label.text = "Jogo Parado"


# Controla a visibilidade dos elementos da HUD com base no estado do jogo
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	# Esconde/mostra elementos de acordo com o estado
	match new_state:
		GameManager.GameState.MENU:
			tic_tac_toe_board_container.visible = false
			game_status_label.text = "Bem-vindo ao Tic-Tac-Shot!"
			game_status_timer.stop()
			restart_game_button.visible = false
			hp_label.visible = false
			kill_label.visible = false
			turn_label.visible = false
			hud.visible = false
			hud2.visible = false
			hud3.visible = false 
			arma.visible = false
			player_anim.visible = false
			health_label.visible = false
			kill_label2.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		GameManager.GameState.TIC_TAC_TOE_TURN:
			tic_tac_toe_board_container.visible = true
			game_status_label.text = "Selecione uma celula para conquistar:"
			game_status_timer.stop()
			restart_game_button.visible = false
			hp_label.visible = false
			kill_label.visible = false
			turn_label.visible = true
			hud.visible = false
			hud2.visible = false
			hud3.visible = false 
			arma.visible = false
			player_anim.visible = false
			health_label.visible = false
			kill_label2.visible = false
			_enable_board_buttons(GameManager.current_player_side == GameManager.PlayerSide.X)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Mouse visível para interagir com o tabuleiro

		GameManager.GameState.FPS_PHASE:
			tic_tac_toe_board_container.visible = false
			game_status_label.text = "Lute!"
			restart_game_button.visible = false
			game_status_timer.start(5.0)
			hp_label.visible = true
			kill_label.visible = true
			turn_label.visible = false
			hud.visible = true
			hud2.visible = true
			hud3.visible = true 
			arma.visible = true
			player_anim.visible = true
			health_label.visible = true
			kill_label2.visible = true

		GameManager.GameState.ROUND_END:
			tic_tac_toe_board_container.visible = false
			game_status_label.text = "Rodada Encerrada!"
			game_status_timer.stop()
			restart_game_button.visible = false
			hp_label.visible = true
			kill_label.visible = true
			turn_label.visible = false
			hud.visible = true
			hud2.visible = true
			hud3.visible = true 
			arma.visible = true
			player_anim.visible = true
			health_label.visible = true
			kill_label2.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		GameManager.GameState.GAME_OVER:
			tic_tac_toe_board_container.visible = true
			restart_game_button.visible = true
			hp_label.visible = false
			kill_label.visible = false
			turn_label.visible = false
			hud.visible = false
			hud2.visible = false
			hud3.visible = false 
			arma.visible = false
			player_anim.visible = false
			health_label.visible = false
			kill_label2.visible = false
			game_status_timer.stop()
			game_status_label.visible = true
			if GameManager.check_tic_tac_toe_win(GameManager.PlayerSide.X):
				game_status_label.text = "VOCE VENCEU (X)!"
			elif GameManager.check_tic_tac_toe_win(GameManager.PlayerSide.O):
				game_status_label.text = "VOCE PERDEU! VITORIA DA IA: O!"
			else:
				game_status_label.text = "EMPATE!"
			_enable_board_buttons(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Mouse visível para interagir com o botão de reiniciar

# Habilita/desabilita botões do tabuleiro
func _enable_board_buttons(enable: bool) -> void:
	for r in range(3):
		for c in range(3):
			var cell_button: Button = tic_tac_toe_grid.get_node("Cell_" + str(r) + "_" + str(c))
			if cell_button:
				# Só habilita se a célula não estiver marcada
				cell_button.disabled = not enable or (GameManager.tic_tac_toe_board[r][c] != GameManager.PlayerSide.NONE)

# Função chamada quando o timer termina
func _on_game_status_timer_timeout():
	game_status_label.visible = false
	game_status_label.text = ""
