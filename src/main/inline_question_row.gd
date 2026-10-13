extends Container

# 짧은 질문은 오답 표식을 바로 뒤에 붙이고, 긴 질문은 표식 너비를 남겨 말줄임한다.
func _get_minimum_size() -> Vector2:
	var height := 0.0
	for child in get_children():
		if child is Control and child.visible:
			height = maxf(height, child.get_combined_minimum_size().y)
	return Vector2(0, height)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var question := get_node("QuestionLabel") as Label
	var summary := get_node("WrongSummary") as Control
	var outcome := get_node("OutcomeBadge") as Control
	var gap := 12.0
	var reserved := 0.0
	for control in [summary, outcome]:
		if control.visible:
			reserved += control.get_combined_minimum_size().x + gap
	var width := maxf(0, size.x - reserved)
	if summary.visible:
		var font := question.get_theme_font("font")
		var text_width := font.get_string_size(
			question.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			question.get_theme_font_size("font_size")
		).x
		width = minf(width, ceilf(text_width) + 1)
	fit_child_in_rect(question, Rect2(0, 0, width, size.y))
	var x := width
	for control in [summary, outcome]:
		if not control.visible:
			continue
		x += gap
		var child_size: Vector2 = control.get_combined_minimum_size()
		fit_child_in_rect(control, Rect2(x, (size.y - child_size.y) / 2, child_size.x, child_size.y))
		x += child_size.x
