extends CharacterBody3D

const SPEED = 2

@export var target_list : Array[Target] # List of every target the customer will go to.
@export var nav_agent : NavigationAgent3D
var current_target : Target # Keep track of which target the customer is going to.

var paused = false
var pause_timer = 0

func _ready():
	if target_list.size() > 0: # If there are any targets
		current_target = target_list[0]
		update_target_position(current_target["target_location"])
	
func _physics_process(delta: float):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Calculate velocity for pathfinding
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	# Move customer
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()
	
	# Pause timer
	if pause_timer < 0 and paused: # If the pause timer is done (below 0) and customer is paused
		paused = false
		target_list.remove_at(0) # Remove first target
		if target_list.size() > 0:
			current_target = target_list[0]
			update_target_position(current_target["target_location"])
		else: # If there are no targets left
			print("FINISHED PATH")
	pause_timer -= delta

func update_target_position(target_position: Vector3): # Update target position for pathfinding
	nav_agent.target_position = target_position

func _on_navigation_agent_3d_navigation_finished() -> void:
	pause_timer = current_target["length"] # Set a pause timer to wait before updating to next target
	paused = true
