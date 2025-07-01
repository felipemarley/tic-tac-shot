extends Node3D
@onready var dun_gen = $DunGen
@onready var player : PackedScene = preload("res://scene/player.tscn")
@onready var enemies : PackedScene = preload("res://scene/enemy.tscn")


func _ready() -> void:
	dun_gen.dungeon_ready.connect(on_dungeon_ready)
	dun_gen.generate()
	
func on_dungeon_ready() -> void:
	var positions : PackedVector3Array = dun_gen.room_positions
	var index : int = randi() % positions.size()
	var spawn : Vector3 = positions.get(index)
	spawn.y += 1
	var player_instance : CharacterBody3D = player.instantiate()
	add_child(player_instance)
	player_instance.global_position = spawn
	enemy_spawn(6)

func enemy_spawn(amount: int) -> void:
	for cell in dun_gen.grid_map.get_used_cells():
		for tile in dun_gen.room_tiles:
			randomize()
			var spawn_enemy_chanc : int = randi_range(1, (tile.size()/2))
			if(spawn_enemy_chanc < tile.size() / 2):
				continue
			if tile.has(cell):
				for enemy in range(1, amount):
					var e = enemies.instantiate()
					add_child(e)
					e.global_position = Vector3(cell) + Vector3(0.5, 1, 0.5)
