extends TestCase

# Phase 4: 사용자 데이터와 분리된 전용 폴더에서 DeckStorage 파일 IO를 검증한다.

const TEST_DECKS_DIR := "user://__gd_phase4_decks"
const TEST_DECK := "__gd_phase4_a.md"
const TEST_TEXT := "# A\n1\n# B\n2\n"
const WORKSPACE_DECK := "__gd_phase4_workspace.md"
const WORKSPACE_TEXT := "# Alpha\nOne\n# Beta\nTwo\n"
const RENAMED_DECK := "__gd_phase4_renamed.md"
const EXPORTED_PATH := "user://__gd_phase4_export.md"
const INVALID_IMPORT_PATH := "user://__gd_phase4_invalid.txt"
const BACKUP_PATH := "user://__gd_phase4_backup.zip"
const INVALID_BACKUP_PATH := "user://__gd_phase4_invalid_backup.zip"
const LEGACY_SAMPLE_TEXT := """# MyFlashCard는 어떤 앱인가요?
Markdown 파일로 만든 카드를 한 장씩 복습하는 간단한 플래시카드 앱입니다.

# 카드는 어디에 저장되나요?
질문과 답은 평범한 .md 파일에 저장됩니다. 특정 앱에 갇히지 않고 텍스트 편집기로도 열 수 있습니다.

# 답은 어떻게 확인하나요?
질문을 먼저 떠올린 다음 「답 보기」 버튼을 누르면 답이 나타납니다.

# Again은 언제 누르나요?
답을 모르거나 헷갈렸을 때 누릅니다. 해당 질문의 오답 횟수가 1 증가합니다.

# Good은 언제 누르나요?
답을 제대로 떠올렸을 때 누릅니다. 오답 횟수를 늘리지 않고 다음 카드로 넘어갑니다.

# 한 덱을 끝내면 어떻게 되나요?
학습 완료 화면이 나타납니다. 「다시 시작」을 누르면 같은 덱을 처음부터 복습할 수 있습니다."""


func run_tests() -> void:
	_cleanup()
	DeckStorage.set_decks_dir(TEST_DECKS_DIR)

	_test_paths_and_crud()
	_test_progress_storage()
	_test_study_resume_storage()
	_test_card_workspace()
	_test_full_backup_restore()
	_test_import_and_export()
	_test_rename_duplicate_delete()
	_test_sample_upgrade_detection()

	_cleanup()
	DeckStorage.set_decks_dir("")
	check(
		DeckStorage.decks_dir() == DeckStorage.DEFAULT_DECKS_DIR,
		"저장소: 빈 경로는 기본 덱 폴더로 복귀"
	)


func _test_sample_upgrade_detection() -> void:
	check(
		DeckStorage.is_legacy_sample_text(LEGACY_SAMPLE_TEXT),
		"저장소: 손대지 않은 옛 샘플 덱 감지"
	)
	check(
		not DeckStorage.is_legacy_sample_text(LEGACY_SAMPLE_TEXT + "\n사용자 수정"),
		"저장소: 사용자가 수정한 샘플 덱은 갱신 대상에서 제외"
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
		DeckStorage.export_deck_result(TEST_DECK, EXPORTED_PATH)
		== DeckStorage.ExportResult.OK,
		"저장소: Export 성공 원인을 구분"
	)


func _test_full_backup_restore() -> void:
	check(
		AppBackup.create_backup(BACKUP_PATH) == AppBackup.Result.OK,
		"백업: 전체 앱 데이터를 ZIP으로 생성"
	)
	var reader := ZIPReader.new()
	var backup_entries: PackedStringArray = []
	if reader.open(BACKUP_PATH) == OK:
		backup_entries = reader.get_files()
		reader.close()
	check(
		"manifest.json" in backup_entries
		and "decks/%s" % TEST_DECK in backup_entries
		and "progress/__gd_phase4_a.json" in backup_entries
		and "study_resume/__gd_phase4_a.json" in backup_entries,
		"백업: 덱·진행도·이어하기와 manifest 포함"
	)

	DeckStorage.write_deck(TEST_DECK, "# 변경됨\n임시 데이터\n")
	var changed_progress := Progress.new()
	changed_progress.set_wrong_count("A", 99)
	DeckStorage.save_progress(TEST_DECK, changed_progress)
	check(
		AppBackup.restore_backup(BACKUP_PATH) == AppBackup.Result.OK,
		"백업: 검증된 ZIP에서 전체 데이터 복원"
	)
	check(
		DeckStorage.read_deck(TEST_DECK) == TEST_TEXT
		and DeckStorage.load_progress(TEST_DECK).get_wrong_count("A") == 2
		and DeckStorage.load_study_resume(TEST_DECK) != null,
		"백업: 복원 후 덱·진행도·이어하기 원본 보존"
	)

	var invalid := FileAccess.open(INVALID_BACKUP_PATH, FileAccess.WRITE)
	invalid.store_string("not a zip")
	invalid.close()
	check(
		AppBackup.restore_backup(INVALID_BACKUP_PATH) == AppBackup.Result.INVALID_ARCHIVE
		and DeckStorage.read_deck(TEST_DECK) == TEST_TEXT,
		"백업: 잘못된 ZIP은 현재 데이터를 건드리지 않고 거부"
	)


func _test_study_resume_storage() -> void:
	var resume := StudyResume.new()
	resume.deck_hash = 12345
	resume.remaining_indices = [1, 0]
	resume.order = DeckOrdering.StudyOrder.SHUFFLE
	resume.scope = 2
	check(DeckStorage.save_study_resume(TEST_DECK, resume), "저장소: 이어서 학습 세션 저장")
	check(
		DeckStorage.study_resume_path(TEST_DECK)
		== "user://study_resume/__gd_phase4_a.json",
		"저장소: 이어서 학습 세션은 덱별 user 경로 사용"
	)
	var restored := DeckStorage.load_study_resume(TEST_DECK)
	check(
		restored != null
		and restored.deck_hash == 12345
		and restored.remaining_indices == [1, 0]
		and restored.order == DeckOrdering.StudyOrder.SHUFFLE
		and restored.scope == 2,
		"저장소: 이어서 학습 세션 왕복"
	)
	check(StudyResume.from_json("깨진 JSON") == null, "저장소: 깨진 이어서 학습 세션 거부")
	check(
		not DeckStorage.export_deck("__없는덱.md", EXPORTED_PATH),
		"저장소: 없는 덱 Export는 false"
	)
	check(
		DeckStorage.export_deck_result("__없는덱.md", EXPORTED_PATH)
		== DeckStorage.ExportResult.DECK_NOT_FOUND,
		"저장소: 없는 덱 Export 오류를 구분"
	)
	check(
		DeckStorage.export_deck_result(
			TEST_DECK,
			"user://__gd_phase4_missing_dir/export.md"
		) == DeckStorage.ExportResult.TARGET_OPEN_FAILED,
		"저장소: 저장 위치 열기 오류를 구분"
	)


func _test_card_workspace() -> void:
	check(
		DeckStorage.write_deck(WORKSPACE_DECK, WORKSPACE_TEXT),
		"카드 작업공간: 전용 덱 준비"
	)
	var initial_progress := Progress.new()
	initial_progress.set_wrong_count("Alpha", 3)
	initial_progress.set_status("Alpha", CardStatus.Value.LEARNING)
	initial_progress.set_favorite("Alpha", true)
	DeckStorage.save_progress(WORKSPACE_DECK, initial_progress)
	var initial_resume := StudyResume.new()
	initial_resume.deck_hash = WORKSPACE_TEXT.hash()
	initial_resume.remaining_indices = [0, 1]
	DeckStorage.save_study_resume(WORKSPACE_DECK, initial_resume)

	var workspace := CardWorkspace.new()
	check(
		workspace.open(WORKSPACE_DECK)
		and workspace.cards.size() == 2
		and workspace.cards[0].question == "Alpha",
		"카드 작업공간: 덱 스냅샷 열기"
	)
	check(
		workspace.move_card(0, 1) == CardWorkspace.MoveResult.SAVED
		and workspace.cards[0].question == "Beta"
		and DeckParser.parse(
			DeckStorage.read_deck(WORKSPACE_DECK)
		)[1].question == "Alpha",
		"카드 작업공간: 카드 순서 저장"
	)
	check(
		DeckStorage.load_study_resume(WORKSPACE_DECK) == null,
		"카드 작업공간: 순서 변경 시 이어하기 제거"
	)

	var edit_resume := StudyResume.new()
	edit_resume.deck_hash = 2
	edit_resume.remaining_indices = [1]
	DeckStorage.save_study_resume(WORKSPACE_DECK, edit_resume)
	workspace.select(1)
	var edit_result := workspace.save_card(
		"Alpha 2",
		"Updated",
		4,
		CardStatus.Value.MASTERED,
		true
	)
	var edited_progress := DeckStorage.load_progress(WORKSPACE_DECK)
	check(
		edit_result.succeeded
		and edit_result.progress_saved
		and edit_result.card.question == "Alpha 2"
		and edit_result.card_index == 1,
		"카드 작업공간: 편집 결과 반환"
	)
	check(
		edited_progress.get_wrong_count("Alpha") == 0
		and edited_progress.get_wrong_count("Alpha 2") == 4
		and edited_progress.get_status("Alpha 2") == CardStatus.Value.MASTERED
		and edited_progress.is_favorite("Alpha 2"),
		"카드 작업공간: 질문 변경 시 진행도 이동"
	)
	check(
		DeckStorage.load_study_resume(WORKSPACE_DECK) == null,
		"카드 작업공간: 일반 편집 시 이어하기 제거"
	)

	workspace.select(-1)
	var add_result := workspace.save_card(
		"Gamma",
		"Three",
		0,
		CardStatus.Value.NEW,
		true
	)
	check(
		add_result.succeeded
		and workspace.cards.size() == 3
		and workspace.cards[2].question == "Gamma",
		"카드 작업공간: 새 카드 추가"
	)

	var study_resume := StudyResume.new()
	study_resume.deck_hash = 3
	study_resume.remaining_indices = [0]
	DeckStorage.save_study_resume(WORKSPACE_DECK, study_resume)
	workspace.select(0)
	var study_edit_result := workspace.save_card(
		"Beta",
		"Two updated",
		0,
		CardStatus.Value.NEW,
		false
	)
	check(
		study_edit_result.succeeded
		and DeckStorage.load_study_resume(WORKSPACE_DECK) != null,
		"카드 작업공간: 학습 중 편집은 이어하기 유지"
	)

	workspace.select(1)
	var delete_result := workspace.delete_selected()
	check(
		delete_result.succeeded
		and delete_result.progress_saved
		and workspace.cards.size() == 2
		and workspace.editing_index == -1,
		"카드 작업공간: 선택 카드 삭제"
	)
	var deleted_progress := DeckStorage.load_progress(WORKSPACE_DECK)
	check(
		deleted_progress.get_wrong_count("Alpha 2") == 0
		and not deleted_progress.is_favorite("Alpha 2")
		and DeckStorage.load_study_resume(WORKSPACE_DECK) == null,
		"카드 작업공간: 삭제한 카드의 진행도와 이어하기 정리"
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
	check(
		DeckStorage.load_study_resume(RENAMED_DECK) != null
		and DeckStorage.load_study_resume(TEST_DECK) == null,
		"저장소: 이름 변경 시 이어서 학습 세션 이동"
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
	check(
		duplicated is String and DeckStorage.load_study_resume(duplicated) == null,
		"저장소: 덱 복제 시 진행 중 세션은 복사하지 않음"
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
		WORKSPACE_DECK,
		RENAMED_DECK,
		"__gd_phase4_renamed (2).md",
	]:
		var path := DeckStorage.progress_path(deck_file)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		var resume_path := DeckStorage.study_resume_path(deck_file)
		if FileAccess.file_exists(resume_path):
			DirAccess.remove_absolute(resume_path)

	if FileAccess.file_exists(EXPORTED_PATH):
		DirAccess.remove_absolute(EXPORTED_PATH)
	if FileAccess.file_exists(INVALID_IMPORT_PATH):
		DirAccess.remove_absolute(INVALID_IMPORT_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
	if FileAccess.file_exists(INVALID_BACKUP_PATH):
		DirAccess.remove_absolute(INVALID_BACKUP_PATH)
