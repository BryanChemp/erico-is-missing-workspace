extends CharacterBody3D

class_name Player

@onready var head = $Head
@onready var camera = $Head/Camera

const SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

var mouse_captured = true

var target_rotation_x = 0.0
var target_rotation_y = 0.0

const CAMERA_SMOOTH = 8.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	handle_mouse_toggle(event)
	handle_camera_input(event)

func handle_camera_input(event):
	if not mouse_captured:
		return

	if event is InputEventMouseMotion:
		target_rotation_x -= event.relative.y * MOUSE_SENSITIVITY
		target_rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		target_rotation_x = clamp(target_rotation_x, deg_to_rad(-60), deg_to_rad(60))

func _process(delta):
	head.rotation.x = target_rotation_x
	rotation.y = target_rotation_y

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement()
	move_and_slide()

func handle_movement():
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if input_dir != Vector2.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_mouse_toggle(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_captured = !mouse_captured
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
		)

func handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
