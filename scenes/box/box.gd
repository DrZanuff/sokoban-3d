extends CharacterBody3D

class_name Box

var _is_moving: bool = false

@onready var _raycast_north: RayCast3D = %RayCastNorth
@onready var _raycast_south: RayCast3D = %RayCastSouth
@onready var _raycast_west: RayCast3D = %RayCastWest
@onready var _raycast_east: RayCast3D = %RayCastEast

func _ready() -> void:
	Global.register_box(self)
