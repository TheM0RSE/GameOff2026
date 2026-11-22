extends TextureProgressBar

enum GearState { # Divide damage by incrementing number to make it harder to gear up
	ONE = 1,
	TWO = 2,
	THREE = 4,
	FOUR = 6,
	FIVE = -1,
}

@export var animation_player: AnimationPlayer
@export var gear_label: Label

const max_gear: int = 5
var current_gear: GearState = GearState.ONE
var current_value: int = 0

var animation_time = 0.1

func add_value(value: int):
	if current_gear == GearState.FIVE:
		return
	value /= current_gear
	var new_value = current_value + value
	if new_value >= 100:
		gear_up(new_value)
		update_bar(current_value, new_value, true)
	else:
		update_bar(current_value, new_value)
	
func update_bar(old_value: int, new_value: int, geared_up: int = false):
	current_value = new_value
	if current_gear == GearState.FIVE:
		var tween := create_tween()
		tween.tween_property(self, "value", 100, animation_time).from(old_value)
	elif geared_up:
		var tween := create_tween()
		tween.tween_method(_update_wrapped_value, old_value, new_value, animation_time)
	else:
		var tween := create_tween()
		tween.tween_property(self, "value", new_value, animation_time).from(old_value)
	
func gear_up(value: int):
	var rest_value = value - 100
	current_value = rest_value
	# Increment Gear
	var gears = GearState.values()
	var next_index = (gears.find(current_gear) + 1)
	current_gear = gears[next_index] as GearState
	
	animation_player.stop()
	animation_player.play("gear_spin")
	gear_label.text = str(next_index + 1)
	if current_gear == GearState.FIVE:
		self.value = 100
	
func _update_wrapped_value(raw_val: float):
	current_value = fmod(raw_val, 100)
	self.value = current_value
