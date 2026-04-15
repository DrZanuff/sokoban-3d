extends Node3D

class_name  GameLevel

@onready var _player: Player = %Player
@onready var _gridmap: GridMap = %GridMap

var _box_list: Array[Box] = []
var _box_map: Dictionary[NodePath, Box]

var _goal_list: Array[Goal] = []
var _goal_map: Dictionary[NodePath, Goal]

var _plate_list: Array[PressurePlate] = []
var _plate_map: Dictionary[NodePath, PressurePlate]

func add_box(box: Box) -> void:
	var path = box.get_path()
	_box_list.push_back(box)
	_box_map[path] = box

func add_goal(goal: Goal) -> void:
	var path = goal.get_path()
	_goal_list.push_back(goal)
	_goal_map[path] = goal

func add_plate(plate: PressurePlate) -> void:
	var path = plate.get_path()
	_plate_list.push_back(plate)
	_plate_map[path] = plate

func _ready() -> void:
	ready.emit()
