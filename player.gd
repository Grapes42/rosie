extends RigidBody3D

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshPitch/MeshRoll/MeshInstance3D
@onready var mesh_pitch := $MeshPitch
@onready var mesh_roll := $MeshPitch/MeshRoll

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	apply_central_force(twist_pivot.basis * input * 3000 * delta)
		
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
		
	if Input.is_action_just_pressed("jump"):
		apply_central_force(Vector3.UP * 1200)
		
	if Input.is_action_just_pressed("switch_camera"):
		twist_pivot.rotate_y(deg_to_rad(180))

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	twist_pivot.rotate_y(twist_input)
	mesh_pitch.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-50), deg_to_rad(50))
	twist_input = 0.0
	pitch_input = 0.0
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			
			pitch_input = - event.relative.y * mouse_sensitivity
