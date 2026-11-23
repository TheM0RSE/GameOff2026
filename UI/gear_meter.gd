extends TextureProgressBar

enum GearState { # Divide damage by incrementing number to make it harder to gear up
	ONE = 1,
	TWO = 2,
	THREE = 4,
	FOUR = 5,
	FIVE = -1,
}

@export var animation_player: AnimationPlayer
@export var gear_label: Label

const max_gear: int = 5
var current_gear: GearState = GearState.ONE
var current_value: int = 0

var animation_time = 0.5

var time_until_decay = 2
var time_until_geardown = 2
var decay_timer = time_until_decay
var geardown_timer = time_until_geardown

func _physics_process(delta: float) -> void:
	if decay_timer < 0:
		if geardown_timer < 0 and current_gear != GearState.ONE:
			geardown_timer = time_until_geardown
			gear(true)
			update_bar(100, 90)
		else:
			if current_value <= 0:
				geardown_timer -= delta
			else:
				geardown_timer = time_until_geardown
				decay_timer = time_until_decay
				if current_value < 10:
					update_bar(current_value, 0)
				else:
					update_bar(current_value, current_value-10)
	decay_timer -= delta

func add_value(value: int):
	decay_timer = time_until_decay
	if current_gear == GearState.FIVE:
		return
	value /= current_gear
	var new_value = current_value + value
	if new_value >= 100:
		gear()
		update_bar(current_value, new_value, true)
	else:
		update_bar(current_value, new_value)
	
func update_bar(old_value: int, new_value: int, geared_up: int = false):
	current_value = new_value
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if current_gear == GearState.FIVE:
		tween.tween_property(self, "value", 100, animation_time).from(old_value)
	elif geared_up:
		tween.tween_method(_update_wrapped_value, old_value, new_value, animation_time)
	else:
		tween.tween_property(self, "value", new_value, animation_time).from(old_value)
	
func gear(gear_down: bool = false):
	var gears = GearState.values()
	var next_index: int
	if gear_down:
		next_index = gears.find(current_gear) - 1
	else:
		next_index = gears.find(current_gear) + 1
	current_gear = gears[next_index] as GearState
	animation_player.stop()
	animation_player.play("gear_spin")
	gear_label.text = str(next_index + 1)
	if current_gear == GearState.FIVE:
		self.value = 100
	
func _update_wrapped_value(raw_val: float):
	current_value = fmod(raw_val, 100)
	self.value = current_value
