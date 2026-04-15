extends CharacterBody3D

class_name Box

var _is_moving: bool = false

@onready var _raycast_north: RayCast3D = %RayCastNorth
@onready var _raycast_south: RayCast3D = %RayCastSouth
@onready var _raycast_west: RayCast3D = %RayCastWest
@onready var _raycast_east: RayCast3D = %RayCastEast

func _ready() -> void:
	Global.register_box(self)

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

func can_be_pushed(direction: Vector3) -> bool:
	if _is_moving:
		return false

	var raycast: RayCast3D = _get_raycast(direction)
	if raycast == null:
		return false

	raycast.force_raycast_update()
	if raycast.is_colliding():
		return false

	return true

func push(direction: Vector3) -> void:
	if _is_moving:
		return

	_is_moving = true
	var target: Vector3 = global_position + (direction * Global.MOVEMENT_FACTOR)
	var duration: float = Global.MOVEMENT_FACTOR / Global.MOVEMENT_SPEED
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration)
	await tween.finished
	global_position = global_position.snapped(Vector3.ONE * Global.MOVEMENT_FACTOR)
	_is_moving = false
