extends Node3D

const GAME_SCENE_PATH := "res://scenes/main_game.tscn"

@onready var _play_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/PlayButton"
@onready var _options_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/OptionsButton"
@onready var _quit_button: Button = $"Win/WinUI/MarginContainer/VBoxContainer/QuitButton"


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_options_pressed() -> void:
	# Placeholder action until options are implemented.
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
