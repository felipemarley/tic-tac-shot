extends Node3D

signal enemies_spawned_for_round(count: int)

@onready var dun_gen = $DunGen
@onready var player : PackedScene = preload("res://scene/player.tscn")
@onready var enemies : PackedScene = preload("res://scene/enemy.tscn")
var player_instance : CharacterBody3D = null


func _ready() -> void:
	dun_gen.dungeon_ready.connect(on_dungeon_ready)
	dun_gen.generate()

	enemies_spawned_for_round.connect(GameManager.start_new_fps_round)


func on_dungeon_ready() -> void:
	var positions : PackedVector3Array = dun_gen.room_positions
	var index : int = randi() % positions.size()
	var spawn : Vector3 = positions.get(index)
	spawn.y += 1.4
	player_instance = player.instantiate()
	add_child(player_instance)
	player_instance.global_position = spawn

	enemy_spawn()
	dun_gen.grid_map.clear()

	GameManager.player_spawned.emit(player_instance)

func enemy_spawn() -> void:
	var spawned_enemy_count : int = 0
	for cell in dun_gen.grid_map.get_used_cells():
		for tile in dun_gen.room_tiles:
			randomize()
			var spawn_enemy_chanc : int = randi_range(1, (tile.size()/2))
			if(spawn_enemy_chanc < tile.size() / 2):
				continue
			if tile.has(cell):
				var e = enemies.instantiate()
				add_child(e)
				e.global_position = Vector3(cell) + Vector3(0.5, 1, 0.5)

				e.died_and_killed.connect(GameManager.add_kill)
				spawned_enemy_count += 1

	enemies_spawned_for_round.emit(spawned_enemy_count)
