extends KinematicBody

onready var at = $AnimationTree
onready var sm = at.get("parameters/playback")

export(float) var ROOT_MOTION_SCALE = 1.0
export(float) var HEADING_CONTROL = 0.1
export(float) var HEADING_CONTROL_CROUCH = 0.08
export(float) var HEADING_CONTROL_ROLL = 0.03

var GRAVITY = 9.81
export(float) var MASS = 1.0

var velocity = Vector3()			# Player velocity
var cn								# Current state

static func normalize_angle(x):
	# Normalize an angle
    return fposmod(x + PI, 2.0 * PI) - PI


static func xz_angle(v):
	# Find XZ plane angle of a vector
	if v.length() == 0.0:
		return 0.0
	return atan2(v.x, v.z)


func _process(delta):

	# Get player's cardinal directions
	var FORWARD = get_global_transform().basis.z
	var RIGHT = -get_global_transform().basis.x
	var UP = get_global_transform().basis.y

	# Get input
	var in_vec = Vector3(
		Input.get_action_strength("Up") - Input.get_action_strength("Down"),
		0,
		Input.get_action_strength("Right") - Input.get_action_strength("Left")
	)
	if in_vec.length() > 1.0: in_vec = in_vec.normalized()
	var jump = Input.is_action_just_pressed("Jump")
	var roll = Input.is_action_just_pressed("Roll")
	var toggle_crouch = Input.is_action_just_pressed("Toggle Crouch")
	var escape = Input.is_action_pressed("Escape")

	if escape:
		get_tree().quit()

	# if !is_on_floor():
	# 	sm.travel("Fall")
	# else:
	# 	sm.travel("Standing Loco")
	
	# Transition state machine based on input
	cn = sm.get_current_node()

	if cn == "Crouching Loco":
		# Go to standing
		if toggle_crouch: sm.travel("Standing Loco")

		# Can roll from crouching
		if roll: sm.travel("Roll")
	else:
		# Go to crouch
		if toggle_crouch: sm.travel("Crouching Loco")
		
		# Can roll or back-step from standing
		if roll:
			if in_vec.length() > 0.0:
				sm.travel("Roll")
			else:
				sm.travel("Back Step")
		
		# Can jump from standing
		if jump:
			sm.travel("Jump")
	
	var heading_control = 0.0
	if cn == "Standing Loco": heading_control = HEADING_CONTROL
	elif cn == "Crouching Loco":  heading_control = HEADING_CONTROL_CROUCH
	elif cn == "Roll": heading_control = HEADING_CONTROL_ROLL

	# Apply heading control
	if in_vec.length() > 0.0:
		rotate_object_local(
			Vector3(0, 1, 0),
			heading_control * normalize_angle(
				xz_angle(in_vec) -
				xz_angle(FORWARD)
			)
		)
	
	# Set walk/run animation blend
	at.set(
		"parameters/Standing Loco/Forward/blend_amount",
		in_vec.length() * 2.0 - 1.0
	)
	# Set sneak animation blend
	at.set(
		"parameters/Crouching Loco/Forward/blend_amount",
		in_vec.length()
	)
	
	# Set root motion velocity
	var rm_dx = at.get_root_motion_transform().origin * ROOT_MOTION_SCALE
	rm_dx = FORWARD * rm_dx.z + -RIGHT * rm_dx.x + UP * rm_dx.y
	velocity = rm_dx / delta


func _physics_process(delta):

	if cn != "Jump":
		# Apply gravity
		velocity += Vector3(0, -GRAVITY * MASS, 0)

	# Move
	#translation += velocity * delta

	# Move and slide
	velocity = move_and_slide(
		velocity,					# Input velocity
		Vector3(0, 1.0, 0.0),   	# Floor normal
		true						# Stop on slope
	)

	# Move and collide
	# var collision = move_and_collide(velocity * delta)
	# if collision:
	# 	velocity = velocity.slide(collision.normal)
	