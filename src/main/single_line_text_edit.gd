class_name SingleLineTextEdit
extends TextEdit

# 질문은 Markdown '# 한 줄'로 저장되므로 줄바꿈을 원천 차단한다.
# LineEdit 대신 TextEdit인 이유: 긴 질문을 가로로 자르지 않고 여러 줄로 감싸 보여 주기 위해서다.

signal submitted


func _ready() -> void:
	text_changed.connect(_strip_newlines)


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		accept_event()
		if key_event.pressed and not key_event.echo:
			submitted.emit()


# Enter는 위에서 막지만 IME 확정이나 붙여넣기로 줄바꿈이 들어올 수 있다.
func _strip_newlines() -> void:
	if text.find("\n") == -1:
		return
	var caret_offset := get_caret_column()
	for line in get_caret_line():
		caret_offset += get_line(line).length() + 1
	text = text.replace("\n", " ")
	set_caret_line(0)
	set_caret_column(caret_offset)
