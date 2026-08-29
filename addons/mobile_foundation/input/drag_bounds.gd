class_name DragBounds
extends RefCounted

# 집어 든 항목이 잘려 보이지 않도록, 끄는 자리를 보이는 영역 안으로 묶는다.
# 목록 재정렬, 인벤토리 칸 옮기기, 핫바 슬롯 끌기에 그대로 쓴다.


# 항목을 잘라 내는 조상 노드를 찾는다.
# 기본은 ScrollContainer지만, 인벤토리 판처럼 다른 노드가 잘라 낸다면
# clip_class에 그 노드의 class 이름을 넘긴다.
static func clip_ancestor(node: Node, clip_class: String = "ScrollContainer") -> Control:
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.is_class(clip_class):
			return ancestor as Control
		ancestor = ancestor.get_parent()
	return null


# item의 부모 좌표계에서, clip이 보여 주는 영역 안으로 desired를 묶는다.
# clip이나 부모가 없으면 묶을 기준이 없으므로 desired를 그대로 돌려준다.
static func clamped(desired: Vector2, item: Control, clip: Control) -> Vector2:
	var parent := item.get_parent() as Control
	if clip == null or parent == null:
		return desired

	var bounds := clip.get_global_rect()
	bounds.position -= parent.get_global_rect().position
	return clamped_position(desired, item.size, item.scale, item.pivot_offset, bounds)


# scale은 pivot_offset을 축으로 적용되므로, 그 축에서 삐져나온 폭까지 감안해야
# 테두리가 잘리지 않는다.
# 항목이 영역보다 크면 묶을 자리가 없으므로 시작 지점에 둔다.
static func clamped_position(
	desired: Vector2,
	item_size: Vector2,
	item_scale: Vector2,
	pivot_offset: Vector2,
	bounds: Rect2
) -> Vector2:
	var grown := item_size * item_scale
	var pivot_shift := pivot_offset * (item_scale - Vector2.ONE)
	var lowest := bounds.position + pivot_shift
	var highest := bounds.end - grown + pivot_shift
	return Vector2(
		clampf(desired.x, lowest.x, maxf(lowest.x, highest.x)),
		clampf(desired.y, lowest.y, maxf(lowest.y, highest.y))
	)
