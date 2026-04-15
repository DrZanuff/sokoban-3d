extends Control

class_name GameUI

func fade_in() -> void:
	%AnimationPlayer.play("fade_in")

func fade_out() -> void:
	%AnimationPlayer.play("fade_out")

func _process(_delta):
	%FPSLabel.text = "FPS: %s" % Engine.get_frames_per_second()
