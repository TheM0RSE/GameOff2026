extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Mouse & camera variables
var mouse_sensitivity := 0.2

@export var camera : Camera3D
var cam_rotation := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Lock mouse ingame

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cam_rotation.y -= event.relative.x * mouse_sensitivity
		cam_rotation.x -= event.relative.y * mouse_sensitivity
		
		cam_rotation.x = clamp(cam_rotation.x, -90, 90) # Clamp up and down rotation of camera
		
		rotation_degrees.y = cam_rotation.y # Rotate character left and right
		camera.rotation_degrees.x = cam_rotation.x # Rotate camera up and down
