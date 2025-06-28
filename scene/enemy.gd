class_name Enemy
extends CharacterBody3D

@onready var state_machine: StateMachine = $StateMachine
@onready var enemy : Enemy = get_tree().get_first_node_in_group("Enemy")


func _ready() -> void:state_machine._init()

func _process(delta: float) -> void: state_machine.process_frame(delta)

func _physics_process(delta: float) -> void: state_machine.process_physics(delta)

func _input(event: InputEvent) -> void: state_machine.process_input(event)
