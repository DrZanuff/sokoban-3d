extends Area3D

class_name PressurePlate
var _is_active: bool = false

func _ready() -> void:
	Global.register_pressure_plate(self)
