class_name DragBounds
extends RefCounted

# 집어 든 항목이 스크롤 프레임 밖으로 나가면 잘려 보인다.
# 끄는 자리를 보이는 영역 안으로 묶어 항상 온전히 보이게 한다.


static func clip_ancestor(node: Node) -> Control:
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			return ancestor as Control
		ancestor = ancestor.get_parent()
	return null


static func clamped(desired: Vector2, item: Control, clip: Control) -> Vector2:
	var parent := item.get_parent() as Control
	if clip == null or parent == null:
		return desired

	var bounds := clip.get_global_rect()
	bounds.position -= parent.get_global_rect().position
	return clamped_position(desired, item.size, item.scale, bounds)


# 집은 항목은 가운데를 축으로 커지므로, 커진 만큼 layout 사각형 밖으로 삐져나온다.
# 그 삐져나온 폭까지 감안해야 테두리가 잘리지 않는다.
static func clamped_position(
	desired: Vector2,
	item_size: Vector2,
	item_scale: Vector2,
	bounds: Rect2
) -> Vector2:
	var grown := item_size * item_scale
	var overflow := (grown - item_size) * 0.5
	var lowest := bounds.position + overflow
	var highest := bounds.end - grown + overflow
	return Vector2(
		clampf(desired.x, lowest.x, maxf(lowest.x, highest.x)),
		clampf(desired.y, lowest.y, maxf(lowest.y, highest.y))
	)
