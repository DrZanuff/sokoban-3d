extends Node

class_name CameraController

const CAMERA_FOLLOW_LERP_SPEED := 0.05
const CAMERA_FOLLOW_THRESHOLD := 0.01

var _player: Player
var _camera_xz_offset: Vector2 = Vector2.ZERO
@onready var _camera: Camera3D = %Camera3D

func _ready() -> void:
	_player = get_parent()
	if _player != null:
		var parent_pos := _player.global_position
		var camera_pos := _camera.global_position
		_camera_xz_offset = Vector2(camera_pos.x - parent_pos.x, camera_pos.z - parent_pos.z)

func _process(delta: float) -> void:
	_update_camera_follow(delta)

func _update_camera_follow(delta: float) -> void:
	var camera_parent := _player
	if camera_parent == null:
		return

	var parent_pos := camera_parent.global_position
	var desired_xz := Vector2(parent_pos.x, parent_pos.z) + _camera_xz_offset
	var current_xz := Vector2(_camera.global_position.x, _camera.global_position.z)
	var distance := current_xz.distance_to(desired_xz)
	if distance < CAMERA_FOLLOW_THRESHOLD:
		return

	var t: float = clamp(delta * CAMERA_FOLLOW_LERP_SPEED, 0.0, 1.0)
	var next_xz := current_xz.lerp(desired_xz, t)
	_camera.global_position = Vector3(next_xz.x, _camera.global_position.y, next_xz.y)
