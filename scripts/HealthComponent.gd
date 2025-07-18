extends Node

# Sinal emitido quando a vida muda
signal health_changed(new_hp)
# Sinal emitido quando a entidade morre
signal died
# Sinal emitido quando a entidade vai tomar dano
signal damaged(amount: int)

@export var max_hp: int = 1
@export var current_hp: int
var is_dead: bool = false

func _ready():
	current_hp = max_hp
	health_changed.emit(current_hp)
	# Conecta o próprio sinal de dano ao método de aplicar dano
	damaged.connect(self.take_damage)

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
