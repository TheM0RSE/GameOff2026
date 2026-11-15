extends CharacterBody3D

@export var movement_speed: float = 4.0
@export var headshot_multiplier = 1.5 # Multiplier if it gets hit in the head
@export var player: Node3D # Assign player node in the inspector

@export var health_component: HealthComponent # Handles health and damage
@export var health_bar: ProgressBar

@export var head_collider: Area3D # Head collider
@export var body_collider: Area3D # Body collider

@onready var nav_agent: NavigationAgent3D =  $NavigationAgent3D

func _ready() -> void:
	# Wait for the navigation map to sync
	await get_tree().physics_frame
	
func _physics_process(delta: float) -> void:
	if not player:
		return
		
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
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
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	
	# Rotate smoothly to face the movement direction
	if direction.length_squared() > 0.001:
		look_at(Vector3(global_position.x + direction.x, global_position.y, global_position.z + direction .z), Vector3.UP)
		
		
	move_and_slide()

func take_damage(collider: Area3D, damage: int):
	if not health_component:
		return
	if collider == head_collider:
		health_component.take_damage(damage * headshot_multiplier) # Multiply with headshot_multiplier if weapon hits head
	elif collider == body_collider:
		health_component.take_damage(damage)
	else:
		print("Not a body or head collider?")

func _on_health_component_health_changed(current_health: int): # What happens when the enemy's health changes?
	if not health_bar:
		return
	health_bar.value = current_health # Update healthbar with new current health


func _on_health_component_damage_taken(amount: int) -> void: # What happens when the enemy takes damage?
	print("Enemy takes %s damage" % amount)
	pass 

func _on_health_component_died() -> void: # What happens when the enemy dies?
	queue_free() # Deletes itself
	pass 
