extends CharacterBody3D

# Player variables
@export var collision : CollisionShape3D
const STAND_HEIGHT = 2.0
const LOW_HEIGHT = 1.0
var stand_cam_y = 0.0
var stand_col_y = 0.0

# Camera effects
var base_fov = 0
const WALK_FOV_PER_SPEED = 0.5
const FAST_FOV_PER_SPEED = 1.5
const MAX_FOV_BOOST = 100.0

const TILT_ANGLE = 2 # degrees
var camera_fx_strength = 1.0 # 1.0 = full, 0.0 = off

var mouse_turn = 0.0
const MOUSE_TILT = 0.002 # How much tilt per mouse movement
const MAX_MOUSE_TILT = 2.0 # Degrees

var shake = 0.0

var cam_smooth_y = 0.0
const CAM_SMOOTH = 14.0 # Higher = less smoothing
const CAM_MAX_LAG = 0.25

# Move Variables
var speed: float = 0
const WALK_SPEED = 10.0

const HARD_LANDING_SPEED = 12.0

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

# Mantling
@export var chest_ray : RayCast3D
@export var head_ray : RayCast3D
@export var top_ray : RayCast3D
@export var ceiling_ray : RayCast3D

var mantle_cooldown = 0.0
const MANTLE_COOLDOWN_TIME = 0.35
var last_speed = 0

var vault_direction = Vector3.ZERO
var vault_speed = 0.0

const WALL_SPEED_DECAY = 400.0

var is_vaulting = false
var vault_ledge_y = 0.0
const VAULT_LIFT_SPEED = 9.0

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
	cam_smooth_y = camera.global_position.y
	stand_cam_y = camera.position.y
	stand_col_y = collision.position.y
	speed = WALK_SPEED
	base_fov = camera.fov
	
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

func _physics_process(delta: float) -> void:	
	mantle_cooldown -= delta
	
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
	check_mantle(delta)
	dash_and_move(delta)
	update_height(delta)
	
	var h_speed_now = Vector3(velocity.x, 0, velocity.z).length()
	
	if not is_on_wall():
		last_speed = h_speed_now
	else:
		last_speed = move_toward(last_speed, h_speed_now, WALL_SPEED_DECAY * delta)
	
	var was_on_floor = is_on_floor()
	var fall_speed = -velocity.y # How fast we are falling
	move_and_slide()
	update_camera_fx(delta)
	just_landed = is_on_floor() and not was_on_floor
	
	if just_landed and fall_speed > HARD_LANDING_SPEED:
		var impact = (fall_speed - HARD_LANDING_SPEED) * 0.005
		shake = max(shake, clamp(impact, 0.0, 0.08))

# Update player height
func update_height(delta):
	var target_height = STAND_HEIGHT
	
	# Check if the player is sliding or if the player is still under something while in a slide
	if is_sliding or ceiling_ray.is_colliding():
		target_height = LOW_HEIGHT
	
	var drop = STAND_HEIGHT - target_height
	var cam_target = stand_cam_y - drop
		
	collision.shape.height = target_height
	collision.position.y = stand_col_y - drop / 2
	
	var desired_y = global_position.y + cam_target

	# Follow it smoothly
	cam_smooth_y = lerp(cam_smooth_y, desired_y, CAM_SMOOTH * delta)

	# But never fall too far behind (e.g. long falls or fast jumps)
	cam_smooth_y = clamp(cam_smooth_y, desired_y - CAM_MAX_LAG, desired_y + CAM_MAX_LAG)

	# Turn that world height back into the camera's local height
	camera.position.y = cam_smooth_y - global_position.y
	
func mouse_move():
	# Apply rotation on every rendered framed
	rotate_y(-mouse_input.x * mouse_sensitivity)
	camera.rotate_x(-mouse_input.y * mouse_sensitivity)
	
	# Clamp vertical camera angle so you can't look upside down
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	mouse_turn += mouse_input.x
	
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
			camera.fov += 12 * camera_fx_strength
			shake = 0.04
			dash_timer = dash_duration
			charges_refill_currentTime = charges_refill_time
			
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
			
	elif mantle_cooldown > 0:
		horizontal = vault_direction * vault_speed
		
		var feet_y = global_position.y - STAND_HEIGHT / 2
		var remaining = (vault_ledge_y + 0.1) - feet_y
		
		if is_vaulting and remaining > 0:
			velocity.y = clamp(remaining * 15.0, 3.0, VAULT_LIFT_SPEED)
		elif is_vaulting:
			velocity.y = 0.0
			is_vaulting = false
		
	elif is_sliding:
		horizontal = horizontal.move_toward(Vector3.ZERO, SLIDE_FRICTION * delta)
		
		var n := get_floor_normal()
		var downhill := Vector3.DOWN - n * Vector3.DOWN.dot(n)
		
		if n.y > 0.7:
			horizontal += downhill * SLOPE_ACCEL * delta
		
		# Stop conditions
		if horizontal.length() < SLIDE_MIN_SPEED or (not Input.is_action_pressed("Slide") and not ceiling_ray.is_colliding()):
			is_sliding = false
			
	else:
		if not is_on_floor() and direction != Vector3.ZERO and horizontal.length() > speed:
			target = direction * horizontal.length()
		
		# Apply normal movement to the player
		horizontal = horizontal.move_toward(target, rate * delta)
		
		charges_refill_currentTime -= delta
		
		# print(charges_refill_currentTime)
		if charges_refill_currentTime <= 0 and dash_charges < 3:
			charges_refill_currentTime = charges_refill_time
			dash_charges += 1
			print(dash_charges)
			
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	
	if is_sliding and is_on_floor():
		var n := get_floor_normal()
		if n.y > 0.7:
			var follow_y = -(n.x * velocity.x + n.z * velocity.z) / n.y
			velocity.y = min(follow_y, 0.0)

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
		
func check_mantle(delta):
	var input_dir := Input.get_vector("left", "right", "up", "down")
	
	var h_speed = Vector3(velocity.x, 0, velocity.z).length()
	var look = max(1.2, h_speed * 0.15)
	
	chest_ray.target_position.z = -look
	head_ray.target_position.z = -look
	top_ray.position.z = -(look - 0.2)
	
	if not is_on_floor() and mantle_cooldown <= 0 and input_dir.y < 0 and not is_sliding and chest_ray.is_colliding() and not head_ray.is_colliding() and top_ray.is_colliding():
		var ledge_point = top_ray.get_collision_point()
		vault(top_ray.get_collision_point())

# Handle mantling
func vault(ledge_point):
	is_dashing = false
	mantle_cooldown = MANTLE_COOLDOWN_TIME
	
	vault_ledge_y = ledge_point.y
	is_vaulting = true

	vault_direction = -transform.basis.z
	vault_speed = max(last_speed, 4.0)

	# Camera starts a bit lower and glides up = smooth climb feel
	camera.position.y -= 0.4

# Handle camera effects
func update_camera_fx(delta):
	var h_speed = Vector3(velocity.x, 0, velocity.z).length()
	
	var walk_part = min(h_speed, WALK_SPEED)
	var fast_part = max(h_speed - WALK_SPEED, 0)
	
	var boost = walk_part * WALK_FOV_PER_SPEED + fast_part * FAST_FOV_PER_SPEED
	boost = clamp(boost, 0, MAX_FOV_BOOST)
	
	camera.fov = lerp(camera.fov, base_fov + boost, 8 * delta)
	
	# Camera tilt when strafing
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var target_tilt = -input_dir.x * deg_to_rad(TILT_ANGLE) * camera_fx_strength
	
	# Tilt when turning with the mouse (only when moving)
	var move_factor = clamp(h_speed / WALK_SPEED, 0.0, 1.0)
	var turn_tilt = clamp(-mouse_turn * MOUSE_TILT, -deg_to_rad(MAX_MOUSE_TILT), deg_to_rad(MAX_MOUSE_TILT))
	target_tilt += turn_tilt * move_factor * camera_fx_strength
	mouse_turn = 0.0
	
	if is_sliding:
		var side = slide_direction.dot(transform.basis.x)
		target_tilt += -side * deg_to_rad(5)
	
	camera.rotation.z = lerp(camera.rotation.z, target_tilt, 10 * delta)
	
	if is_sliding and is_on_floor():
		shake = max(shake, 0.005)
	
	var s = shake * camera_fx_strength
	camera.h_offset = randf_range(-s, s)
	camera.v_offset = randf_range(-s, s)
	shake = move_toward(shake, 0.0, 0.8 * delta)
