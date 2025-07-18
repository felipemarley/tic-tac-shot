extends Node

@export var max_hp: int = 1
@export var current_hp: int
var is_dead: bool = false

# Sinal para avisar que a vida mudou
signal health_changed(new_hp)
# Sinal para avisar que a entidade morreu
signal died

func _ready():
	current_hp = max_hp
	health_changed.emit(current_hp)

func take_damage(amount: int):
	if is_dead: return

	current_hp -= amount
	health_changed.emit(current_hp)

	if current_hp <= 0:
		die()

func die():
	if is_dead: return
	is_dead = true
	died.emit()
