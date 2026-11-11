extends CharacterBody3D

const SPEED = 2

@export var nav_agent : NavigationAgent3D

func _physics_process(delta: float):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

func update_target_position(target_position: Vector3): # Update target position for pathfinding
	nav_agent.target_position = target_position
