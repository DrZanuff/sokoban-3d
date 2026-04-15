extends Node3D

class_name MainGameController

@export var _levels: Array[PackedScene]
@export var _current_level: int = 0

@onready var _game_ui: GameUI = %GameUI
@onready var _level_container: Node3D = %LevelContainer


func _ready() -> void:
	Global.register_game_controller(self)
	_clear_level()
	load_level(_current_level)

func load_level(level: int) -> void:
	if level < 0 or level >= _levels.size():
		printerr("Level index out of bounds: %d (available: %d)" % [level, _levels.size()])
		return

	var level_scene: PackedScene = _levels[level]
	if level_scene == null:
		printerr("Level scene at index %d is null." % level)
		return

	var instance: Node = level_scene.instantiate()
	if instance == null:
		printerr("Failed to instantiate level at index %d." % level)
		return

	var game_level: GameLevel = instance as GameLevel
	if game_level == null:
		printerr("Level root must be GameLevel. Got: %s" % instance.get_class())
		instance.free()
		return

	_level_container.add_child(game_level)
	await _await_level_loading(game_level)
	_game_ui.fade_out()

func _await_level_loading(game_level: GameLevel) -> void:
	while not game_level.is_node_ready():
		await get_tree().create_timer(0.5).timeout

func get_game_ui() -> GameUI:
	return _game_ui

func _clear_level() -> void:
	for child in _level_container.get_children():
		child.queue_free()
