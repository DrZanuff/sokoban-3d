extends Node3D

const GAME_SCENE_PATH := "res://scenes/main_game.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "options"
const FULLSCREEN_KEY := "fullscreen"

@onready var _play_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/PlayButton"
@onready var _options_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/OptionsButton"
@onready var _quit_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/QuitButton"
@onready var _main_menu_root: MarginContainer = $"Win/WinUI/MarginContainer"
@onready var _options_panel: PanelContainer = $"Win/WinUI/OptionsPanel"
@onready var _fullscreen_button: Button = $"Win/WinUI/OptionsPanel/MarginContainer/VBoxContainer/FullscreenButton"
@onready var _volume_slider: HSlider = $"Win/WinUI/OptionsPanel/MarginContainer/VBoxContainer/VolumeSlider"
@onready var _back_button: Button = $"Win/WinUI/OptionsPanel/MarginContainer/VBoxContainer/BackButton"

var _buttons: Array[Button] = []
var _base_labels: Array[String] = []
var _selected_index: int = 0
var _options_controls: Array[Control] = []
var _options_base_labels: Array[String] = []
var _selected_options_index: int = 0

enum MenuState {
	MAIN,
	OPTIONS
}

var _menu_state: MenuState = MenuState.MAIN


func _ready() -> void:
	_buttons = [_play_button, _options_button, _quit_button]
	for button in _buttons:
		_base_labels.push_back(button.text)
		button.focus_mode = Control.FOCUS_NONE

	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_play_button.pressed.connect(AudioManager.play_click)
	_options_button.pressed.connect(AudioManager.play_click)
	_quit_button.pressed.connect(AudioManager.play_click)
	_fullscreen_button.pressed.connect(_toggle_fullscreen)
	_back_button.pressed.connect(_close_options)
	_fullscreen_button.pressed.connect(AudioManager.play_click)
	_back_button.pressed.connect(AudioManager.play_click)
	_volume_slider.value_changed.connect(_on_volume_slider_changed)

	_options_controls = [_fullscreen_button, _volume_slider, _back_button]
	_options_base_labels = [
		"Fullscreen: ",
		"Music Volume",
		"Back to Menu"
	]

	_load_settings()
	_volume_slider.value = AudioManager.get_master_volume_percent()
	_apply_options_visibility()
	_update_fullscreen_label()
	_update_selection_visuals()
	_update_options_selection_visuals()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("ui_up"):
		AudioManager.play_click()
		if _menu_state == MenuState.MAIN:
			_move_selection(-1)
		else:
			_move_options_selection(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		AudioManager.play_click()
		if _menu_state == MenuState.MAIN:
			_move_selection(1)
		else:
			_move_options_selection(1)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.keycode == KEY_SPACE:
		AudioManager.play_click()
		if _menu_state == MenuState.MAIN:
			_activate_selected_option()
		else:
			_activate_selected_options_option()
		return

	if _menu_state == MenuState.OPTIONS and event.is_action_pressed("ui_left"):
		AudioManager.play_click()
		_change_volume(-5.0)
		get_viewport().set_input_as_handled()
		return

	if _menu_state == MenuState.OPTIONS and event.is_action_pressed("ui_right"):
		AudioManager.play_click()
		_change_volume(5.0)
		get_viewport().set_input_as_handled()


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


func _move_options_selection(direction: int) -> void:
	if _options_controls.is_empty():
		return

	_selected_options_index = wrapi(_selected_options_index + direction, 0, _options_controls.size())
	_update_options_selection_visuals()


func _update_options_selection_visuals() -> void:
	for i in _options_controls.size():
		var control := _options_controls[i]
		var selected := i == _selected_options_index
		var target_alpha := 1.0 if selected else 0.85
		control.modulate = Color(1.0, 1.0, 1.0, target_alpha)

		if control == _fullscreen_button:
			var base_text := "%s%s" % [_options_base_labels[0], _fullscreen_status_text()]
			_fullscreen_button.text = ">> %s <<" % base_text if selected else base_text
		elif control == _back_button:
			var back_text := _options_base_labels[2]
			_back_button.text = ">> %s <<" % back_text if selected else back_text


func _activate_selected_option() -> void:
	match _selected_index:
		0:
			_on_play_pressed()
		1:
			_on_options_pressed()
		2:
			_on_quit_pressed()


func _activate_selected_options_option() -> void:
	match _selected_options_index:
		0:
			_toggle_fullscreen()
		1:
			_change_volume(10.0)
		2:
			_close_options()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_options_pressed() -> void:
	_menu_state = MenuState.OPTIONS
	_apply_options_visibility()
	_update_options_selection_visuals()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _close_options() -> void:
	_menu_state = MenuState.MAIN
	_apply_options_visibility()
	_update_selection_visuals()


func _apply_options_visibility() -> void:
	_main_menu_root.visible = _menu_state == MenuState.MAIN
	_options_panel.visible = _menu_state == MenuState.OPTIONS


func _toggle_fullscreen() -> void:
	var is_fullscreen := _is_fullscreen()
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	_update_fullscreen_label()
	_save_settings()


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _fullscreen_status_text() -> String:
	return "On" if _is_fullscreen() else "Off"


func _update_fullscreen_label() -> void:
	var text := "%s%s" % [_options_base_labels[0], _fullscreen_status_text()]
	_fullscreen_button.text = text
	_update_options_selection_visuals()


func _change_volume(delta: float) -> void:
	if _selected_options_index != 1:
		return

	_volume_slider.value = clampf(_volume_slider.value + delta, _volume_slider.min_value, _volume_slider.max_value)


func _on_volume_slider_changed(_value: float) -> void:
	AudioManager.set_master_volume_percent(_volume_slider.value)
	_save_settings()


func _load_settings() -> void:
	var settings := ConfigFile.new()
	var error := settings.load(SETTINGS_PATH)
	if error != OK:
		return

	if settings.has_section_key(SETTINGS_SECTION, FULLSCREEN_KEY):
		var use_fullscreen := bool(settings.get_value(SETTINGS_SECTION, FULLSCREEN_KEY, false))
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if use_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		)


func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value(SETTINGS_SECTION, FULLSCREEN_KEY, _is_fullscreen())
	settings.save(SETTINGS_PATH)
