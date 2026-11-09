extends Node3D
class_name Glock

@export var shoot_sfx : AudioStreamPlayer3D
@export var animation_player : AnimationPlayer
@export var camera : Camera3D

@export var shoot_rate = 0.2 # Gun delay
var shoot_rate_timer = 0.0

const RAY_LENGTH = 1000 # Shooting length

func shoot():
	if shoot_rate_timer > 0:
		return
		
	# SHOOTING DIRECTION
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = camera.project_ray_origin(mouse_pos)
	var ray_to = camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var space_state = get_world_3d().direct_space_state
	var collision = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_from, ray_to))
	
	if collision:
		var coll_position = collision["position"] # Get the intersect point of the first collision
		
		# TESTING (CREATES BOX WHERE MOUSE IS POINTED)
		var box = CSGBox3D.new()
		box.size = Vector3(1, 1, 1)
		box.position = coll_position
		get_tree().current_scene.add_child(box)
		# TESTING
	
	shoot_rate_timer = 0.2
	shoot_sfx.stop()
	shoot_sfx.play()
	animation_player.stop()
	animation_player.play("Glock_Shoot")

func _process(delta):
	shoot_rate_timer -= delta
