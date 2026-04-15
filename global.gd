extends Node

const MOVEMENT_FACTOR = 1.0 # in meters

var _game_controller: MainGameController

func register_game_controller(game_controller: MainGameController) -> void:
	_game_controller = game_controller

func get_game_controller() -> MainGameController:
	return _game_controller

func register_goal(goal: Goal) -> void:
	_game_controller
	pass

func register_pressure_plate(plate: PressurePlate) -> void:
	pass

func register_box(box: Box) -> void:
	pass
