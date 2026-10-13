class_name ListReorder
extends Node

## 자식 Control의 놓기 위치를 계산하고 순서를 한 번 바꾼다.
## 입력, 들어 올리기 연출, 데이터 저장은 호출하는 쪽이 맡는다.
signal reordered(from_index: int, to_index: int)

enum Layout { VERTICAL, FLOW }

@export var items: Container
@export var layout := Layout.VERTICAL

var _moving: Control


func begin(item: Control) -> void:
	cancel()
	if is_instance_valid(items) and is_instance_valid(item) and item.get_parent() == items:
		_moving = item


func cancel() -> void:
	_moving = null


## pointer는 항목의 get_global_rect()와 같은 canvas 좌표다.
## 시작한 항목과 다른 항목의 release, 중복 release는 무시한다.
func finish(item: Control, pointer: Vector2) -> void:
	if not is_instance_valid(_moving) or item != _moving:
		return
	cancel()
	if not is_instance_valid(items) or item.get_parent() != items:
		return
	var from_index := item.get_index()
	var to_index := target_at(item, pointer)
	if to_index < 0 or to_index == from_index:
		return
	items.move_child(item, to_index)
	reordered.emit(from_index, to_index)


func target_at(item: Control, pointer: Vector2) -> int:
	if not is_instance_valid(items) or not is_instance_valid(item):
		return -1
	if item.get_parent() != items:
		return -1
	var anchor_index := -1
	var after_anchor := false
	var closest_distance := INF
	for child in items.get_children():
		var candidate := child as Control
		if candidate == null or candidate == item or not candidate.visible:
			continue
		var rect := candidate.get_global_rect()
		for after in [false, true]:
			var distance: float
			if layout == Layout.VERTICAL:
				var edge := rect.end.y if after else rect.position.y
				distance = absf(pointer.y - edge)
			else:
				var edge := rect.end.x if after else rect.position.x
				var nearest_y := clampf(pointer.y, rect.position.y, rect.end.y)
				distance = pointer.distance_to(Vector2(edge, nearest_y))
			if distance < closest_distance:
				closest_distance = distance
				anchor_index = candidate.get_index()
				after_anchor = after
	var target := ListInsertion.target_index(
		items.get_child_count(), item.get_index(), anchor_index, after_anchor
	)
	return -1 if target == item.get_index() else target
