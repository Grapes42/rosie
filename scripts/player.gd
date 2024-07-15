extends CharacterBody3D

var input_dir

const WALKING_SPEED = 15.0
const RUN_SPEED = 30.0

const ROLL_MULT = 3
const ROLL_PERIOD = 0.2

const ROLL_STEP = deg_to_rad(20)
const ROLL_STEPS = deg_to_rad(360)/ROLL_STEP
const ROLL_DEL = ROLL_PERIOD/ROLL_STEPS

var current_speed = WALKING_SPEED


const JUMP_VELOCITY = 20
const SUPER_JUMP_VELOCITY = 40

var lerp_speed = 10.0

var direction = Vector3.ZERO
var roll_direction = Vector3.ZERO

const mouse_sensitivity := 0.002
var twist_input := 0.0
var pitch_input := 0.0

var rolling = false


@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshPitch/MeshRoll/RosieMesh
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
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("super_jump") and is_on_floor():
		velocity.y = SUPER_JUMP_VELOCITY
	
	if Input.is_action_pressed("sprint"):
		current_speed = RUN_SPEED
	else:
		current_speed = WALKING_SPEED
	# Tricks
	
	
	if not is_on_floor():				
		if Input.is_action_just_pressed("pitch"):
			for i in range(360/10):
				mesh_pitch.rotate_object_local(Vector3.RIGHT, deg_to_rad(10))
				await get_tree().create_timer(0.001).timeout
			
		if Input.is_action_just_pressed("yaw"):
			for i in range(360/10):
				mesh_pitch.rotate_y(deg_to_rad(10))
				await get_tree().create_timer(0.001).timeout
			
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.is_action_just_pressed("switch_camera"):
		twist_pivot.rotate_y(deg_to_rad(180))
		
	rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-50), deg_to_rad(50))
	twist_input = 0.0
	pitch_input = 0.0

		
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	roll_direction = lerp(roll_direction,(transform.basis * Vector3(input_dir.x, 0, 0)).normalized(),delta*lerp_speed)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if rolling:
			velocity.x += roll_direction.x * ROLL_MULT * current_speed
			velocity.z += roll_direction.z * ROLL_MULT * current_speed
		
		if Input.is_action_just_pressed("roll"):
			if is_on_floor() and (not rolling):
				var timer := Timer.new()
				add_child(timer)
				timer.wait_time = ROLL_PERIOD
				timer.one_shot = true
				timer.start()
				timer.connect("timeout",_on_timer_timeout)
				rolling = true
			roll_animation()
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			
			pitch_input = - event.relative.y * mouse_sensitivity

func _on_timer_timeout() -> void:
	rolling = false
	#queue_free()
	
func roll_animation():
	if input_dir.x < 0:
		for i in range(ROLL_STEPS):
			mesh_roll.rotate_object_local(Vector3.BACK, ROLL_STEP)
			await get_tree().create_timer(ROLL_DEL).timeout
	if input_dir.x > 0:
		for i in range(ROLL_STEPS):
			mesh_roll.rotate_object_local(Vector3.FORWARD, ROLL_STEP)
			await get_tree().create_timer(ROLL_DEL).timeout
