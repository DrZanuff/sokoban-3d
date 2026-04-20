extends Node3D

const GAME_SCENE_PATH := "res://scenes/main_game.tscn"

@onready var _play_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/PlayButton"
@onready var _options_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/OptionsButton"
@onready var _quit_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/QuitButton"

var _buttons: Array[Button] = []
var _base_labels: Array[String] = []
var _selected_index: int = 0


func _ready() -> void:
	_buttons = [_play_button, _options_button, _quit_button]
	for button in _buttons:
		_base_labels.push_back(button.text)
		button.focus_mode = Control.FOCUS_NONE

	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_update_selection_visuals()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.keycode == KEY_SPACE:
		_activate_selected_option()


func _move_selection(direction: int) -> void:
	if _buttons.is_empty():
		return

	_selected_index = wrapi(_selected_index + direction, 0, _buttons.size())
	_update_selection_visuals()


func _update_selection_visuals() -> void:
	for i in _buttons.size():
		var button := _buttons[i]
		if i == _selected_index:
			button.text = ">> %s <<" % _base_labels[i]
			button.modulate = Color(1.0, 0.97, 0.6, 1.0)
		else:
			button.text = _base_labels[i]
			button.modulate = Color(1.0, 1.0, 1.0, 0.85)


func _activate_selected_option() -> void:
	match _selected_index:
		0:
			_on_play_pressed()
		1:
			_on_options_pressed()
		2:
			_on_quit_pressed()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_options_pressed() -> void:
	# Placeholder action until options are implemented.
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
