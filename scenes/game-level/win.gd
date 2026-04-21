extends GameLevel

const MENU_SCENE_PATH := "res://menu.tscn"

@onready var _play_again_button: Button = $"WinUI/MarginContainer/VBoxContainer/Button"

var _is_returning_to_menu: bool = false


func _ready() -> void:
	super._ready()
	_play_again_button.pressed.connect(AudioManager.play_click)
	_play_again_button.pressed.connect(_return_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if _is_returning_to_menu:
		return

	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		AudioManager.play_click()
		return

	if event is InputEventKey and event.keycode == KEY_SPACE:
		AudioManager.play_click()
		_return_to_menu() 


func _return_to_menu() -> void:
	if _is_returning_to_menu:
		return

	_is_returning_to_menu = true
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
