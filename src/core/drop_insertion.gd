class_name DropInsertion
extends RefCounted

# 움직이는 항목을 빼고 anchor의 앞/뒤 경계에 다시 넣었을 때의 최종 index를 구한다.


static func target_index(
	item_count: int,
	moving_index: int,
	anchor_index: int,
	after_anchor: bool
) -> int:
	if (
		item_count <= 1
		or moving_index < 0
		or moving_index >= item_count
		or anchor_index < 0
		or anchor_index >= item_count
		or anchor_index == moving_index
	):
		return -1

	var insertion_slot := anchor_index + (1 if after_anchor else 0)
	if moving_index < insertion_slot:
		insertion_slot -= 1
	return clampi(insertion_slot, 0, item_count - 1)
