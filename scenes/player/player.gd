extends CharacterBody3D

class_name Player

var _is_moving: bool = false

@onready var _raycast_north: RayCast3D = %RayCastNorth
@onready var _raycast_south: RayCast3D = %RayCastSouth
@onready var _raycast_west: RayCast3D = %RayCastWest
@onready var _raycast_east: RayCast3D = %RayCastEast

@onready var _player_mesh: Marker3D = %Mesh


