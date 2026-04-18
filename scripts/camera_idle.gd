extends Camera3D

class_name CameraIdle

## Idle sway around the rotation set in the editor (or at spawn). Motion is continuous and
## stays within max deviation, with occasional stronger easing back toward the base aim.

@export_group("Sway")
## If true, euler Z (roll) stays fixed at the base rotation; only X/Y sway applies.
@export var lock_rotation_z: bool = false
## Peak deviation from the original euler angles (degrees), per axis.
@export var max_deviation_deg: Vector3 = Vector3(2.2, 1.8, 1.2)
## Angular frequencies for the sway (rad/s); use different values so motion never repeats quickly.
@export var sway_frequency: Vector3 = Vector3(0.11, 0.087, 0.095)
## Phase offsets so axes are not in lockstep.
@export var sway_phase: Vector3 = Vector3(0.7, 2.1, 1.35)
## How fast the camera follows the animated target (higher = snappier).
@export var follow_smoothness: float = 1.15

@export_group("Correction")
## Seconds between correction pulses (each pulse briefly aligns closer to the exact spawn rotation).
@export var correction_interval: float = 14.0
## How much stronger following becomes during a correction pulse (multiplier).
@export var correction_boost: float = 2.6
## How much the animated target shifts toward zero offset during a pulse (keeps some motion).
@export var correction_toward_base: float = 0.42

var _base_rotation: Vector3
var _sway_offset: Vector3 = Vector3.ZERO
var _time_s: float = 0.0


func _ready() -> void:
	_base_rotation = rotation


func _process(delta: float) -> void:
	_time_s += delta
	var t := _time_s

	# Perpetual, bounded target offset (never settles to a constant — multiple incommensurate tones).
	var wobble := Vector3(
		sin(t * sway_frequency.x + sway_phase.x),
		sin(t * sway_frequency.y + sway_phase.y),
		cos(t * sway_frequency.z + sway_phase.z)
	)
	# Second layer so angular velocity does not stay near zero for long on any axis.
	wobble += Vector3(
		0.35 * sin(t * sway_frequency.x * 2.17 + 0.3),
		0.35 * cos(t * sway_frequency.y * 2.03 + 1.1),
		0.28 * sin(t * sway_frequency.z * 2.31 + 0.9)
	)

	var max_r := Vector3(
		deg_to_rad(max_deviation_deg.x),
		deg_to_rad(max_deviation_deg.y),
		deg_to_rad(max_deviation_deg.z)
	)
	var target_offset := Vector3(
		wobble.x * max_r.x,
		wobble.y * max_r.y,
		wobble.z * max_r.z
	)
	if lock_rotation_z:
		target_offset.z = 0.0

	# One smooth peak per interval: briefly ease toward exact base while still following a reduced wobble.
	var u := fposmod(t, maxf(correction_interval, 0.001)) / maxf(correction_interval, 0.001)
	var pulse := sin(PI * u)
	pulse *= pulse
	var blended_target := target_offset.lerp(Vector3.ZERO, pulse * correction_toward_base)

	var correct_strength := 1.0 + (correction_boost - 1.0) * pulse
	var k := 1.0 - exp(-follow_smoothness * correct_strength * delta)
	_sway_offset = _sway_offset.lerp(blended_target, k)
	if lock_rotation_z:
		_sway_offset.z = 0.0

	rotation = _base_rotation + _sway_offset
