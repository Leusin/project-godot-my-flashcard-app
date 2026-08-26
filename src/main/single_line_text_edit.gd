class_name SingleLineTextEdit
extends TextEdit

# 질문은 Markdown '# 한 줄'로 저장되므로 줄바꿈을 원천 차단한다.
# LineEdit 대신 TextEdit인 이유: 긴 질문을 가로로 자르지 않고 여러 줄로 감싸 보여 주기 위해서다.
# 다만 무한정 늘어나면 카드 프레임의 2:3 비율이 깨지므로 보이는 줄 수를 제한하고 그 뒤로는 스크롤한다.

signal submitted

@export var min_visible_lines := 2
@export var max_visible_lines := 4


func _ready() -> void:
	text_changed.connect(_on_text_changed)
	resized.connect(_update_height)
	_update_height()


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.keycode != KEY_ENTER and key_event.keycode != KEY_KP_ENTER:
		return
	# 한글 같은 IME 조합 중 Enter는 글자 확정에 필요하다. 이 이벤트를 submit으로
	# 가로채면 마지막 음절이 사라지거나 다음 입력칸으로 포커스가 튄다.
	if has_ime_text():
		return
	accept_event()
	if key_event.pressed and not key_event.echo:
		submitted.emit()


func _on_text_changed() -> void:
	_strip_newlines()
	_update_height()


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


func height_for_lines(visible_lines: int) -> float:
	return (
		visible_lines * get_line_height()
		+ get_theme_stylebox("normal").get_minimum_size().y
	)


func _update_height() -> void:
	var wrapped_lines := 1 if get_line_count() == 0 else get_line_wrap_count(0) + 1
	var wanted := height_for_lines(
		clampi(wrapped_lines, min_visible_lines, max_visible_lines)
	)
	if is_equal_approx(custom_minimum_size.y, wanted):
		return
	custom_minimum_size.y = wanted
