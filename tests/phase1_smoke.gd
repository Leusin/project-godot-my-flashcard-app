extends Node


var _failures := 0


func _ready() -> void:
	print("# Phase 1 ready")
	_test_display_name()
	_test_is_deck_file()
	_test_unique_file_name()
	_test_progress_file_name()

	if _failures == 0:
		print("PASS: DeckNaming Phase 1 checks")
		get_tree().quit(0)
	else:
		push_error("FAIL: Phase 1 checks failed: %d" % _failures)
		get_tree().quit(1)


func _test_display_name() -> void:
	_check(DeckNaming.display_name("영어단어.md") == "영어단어", "표시 이름: .md 제거")
	_check(DeckNaming.display_name("Deck.MD") == "Deck", "표시 이름: 대문자 확장자 제거")
	_check(DeckNaming.display_name(" Deck.MD ") == "Deck", "표시 이름: 앞뒤 공백 제거")


func _test_is_deck_file() -> void:
	_check(DeckNaming.is_deck_file("Deck.MD"), "덱 판정: 대문자 확장자 허용")
	_check(DeckNaming.is_deck_file("a.md"), "덱 판정: 정상 Markdown 파일")
	_check(not DeckNaming.is_deck_file(".md"), "덱 판정: 빈 덱 이름 거부")


func _test_unique_file_name() -> void:
	var existing: Array[String] = ["a.md", "a (2).md"]
	_check(
		DeckNaming.unique_file_name("A.MD", existing) == "A (3).md",
		"고유 이름: 대소문자를 무시하고 번호 추가"
	)
	_check(
		DeckNaming.unique_file_name("a.md", existing) == "a (3).md",
		"고유 이름: 기존 번호 다음 값 사용"
	)
	_check(
		DeckNaming.unique_file_name("b.md", existing) == "b.md",
		"고유 이름: 충돌이 없으면 원본 유지"
	)


func _test_progress_file_name() -> void:
	_check(
		DeckNaming.progress_file_name("영어단어.md") == "영어단어.json",
		"진행도 이름: .md를 .json으로 변경"
	)


func _check(condition: bool, name: String) -> void:
	if condition:
		print("PASS: %s" % name)
		return

	_failures += 1
	push_error("FAIL: %s" % name)
