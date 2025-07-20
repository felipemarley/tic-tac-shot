extends Button

@export var default_color: Color = Color.WHITE
@export var x_color: Color = Color.RED
@export var o_color: Color = Color.BLUE

var grid_position: Vector2i  # Renomeado para evitar conflito
var cell_owner: String = ""  # Renomeado para evitar conflito

@export var lost_color: Color = Color(0.5, 0, 0, 1)  # Vermelho escuro para derrota

# Renomeados para evitar sobrescrita de métodos nativos
func set_grid_position(pos: Vector2i):
	grid_position = pos
	update_appearance()

func update_appearance():
	match cell_owner:
		"X":
			$Label.text = "X"
			$Label.modulate = x_color
		"O":
			$Label.text = "O"
			$Label.modulate = o_color
		_:
			$Label.text = ""
			$Label.modulate = default_color

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	update_appearance()
	

func set_cell_owner(new_owner: String, player_lost: bool = false):
	cell_owner = new_owner
	if player_lost:
		# Efeito especial quando o jogador perde
		var tween = create_tween()
		tween.tween_property($Label, "modulate", lost_color, 0.5)
		tween.parallel().tween_property(self, "modulate", lost_color, 0.5)
	update_appearance()
	disabled = true
