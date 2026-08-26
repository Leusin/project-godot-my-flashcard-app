class_name DeckLibraryOrder
extends RefCounted

# 덱 목록에 보여 줄 차례를 정한다.
# 저장된 차례가 먼저고, 거기 없는 덱은 새로 생긴 것이라 맨 앞에 온다.
# 사라진 덱은 차례에서 빠진다.


static func apply(order: Array[String], deck_files: Array[String]) -> Array[String]:
	var present := {}
	for deck_file in deck_files:
		present[deck_file] = true

	var known: Array[String] = []
	var placed := {}
	for deck_file in order:
		if present.has(deck_file) and not placed.has(deck_file):
			known.append(deck_file)
			placed[deck_file] = true

	var fresh: Array[String] = []
	for deck_file in deck_files:
		if not placed.has(deck_file):
			fresh.append(deck_file)

	return fresh + known


static func moved(order: Array[String], from_index: int, to_index: int) -> Array[String]:
	var result: Array[String] = order.duplicate()
	if from_index < 0 or from_index >= result.size():
		return result

	var target := clampi(to_index, 0, result.size() - 1)
	if target == from_index:
		return result

	var deck_file := result[from_index]
	result.remove_at(from_index)
	result.insert(target, deck_file)
	return result
