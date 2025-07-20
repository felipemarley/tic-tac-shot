extends CanvasLayer

@export var cell_scene: PackedScene = preload("res://ui_ux/CellUI.tscn")
@export var board_manager: NodePath
@onready var board_manager_node: Node = get_node(board_manager) if board_manager else null

var cells = {}
var game_active: bool = true

func _ready():
	visible = true
	assert(cell_scene, "Cena da célula não atribuída!")
	assert(board_manager_node, "BoardManager não atribuído ou caminho inválido!")

	setup_board()
	connect_signals()

func connect_signals():
	if board_manager_node:
		if board_manager_node.has_signal("cell_conquered"):
			board_manager_node.cell_conquered.connect(_on_cell_conquered.bind())
		if board_manager_node.has_signal("game_over"):
			board_manager_node.game_over.connect(_on_game_over)

		if board_manager_node.has_signal("board_visibility_changed"):
			board_manager_node.board_visibility_changed.connect(_on_board_visibility_changed)

		if board_manager_node.has_signal("ai_cell_selected"):
			board_manager_node.ai_cell_selected.connect(_on_ai_cell_selected)
	else:
		push_error("BoardManager node é nulo!")

func setup_board():
	var container = $MarginContainer/GridContainer

	if not board_manager_node:
		push_error("BoardManager não disponível!")
		return

	container.columns = board_manager_node.grid_size

	for child in container.get_children():
		child.queue_free()
	cells.clear()

	for i in range(board_manager_node.grid_size):
		for j in range(board_manager_node.grid_size):
			var cell = cell_scene.instantiate()
			var pos = Vector2i(i, j)

			if cell.has_method("set_grid_position"):
				cell.set_grid_position(pos)

			if cell.is_class("Button"):
				cell.pressed.connect(_on_cell_pressed.bind(i, j))

			container.add_child(cell)
			cells[pos] = cell
			cell.name = "Cell_%d_%d" % [i, j]

func _on_cell_pressed(row: int, col: int):
	if not game_active:
		return

	if not board_manager_node:
		push_error("BoardManager não disponível!")
		return

	var pos = Vector2i(row, col)
	if not cells.has(pos):
		push_error("Célula não encontrada: ", pos)
		return

	board_manager_node.start_battle(pos)

func _on_game_over(winner: String):
	game_active = false

	var game_over_ui = preload("res://ui_ux/GameOverUI.tscn").instantiate()
	if game_over_ui.has_method("set_winner"):
		game_over_ui.set_winner(winner)
	add_child(game_over_ui)

	for cell in cells.values():
		if cell.is_class("Button"):
			cell.disabled = true

func _on_board_visibility_changed(show: bool):
	visible = show
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS if show else Control.MOUSE_FILTER_IGNORE

	for cell in cells.values():
		if cell.is_class("Button"):
			cell.disabled = not show

func _on_ai_cell_selected(pos: Vector2i):
	if not cells.has(pos):
		return

	var cell = cells[pos]
	var tween = create_tween()
	tween.tween_property(cell, "scale", Vector2(0.8, 0.8), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(cell, "scale", Vector2(1, 1), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Após a animação, avisa o BoardManager para continuar
	tween.connect("finished", Callable(board_manager_node, "on_ai_cell_animation_finished").bind(pos))

func _on_cell_conquered(cell_position: Vector2i, conqueror: String, player_lost: bool = false):
	if not cells.has(cell_position):
		push_error("Posição inválida: ", cell_position)
		return
	var cell = cells[cell_position]
	if cell.has_method("set_cell_owner"):
		cell.set_cell_owner(conqueror, player_lost)
		# Efeito adicional se o jogador perdeu
		if player_lost:
			var shake_tween = create_tween()
			shake_tween.tween_property(cell, "position:x", cell.position.x + 5, 0.1)
			shake_tween.tween_property(cell, "position:x", cell.position.x - 5, 0.1)
			shake_tween.tween_property(cell, "position:x", cell.position.x, 0.1)
			shake_tween.set_loops(3)

func reset_board():
	game_active = true
	setup_board()
