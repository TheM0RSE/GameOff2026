extends CharacterBody3D

var speed: float = 0
const WALK_SPEED = 10.0

# Jump
const JUMP_VELOCITY = 6.5

@export var coyote_time = 0.12
var coyote_timer = 0.0

@export var jump_buffer_time = 0.08 # 80 ms buffer window
var jump_buffer_timer = 0.0

@export var fall_multiplier = 1.5

# Dash
var is_dashing = false
@export var dash_duration = 0.25
var dash_timer = 0
var dash_charges = 3
var charges_refill_time = 5
var charges_refill_currentTime = 0
var dash_direction = Vector3.ZERO
@export var dash_speed = 20

# Stamina later

const WEIGHT = 2.0

var rate = 0
const GROUND_ACCEL = 80
const GROUND_FRICTION = 60
const AIR_ACCEL = 15
const AIR_FRICTION = 0.5

# Mouse & camera variables
var mouse_sensitivity := 0.005
var mouse_input = Vector2.ZERO

@export var camera : Camera3D
var cam_rotation := Vector2.ZERO

@export var glock : Glock

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Lock mouse ingame
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Collect mouse input data
		mouse_input += event.relative
	
func _process(delta: float) -> void:
	# If left moues button is pressed, call the shoot function in the pistol
	if Input.is_action_just_pressed("interact"):
		glock.shoot()
	
	# Call mouse move function
	mouse_move()
	
	#Toggle between locked and unlocked mouse
	if Input.is_action_just_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:	
	# If player is not on ground
	if not is_on_floor():
		# Gravity normal in the start of a jump and higher with fall_multiplier when falling
		if velocity.y < 0:
			velocity += get_gravity() * WEIGHT * fall_multiplier * delta
		else:
			velocity += get_gravity() * WEIGHT * delta
		
		coyote_timer -= 1 * delta
		
		# Set air rate for friction
		rate = AIR_ACCEL
	else:
		# Set ground rate for friction
		rate = GROUND_ACCEL
		coyote_timer = coyote_time
		
	jump(delta)	
	dash_and_move(delta)
	move_and_slide()
	
func mouse_move():
	# Apply rotation on every rendered framed
	rotate_y(-mouse_input.x * mouse_sensitivity)
	camera.rotate_x(-mouse_input.y * mouse_sensitivity)
	
	# Clamp vertical camera angle so you can't look upside down
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Clear the accumulated input so it doesn't carry over to the next frame
	mouse_input = Vector2.ZERO
	
func dash_and_move(delta):
	# Get input direction and handle movement
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var horizontal = Vector3(velocity.x, 0, velocity.z)
	
	# Register dash input
	if Input.is_action_just_pressed("Dash") and not is_dashing:
		# Check if the player has more than 0 dash charges
		if dash_charges > 0:
			# Remove one charge
			dash_charges -= 1
			print(dash_charges)
			
			# If moving, dash in movement direction. Otherwise dash forward
			if direction != Vector3.ZERO:
				dash_direction = direction
			else:
				dash_direction = -transform.basis.z # Default forward if standing still
				
			is_dashing = true
			dash_timer = dash_duration
			charges_refill_currentTime = charges_refill_time
		else:
			# print("Don't have any dash charges")
			return
	
	# Set target direction
	var target = direction * WALK_SPEED
	# Handle dash
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		
		if dash_timer <= 0:
			is_dashing = false
	else:
		# Apply normal movement to the player
		horizontal = horizontal.move_toward(target, rate * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
		
		charges_refill_currentTime -= charges_refill_time * delta
		
		# print(charges_refill_currentTime)
		if charges_refill_currentTime <= 0 and dash_charges < 3:
			charges_refill_currentTime = charges_refill_time
			dash_charges += 1
			print(dash_charges)

func jump(delta):
	# Decrease the jump buffer timer over time
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Register jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Execute jump if on floor and buffer is active and if coyote timer is higher than 0
	if (is_on_floor() or coyote_timer > 0.0) and jump_buffer_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0 # Consume the buffer
		coyote_timer = 0.0
