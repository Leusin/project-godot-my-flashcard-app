class_name StudyResume
extends RefCounted

var deck_hash: int
var remaining_indices: Array[int] = []
var order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
var scope: int


func to_json() -> String:
	return JSON.stringify({
		"deck_hash": deck_hash,
		"remaining_indices": remaining_indices,
		"order": order,
		"scope": scope,
	}, "\t")


static func from_json(json: String) -> StudyResume:
	if json.strip_edges().is_empty():
		return null

	# parse_string은 깨진 입력에 엔진 오류를 남긴다.
	# 깨진 파일을 조용히 버리는 것이 여기 규칙이라 오류 코드만 받는다.
	var parser := JSON.new()
	if parser.parse(json) != OK:
		return null

	var parsed: Variant = parser.data
	if parsed is not Dictionary:
		return null

	var data := parsed as Dictionary
	var hash_value: Variant = data.get("deck_hash")
	var indices_value: Variant = data.get("remaining_indices")
	if (hash_value is not int and hash_value is not float) or indices_value is not Array:
		return null

	var resume := StudyResume.new()
	resume.deck_hash = int(hash_value)
	for value: Variant in indices_value:
		if value is not int and value is not float:
			return null
		resume.remaining_indices.append(int(value))

	var order_value: Variant = data.get("order", DeckOrdering.StudyOrder.SEQUENTIAL)
	if order_value is int or order_value is float:
		resume.order = int(order_value)

	var scope_value: Variant = data.get("scope", 0)
	if scope_value is int or scope_value is float:
		resume.scope = int(scope_value)

	return resume
