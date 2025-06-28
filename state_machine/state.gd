class_name State 
extends Node3D

func enter() -> void: pass

func exit() -> void: pass

func process_physics(delta: float) -> State: return null

func process_frame(delta: float) -> State: return null

func process_input(event: InputEvent) -> State: return null
