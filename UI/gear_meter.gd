extends TextureProgressBar

var gear_amount: int = 1
@export var animation_player: AnimationPlayer
@export var gear_label: Label

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		animation_player.stop()
		animation_player.play("gear_spin")
		gear_amount += 1
		gear_label.text = str(gear_amount)
