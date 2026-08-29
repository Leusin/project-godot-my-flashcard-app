class_name SafeAreaMargin
extends MarginContainer

# 안전 영역만큼 자식을 안쪽으로 들여 놓는 MarginContainer.
# 창 크기가 바뀔 때마다 다시 계산하므로 화면 회전에도 따라간다.
#
# 화면 전체를 감싸는 뿌리 여백으로 쓰면 된다. 여백 값을 다른 노드(상단 알림, 하단 시트)와
# 나눠 써야 하면 insets_changed를 잇거나, 직접 SafeArea.current_insets()를 부른다.

# 안전 영역과 무관하게 늘 두는 기본 여백.
@export var base_margin := 0.0
# 어떤 변에 안전 영역을 더할지. 그 변을 직접 다루고 싶으면 꺼 둔다.
@export var apply_left := true
@export var apply_top := true
@export var apply_right := true
@export var apply_bottom := true

# 좌, 상, 우, 하 순서의 안전 영역 여백.
signal insets_changed(insets: Vector4)

var _insets := Vector4.ZERO


func _ready() -> void:
	get_tree().root.size_changed.connect(apply_insets)
	# _ready() 시점에는 viewport 크기가 아직 최종값이 아니다.
	apply_insets.call_deferred()


# 마지막으로 적용한 여백. 아직 적용 전이면 0이다.
func insets() -> Vector4:
	return _insets


# 창 크기가 바뀌면 알아서 다시 부른다.
# 화면 밖에서 layout을 직접 흔든 뒤 곧바로 맞추고 싶을 때만 손으로 부른다.
func apply_insets() -> void:
	if not is_inside_tree():
		return

	_insets = SafeArea.current_insets(get_viewport_rect().size)
	_set_margin("margin_left", _insets.x if apply_left else 0.0)
	_set_margin("margin_top", _insets.y if apply_top else 0.0)
	_set_margin("margin_right", _insets.z if apply_right else 0.0)
	_set_margin("margin_bottom", _insets.w if apply_bottom else 0.0)
	insets_changed.emit(_insets)


func _set_margin(constant: String, inset: float) -> void:
	add_theme_constant_override(constant, roundi(base_margin + inset))
