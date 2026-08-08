class_name StudySession
extends RefCounted

var _cards: Array[FlashCard]
var _position: int

func _init(cards: Array[FlashCard]) -> void:
	_cards = cards.duplicate()

func is_finished() -> bool:
	return _position >= _cards.size()

func current() -> FlashCard:
	if is_finished():
		return null
	return _cards[_position]

func remaining() -> int:
	assert(
		_position >= 0 and _position <= _cards.size(),
		"세션 위치가 유효 범위를 벗어남"
	)

	return _cards.size() - _position

func next() -> void:
	if is_finished():
		return
	_position += 1

func replace_current(card: FlashCard) -> void:
	assert(card != null, "교체할 카드가 null임")

	if is_finished():
		return

	_cards[_position] = card
