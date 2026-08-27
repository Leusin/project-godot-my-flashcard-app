class_name MaxWidthBox
extends MarginContainer

# 넓은 PC 창에서 목록과 버튼이 끝까지 늘어나면 글자는 왼쪽 끝, 아이콘은
# 오른쪽 끝으로 갈라져 어색하다. 학습 카드와 같은 기준 폭까지만 쓰고
# 남는 자리는 좌우로 나눠 비운다. 좁은 화면에서는 아무것도 하지 않는다.

# 기준 폭은 세로 설계 폭에서 좌우 페이지 여백을 뺀 값이다. 학습 카드도
# 이 폭에 맞춰 2:3으로 놓이므로 두 화면의 기둥 폭이 같아진다.
# PAGE_MARGIN은 main.gd의 BASE_PAGE_MARGIN과 같은 값을 쓴다.
const PAGE_MARGIN := 32.0

## 0이면 설계 폭에서 자동으로 구한다.
@export var max_width := 0.0


func _ready() -> void:
	resized.connect(_apply_side_margins)
	_apply_side_margins()


func _apply_side_margins() -> void:
	var side := int(maxf(0.0, size.x - width_limit()) * 0.5)
	add_theme_constant_override("margin_left", side)
	add_theme_constant_override("margin_right", side)


func width_limit() -> float:
	if max_width > 0.0:
		return max_width
	var design_width: float = ProjectSettings.get_setting(
		"display/window/size/viewport_width", 720
	)
	return design_width - 2.0 * PAGE_MARGIN
