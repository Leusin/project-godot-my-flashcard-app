extends TestCase

# Phase 1: 데이터 모델과 덱 이름 규칙(DeckNaming).


func run_tests() -> void:
	_test_display_name()
	_test_is_deck_file()
	_test_unique_file_name()
	_test_progress_file_name()


func _test_display_name() -> void:
	check(DeckNaming.display_name("영어단어.md") == "영어단어", "표시 이름: .md 제거")
	check(DeckNaming.display_name("Deck.MD") == "Deck", "표시 이름: 대문자 확장자 제거")
	check(DeckNaming.display_name(" Deck.MD ") == "Deck", "표시 이름: 앞뒤 공백 제거")


func _test_is_deck_file() -> void:
	check(DeckNaming.is_deck_file("Deck.MD"), "덱 판정: 대문자 확장자 허용")
	check(DeckNaming.is_deck_file("a.md"), "덱 판정: 정상 Markdown 파일")
	check(not DeckNaming.is_deck_file(".md"), "덱 판정: 빈 덱 이름 거부")


func _test_unique_file_name() -> void:
	var existing: Array[String] = ["a.md", "a (2).md"]
	check(
		DeckNaming.unique_file_name("A.MD", existing) == "A (3).md",
		"고유 이름: 대소문자를 무시하고 번호 추가"
	)
	check(
		DeckNaming.unique_file_name("a.md", existing) == "a (3).md",
		"고유 이름: 기존 번호 다음 값 사용"
	)
	check(
		DeckNaming.unique_file_name("b.md", existing) == "b.md",
		"고유 이름: 충돌이 없으면 원본 유지"
	)


func _test_progress_file_name() -> void:
	check(
		DeckNaming.progress_file_name("영어단어.md") == "영어단어.json",
		"진행도 이름: .md를 .json으로 변경"
	)
