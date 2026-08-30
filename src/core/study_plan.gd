class_name StudyPlan
extends RefCounted

enum Scope {
	ALL,
	INCOMPLETE,
	WRONG,
}

class Summary:
	extends RefCounted

	var total_count := 0
	var new_count := 0
	var learning_count := 0
	var mastered_count := 0

var deck_file := ""
var cards: Array[FlashCard] = []
var deck_hash := 0
var active_indices: Array[int] = []
var active_order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
var active_scope: int = Scope.ALL


func clear() -> void:
	deck_file = ""
	cards.clear()
	deck_hash = 0
	_clear_active()


func prepare(
	source_deck_file: String,
	source_cards: Array[FlashCard],
	source_hash: int
) -> void:
	deck_file = source_deck_file
	cards = _copy_cards(source_cards)
	deck_hash = source_hash
	_clear_active()


func replace_cards(
	updated_deck_file: String,
	updated_cards: Array[FlashCard],
	updated_hash: int
) -> void:
	deck_file = updated_deck_file
	cards = _copy_cards(updated_cards)
	deck_hash = updated_hash


func summary(progress: Progress) -> Summary:
	var result := Summary.new()
	result.total_count = cards.size()
	for card in cards:
		match progress.get_status(card.question):
			CardStatus.Value.LEARNING:
				result.learning_count += 1
			CardStatus.Value.MASTERED:
				result.mastered_count += 1
			_:
				result.new_count += 1
	return result


func is_valid_resume(resume: StudyResume) -> bool:
	if resume == null or resume.deck_hash != deck_hash:
		return false
	if resume.remaining_indices.is_empty():
		return false
	for index in resume.remaining_indices:
		if index < 0 or index >= cards.size():
			return false
	return true


func indices_for_scope(progress: Progress, scope: int) -> Array[int]:
	var indices: Array[int] = []
	for index in cards.size():
		var card := cards[index]
		if scope == Scope.INCOMPLETE and (
			progress.get_status(card.question) == CardStatus.Value.MASTERED
		):
			continue
		if scope == Scope.WRONG and progress.get_wrong_count(card.question) <= 0:
			continue
		indices.append(index)
	return indices


func begin(
	indices: Array[int],
	order: DeckOrdering.StudyOrder,
	scope: int,
	apply_order: bool
) -> Array[FlashCard]:
	for index in indices:
		if index < 0 or index >= cards.size():
			_clear_active()
			return []

	active_indices = indices.duplicate()
	if apply_order and order == DeckOrdering.StudyOrder.SHUFFLE:
		active_indices.shuffle()
	active_order = order
	active_scope = scope

	var selected_cards: Array[FlashCard] = []
	for index in active_indices:
		selected_cards.append(cards[index])
	return selected_cards


func active_index_at(position: int) -> int:
	if position < 0 or position >= active_indices.size():
		return -1
	return active_indices[position]


func can_map_active_cards(card_count: int) -> bool:
	return not active_indices.is_empty() and active_indices.size() == card_count


func make_resume(position: int) -> StudyResume:
	if position < 0 or position >= active_indices.size():
		return null

	var resume := StudyResume.new()
	resume.deck_hash = deck_hash
	resume.order = active_order
	resume.scope = active_scope
	for index in range(position, active_indices.size()):
		resume.remaining_indices.append(active_indices[index])
	return resume


func _clear_active() -> void:
	active_indices.clear()
	active_order = DeckOrdering.StudyOrder.SEQUENTIAL
	active_scope = Scope.ALL


static func _copy_cards(source: Array[FlashCard]) -> Array[FlashCard]:
	var copied: Array[FlashCard] = []
	for card in source:
		copied.append(FlashCard.new(card.question, card.answer))
	return copied
