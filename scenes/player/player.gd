extends CharacterBody3D

class_name Player

var _is_moving: bool = false
var _input_enabled: bool = true
var _is_level_complete_sequence_running: bool = false
const ROTATION_LERP_SPEED := 12.0
const PUSH_MIN_DELAY := 0.2
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

func _physics_process(_delta: float) -> void:
	if not _input_enabled:
		return

	if _is_moving:
		return

	var direction := _get_input_direction()
	if direction == Vector3.ZERO:
		return

	_try_move(direction)

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

func _get_input_direction() -> Vector3:
	var direction := Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		direction = Vector3(0.0, 0.0, 1.0)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector3(0.0, 0.0, -1.0)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector3(1.0, 0.0, 0.0)
	elif Input.is_action_pressed("ui_right"):
		direction = Vector3(-1.0, 0.0, 0.0)

	return direction

func _try_move(direction: Vector3) -> void:
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

	_is_moving = true
	_face_direction(direction)

	%AnimationPlayer.play("attack-kick-left")
	await get_tree().create_timer(PUSH_MIN_DELAY).timeout

	if not box.can_be_pushed(direction):
		_is_moving = false
		%AnimationPlayer.play("idle")
		return

	await box.push(direction)
	_is_moving = false
	%AnimationPlayer.play("idle")

func _move(direction: Vector3) -> void:
	%AnimationPlayer.play("walk")
	_is_moving = true
	var target: Vector3 = global_position + (direction * Global.MOVEMENT_FACTOR)
	var duration: float = Global.MOVEMENT_FACTOR / Global.MOVEMENT_SPEED
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration)
	await tween.finished
	global_position = global_position.snapped(Vector3.ONE * Global.MOVEMENT_FACTOR)
	_is_moving = false
	%AnimationPlayer.play("idle")

func _face_direction(direction: Vector3) -> void:
	_target_mesh_yaw = atan2(direction.x, direction.z)

func on_goal_reached() -> void:
	if _is_level_complete_sequence_running:
		return

	_input_enabled = false
	_is_level_complete_sequence_running = true

	while _is_moving:
		await get_tree().process_frame

	%AnimationPlayer.play("emote-yes")
	await %AnimationPlayer.animation_finished

	var game_controller: MainGameController = Global.get_game_controller()
	if game_controller != null:
		game_controller.load_next_level_if_available()
