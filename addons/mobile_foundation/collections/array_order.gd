class_name ArrayOrder
extends RefCounted

# 배열 안에서 항목 하나의 자리를 옮긴다. 원본은 건드리지 않는다.
#
# 타입이 있는 배열(Array[T])을 넘겨도 duplicate()가 타입을 지키므로 그대로 동작한다.
# 다만 정적 타입은 Array로 좁혀지니, 받는 쪽에서 다시 Array[T]로 쓰려면 assign()을 거친다.
#
#	var reordered: Array[Item] = []
#	reordered.assign(ArrayOrder.moved(items, from_index, to_index))


# to_index는 배열 안으로 묶는다. 범위를 넘는 목적지는 끝에 붙는 뜻으로 읽는다.
# from_index가 범위 밖이면 옮길 항목이 없으므로 복사본을 그대로 돌려준다.
static func moved(items: Array, from_index: int, to_index: int) -> Array:
	var result := items.duplicate()
	if from_index < 0 or from_index >= result.size():
		return result

	var target := clampi(to_index, 0, result.size() - 1)
	if target == from_index:
		return result

	var item: Variant = result[from_index]
	result.remove_at(from_index)
	result.insert(target, item)
	return result
