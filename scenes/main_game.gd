extends Node3D

class_name MainGameController

@export var _levels: Array[PackedScene]
@export var _current_level: int = 0

@onready var _game_ui: GameUI = %GameUI
@onready var _level_container: Node3D = %LevelContainer
var _is_loading_level: bool = false
var _is_level_transition_locked: bool = false


func _ready() -> void:
	Global.register_game_controller(self)
	_clear_level()
	load_level(_current_level)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if _is_level_transition_locked:
		return
	if Input.is_action_pressed("ui_accept"):
		restart_current_level()

func load_level(level: int) -> void:
	if _is_loading_level:
		return
	_is_level_transition_locked = false
	_is_loading_level = true

	if level < 0 or level >= _levels.size():
		printerr("Level index out of bounds: %d (available: %d)" % [level, _levels.size()])
		_is_loading_level = false
		return

	var level_scene: PackedScene = _levels[level]
	if level_scene == null:
		printerr("Level scene at index %d is null." % level)
		_is_loading_level = false
		return

	var instance: Node = level_scene.instantiate()
	if instance == null:
		printerr("Failed to instantiate level at index %d." % level)
		_is_loading_level = false
		return

	var game_level: GameLevel = instance as GameLevel
	if game_level == null:
		printerr("Level root must be GameLevel. Got: %s" % instance.get_class())
		instance.free()
		_is_loading_level = false
		return

	_current_level = level
	_game_ui.fade_in()
	_clear_level()
	Global.set_current_level(game_level)
	_level_container.add_child(game_level)
	await _await_level_loading(game_level)
	_game_ui.fade_out()
	_is_loading_level = false

func _await_level_loading(game_level: GameLevel) -> void:
	while not game_level.is_node_ready():
		await get_tree().create_timer(0.5).timeout

func get_game_ui() -> GameUI:
	return _game_ui

func restart_current_level() -> void:
	load_level(_current_level)

func load_next_level_if_available() -> void:
	if _is_loading_level:
		return

	_is_level_transition_locked = true
	var next_level: int = _current_level + 1
	if next_level >= _levels.size():
		_is_level_transition_locked = false
		return

	load_level(next_level)

func _clear_level() -> void:
	for child in _level_container.get_children():
		child.queue_free()
