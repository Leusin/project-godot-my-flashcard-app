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


static func clamped(
	desired: Vector2,
	item: Control,
	clip: Control
) -> Vector2:
	if clip == null or item.get_parent() == null:
		return desired

	var bounds := clip.get_global_rect()
	var parent_origin := (item.get_parent() as Control).get_global_rect().position
	var lowest := bounds.position - parent_origin
	var highest := bounds.end - parent_origin - item.size
	return Vector2(
		clampf(desired.x, lowest.x, maxf(lowest.x, highest.x)),
		clampf(desired.y, lowest.y, maxf(lowest.y, highest.y))
	)
