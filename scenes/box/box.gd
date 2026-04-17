extends CharacterBody3D

class_name Box

var _is_moving: bool = false
var _pressure_plate_contacts: int = 0
var _box_material: StandardMaterial3D

const DEFAULT_ALBEDO: Color = Color("e6e6e6")
const ACTIVE_PLATE_ALBEDO: Color = Color("e6f34eff")

@onready var _raycast_north: RayCast3D = %RayCastNorth
@onready var _raycast_south: RayCast3D = %RayCastSouth
@onready var _raycast_west: RayCast3D = %RayCastWest
@onready var _raycast_east: RayCast3D = %RayCastEast

@onready var _mesh_3d: MeshInstance3D = %MeshInstance3D

func _ready() -> void:
	_setup_unique_material()
	Global.register_box(self)

func _setup_unique_material() -> void:
	var base_material: Material = _mesh_3d.get_active_material(0)
	if not (base_material is StandardMaterial3D):
		return

	_box_material = (base_material as StandardMaterial3D).duplicate(true)
	_mesh_3d.set_surface_override_material(0, _box_material)
	_update_albedo()

func on_pressure_plate_entered() -> void:
	_pressure_plate_contacts += 1
	_update_albedo()

func on_pressure_plate_exited() -> void:
	_pressure_plate_contacts = maxi(0, _pressure_plate_contacts - 1)
	_update_albedo()

func _update_albedo() -> void:
	if _box_material == null:
		return
	_box_material.albedo_color = ACTIVE_PLATE_ALBEDO if _pressure_plate_contacts > 0 else DEFAULT_ALBEDO

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
