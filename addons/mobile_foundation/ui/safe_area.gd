class_name SafeArea
extends RefCounted

# 노치와 제스처 바를 피할 여백을 구한다.
#
# DisplayServer가 돌려주는 안전 영역은 창 픽셀 단위인데 UI는 viewport 좌표를 쓴다.
# 두 단위가 다르므로 배율을 곱하지 않으면 stretch를 쓰는 화면에서 여백이 어긋난다.
#
# 여백은 Vector4에 좌, 상, 우, 하 순서로 담는다.


static func insets_in_viewport(
	safe_area: Rect2i,
	window_size: Vector2i,
	viewport_size: Vector2
) -> Vector4:
	if window_size.x <= 0 or window_size.y <= 0:
		return Vector4.ZERO

	var viewport_scale := Vector2(
		viewport_size.x / float(window_size.x),
		viewport_size.y / float(window_size.y)
	)
	return Vector4(
		maxi(safe_area.position.x, 0) * viewport_scale.x,
		maxi(safe_area.position.y, 0) * viewport_scale.y,
		maxi(window_size.x - safe_area.end.x, 0) * viewport_scale.x,
		maxi(window_size.y - safe_area.end.y, 0) * viewport_scale.y
	)


# 안전 영역을 따질 기기인지. 데스크톱에는 노치가 없으므로 묻지 않는다.
static func is_handheld() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"


# 지금 화면의 여백. 손에 드는 기기가 아니면 0이다.
# 순수 계산은 insets_in_viewport()에 있고, 이쪽은 DisplayServer 조회만 얹는다.
static func current_insets(viewport_size: Vector2) -> Vector4:
	if not is_handheld():
		return Vector4.ZERO

	return insets_in_viewport(
		DisplayServer.get_display_safe_area(),
		DisplayServer.window_get_size(),
		viewport_size
	)
