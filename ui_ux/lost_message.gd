extends ColorRect

@onready var player = get_tree().get_root().find_child("Player", true, false)

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var message := self

func _show_lost_message():
	message.visible = true

	if anim_player:
		anim_player.play("fade-in-fade-out")

	await anim_player.animation_finished
	message.visible = false   
