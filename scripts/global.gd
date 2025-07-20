extends Node

var board_state = {}  # {"0,0": null, "1,1": "X", ...}
var board_size = 3
var player_symbol = "O"
var ai_symbol = "X"
var turn = "ai"

func initialize_board():
	board_state.clear()
	for row in range(board_size):
		for col in range(board_size):
			var cell_id = "%d,%d" % [row, col]
			board_state[cell_id] = null
