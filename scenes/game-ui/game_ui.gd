extends Control

class_name GameUI
var _restart_label_tween: Tween

func _ready() -> void:
	%RestartLabel.hide()
	%RestartLabel.modulate.a = 0.0

func fade_in() -> void:
	%AnimationPlayer.play("fade_in")
	_fade_restart_label(0.0, false)

func fade_out() -> void:
	%AnimationPlayer.play("fade_out")
	%RestartLabel.show()
	_fade_restart_label(1.0, true)

func _fade_restart_label(target_alpha: float, keep_visible: bool) -> void:
	if _restart_label_tween != null and _restart_label_tween.is_valid():
		_restart_label_tween.kill()

	_restart_label_tween = create_tween()
	_restart_label_tween.tween_property(%RestartLabel, "modulate:a", target_alpha, 0.25)
	await _restart_label_tween.finished
	if not keep_visible:
		%RestartLabel.hide()

func _process(_delta):
	%FPSLabel.text = "FPS: %s" % Engine.get_frames_per_second()
