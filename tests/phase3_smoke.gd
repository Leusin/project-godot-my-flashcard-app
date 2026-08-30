extends TestCase

# Phase 3: 학습 세션 큐와 덱 순서 규칙(StudySession, DeckOrdering).


func run_tests() -> void:
	_test_queue_progression()
	_test_single_and_empty_decks()
	_test_replace_current()
	_test_input_array_is_copied()
	_test_sequential_ordering()
	_test_shuffle_ordering()
	_test_app_settings_round_trip()
	_test_app_settings_defaults()
	_test_progress_wrong_count()
	_test_progress_status()
	_test_progress_favorite()
	_test_progress_remove()
	_test_progress_rename()
	_test_progress_json()
	_test_progress_fixtures()
	_test_card_ordering()
	_test_deck_library_order()
	_test_study_plan()
	_test_back_navigation()


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
	check(not session.previous(), "세션: 첫 카드에서는 이전으로 이동하지 않음")

	session.next()
	check(session.current().question == "B", "세션: next 후 다음 카드로 이동")
	check(session.remaining() == 2, "세션: next 후 남은 카드 수 감소")
	check(session.previous(), "세션: 진행한 뒤 이전 카드로 이동 가능")
	check(
		session.current().question == "A" and session.remaining() == 3,
		"세션: previous 후 이전 카드와 남은 수 복구"
	)

	session.next()
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


func _test_sequential_ordering() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
	]
	var ordered := DeckOrdering.apply(DeckOrdering.StudyOrder.SEQUENTIAL, cards)

	check(
		ordered.size() == 3
		and ordered[0].question == "A"
		and ordered[1].question == "B"
		and ordered[2].question == "C",
		"순서: Sequential은 입력 순서를 유지"
	)

	ordered.clear()
	check(
		cards.size() == 3
		and cards[0].question == "A"
		and cards[1].question == "B"
		and cards[2].question == "C",
		"순서: Sequential 결과를 변경해도 원본 배열은 유지"
	)


func _test_shuffle_ordering() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
		FlashCard.new("D", "4"),
		FlashCard.new("E", "5"),
	]
	var shuffled := DeckOrdering.apply(DeckOrdering.StudyOrder.SHUFFLE, cards)
	var questions: Array[String] = []
	for card in shuffled:
		questions.append(card.question)

	check(shuffled.size() == cards.size(), "순서: Shuffle도 카드 수를 유지")
	questions.sort()
	check(questions == ["A", "B", "C", "D", "E"], "순서: Shuffle은 카드를 잃지 않음")
	check(
		cards[0].question == "A" and cards[4].question == "E",
		"순서: Shuffle이 원본 배열을 변경하지 않음"
	)

	var empty_cards: Array[FlashCard] = []
	check(
		DeckOrdering.apply(DeckOrdering.StudyOrder.SHUFFLE, empty_cards).is_empty(),
		"순서: 빈 덱 Shuffle은 빈 배열"
	)

func _test_app_settings_round_trip() -> void:
	var settings := AppSettings.new()
	settings.last_deck_file = "영어단어.md"
	settings.deck_dir = "user://test-decks"
	settings.shuffle_study = true
	settings.haptics_enabled = false

	var restored := AppSettings.from_json(settings.to_json())

	check(
		restored.last_deck_file == "영어단어.md",
		"설정: 마지막 덱 직렬화 왕복"
	)
	check(
		restored.deck_dir == "user://test-decks",
		"설정: 덱 폴더 직렬화 왕복"
	)
	check(
		restored.shuffle_study,
		"설정: 학습 순서 직렬화 왕복"
	)
	check(
		not restored.haptics_enabled,
		"설정: 햅틱 사용 여부 직렬화 왕복"
	)


func _test_app_settings_defaults() -> void:
	var empty := AppSettings.from_json("")

	check(
		empty.last_deck_file.is_empty(),
		"설정: 빈 JSON의 마지막 덱 기본값"
	)
	check(
		empty.deck_dir.is_empty(),
		"설정: 빈 JSON의 덱 폴더 기본값"
	)
	check(
		not empty.shuffle_study,
		"설정: 학습 순서 기본값은 Sequential"
	)
	check(
		empty.haptics_enabled,
		"설정: 햅틱은 기본으로 사용"
	)

	var malformed := AppSettings.from_json("{깨진 json")
	check(
		malformed.last_deck_file.is_empty()
		and malformed.deck_dir.is_empty()
		and not malformed.shuffle_study
		and malformed.haptics_enabled,
		"설정: 깨진 JSON은 모든 값을 기본값으로 복구"
	)

func _test_progress_wrong_count() -> void:
	var progress := Progress.new()

	check(
		progress.get_wrong_count("없는 질문") == 0,
		"진행도: 기록이 없는 질문은 0"
	)

	progress.add_wrong("Apple")
	progress.add_wrong("Apple")
	progress.add_wrong("Red")

	check(
		progress.get_wrong_count("Apple") == 2,
		"진행도: 같은 질문의 오답 횟수 누적"
	)
	check(
		progress.get_wrong_count("Red") == 1,
		"진행도: 질문별 오답 횟수 독립"
	)

	progress.set_wrong_count("Apple", 7)

	check(
		progress.get_wrong_count("Apple") == 7,
		"진행도: 오답 횟수 직접 수정"
	)

	progress.set_wrong_count("Apple", 0)
	check(
		progress.get_wrong_count("Apple") == 0,
		"진행도: 오답 횟수 0이면 기록 제거"
	)

	progress.set_wrong_count("Red", -1)
	check(
		progress.get_wrong_count("Red") == 0,
		"진행도: 음수 오답 횟수는 기록 제거"
	)

func _test_progress_status() -> void:
	var progress := Progress.new()

	check(
		progress.get_status("Apple") == CardStatus.Value.NEW,
		"진행도: 상태 기록이 없으면 NEW"
	)

	progress.set_status("Apple", CardStatus.Value.LEARNING)
	check(
		progress.get_status("Apple") == CardStatus.Value.LEARNING,
		"진행도: 상태를 LEARNING으로 변경"
	)

	progress.set_status("Apple", CardStatus.Value.MASTERED)
	check(
		progress.get_status("Apple") == CardStatus.Value.MASTERED,
		"진행도: 상태를 MASTERED로 변경"
	)

	progress.set_status("Apple", CardStatus.Value.NEW)
	check(
		progress.get_status("Apple") == CardStatus.Value.NEW,
		"진행도: NEW로 변경하면 상태 기록 제거"
	)


func _test_progress_favorite() -> void:
	var progress := Progress.new()
	check(not progress.is_favorite("Apple"), "진행도: 기록이 없으면 즐겨찾기 아님")
	progress.set_favorite("Apple", true)
	check(progress.is_favorite("Apple"), "진행도: 카드 즐겨찾기 설정")
	progress.set_favorite("Apple", false)
	check(not progress.is_favorite("Apple"), "진행도: 카드 즐겨찾기 해제")


func _test_progress_remove() -> void:
	var progress := Progress.new()
	progress.set_wrong_count("Apple", 5)
	progress.set_status("Apple", CardStatus.Value.LEARNING)
	progress.set_favorite("Apple", true)

	progress.remove("Apple")

	check(
		progress.get_wrong_count("Apple") == 0,
		"진행도: remove가 오답 횟수를 제거"
	)
	check(
		progress.get_status("Apple") == CardStatus.Value.NEW,
		"진행도: remove가 카드 상태를 제거"
	)
	check(not progress.is_favorite("Apple"), "진행도: remove가 즐겨찾기를 제거")

	progress.remove("없는 질문")
	check(
		progress.get_wrong_count("없는 질문") == 0,
		"진행도: 없는 질문 제거는 아무 일도 하지 않음"
	)


func _test_progress_rename() -> void:
	var moved := Progress.new()
	moved.set_wrong_count("A", 2)
	moved.set_status("A", CardStatus.Value.LEARNING)
	moved.set_favorite("A", true)
	moved.set_status("B", CardStatus.Value.MASTERED)
	moved.rename("A", "B")

	check(moved.get_wrong_count("B") == 2, "진행도 이사: 오답 횟수가 새 질문으로 이동")
	check(moved.get_wrong_count("A") == 0, "진행도 이사: 옛 질문의 오답 기록 제거")
	check(
		moved.get_status("B") == CardStatus.Value.LEARNING,
		"진행도 이사: 이동한 카드 상태로 목적지 상태 덮어쓰기"
	)
	check(
		moved.get_status("A") == CardStatus.Value.NEW,
		"진행도 이사: 옛 질문의 상태 기록 제거"
	)
	check(
		moved.is_favorite("B") and not moved.is_favorite("A"),
		"진행도 이사: 즐겨찾기를 새 질문으로 이동"
	)

	var merged := Progress.new()
	merged.set_wrong_count("A", 2)
	merged.set_wrong_count("B", 1)
	merged.rename("A", "B")
	check(merged.get_wrong_count("B") == 3, "진행도 이사: 목적지 오답 횟수와 병합")

	var same := Progress.new()
	same.set_wrong_count("A", 1)
	same.rename("A", "A")
	check(same.get_wrong_count("A") == 1, "진행도 이사: 같은 질문이면 아무 일도 하지 않음")

	var absent := Progress.new()
	absent.set_wrong_count("B", 1)
	absent.rename("A", "B")
	check(absent.get_wrong_count("B") == 1, "진행도 이사: 옮길 기록이 없으면 목적지 유지")

	var blank := Progress.new()
	blank.set_wrong_count("A", 1)
	blank.set_status("A", CardStatus.Value.LEARNING)
	blank.rename("A", "")
	check(
		blank.get_wrong_count("A") == 1
		and blank.get_status("A") == CardStatus.Value.LEARNING,
		"진행도 이사: 빈 새 질문이면 기존 기록 유지"
	)


func _test_progress_json() -> void:
	var progress := Progress.new()
	progress.set_wrong_count("Apple", 3)
	progress.set_status("Apple", CardStatus.Value.LEARNING)
	progress.set_status("Banana", CardStatus.Value.MASTERED)
	progress.set_favorite("Banana", true)

	var restored := Progress.from_json(progress.to_json())
	check(
		restored.get_wrong_count("Apple") == 3
		and restored.get_status("Apple") == CardStatus.Value.LEARNING,
		"진행도 JSON: 횟수와 상태 왕복"
	)
	check(
		restored.get_wrong_count("Banana") == 0
		and restored.get_status("Banana") == CardStatus.Value.MASTERED
		and restored.is_favorite("Banana"),
		"진행도 JSON: 상태와 즐겨찾기만 있는 카드 왕복"
	)
	check(Progress.from_json("").get_wrong_count("x") == 0, "진행도 JSON: 빈 값 복구")
	check(
		Progress.from_json("{깨진 json").get_wrong_count("x") == 0,
		"진행도 JSON: 깨진 값 복구"
	)
	check(
		Progress.from_json("[]").get_status("x") == CardStatus.Value.NEW,
		"진행도 JSON: 객체가 아니면 빈 진행도"
	)


func _test_progress_fixtures() -> void:
	var legacy := Progress.from_json(
		FileAccess.get_file_as_string("res://tests/fixtures/progress_legacy.json")
	)
	check(
		legacy.get_wrong_count("Apple") == 3
		and legacy.get_status("Apple") == CardStatus.Value.NEW,
		"진행도 fixture: 옛 숫자 형식 호환"
	)
	check(legacy.get_wrong_count("Zero") == 0, "진행도 fixture: 옛 형식의 0은 기본값")

	var current := Progress.from_json(
		FileAccess.get_file_as_string("res://tests/fixtures/progress_current.json")
	)
	check(
		current.get_wrong_count("Apple") == 3
		and current.get_status("Apple") == CardStatus.Value.LEARNING,
		"진행도 fixture: 현재 형식의 횟수와 상태"
	)
	check(
		current.get_wrong_count("Banana") == 0
		and current.get_status("Banana") == CardStatus.Value.MASTERED,
		"진행도 fixture: 현재 형식의 상태만 복원"
	)

	var malformed := Progress.from_json(
		FileAccess.get_file_as_string("res://tests/fixtures/progress_malformed.json")
	)
	check(
		malformed.get_wrong_count("Apple") == 0
		and malformed.get_status("Apple") == CardStatus.Value.NEW,
		"진행도 fixture: 깨진 JSON은 빈 진행도로 복구"
	)


func _test_card_ordering() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
	]

	var moved_down := CardOrdering.moved(cards, 0, 2)
	check(
		moved_down[0].question == "B"
		and moved_down[1].question == "C"
		and moved_down[2].question == "A",
		"카드 순서: 아래로 옮기면 사이 카드가 앞으로 당겨진다"
	)

	var moved_up := CardOrdering.moved(cards, 2, 0)
	check(
		moved_up[0].question == "C"
		and moved_up[1].question == "A"
		and moved_up[2].question == "B",
		"카드 순서: 위로 옮기면 사이 카드가 뒤로 밀린다"
	)

	check(
		cards[0].question == "A" and cards[2].question == "C",
		"카드 순서: 원본 배열은 그대로 둔다"
	)
	check(
		CardOrdering.moved(cards, 1, 1)[1].question == "B",
		"카드 순서: 같은 자리로 옮기면 그대로"
	)
	check(
		CardOrdering.moved(cards, 0, 99)[2].question == "A",
		"카드 순서: 범위를 넘는 목적지는 끝으로 붙인다"
	)
	check(
		CardOrdering.moved(cards, 5, 0).size() == 3
		and CardOrdering.moved(cards, 5, 0)[0].question == "A",
		"카드 순서: 없는 카드를 옮기면 아무 일도 없다"
	)


func _test_deck_library_order() -> void:
	var stored: Array[String] = ["b.md", "a.md"]
	var files: Array[String] = ["a.md", "b.md"]
	check(
		DeckLibraryOrder.apply(stored, files) == ["b.md", "a.md"],
		"덱 차례: 저장된 순서를 그대로 따른다"
	)

	var with_new: Array[String] = ["a.md", "b.md", "새덱.md"]
	check(
		DeckLibraryOrder.apply(stored, with_new) == ["새덱.md", "b.md", "a.md"],
		"덱 차례: 차례에 없는 새 덱은 맨 앞에 온다"
	)

	var removed: Array[String] = ["a.md"]
	check(
		DeckLibraryOrder.apply(stored, removed) == ["a.md"],
		"덱 차례: 사라진 덱은 차례에서 빠진다"
	)

	var duplicated_order: Array[String] = ["a.md", "a.md", "b.md"]
	check(
		DeckLibraryOrder.apply(duplicated_order, files) == ["a.md", "b.md"],
		"덱 차례: 차례에 중복이 있어도 한 번만 놓는다"
	)

	check(
		DeckLibraryOrder.apply([], files) == ["a.md", "b.md"],
		"덱 차례: 저장된 차례가 없으면 받은 목록 그대로"
	)

	check(
		DeckLibraryOrder.moved(stored, 0, 1) == ["a.md", "b.md"]
		and DeckLibraryOrder.moved(stored, 1, 0) == ["a.md", "b.md"]
		and stored == ["b.md", "a.md"],
		"덱 차례: 자리를 옮겨도 원본 배열은 그대로 둔다"
	)

	var settings := AppSettings.new()
	settings.deck_order = ["b.md", "a.md"]
	check(
		AppSettings.from_json(settings.to_json()).deck_order == ["b.md", "a.md"],
		"설정: 덱 차례 직렬화 왕복"
	)
	check(
		AppSettings.from_json("{}").deck_order.is_empty(),
		"설정: 덱 차례 기본값은 빈 목록"
	)


func _test_study_plan() -> void:
	var source: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
	]
	var plan := StudyPlan.new()
	plan.prepare("deck.md", source, 42)
	source[0].question = "changed outside"
	check(
		plan.deck_file == "deck.md"
		and plan.deck_hash == 42
		and plan.cards[0].question == "A",
		"학습 계획: 준비 덱과 카드를 독립적으로 보관"
	)

	var progress := Progress.new()
	progress.set_status("B", CardStatus.Value.MASTERED)
	progress.set_status("C", CardStatus.Value.LEARNING)
	progress.add_wrong("C")
	var summary := plan.summary(progress)
	check(
		summary.total_count == 3
		and summary.new_count == 1
		and summary.learning_count == 1
		and summary.mastered_count == 1,
		"학습 계획: 카드 상태별 준비 화면 요약"
	)
	check(
		plan.indices_for_scope(progress, StudyPlan.Scope.INCOMPLETE) == [0, 2]
		and plan.indices_for_scope(progress, StudyPlan.Scope.WRONG) == [2],
		"학습 계획: 미완료와 오답 범위를 원본 index로 선택"
	)

	var resume := StudyResume.new()
	resume.deck_hash = 42
	resume.remaining_indices = [1, 2]
	check(plan.is_valid_resume(resume), "학습 계획: 현재 덱의 이어하기 기록 허용")
	resume.remaining_indices = [3]
	check(not plan.is_valid_resume(resume), "학습 계획: 범위 밖 이어하기 index 거부")

	var selected := plan.begin(
		[2, 0],
		DeckOrdering.StudyOrder.SEQUENTIAL,
		StudyPlan.Scope.WRONG,
		false
	)
	check(
		selected.size() == 2
		and selected[0].question == "C"
		and selected[1].question == "A"
		and plan.active_index_at(0) == 2,
		"학습 계획: 선택 index 순서로 활성 카드 구성"
	)
	var saved_resume := plan.make_resume(1)
	check(
		saved_resume.deck_hash == 42
		and saved_resume.remaining_indices == [0]
		and saved_resume.scope == StudyPlan.Scope.WRONG,
		"학습 계획: 현재 위치부터 이어하기 기록 생성"
	)
	check(
		plan.begin(
			[99],
			DeckOrdering.StudyOrder.SEQUENTIAL,
			StudyPlan.Scope.ALL,
			false
		).is_empty()
		and plan.active_indices.is_empty(),
		"학습 계획: 범위 밖 활성 index를 안전하게 거부"
	)

	var replacement: Array[FlashCard] = [FlashCard.new("New", "Answer")]
	plan.replace_cards("renamed.md", replacement, 99)
	replacement[0].question = "changed again"
	check(
		plan.deck_file == "renamed.md"
		and plan.cards[0].question == "New"
		and plan.deck_hash == 99,
		"학습 계획: 편집된 덱 snapshot 교체"
	)
	plan.clear()
	check(
		plan.deck_file.is_empty()
		and plan.cards.is_empty()
		and plan.active_indices.is_empty(),
		"학습 계획: 준비·활성 상태 초기화"
	)


func _test_back_navigation() -> void:
	var priority: Array[int] = []
	priority.assign(BackNavigation.PRIORITY)
	var unique_actions: Dictionary[int, bool] = {}
	for action in priority:
		unique_actions[action] = true
	check(
		unique_actions.size() == priority.size()
		and not unique_actions.has(BackNavigation.Action.RETURN_TO_STUDY_READY),
		"뒤로가기: 우선순위 action은 중복 없이 fallback과 분리"
	)

	var individual_routes_resolve := true
	for action in priority:
		var active: Dictionary = {}
		active[action] = true
		if BackNavigation.resolve(active) != action:
			individual_routes_resolve = false
			break
	check(
		individual_routes_resolve,
		"뒤로가기: 각 활성 route를 대응 action으로 결정"
	)

	var adjacent_priority_is_stable := true
	for index in range(priority.size() - 1):
		var active: Dictionary = {}
		active[priority[index]] = true
		active[priority[index + 1]] = true
		if BackNavigation.resolve(active) != priority[index]:
			adjacent_priority_is_stable = false
			break
	check(
		adjacent_priority_is_stable,
		"뒤로가기: modal·popup·page 우선순서 유지"
	)

	var all_active: Dictionary = {}
	for action in priority:
		all_active[action] = true
	check(
		BackNavigation.resolve(all_active) == priority[0],
		"뒤로가기: 여러 UI가 겹치면 최상위 modal 하나만 선택"
	)
	check(
		BackNavigation.resolve({})
		== BackNavigation.Action.RETURN_TO_STUDY_READY,
		"뒤로가기: 알려진 UI가 없으면 학습 준비 화면으로 복귀"
	)
