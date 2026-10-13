class_name CardFaceLayout
extends RefCounted


static func set_answer_visible(
	question_scroll: ScrollContainer,
	question_label: Label,
	answer_scroll: ScrollContainer,
	answer_label: Label,
	card_properties: Control,
	show_answer: bool
) -> void:
	answer_scroll.visible = show_answer
	card_properties.visible = show_answer
	if show_answer:
		question_scroll.scroll_vertical = 0
		question_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		question_scroll.custom_minimum_size.y = 150.0
		question_scroll.size_flags_vertical = Control.SIZE_FILL
		question_label.max_lines_visible = 2
		question_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		question_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56, 1))
	else:
		question_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		question_scroll.custom_minimum_size.y = 0.0
		question_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		question_label.max_lines_visible = -1
		question_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		question_label.remove_theme_color_override("font_color")
	question_label.add_theme_font_size_override("font_size", 42)
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	answer_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
