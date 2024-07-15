extends CharacterBody3D


const SPEED = 20.0
const JUMP_VELOCITY = 15

const mouse_sensitivity := 0.002
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshPitch/MeshRoll/MeshInstance3D
@onready var mesh_pitch := $MeshPitch
@onready var mesh_roll := $MeshPitch/MeshRoll

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if not is_on_floor():
		if Input.is_action_just_pressed("roll"):
			for i in range(360/10):
				mesh_roll.rotate_object_local(Vector3.RIGHT, deg_to_rad(10))
				await get_tree().create_timer(0.001).timeout
				
		if Input.is_action_just_pressed("pitch"):
			for i in range(360/10):
				mesh_pitch.rotate_object_local(Vector3.BACK, deg_to_rad(10))
				await get_tree().create_timer(0.001).timeout
			
		if Input.is_action_just_pressed("yaw"):
			for i in range(360/10):
				mesh_pitch.rotate_y(deg_to_rad(10))
				await get_tree().create_timer(0.001).timeout
			
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-50), deg_to_rad(50))
	twist_input = 0.0
	pitch_input = 0.0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			
			pitch_input = - event.relative.y * mouse_sensitivity
