extends TextureProgressBar

@export var animation_player: AnimationPlayer
@export var gear_label: Label

const max_gear: int = 5
var current_gear: int = 1
var current_value: int = 0

var animation_time = 0.1

func add_value(value: int):
	var new_value = current_value + value
	if new_value >= 100:
		update_bar(current_value, new_value, true)
		gear_up(new_value)
	else:
		update_bar(current_value, new_value)
	
func update_bar(old_value: int, new_value: int, geared_up: int = false):
	current_value = new_value
	if geared_up:
		var tween := create_tween()
		tween.tween_method(_update_wrapped_value, old_value, new_value, animation_time)
	else:
		var tween := create_tween()
		tween.tween_property(self, "value", new_value, animation_time).from(old_value)
	
func gear_up(value: int):
	var rest_value = value - 100
	current_value = rest_value
	current_gear += 1
	animation_player.stop()
	animation_player.play("gear_spin")
	gear_label.text = str(current_gear)
	
func _update_wrapped_value(raw_val: float):
	current_value = fmod(raw_val, 100)
	self.value = current_value
