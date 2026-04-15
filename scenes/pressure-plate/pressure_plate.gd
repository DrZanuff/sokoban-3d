extends Area3D

class_name PressurePlate

func _ready() -> void:
	Global.register_pressure_plate(self)
