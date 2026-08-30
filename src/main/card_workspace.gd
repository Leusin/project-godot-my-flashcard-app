class_name CardWorkspace
extends RefCounted

# 카드 편집용 덱 스냅샷과 저장 작업을 함께 관리한다.
# 화면 전환은 MainApp, 학습 세션 반영은 CardEditCoordinator가 맡는다.

enum MoveResult {
	UNCHANGED,
	SAVED,
	SAVE_FAILED,
}

class SaveResult:
	extends RefCounted

	var succeeded := false
	var progress_saved := false
	var card_index := -1
	var card: FlashCard
	var markdown := ""
	var progress: Progress

class DeleteResult:
	extends RefCounted

	var succeeded := false
	var progress_saved := false
	var deleted_question := ""
	var markdown := ""
	var progress: Progress

var deck_file := ""
var cards: Array[FlashCard] = []
var editing_index := -1


func clear() -> void:
	deck_file = ""
	cards.clear()
	editing_index = -1


func open(source_deck_file: String) -> bool:
	if not DeckStorage.deck_exists(source_deck_file):
		return false

	load_snapshot(
		source_deck_file,
		DeckParser.parse(DeckStorage.read_deck(source_deck_file))
	)
	return true


func load_snapshot(
	source_deck_file: String,
	source_cards: Array[FlashCard]
) -> void:
	deck_file = source_deck_file
	cards = _copy_cards(source_cards)
	editing_index = -1


func select(index: int) -> bool:
	if index < -1 or index >= cards.size():
		return false
	editing_index = index
	return true


func is_valid_index(index: int) -> bool:
	return index >= 0 and index < cards.size()


func card_at(index: int) -> FlashCard:
	if not is_valid_index(index):
		return null
	return cards[index]


func load_progress() -> Progress:
	return DeckStorage.load_progress(deck_file)


func move_card(from_index: int, to_index: int) -> MoveResult:
	if (
		not is_valid_index(from_index)
		or not is_valid_index(to_index)
		or from_index == to_index
	):
		return MoveResult.UNCHANGED

	var updated := CardOrdering.moved(cards, from_index, to_index)
	if not DeckStorage.write_deck(deck_file, DeckWriter.to_markdown(updated)):
		return MoveResult.SAVE_FAILED

	cards = updated
	# 이어하기 기록은 카드 위치를 사용하므로 순서가 바뀌면 폐기한다.
	DeckStorage.delete_study_resume(deck_file)
	return MoveResult.SAVED


func save_card(
	question: String,
	answer: String,
	wrong_count: int,
	status: CardStatus.Value,
	invalidate_resume: bool
) -> SaveResult:
	var result := SaveResult.new()
	if deck_file.is_empty():
		return result

	var updated := _copy_cards(cards)
	var original_question := ""
	var saved_index := editing_index
	if editing_index < 0:
		saved_index = updated.size()
		updated.append(FlashCard.new(question, answer))
	elif editing_index >= updated.size():
		return result
	else:
		original_question = updated[editing_index].question
		updated[editing_index] = FlashCard.new(question, answer)

	var markdown := DeckWriter.to_markdown(updated)
	if not DeckStorage.write_deck(deck_file, markdown):
		return result

	var progress := DeckStorage.load_progress(deck_file)
	if not original_question.is_empty() and original_question != question:
		var old_question_still_exists := false
		for index in updated.size():
			if index != saved_index and updated[index].question == original_question:
				old_question_still_exists = true
				break
		if not old_question_still_exists:
			progress.rename(original_question, question)

	progress.set_wrong_count(question, wrong_count)
	progress.set_status(question, status)
	var progress_saved := DeckStorage.save_progress(deck_file, progress)
	if invalidate_resume:
		DeckStorage.delete_study_resume(deck_file)

	cards = updated
	editing_index = saved_index
	result.succeeded = true
	result.progress_saved = progress_saved
	result.card_index = saved_index
	result.card = cards[saved_index]
	result.markdown = markdown
	result.progress = progress
	return result


func delete_selected() -> DeleteResult:
	var result := DeleteResult.new()
	if not is_valid_index(editing_index):
		return result

	var deleted_question := cards[editing_index].question
	var updated := _copy_cards(cards)
	updated.remove_at(editing_index)
	var markdown := DeckWriter.to_markdown(updated)
	if not DeckStorage.write_deck(deck_file, markdown):
		return result

	var progress := DeckStorage.load_progress(deck_file)
	var question_still_exists := false
	for card in updated:
		if card.question == deleted_question:
			question_still_exists = true
			break
	if not question_still_exists:
		progress.remove(deleted_question)

	var progress_saved := DeckStorage.save_progress(deck_file, progress)
	DeckStorage.delete_study_resume(deck_file)
	cards = updated
	editing_index = -1
	result.succeeded = true
	result.progress_saved = progress_saved
	result.deleted_question = deleted_question
	result.markdown = markdown
	result.progress = progress
	return result


static func _copy_cards(source: Array[FlashCard]) -> Array[FlashCard]:
	var copied: Array[FlashCard] = []
	for card in source:
		copied.append(FlashCard.new(card.question, card.answer))
	return copied
