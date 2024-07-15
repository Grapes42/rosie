extends CharacterBody3D

#
# Movement Constants
#

# Basic movement
const WALKING_SPEED = 15.0
const RUN_SPEED = 30.0

const JUMP_VELOCITY = 20
const SUPER_JUMP_VELOCITY = 40

const LERP_RATE = 10.0

# Rolling
const ROLL_MULT = 3
const ROLL_PERIOD = 0.2

const ROLL_STEP = deg_to_rad(20)
const ROLL_STEPS = deg_to_rad(360)/ROLL_STEP
const ROLL_DEL = ROLL_PERIOD/ROLL_STEPS

#
# Movement variables
#
var input_dir
var current_speed = WALKING_SPEED

var direction = Vector3.ZERO
var roll_direction = Vector3.ZERO

var rolling = false

#
# Camera
#

# Camera constants
const MOUSE_SENS := 0.002

# Camera variables
var yaw_input := 0.0
var pitch_input := 0.0

#
# Scene references
#

# Camera
@onready var camera_yaw := $CameraYaw
@onready var camera_pitch := $CameraYaw/CameraPitch

# Mesh
@onready var mesh_pitch := $MeshPitch
@onready var mesh_roll := $MeshPitch/MeshRoll
@onready var mesh_yaw := $MeshPitch/MeshRoll/MeshYaw

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#
# Ready
#
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
#
# Main process
#
func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	#
	# Jumping
	#
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("super_jump") and is_on_floor():
		velocity.y = SUPER_JUMP_VELOCITY
		

	#
	# Spin actions
	#
	
	# Yaw spin, slows falling
	if not is_on_floor():				
		if Input.is_action_just_pressed("yaw"):
			velocity.y = -.01
			yaw_animation()
	
	# Pitch spin, will be an attack/deflect
	if Input.is_action_just_pressed("pitch"):
			pitch_animation()
			
	# Roll spin, side dodge
	if Input.is_action_just_pressed("action"):
			if is_on_floor() and (not rolling):
				var timer := Timer.new()
				add_child(timer)
				timer.wait_time = ROLL_PERIOD
				timer.one_shot = true
				timer.start()
				timer.connect("timeout",_on_timer_timeout)
				rolling = true
			roll_animation()
			
	#
	# Other controls
	#
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.is_action_just_pressed("switch_camera"):
		camera_yaw.rotate_y(deg_to_rad(180))
		
	
	
	#
	# Camera movement
	#
	rotate_y(yaw_input)
	camera_pitch.rotate_x(pitch_input)
	camera_pitch.rotation.x = clamp(camera_pitch.rotation.x, deg_to_rad(-50), deg_to_rad(50))
	yaw_input = 0.0
	pitch_input = 0.0

	#
	# Speed control
	#
	if Input.is_action_pressed("sprint"):
		current_speed = RUN_SPEED
	else:
		current_speed = WALKING_SPEED
		

	#
	# Basic movement
	#
	
	# Basic input vector
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back") # Input
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*LERP_RATE) #Input to vector along basis
	
	# Input vector for roll
	roll_direction = lerp(roll_direction,(transform.basis * Vector3(input_dir.x, 0, 0)).normalized(),delta*LERP_RATE)
	
	# If direction vector isn't 0
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Add velocity for roll dodge
		if rolling:
			velocity.x += roll_direction.x * ROLL_MULT * current_speed
			velocity.z += roll_direction.z * ROLL_MULT * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	
#
# Functions
#

# Camera input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			yaw_input = - event.relative.x * MOUSE_SENS
			
			pitch_input = - event.relative.y * MOUSE_SENS

# Timer for rolling movement
func _on_timer_timeout() -> void:
	rolling = false
	#queue_free()
	
# Plays roll rotation animation
func roll_animation():
	# If moving left, rotate counter-clockwise
	if input_dir.x < 0:
		for i in range(ROLL_STEPS):
			mesh_roll.rotate_object_local(Vector3.BACK, ROLL_STEP)
			await get_tree().create_timer(ROLL_DEL).timeout
	# If moving right, rotate clockwise
	if input_dir.x > 0:
		for i in range(ROLL_STEPS):
			mesh_roll.rotate_object_local(Vector3.FORWARD, ROLL_STEP)
			await get_tree().create_timer(ROLL_DEL).timeout
		
# Plays yaw rotation animation	
func yaw_animation():
	for i in range(ROLL_STEPS):
		mesh_yaw.rotate_y(ROLL_STEP)
		await get_tree().create_timer(ROLL_DEL).timeout

# Plays pitch rotation animation	
func pitch_animation():
	for i in range(ROLL_STEPS):
		mesh_roll.rotate_object_local(Vector3.RIGHT, ROLL_STEP)
		await get_tree().create_timer(ROLL_DEL).timeout
