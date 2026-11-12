extends CharacterBody3D

@export var movement_speed: float = 4.0
@export var player: Node3D # Assign player node in the inspector

@onready var nav_agent: NavigationAgent3D =  $NavigationAgent3D

func _ready() -> void:
	# Wait for the navigation map to sync
	await get_tree().physics_frame
	
func _physics_process(delta: float) -> void:
	if not player:
		return
	
	# Update the navigation agent's target position to the player's position
	nav_agent.target_position = player.global_position
	
	# Check if we have reached the target
	if nav_agent.is_navigation_finished():
		return
		
	# Get the next position along the path
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	
	# Calculate direction and move towards the next position
	var direction: Vector3 = current_agent_position.direction_to(next_path_position)
	velocity = direction * movement_speed
	
	# Rotate smoothly to face the movement direction
	if direction.length_squared() > 0.001:
		look_at(Vector3(global_position.x + direction.x, global_position.y, global_position.z + direction .z), Vector3.UP)
		
		
	move_and_slide()
