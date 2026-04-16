extends Node

const MOVEMENT_FACTOR = 1.0 # in meters
const MOVEMENT_SPEED = 5.0

var _game_controller: MainGameController
var _current_level: GameLevel

func register_game_controller(game_controller: MainGameController) -> void:
	_game_controller = game_controller

func get_game_controller() -> MainGameController:
	return _game_controller

func set_current_level(level: GameLevel) -> void:
	_current_level = level

func get_current_level() -> GameLevel:
	return _current_level

func register_goal(goal: Goal) -> void:
	if _current_level == null:
		return
	_current_level.add_goal(goal)

func register_pressure_plate(plate: PressurePlate) -> void:
	if _current_level == null:
		return
	_current_level.add_plate(plate)

func register_box(box: Box) -> void:
	if _current_level == null:
		return
	_current_level.add_box(box)
