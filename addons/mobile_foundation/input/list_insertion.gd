class_name ListInsertion
extends RefCounted

# 끌어 놓기로 순서를 바꿀 때, 가리킨 경계를 최종 index로 바꾼다.
# 한 줄로 늘어선 무엇에나 쓴다 (목록 행, 인벤토리 칸, 핫바 슬롯).
# 화면 좌표는 다루지 않는다. 어느 항목의 앞/뒤를 가리켰는지는 부르는 쪽이 정한다.


# 이미 목록 안에 있는 항목을 anchor의 앞/뒤 경계로 옮겼을 때의 최종 index.
# 움직이는 항목을 먼저 빼고 세므로, 끌어 온 자리와 결과 index가 다를 수 있다.
# 옮길 수 없는 요청이면 -1 (경계가 자기 자신이거나, index가 범위 밖이거나, 항목이 하나뿐).
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


# 바깥에서 가져온 새 항목을 anchor의 앞/뒤 경계에 끼워 넣을 자리.
# 빼는 항목이 없으므로 결과는 0..item_count다. 끝에 붙이면 item_count가 된다.
# Array.insert()에 그대로 넘길 수 있다.
static func insertion_index(item_count: int, anchor_index: int, after_anchor: bool) -> int:
	if item_count <= 0 or anchor_index < 0:
		return 0
	if anchor_index >= item_count:
		return item_count

	return clampi(anchor_index + (1 if after_anchor else 0), 0, item_count)
