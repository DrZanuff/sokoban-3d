extends Area3D

class_name PressurePlate
var _is_active: bool = false

func _ready() -> void:
	Global.register_pressure_plate(self)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func get_is_active() -> bool:
	return _is_active

func _on_body_entered(body: Node3D) -> void:
	if not (body is Box):
		return

	var box: Box = body as Box
	box.on_pressure_plate_entered()
	_is_active = true
	AudioManager.play_pressure_plate()
	_notify_level()

func _on_body_exited(body: Node3D) -> void:
	if not (body is Box):
		return

	var box: Box = body as Box
	box.on_pressure_plate_exited()
	_is_active = false
	_notify_level()

func _notify_level() -> void:
	var level: GameLevel = Global.get_current_level()
	if level == null:
		return
	level.check_completion()
