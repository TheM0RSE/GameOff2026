extends CharacterBody3D

# Player variables
@export var collision : CollisionShape3D
const STAND_HEIGHT = 2.0
const LOW_HEIGHT = 1.0
var stand_cam_y = 0.0
var stand_col_y = 0.0

# Move Variables
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

# Slide
var is_sliding = false
var slide_direction = Vector3.ZERO
@export var slide_speed = 14.0
const SLIDE_FRICTION = 8
const SLIDE_MIN_SPEED = 4.0
const SLOPE_ACCEL = 60

var was_on_floor = false
var just_landed = false

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
	stand_cam_y = camera.position.y
	stand_col_y = collision.position.y
	speed = WALK_SPEED
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Collect mouse input data
		mouse_input += event.relative
	
func _process(delta: float) -> void:
	# If left moues button is pressed, call the shoot fuwdnction in the pistol
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
	update_height(delta)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	just_landed = is_on_floor() and not was_on_floor

# Update player height
func update_height(delta):
	var target_height = STAND_HEIGHT
	var drop = STAND_HEIGHT - target_height
	var cam_target = stand_cam_y - drop
	
	if is_sliding:
		target_height = LOW_HEIGHT
		
	collision.shape.height = target_height
	collision.position.y = stand_col_y - drop / 2
	
	camera.position.y = lerp(camera.position.y, cam_target, 15 * delta)
	
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
	if Input.is_action_just_pressed("Dash") and not is_dashing and not is_sliding:
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
			
	# Register slide input
	if ((Input.is_action_just_pressed("Slide") and is_on_floor()) or (Input.is_action_pressed("Slide") and just_landed)) and not is_sliding:
		if horizontal.length() > SLIDE_MIN_SPEED:
			is_sliding = true
			is_dashing = false
			slide_direction = horizontal.normalized()
			horizontal = slide_direction * max(horizontal.length(), slide_speed)
	
	# Set target direction
	var target = direction * speed
	
	# Handle dash
	if is_dashing:
		dash_timer -= delta
		horizontal = dash_direction * dash_speed
		
		if dash_timer <= 0:
			is_dashing = false
	elif is_sliding:
		horizontal = horizontal.move_toward(Vector3.ZERO, SLIDE_FRICTION * delta)
		
		var n := get_floor_normal()
		var downhill := Vector3.DOWN - n * Vector3.DOWN.dot(n)
		
		horizontal += downhill * SLOPE_ACCEL * delta
		
		# Stop conditions
		if horizontal.length() < SLIDE_MIN_SPEED or not Input.is_action_pressed("Slide"):
			is_sliding = false
	else:
		# Apply normal movement to the player
		horizontal = horizontal.move_toward(target, rate * delta)
		
		if not is_on_floor() and direction != Vector3.ZERO and horizontal.length() > speed:
			target = direction * horizontal.length()
		
		charges_refill_currentTime -= charges_refill_time * delta
		
		# print(charges_refill_currentTime)
		if charges_refill_currentTime <= 0 and dash_charges < 3:
			charges_refill_currentTime = charges_refill_time
			dash_charges += 1
			print(dash_charges)
			
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	
	if is_sliding and is_on_floor():
		var n := get_floor_normal()
		velocity.y = -(n.x * velocity.x + n.z * velocity.z) / n.y

func jump(delta):
	
	
	# Decrease the jump buffer timer over time
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Register jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Execute jump if on floor and buffer is active and if coyote timer is higher than 0
	if (is_on_floor() or coyote_timer > 0.0) and jump_buffer_timer > 0:
		if is_sliding:
			is_sliding = false
		
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0 # Consume the buffer
		coyote_timer = 0.0
