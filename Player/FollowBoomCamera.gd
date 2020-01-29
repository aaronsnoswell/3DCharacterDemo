tool
extends Spatial
class_name FollowBoomCamera

export(NodePath) var target_path
onready var target = get_node(target_path)
onready var offset = translation - target.translation
export(float) var follow_speed = 7.0

export(float) var boom_length = 10.0
export(float) var angle = 45.0

onready var camera = $Camera

func _ready():
	pass

func _process(delta):
	# Set camera orientation
	rotation_degrees.z = -angle
	camera.translation.x = -boom_length

	# Follow the target
	var pos_err = target.translation + offset - translation
	translation += pos_err * follow_speed * delta
