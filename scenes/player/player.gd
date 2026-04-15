extends CharacterBody3D

class_name Player

var _is_moving: bool = false
const ROTATION_LERP_SPEED := 12.0
var _target_mesh_yaw: float = 0.0

@onready var _raycast_north: RayCast3D = %RayCastNorth
@onready var _raycast_south: RayCast3D = %RayCastSouth
@onready var _raycast_west: RayCast3D = %RayCastWest
@onready var _raycast_east: RayCast3D = %RayCastEast

@onready var _player_mesh: Marker3D = %Mesh

func _ready() -> void:
	_target_mesh_yaw = _player_mesh.rotation.y

func _process(delta: float) -> void:
	_player_mesh.rotation.y = lerp_angle(
		_player_mesh.rotation.y,
		_target_mesh_yaw,
		delta * ROTATION_LERP_SPEED
	)

func _get_raycast(direction: Vector3) -> RayCast3D:
	if direction == Vector3(0.0, 0.0, 1.0):
		return _raycast_north
	if direction == Vector3(0.0, 0.0, -1.0):
		return _raycast_south
	if direction == Vector3(1.0, 0.0, 0.0):
		return _raycast_west
	if direction == Vector3(-1.0, 0.0, 0.0):
		return _raycast_east
	return null

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if _is_moving:
		return

	var direction := Vector3.ZERO
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector3(0.0, 0.0, 1.0)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector3(0.0, 0.0, -1.0)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector3(1.0, 0.0, 0.0)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector3(-1.0, 0.0, 0.0)

	if direction == Vector3.ZERO:
		return

	var raycast: RayCast3D = _get_raycast(direction)
	if raycast == null:
		return

	raycast.force_raycast_update()
	if not raycast.is_colliding():
		_face_direction(direction)
		_move(direction)
		return

	var collider := raycast.get_collider()
	var box: Box = collider as Box
	if box == null:
		return

	if not box.can_be_pushed(direction):
		return

	box.push(direction)
	_face_direction(direction)
	_move(direction)

func _move(direction: Vector3) -> void:
	_is_moving = true
	var target: Vector3 = global_position + (direction * Global.MOVEMENT_FACTOR)
	var duration: float = Global.MOVEMENT_FACTOR / Global.MOVEMENT_SPEED
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration)
	await tween.finished
	global_position = global_position.snapped(Vector3.ONE * Global.MOVEMENT_FACTOR)
	_is_moving = false

func _face_direction(direction: Vector3) -> void:
	_target_mesh_yaw = atan2(direction.x, direction.z)
