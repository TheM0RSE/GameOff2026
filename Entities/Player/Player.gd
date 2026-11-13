extends CharacterBody3D

var speed: float = 0
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0

# Jump
const JUMP_VELOCITY = 6.5

@export var coyote_time = 0.12
var coyote_timer = 0.0

@export var jump_buffer_time = 0.08 # 80 ms buffer window
var jump_buffer_timer = 0.0

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
	
	# If left shift is held, change speed to sprint speed.
	if Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

func _physics_process(delta: float) -> void:	
	# If player is not on ground
	if not is_on_floor():
		# Gravity
		coyote_timer -= 1 * delta
		velocity += get_gravity() * WEIGHT * delta
		
		# Set air rate for friction
		rate = AIR_ACCEL
	else:
		# Set ground rate for friction
		rate = GROUND_ACCEL
		coyote_timer = coyote_time
		
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

	# Get input direction and handle movement
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Set target direction
	var target = direction * speed
	
	# Apply movement to the player
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)

	move_and_slide()
	
func mouse_move():
	# Apply rotation on every rendered frame
	rotate_y(-mouse_input.x * mouse_sensitivity)
	camera.rotate_x(-mouse_input.y * mouse_sensitivity)
	
	# Clamp vertical camera angle so you can't look upside down
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Clear the accumulated input so it doesn't carry over to the next frame
	mouse_input = Vector2.ZERO
