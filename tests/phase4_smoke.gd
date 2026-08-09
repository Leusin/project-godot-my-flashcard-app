extends TestCase

# Phase 4: 사용자 데이터와 분리된 전용 폴더에서 DeckStorage 파일 IO를 검증한다.

const TEST_DECKS_DIR := "user://__gd_phase4_decks"
const TEST_DECK := "__gd_phase4_a.md"
const TEST_TEXT := "# A\n1\n# B\n2\n"
const RENAMED_DECK := "__gd_phase4_renamed.md"
const EXPORTED_PATH := "user://__gd_phase4_export.md"
const INVALID_IMPORT_PATH := "user://__gd_phase4_invalid.txt"


func run_tests() -> void:
	_cleanup()
	DeckStorage.set_decks_dir(TEST_DECKS_DIR)

	_test_paths_and_crud()
	_test_progress_storage()
	_test_import_and_export()
	_test_rename_duplicate_delete()

	_cleanup()
	DeckStorage.set_decks_dir("")
	check(
		DeckStorage.decks_dir() == DeckStorage.DEFAULT_DECKS_DIR,
		"저장소: 빈 경로는 기본 덱 폴더로 복귀"
	)


func _test_paths_and_crud() -> void:
	check(DeckStorage.decks_dir() == TEST_DECKS_DIR, "저장소: 테스트 전용 덱 폴더 설정")
	check(
		DeckStorage.deck_path(TEST_DECK) == "%s/%s" % [TEST_DECKS_DIR, TEST_DECK],
		"저장소: 덱 파일 경로 조합"
	)
	check(DeckStorage.write_deck(TEST_DECK, TEST_TEXT), "저장소: 덱 쓰기 성공")
	check(DeckStorage.deck_exists(TEST_DECK), "저장소: 쓴 덱이 존재")
	check(DeckStorage.read_deck(TEST_DECK) == TEST_TEXT, "저장소: 덱 내용 왕복")
	check(TEST_DECK in DeckStorage.list_deck_files(), "저장소: 덱 목록에 Markdown 파일 표시")
	check(not DeckStorage.deck_exists(""), "저장소: 빈 파일 이름은 존재하지 않음")
	check(not DeckStorage.deck_exists("__없는덱.md"), "저장소: 없는 덱은 존재하지 않음")


func _test_progress_storage() -> void:
	var progress := Progress.new()
	progress.set_wrong_count("A", 2)
	progress.set_status("A", CardStatus.Value.LEARNING)

	check(DeckStorage.save_progress(TEST_DECK, progress), "저장소: 진행도 저장 성공")
	check(
		DeckStorage.progress_path(TEST_DECK) == "user://progress/__gd_phase4_a.json",
		"저장소: 진행도는 덱별 user 경로 사용"
	)
	var restored := DeckStorage.load_progress(TEST_DECK)
	check(
		restored.get_wrong_count("A") == 2
		and restored.get_status("A") == CardStatus.Value.LEARNING,
		"저장소: 진행도 파일 왕복"
	)
	check(
		DeckStorage.load_progress("__없는덱.md").get_wrong_count("A") == 0,
		"저장소: 진행도 파일이 없으면 빈 진행도"
	)


func _test_import_and_export() -> void:
	var imported: Variant = DeckStorage.import_deck(DeckStorage.deck_path(TEST_DECK))
	check(imported == "__gd_phase4_a (2).md", "저장소: 중복 이름 Import에 번호 추가")
	check(
		imported is String and DeckStorage.read_deck(imported) == TEST_TEXT,
		"저장소: Import 내용 보존"
	)
	check(
		DeckStorage.import_deck("user://__gd_phase4_missing.md") == null,
		"저장소: 없는 파일 Import는 null"
	)
	var invalid_import := FileAccess.open(INVALID_IMPORT_PATH, FileAccess.WRITE)
	invalid_import.store_string(TEST_TEXT)
	invalid_import.close()
	check(
		DeckStorage.import_deck(INVALID_IMPORT_PATH) == null,
		"저장소: Markdown이 아닌 파일 Import는 null"
	)

	check(DeckStorage.export_deck(TEST_DECK, EXPORTED_PATH), "저장소: 덱 Export 성공")
	check(FileAccess.get_file_as_string(EXPORTED_PATH) == TEST_TEXT, "저장소: Export 내용 보존")
	check(
		not DeckStorage.export_deck("__없는덱.md", EXPORTED_PATH),
		"저장소: 없는 덱 Export는 false"
	)


func _test_rename_duplicate_delete() -> void:
	check(DeckStorage.rename_deck(TEST_DECK, RENAMED_DECK), "저장소: 덱 이름 변경 성공")
	check(not DeckStorage.deck_exists(TEST_DECK), "저장소: 이름 변경 후 옛 덱 제거")
	check(DeckStorage.deck_exists(RENAMED_DECK), "저장소: 이름 변경 후 새 덱 존재")
	check(
		DeckStorage.load_progress(RENAMED_DECK).get_wrong_count("A") == 2,
		"저장소: 이름 변경 시 진행도 이동"
	)
	check(
		DeckStorage.load_progress(TEST_DECK).get_wrong_count("A") == 0,
		"저장소: 이름 변경 후 옛 진행도 제거"
	)

	var duplicated: Variant = DeckStorage.duplicate_deck(RENAMED_DECK)
	check(duplicated == "__gd_phase4_renamed (2).md", "저장소: 덱 복제 이름 생성")
	check(
		duplicated is String and DeckStorage.read_deck(duplicated) == TEST_TEXT,
		"저장소: 복제한 덱 내용 보존"
	)
	check(
		duplicated is String
		and DeckStorage.load_progress(duplicated).get_wrong_count("A") == 2,
		"저장소: 덱 복제 시 진행도 복사"
	)
	check(DeckStorage.duplicate_deck("__없는덱.md") == null, "저장소: 없는 덱 복제는 null")

	if duplicated is String:
		check(DeckStorage.delete_deck(duplicated), "저장소: 덱 삭제 성공")
		check(not DeckStorage.deck_exists(duplicated), "저장소: 삭제한 덱 파일 제거")
		check(
			not FileAccess.file_exists(DeckStorage.progress_path(duplicated)),
			"저장소: 덱 삭제 시 진행도 제거"
		)
	check(not DeckStorage.delete_deck("__없는덱.md"), "저장소: 없는 덱 삭제는 false")


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(TEST_DECKS_DIR):
		for file_name in DirAccess.get_files_at(TEST_DECKS_DIR):
			DirAccess.remove_absolute("%s/%s" % [TEST_DECKS_DIR, file_name])
		DirAccess.remove_absolute(TEST_DECKS_DIR)

	for deck_file in [
		TEST_DECK,
		"__gd_phase4_a (2).md",
		RENAMED_DECK,
		"__gd_phase4_renamed (2).md",
	]:
		var path := DeckStorage.progress_path(deck_file)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	if FileAccess.file_exists(EXPORTED_PATH):
		DirAccess.remove_absolute(EXPORTED_PATH)
	if FileAccess.file_exists(INVALID_IMPORT_PATH):
		DirAccess.remove_absolute(INVALID_IMPORT_PATH)
