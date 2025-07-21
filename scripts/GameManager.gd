extends Node

@onready var board_manager = get_tree().get_root().find_child("BoardManager", true, false)
@onready var player = get_tree().get_root().find_child("Player", true, false)

signal kill_count_changed(new_count: int)
signal player_spawned(player: Node)
signal arena_completed(victory: bool)
signal enemies_count_updated(total: int, killed: int)  # Novo sinal
signal win

var is_win = false

var kill_count: int = 0:
	set(value):
		kill_count = value
		kill_count_changed.emit(kill_count)
		enemies_count_updated.emit(total_enemies, kill_count)

var total_enemies: int = 0:
	set(value):
		total_enemies = value
		enemies_count_updated.emit(total_enemies, kill_count)

var current_player: CharacterBody3D = null
var enemies_in_arena: Array = []  # Lista de inimigos na arena atual

func _ready():
	pass

func add_kill() -> void:
	kill_count += 1
	# Verificação automática se todos os inimigos foram derrotados
	if kill_count == total_enemies:
		win_true()
		
		#report_arena_result(true)

func register_enemy(enemy: Node) -> void:
	if not enemy in enemies_in_arena:
		enemies_in_arena.append(enemy)
		total_enemies = enemies_in_arena.size()
		enemy.tree_exiting.connect(_on_enemy_destroyed.bind(enemy))

func _on_enemy_destroyed(enemy: Node):
	if enemy in enemies_in_arena:
		enemies_in_arena.erase(enemy)
	# Não chamamos add_kill() aqui pois o inimigo pode ter sido destruído sem ser morto

func report_arena_result(victory: bool):
	arena_completed.emit(victory)
	reset_arena_counts()

func reset_arena_counts():
	enemies_in_arena.clear()
	total_enemies = 0
	kill_count = 0

func reset_all_counts():
	reset_arena_counts()
	current_player = null

func win_true():
	if is_win: return
	is_win = true
	Global.victory = Global.player_symbol
	print("Vencedor da célula: " + Global.victory)
	win.emit()  
	
func is_not_win():
	if !is_win: return
	is_win = false
	
