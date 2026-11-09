extends Node3D
class_name Glock

@export var shoot_sfx : AudioStreamPlayer3D
@export var animation_player : AnimationPlayer

@export var shoot_rate = 0.2
var shoot_rate_timer = 0.0

func shoot():
	if shoot_rate_timer > 0:
		return
	shoot_rate_timer = 0.2
	shoot_sfx.stop()
	shoot_sfx.play()
	animation_player.stop()
	animation_player.play("Glock_Shoot")

func _process(delta):
	shoot_rate_timer -= delta
