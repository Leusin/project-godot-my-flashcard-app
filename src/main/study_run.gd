class_name StudyRun
extends RefCounted

# 진행 중인 한 번의 학습 세션과 그 결과를 관리한다.
# 화면 표시와 입력 잠금은 MainApp이 맡는다.

class RetrySelection:
	extends RefCounted

	var cards: Array[FlashCard] = []
	var deck_indices: Array[int] = []
	var uses_deck_indices := false

var deck_file := ""
var session: StudySession
var progress := Progress.new()
var source_cards: Array[FlashCard] = []
var cards: Array[FlashCard] = []
var outcomes: Array[int] = []


func clear() -> void:
	deck_file = ""
	session = null
	progress = Progress.new()
	source_cards.clear()
	cards.clear()
	outcomes.clear()


func start(
	source_deck_file: String,
	selected_cards: Array[FlashCard],
	order: DeckOrdering.StudyOrder
) -> void:
	deck_file = source_deck_file
	progress = DeckStorage.load_progress(deck_file)
	source_cards = selected_cards.duplicate()
	cards = DeckOrdering.apply(order, source_cards)
	session = StudySession.new(cards)
	outcomes.clear()
	outcomes.resize(cards.size())
	outcomes.fill(StudyOutcome.Value.PENDING)


func has_current() -> bool:
	return session != null and not session.is_finished()


func is_finished() -> bool:
	return session == null or session.is_finished()


func current() -> FlashCard:
	if not has_current():
		return null
	return session.current()


func position() -> int:
	return -1 if session == null else session.position()


func remaining() -> int:
	return 0 if session == null else session.remaining()


func can_go_previous() -> bool:
	return has_current() and session.position() > 0


func previous() -> bool:
	if not can_go_previous():
		return false
	return session.previous()


func commit(outcome: int) -> bool:
	if not has_current() or outcome not in [
		StudyOutcome.Value.AGAIN,
		StudyOutcome.Value.GOOD,
		StudyOutcome.Value.SKIP,
	]:
		return false

	var index := session.position()
	outcomes[index] = outcome
	var card := session.current()
	match outcome:
		StudyOutcome.Value.AGAIN:
			progress.add_wrong(card.question)
			progress.set_status(card.question, CardStatus.Value.LEARNING)
			DeckStorage.save_progress(deck_file, progress)
		StudyOutcome.Value.GOOD:
			progress.set_status(card.question, CardStatus.Value.MASTERED)
			DeckStorage.save_progress(deck_file, progress)
		StudyOutcome.Value.SKIP:
			pass
	session.next()
	return true


func replace_current(updated_card: FlashCard, updated_progress: Progress) -> bool:
	if not has_current() or updated_card == null or updated_progress == null:
		return false

	var original_card := session.current()
	var source_index := source_cards.find(original_card)
	var current_position := session.position()
	session.replace_current(updated_card)
	cards[current_position] = updated_card
	if source_index >= 0 and source_index < source_cards.size():
		source_cards[source_index] = updated_card
	progress = updated_progress
	return true


func replace_result(
	result_index: int,
	source_index: int,
	updated_card: FlashCard,
	updated_progress: Progress
) -> bool:
	if (
		result_index < 0
		or result_index >= cards.size()
		or updated_card == null
		or updated_progress == null
	):
		return false

	cards[result_index] = updated_card
	if source_index >= 0 and source_index < source_cards.size():
		source_cards[source_index] = updated_card
	progress = updated_progress
	return true


func result_card(index: int) -> FlashCard:
	if index < 0 or index >= cards.size():
		return null
	return cards[index]


func positions_for_outcome(outcome: int) -> Array[int]:
	var positions: Array[int] = []
	for index in outcomes.size():
		if outcomes[index] == outcome:
			positions.append(index)
	return positions


func cards_at(positions: Array[int]) -> Array[FlashCard]:
	var selected: Array[FlashCard] = []
	for index in positions:
		if index >= 0 and index < cards.size():
			selected.append(cards[index])
	return selected


func retry_again(plan: StudyPlan) -> RetrySelection:
	var selection := RetrySelection.new()
	var positions := positions_for_outcome(StudyOutcome.Value.AGAIN)
	selection.cards = cards_at(positions)
	selection.uses_deck_indices = (
		plan != null and plan.can_map_active_cards(cards.size())
	)
	if selection.uses_deck_indices:
		for position_index in positions:
			selection.deck_indices.append(plan.active_index_at(position_index))
	return selection


func sync_resume(plan: StudyPlan) -> bool:
	if (
		plan == null
		or plan.active_indices.is_empty()
		or session == null
		or deck_file.is_empty()
	):
		return false

	if session.is_finished():
		return DeckStorage.delete_study_resume(deck_file)

	var resume := plan.make_resume(session.position())
	return resume != null and DeckStorage.save_study_resume(deck_file, resume)
