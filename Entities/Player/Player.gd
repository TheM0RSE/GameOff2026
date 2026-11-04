extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Mouse & camera variables
var mouse_sensitivity := 0.005
var mouse_input = Vector2.ZERO

@export var camera : Camera3D
var cam_rotation := Vector2.ZERO

@export var animation_player : AnimationPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Lock mouse ingame
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Collect mouse input data
		mouse_input += event.relative
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		animation_player.stop()
		animation_player.play("Glock_Shoot")
	
	# Apply rotation on every rendered frame
	rotate_y(-mouse_input.x * mouse_sensitivity)
	camera.rotate_x(-mouse_input.y * mouse_sensitivity)
	
	# Clamp vertical camera angle so you can't look upside down
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Clear the accumulated input so it doesn't carry over to the next frame
	mouse_input = Vector2.ZERO

func _physics_process(delta: float) -> void:	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction and handle movement
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
