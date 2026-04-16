extends Area3D

class_name Goal

var _is_active: bool = false

func _ready() -> void:
	Global.register_goal(self)
	_refresh_state()

func _refresh_state() -> void:
	%EnabledMesh.visible = _is_active
	%DisabledMesh.visible = not _is_active
	
func set_state(state: bool) -> void:
	_is_active = state
	_refresh_state()

func get_is_active() -> bool:
	return _is_active
