extends TestCase

# Phase 3: 학습 세션 큐 규칙(StudySession).


func run_tests() -> void:
	_test_queue_progression()
	_test_single_and_empty_decks()
	_test_replace_current()
	_test_input_array_is_copied()


func _test_queue_progression() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
	]
	var session := StudySession.new(cards)

	check(session.current().question == "A", "세션: 첫 카드는 입력 순서의 첫 카드")
	check(session.remaining() == 3, "세션: 시작 시 남은 카드 수")
	check(not session.is_finished(), "세션: 카드가 남아 있으면 진행 중")

	session.next()
	check(session.current().question == "B", "세션: next 후 다음 카드로 이동")
	check(session.remaining() == 2, "세션: next 후 남은 카드 수 감소")

	session.next()
	session.next()
	check(session.is_finished(), "세션: 모든 카드를 넘기면 종료")
	check(session.current() == null, "세션: 종료 후 현재 카드는 null")
	check(session.remaining() == 0, "세션: 종료 후 남은 카드 수는 0")

	session.next()
	check(session.remaining() == 0, "세션: 종료 후 next는 남은 수를 음수로 만들지 않음")


func _test_single_and_empty_decks() -> void:
	var single_cards: Array[FlashCard] = [FlashCard.new("하나", "1")]
	var single := StudySession.new(single_cards)
	single.next()
	check(single.is_finished(), "세션: 카드 한 장은 한 번 넘기면 종료")

	var empty_cards: Array[FlashCard] = []
	var empty := StudySession.new(empty_cards)
	check(empty.is_finished(), "세션: 빈 덱은 처음부터 종료")
	check(empty.current() == null, "세션: 빈 덱의 현재 카드는 null")
	check(empty.remaining() == 0, "세션: 빈 덱의 남은 카드 수는 0")
	empty.next()
	check(empty.is_finished(), "세션: 빈 덱에서 next는 아무 일도 하지 않음")


func _test_replace_current() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
	]
	var session := StudySession.new(cards)

	session.replace_current(FlashCard.new("A2", "1e"))
	check(session.current().question == "A2", "세션: 현재 카드 질문 교체")
	check(session.current().answer == "1e", "세션: 현재 카드 답 교체")
	check(session.remaining() == 2, "세션: 현재 카드 교체 후 남은 수 유지")
	check(cards[0].question == "A", "세션: 현재 카드 교체가 입력 배열을 변경하지 않음")

	session.next()
	check(session.current().question == "B", "세션: 교체 후에도 다음 카드는 유지")
	session.next()
	session.replace_current(FlashCard.new("X", "x"))
	check(session.is_finished(), "세션: 종료 후 카드 교체는 종료 상태를 유지")
	check(session.current() == null, "세션: 종료 후 카드 교체는 아무 일도 하지 않음")


func _test_input_array_is_copied() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
	]
	var session := StudySession.new(cards)

	cards.clear()
	check(session.remaining() == 2, "세션: 생성 후 입력 배열 변경의 영향을 받지 않음")
	check(session.current().question == "A", "세션: 복사한 입력 배열의 첫 카드를 유지")
