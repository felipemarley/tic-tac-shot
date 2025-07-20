extends CanvasLayer

@export var cell_scene: PackedScene = preload("res://ui_ux/CellUI.tscn")
@export var board_manager: NodePath
@onready var board_manager_node: Node = get_node(board_manager) if board_manager else null

var cells = {}
var game_active: bool = true

func _ready():
	assert(cell_scene)
	assert(board_manager_node)
	setup_board()
	connect_signals()

func setup_board():
	var container = $MarginContainer/GridContainer
	container.columns = Global.board_size

	for child in container.get_children():
		child.queue_free()
	cells.clear()

	for i in range(Global.board_size):
		for j in range(Global.board_size):
			var cell = cell_scene.instantiate()
			var pos = Vector2i(i, j)
			cell.set_grid_position(pos)
			cell.pressed.connect(_on_cell_pressed.bind(i, j))
			container.add_child(cell)
			cells[pos] = cell
			cell.name = "Cell_%d_%d" % [i, j]

func connect_signals():
	board_manager_node.cell_conquered.connect(_on_cell_conquered)
	board_manager_node.game_over.connect(_on_game_over)
	board_manager_node.board_visibility_changed.connect(_on_board_visibility_changed)
	board_manager_node.ai_cell_selected.connect(_on_ai_cell_selected)

func _on_cell_pressed(row: int, col: int):
	if not game_active:
		return
	board_manager_node.start_battle(Vector2i(row, col))

func _on_cell_conquered(cell_position: Vector2i, conqueror: String, player_lost: bool = false):
	var cell = cells.get(cell_position)
	if cell:
		cell.set_cell_owner(conqueror, player_lost)

func _on_game_over(winner: String):
	game_active = false
	var game_over_ui = preload("res://ui_ux/GameOverUI.tscn").instantiate()
	game_over_ui.set_winner(winner)
	add_child(game_over_ui)

	for cell in cells.values():
		cell.disabled = true

func _on_board_visibility_changed(show: bool):
	visible = show
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS if show else Control.MOUSE_FILTER_IGNORE
	for cell in cells.values():
		cell.disabled = not show

func _on_ai_cell_selected(pos: Vector2i):
	var cell = cells.get(pos)
	if cell:
		var tween = create_tween()
		tween.tween_property(cell, "scale", Vector2(0.8, 0.8), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(cell, "scale", Vector2(1, 1), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.connect("finished", Callable(board_manager_node, "on_ai_cell_animation_finished").bind(pos))

func reset_board():
	game_active = true
	setup_board()
