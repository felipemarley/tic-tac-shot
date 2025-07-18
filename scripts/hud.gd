extends Control

@onready var hp_label: Label = $Label

# HealthComponent do Player
var player_health_component: Node = null

func _ready():
	# HUD está sempre por cima de outros elementos 3D
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func set_player_health_component(health_comp: Node):
	if player_health_component:
		# Desconecta o sinal antigo se já houver um componente conectado
		player_health_component.health_changed.disconnect(_on_player_health_changed)

	player_health_component = health_comp
	if player_health_component:
		player_health_component.health_changed.connect(_on_player_health_changed)

		_on_player_health_changed(player_health_component.current_hp)


func _on_player_health_changed(new_hp: int):
	if not hp_label or not player_health_component:
		return

	# Exibir vida como fração (ex: 70/100)
	var max_hp = player_health_component.max_hp
	hp_label.text = "HP: " + str(new_hp) + " / " + str(max_hp)
	var hp_percentage = float(new_hp) / max_hp

	# Colore barra de HP
	if new_hp <= 0:
		hp_label.modulate = Color("red") # Vermelho quando morto
		hp_label.text = "GAME OVER" # Mensagem de Game Over
	elif hp_percentage <= 0.20: # Abaixo ou igual a 20%
		hp_label.modulate = Color("red") # Vermelho
	elif hp_percentage <= 0.50: # Abaixo ou igual a 50%
		hp_label.modulate = Color("yellow") # Amarelo
	else: # Acima de 50%
		hp_label.modulate = Color("green") # Verde
