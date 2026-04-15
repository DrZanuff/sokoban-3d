extends Control

class_name GameUI

func fade_in() -> void:
	%AnimationPlayer.play("fade_in")

func fade_out() -> void:
	%AnimationPlayer.play("fade_out")
