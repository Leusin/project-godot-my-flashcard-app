class_name AspectFit
extends RefCounted

# 주어진 사각형 안에서 종횡비를 지키며 가장 크게 들어가는 사각형을 가운데에 놓는다.
# aspect_ratio는 width / height다.


static func centered_rect(available: Rect2, aspect_ratio: float) -> Rect2:
	if available.size.x <= 0.0 or available.size.y <= 0.0 or aspect_ratio <= 0.0:
		return Rect2()

	var fitted_size := Vector2(available.size.x, available.size.x / aspect_ratio)
	if fitted_size.y > available.size.y:
		fitted_size = Vector2(available.size.y * aspect_ratio, available.size.y)
	return Rect2(
		available.position + (available.size - fitted_size) * 0.5,
		fitted_size
	)
