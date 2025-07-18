extends Node

signal kill_count_changed(new_count: int)
signal player_spawned(player: Node)

var kill_count: int = 0

func add_kill() -> void:
	kill_count += 1
	kill_count_changed.emit(kill_count)
