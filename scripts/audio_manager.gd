extends Node

const SETTINGS_PATH := "user://audio_settings.cfg"
const SETTINGS_SECTION := "audio"
const VOLUME_KEY := "master_volume_percent"

const SOUND_MAIN_MUSIC := &"main_music"
const SOUND_STEP := &"step"
const SOUND_BOX_PUSH := &"box_push"
const SOUND_PRESSURE_PLATE := &"pressure_plate"
const SOUND_GOAL_ACTIVE := &"goal_active"
const SOUND_CLICK := &"click"
const SOUND_COMPLETE := &"complete"
const SOUND_RESTART := &"restart"

const MASTER_BUS_NAME := "Master"
const DEFAULT_VOLUME_PERCENT := 50.0

const MUSIC_STREAM: AudioStream = preload("res://assets/sounds/main-music.ogg")
const STEP_STREAM: AudioStream = preload("res://assets/sounds/step.ogg")
const BOX_PUSH_STREAM: AudioStream = preload("res://assets/sounds/box-pushg.ogg")
const PRESSURE_PLATE_STREAM: AudioStream = preload("res://assets/sounds/pressure-plate.ogg")
const GOAL_ACTIVE_STREAM: AudioStream = preload("res://assets/sounds/goal-active.ogg")
const CLICK_STREAM: AudioStream = preload("res://assets/sounds/click.ogg")
const COMPLETE_STREAM: AudioStream = preload("res://assets/sounds/complete.ogg")
const RESTART_STREAM: AudioStream = preload("res://assets/sounds/restart.ogg")

@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _step_player: AudioStreamPlayer = $StepPlayer
@onready var _box_push_player: AudioStreamPlayer = $BoxPushPlayer
@onready var _pressure_plate_player: AudioStreamPlayer = $PressurePlatePlayer
@onready var _goal_active_player: AudioStreamPlayer = $GoalActivePlayer
@onready var _click_player: AudioStreamPlayer = $ClickPlayer
@onready var _complete_player: AudioStreamPlayer = $CompletePlayer
@onready var _restart_player: AudioStreamPlayer = $RestartPlayer

var _sound_players: Dictionary = {}
var _master_bus_index: int = -1


func _ready() -> void:
	_master_bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)
	_sound_players = {
		SOUND_MAIN_MUSIC: _music_player,
		SOUND_STEP: _step_player,
		SOUND_BOX_PUSH: _box_push_player,
		SOUND_PRESSURE_PLATE: _pressure_plate_player,
		SOUND_GOAL_ACTIVE: _goal_active_player,
		SOUND_CLICK: _click_player,
		SOUND_COMPLETE: _complete_player,
		SOUND_RESTART: _restart_player
	}
	_assign_streams()
	_load_volume_settings()
	play_music()


func _assign_streams() -> void:
	_music_player.stream = MUSIC_STREAM
	_step_player.stream = STEP_STREAM
	_box_push_player.stream = BOX_PUSH_STREAM
	_pressure_plate_player.stream = PRESSURE_PLATE_STREAM
	_goal_active_player.stream = GOAL_ACTIVE_STREAM
	_click_player.stream = CLICK_STREAM
	_complete_player.stream = COMPLETE_STREAM
	_restart_player.stream = RESTART_STREAM


func play_music() -> void:
	if _music_player.playing:
		return
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_audio(sound_id: StringName) -> void:
	var player := _sound_players.get(sound_id) as AudioStreamPlayer
	if player == null:
		return
	if sound_id == SOUND_MAIN_MUSIC and player.playing:
		return
	player.play()


func stop_audio(sound_id: StringName) -> void:
	var player := _sound_players.get(sound_id) as AudioStreamPlayer
	if player == null:
		return
	player.stop()


func play_step() -> void:
	play_audio(SOUND_STEP)


func play_box_push() -> void:
	play_audio(SOUND_BOX_PUSH)


func play_pressure_plate() -> void:
	play_audio(SOUND_PRESSURE_PLATE)


func play_goal_active() -> void:
	play_audio(SOUND_GOAL_ACTIVE)


func play_click() -> void:
	play_audio(SOUND_CLICK)


func play_complete() -> void:
	play_audio(SOUND_COMPLETE)


func play_restart() -> void:
	play_audio(SOUND_RESTART)


func increase_volume(step_percent: float = 5.0) -> void:
	set_master_volume_percent(get_master_volume_percent() + step_percent)


func decrease_volume(step_percent: float = 5.0) -> void:
	set_master_volume_percent(get_master_volume_percent() - step_percent)


func set_master_volume_percent(percent: float) -> void:
	var clamped_percent := clampf(percent, 0.0, 100.0)
	var db := linear_to_db(clamped_percent / 100.0) if clamped_percent > 0.0 else -80.0
	if _master_bus_index >= 0:
		AudioServer.set_bus_volume_db(_master_bus_index, db)
	_save_volume_settings(clamped_percent)


func get_master_volume_percent() -> float:
	if _master_bus_index < 0:
		return DEFAULT_VOLUME_PERCENT
	var db := AudioServer.get_bus_volume_db(_master_bus_index)
	if db <= -80.0:
		return 0.0
	return clampf(db_to_linear(db) * 100.0, 0.0, 100.0)


func _load_volume_settings() -> void:
	var settings := ConfigFile.new()
	var error := settings.load(SETTINGS_PATH)
	if error != OK:
		set_master_volume_percent(DEFAULT_VOLUME_PERCENT)
		return

	var saved_volume := float(settings.get_value(SETTINGS_SECTION, VOLUME_KEY, DEFAULT_VOLUME_PERCENT))
	set_master_volume_percent(saved_volume)


func _save_volume_settings(percent: float) -> void:
	var settings := ConfigFile.new()
	settings.set_value(SETTINGS_SECTION, VOLUME_KEY, percent)
	settings.save(SETTINGS_PATH)
