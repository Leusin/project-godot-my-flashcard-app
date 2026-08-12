extends TestCase

# Phase 2: Markdown 파서와 writer.


func run_tests() -> void:
	_test_empty_text()
	_test_edge_case_fixture()
	_test_duplicate_question_fixture()
	_test_crlf_and_preamble()
	_test_writer()
	_test_sample_deck()


func _test_empty_text() -> void:
	check(DeckParser.parse("").is_empty(), "빈 텍스트는 빈 카드 목록")


func _test_edge_case_fixture() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/cards_edge_cases.md")
	var cards := DeckParser.parse(text)

	check(cards.size() == 3, "경계 fixture: 카드 수는 3")
	if cards.size() != 3:
		return

	check(cards[0].question == "Apple", "경계 fixture: 첫 질문")
	check(cards[0].answer == "사과\n빨간 과일", "경계 fixture: 여러 줄 답")
	check(cards[1].question == "Empty answer", "경계 fixture: 빈 답 질문")
	check(cards[1].answer.is_empty(), "경계 fixture: 빈 답")
	check(cards[2].question == "Last card", "경계 fixture: 마지막 질문")
	check(cards[2].answer == "마지막 답", "경계 fixture: 마지막 답")


func _test_duplicate_question_fixture() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/duplicate_questions.md")
	var cards := DeckParser.parse(text)

	check(cards.size() == 3, "중복 fixture: 중복 질문도 세 장 보존")
	if cards.size() != 3:
		return

	check(cards[0].question == "Same question", "중복 fixture: 첫 질문")
	check(cards[2].question == "Same question", "중복 fixture: 마지막 중복 질문")
	check(cards[2].answer == "두 번째 답", "중복 fixture: 마지막 중복 카드의 답")


func _test_crlf_and_preamble() -> void:
	var cards := DeckParser.parse("무시할 서문\r\n# Question\r\nAnswer\r\n")

	check(cards.size() == 1, "CRLF와 질문 전 서문")
	if cards.size() != 1:
		return

	check(cards[0].question == "Question", "CRLF: 질문 끝의 CR 제거")
	check(cards[0].answer == "Answer", "CRLF: 답 끝의 CR 제거")


func _test_writer() -> void:
	var empty_cards: Array[FlashCard] = []
	check(DeckWriter.to_markdown(empty_cards).is_empty(), "writer: 빈 카드 목록은 빈 텍스트")

	var cards: Array[FlashCard] = [
		FlashCard.new("Apple", "사과\n빨간 과일"),
		FlashCard.new("Empty answer", ""),
	]
	var markdown := DeckWriter.to_markdown(cards)
	var expected := "# Apple\n사과\n빨간 과일\n# Empty answer\n"
	check(markdown == expected, "writer: 여러 줄 답과 빈 답을 Markdown으로 쓴다")
	if markdown != expected:
		return

	var restored := DeckParser.parse(markdown)
	check(restored.size() == 2, "writer/parser: 왕복 후 카드 수")
	if restored.size() != 2:
		return

	check(restored[0].question == "Apple", "writer/parser: 첫 질문 왕복")
	check(restored[0].answer == "사과\n빨간 과일", "writer/parser: 여러 줄 답 왕복")
	check(restored[1].question == "Empty answer", "writer/parser: 빈 답 질문 왕복")
	check(restored[1].answer.is_empty(), "writer/parser: 빈 답 왕복")


func _test_sample_deck() -> void:
	var text := FileAccess.get_file_as_string("res://sample_deck.md")
	var cards := DeckParser.parse(text)

	check(cards.size() == 15, "샘플 덱: 최신 사용법 15장 제공")
	if cards.size() != 15:
		return

	check(
		cards[0].question == "MyFlashCard는 어떤 앱인가요?"
		and cards[3].answer.contains("카드 자체를 탭")
		and cards[5].answer.contains("오른쪽은 GOOD")
		and cards[-1].answer.contains("개인 학습 데이터"),
		"샘플 덱: 탭·스와이프·내보내기 동작을 현재 UX로 안내"
	)
	check(
		not text.contains("「답 보기」 버튼")
		and not text.contains("「다시 시작」"),
		"샘플 덱: 제거된 버튼과 옛 결과 화면 설명 제거"
	)
