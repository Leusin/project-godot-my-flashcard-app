class_name WrongTallyView
extends Control

@export var stroke_color := Color(0.12, 0.12, 0.12, 1)
@export var stroke_width := 3.5
@export var stroke_spacing := 8.0
@export var group_gap := 12.0
@export var mark_top := 8.0
@export var mark_bottom := 34.0
@export var minimum_height := 42.0

var wrong_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_update_size()


func set_count(value: int) -> void:
	wrong_count = maxi(value, 0)
	tooltip_text = "오답 %d회" % wrong_count
	_update_size()
	queue_redraw()


func _draw() -> void:
	var remaining := wrong_count
	var group_index := 0
	while remaining > 0:
		var marks_in_group := mini(remaining, 5)
		_draw_group(group_index, marks_in_group)
		remaining -= marks_in_group
		group_index += 1


func _draw_group(group_index: int, marks_in_group: int) -> void:
	var group_x := group_index * (stroke_spacing * 3.0 + group_gap)
	var vertical_count := mini(marks_in_group, 4)
	for stroke_index in vertical_count:
		var stroke_x := group_x + stroke_index * stroke_spacing + stroke_width
		draw_line(
			Vector2(stroke_x, mark_top),
			Vector2(stroke_x, mark_bottom),
			stroke_color,
			stroke_width,
			true
		)

	if marks_in_group == 5:
		draw_line(
			Vector2(group_x, mark_bottom - 2.0),
			Vector2(group_x + stroke_spacing * 3.0 + stroke_width * 2.0, mark_top + 2.0),
			stroke_color,
			stroke_width,
			true
		)


func _update_size() -> void:
	var group_count := ceili(wrong_count / 5.0)
	var width := 0.0
	if group_count > 0:
		width = group_count * (stroke_spacing * 3.0 + stroke_width * 2.0)
		width += (group_count - 1) * (group_gap - stroke_width * 2.0)
	custom_minimum_size = Vector2(width, minimum_height)
