extends Node3D
@onready var dun_gen = $DunGen
@onready var player : PackedScene = preload("res://scene/player.tscn")

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
