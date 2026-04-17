@tool
extends Node

class_name LevelGridMapApplier

const DEFAULT_JSON_PATH := "res://generated/deluxe_levels/deluxe_levels_1_11_skip_7.json"

@export_file("*.json") var levels_json_path: String = DEFAULT_JSON_PATH:
	set(value):
		levels_json_path = value
		_reload_levels()

@export var grid_map: GridMap
@export var floor_item_id: int = 1
@export var wall_item_id: int = 0
@export var floor_y: int = -1
@export var wall_y: int = 0
@export var center_map_on_origin: bool = true
@export var invert_z_axis: bool = true

@export_tool_button("Reload Levels", "Reload") var reload_levels_action = _reload_levels
@export_tool_button("Apply Selected Level", "Play") var apply_selected_level_action = _apply_selected_level

var _selected_level_index: int = 0
var _levels_data: Array = []
var _level_options: PackedStringArray = PackedStringArray(["(none loaded)"])


func _ready() -> void:
	if Engine.is_editor_hint():
		_reload_levels()


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	list.append(
		{
			"name": "selected_level",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(_level_options),
		}
	)
	return list


func _get(property: StringName) -> Variant:
	if property == &"selected_level":
		return _selected_level_index
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == &"selected_level":
		_selected_level_index = clampi(int(value), 0, max(_levels_data.size() - 1, 0))
		return true
	return false


func _reload_levels() -> void:
	_levels_data.clear()
	_level_options = PackedStringArray(["(none loaded)"])
	_selected_level_index = 0

	if levels_json_path.is_empty():
		_push_status("levels_json_path is empty.")
		notify_property_list_changed()
		return

	var file := FileAccess.open(levels_json_path, FileAccess.READ)
	if file == null:
		_push_status("Could not open JSON file: %s" % levels_json_path)
		notify_property_list_changed()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		_push_status("JSON root must be an array: %s" % levels_json_path)
		notify_property_list_changed()
		return

	var options: PackedStringArray = PackedStringArray()
	for entry in parsed:
		if not (entry is Dictionary):
			continue
		if not entry.has("rows"):
			continue
		var level_number := int(entry.get("level", _levels_data.size() + 1))
		var rows_variant: Variant = entry["rows"]
		if not (rows_variant is Array):
			continue
		_levels_data.append(entry)
		options.append("Level %d" % level_number)

	if _levels_data.is_empty():
		_level_options = PackedStringArray(["(none loaded)"])
		_push_status("No valid levels found in JSON.")
	else:
		_level_options = options
		_push_status("Loaded %d level(s)." % _levels_data.size())

	notify_property_list_changed()


func _apply_selected_level() -> void:
	if grid_map == null:
		_push_status("grid_map is not assigned.")
		return
	if _levels_data.is_empty():
		_push_status("No levels loaded. Click Reload Levels first.")
		return
	if _selected_level_index < 0 or _selected_level_index >= _levels_data.size():
		_push_status("selected_level is out of range.")
		return

	var level: Dictionary = _levels_data[_selected_level_index]
	var rows_variant: Variant = level.get("rows", [])
	if not (rows_variant is Array):
		_push_status("Selected level rows are invalid.")
		return

	var rows: Array = rows_variant
	var width := 0
	for row_variant in rows:
		var row_text := str(row_variant)
		width = maxi(width, row_text.length())

	var height := rows.size()
	var x_offset := 0
	var z_offset := 0
	if center_map_on_origin:
		x_offset = int(floor(float(width) / 2.0))
		z_offset = int(floor(float(height) / 2.0))

	grid_map.clear()

	for row_idx in range(height):
		var row_text := str(rows[row_idx])
		for col in range(width):
			var ch := " "
			if col < row_text.length():
				ch = row_text[col]
			if ch == " ":
				continue

			var x := col - x_offset
			var z_row := row_idx
			if invert_z_axis:
				z_row = (height - 1) - row_idx
			var z := z_row - z_offset

			# Every non-void map tile gets floor at y = floor_y.
			grid_map.set_cell_item(Vector3i(x, floor_y, z), floor_item_id, 0)

			# Walls get a wall block at y = wall_y.
			if ch == "#":
				grid_map.set_cell_item(Vector3i(x, wall_y, z), wall_item_id, 0)

	var level_number := int(level.get("level", _selected_level_index + 1))
	_push_status("Applied level %d to GridMap." % level_number)


func _push_status(message: String) -> void:
	print("[LevelGridMapApplier] %s" % message)
