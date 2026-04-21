extends Area3D

class_name Goal

var _is_active: bool = false
var _has_triggered_completion: bool = false

func _ready() -> void:
	Global.register_goal(self)
	body_entered.connect(_on_body_entered)
	_refresh_state()

func _refresh_state() -> void:
	%EnabledMesh.visible = _is_active
	%DisabledMesh.visible = not _is_active
	
func set_state(state: bool) -> void:
	var was_active := _is_active
	_is_active = state
	_refresh_state()
	if state and not was_active:
		AudioManager.play_goal_active()

func get_is_active() -> bool:
	return _is_active

func _on_body_entered(body: Node3D) -> void:
	if _has_triggered_completion:
		return
	if not _is_active:
		return

	var player: Player = body as Player
	if player == null:
		return

	_has_triggered_completion = true
	AudioManager.play_complete()
	player.on_goal_reached()
