class_name DeckActionService
extends RefCounted

# 덱 단위 작업의 검증과 저장을 한곳에서 수행한다.
# dialog 표시, 화면 전환, 목록 갱신은 MainApp이 맡는다.

const EMPTY_DECK_MESSAGE := "빈 덱입니다. '# 질문' 형식으로 카드를 추가하세요."
const BROKEN_DECK_MESSAGE := "카드를 찾지 못했습니다. 각 질문을 '# 질문' 형식으로 작성하세요."
const EXPORT_DECK_NOT_FOUND_MESSAGE := "내보낼 덱 파일을 찾을 수 없습니다."
const EXPORT_TARGET_OPEN_FAILED_MESSAGE := "선택한 위치에 파일을 만들 수 없습니다. 저장 권한이나 위치를 확인하세요."
const EXPORT_WRITE_FAILED_MESSAGE := "파일을 저장하지 못했습니다. 저장 공간을 확인하고 다시 시도하세요."
const EXPORT_UNKNOWN_FAILED_MESSAGE := "덱을 내보내지 못했습니다. 다른 위치를 선택해 다시 시도하세요."
const DELETE_DECK_NOT_FOUND_MESSAGE := "삭제할 덱 파일을 찾을 수 없습니다."
const DELETE_DECK_FAILED_MESSAGE := "덱을 삭제하지 못했습니다. 파일이 사용 중인지 확인하고 다시 시도하세요."
const DECK_NAME_EMPTY_MESSAGE := "덱 이름을 입력하세요."
const DECK_NAME_INVALID_MESSAGE := "덱 이름에 < > : \" / \\ | ? * 문자나 끝 마침표를 사용할 수 없습니다."
const DECK_NAME_DUPLICATE_MESSAGE := "같은 이름의 덱이 이미 있습니다."
const RENAME_DECK_NOT_FOUND_MESSAGE := "이름을 변경할 덱 파일을 찾을 수 없습니다."
const RENAME_FAILED_MESSAGE := "덱 이름을 변경하지 못했습니다. 다시 시도하세요."
const DUPLICATE_DECK_NOT_FOUND_MESSAGE := "복제할 덱 파일을 찾을 수 없습니다."
const DUPLICATE_DECK_FAILED_MESSAGE := "덱을 복제하지 못했습니다. 저장 공간을 확인하고 다시 시도하세요."
const CREATE_DECK_SAVE_FAILED_MESSAGE := "덱을 저장하지 못했습니다. 저장 공간을 확인하세요."
const CLIPBOARD_EMPTY_MESSAGE := "클립보드에 Markdown 텍스트가 없습니다."
const CLIPBOARD_BROKEN_MESSAGE := "클립보드에서 카드를 찾지 못했습니다. 각 질문을 '# 질문' 형식으로 작성하세요."
const IMPORT_FAILED_MESSAGE := "덱을 가져오지 못했습니다."


static func validate_new_deck_file(display_name: String) -> DeckActionResult:
	var trimmed_name := display_name.strip_edges()
	if trimmed_name.is_empty():
		return DeckActionResult.rejected(DECK_NAME_EMPTY_MESSAGE)
	if not DeckNaming.is_valid_display_name(trimmed_name):
		return DeckActionResult.rejected(DECK_NAME_INVALID_MESSAGE)

	var deck_file := DeckNaming.deck_file_name(trimmed_name)
	if is_deck_file_taken(deck_file):
		return DeckActionResult.rejected(DECK_NAME_DUPLICATE_MESSAGE)
	return DeckActionResult.completed("", deck_file, "", false)


static func create_from_markdown(
	display_name: String,
	markdown_text: String
) -> DeckActionResult:
	var content_error := clipboard_content_error(markdown_text)
	if not content_error.is_empty():
		return DeckActionResult.rejected(content_error)

	var name_result := validate_new_deck_file(display_name)
	if not name_result.succeeded:
		return name_result
	if not DeckStorage.write_deck(name_result.deck_file, markdown_text):
		return DeckActionResult.rejected(CREATE_DECK_SAVE_FAILED_MESSAGE)
	return DeckActionResult.completed("", name_result.deck_file)


static func duplicate_deck(deck_file: String) -> DeckActionResult:
	if not DeckStorage.deck_exists(deck_file):
		return DeckActionResult.rejected(DUPLICATE_DECK_NOT_FOUND_MESSAGE)

	var duplicated: Variant = DeckStorage.duplicate_deck(deck_file)
	if duplicated is not String:
		push_warning("Deck duplicate failed (source=%s)" % deck_file)
		return DeckActionResult.rejected(DUPLICATE_DECK_FAILED_MESSAGE)

	var duplicated_file := duplicated as String
	return DeckActionResult.completed(
		"'%s' 복제 완료" % DeckNaming.display_name(duplicated_file),
		duplicated_file
	)


static func rename(deck_file: String, new_display_name: String) -> DeckActionResult:
	if not DeckStorage.deck_exists(deck_file):
		return DeckActionResult.rejected(RENAME_DECK_NOT_FOUND_MESSAGE)

	var trimmed_name := new_display_name.strip_edges()
	if trimmed_name.is_empty():
		return DeckActionResult.rejected(DECK_NAME_EMPTY_MESSAGE)
	if not DeckNaming.is_valid_display_name(trimmed_name):
		return DeckActionResult.rejected(DECK_NAME_INVALID_MESSAGE)

	var new_file := DeckNaming.deck_file_name(trimmed_name)
	if new_file.to_lower() == deck_file.to_lower():
		return DeckActionResult.completed(
			"이름이 변경되지 않았습니다.",
			deck_file,
			"",
			false
		)
	if is_deck_file_taken(new_file):
		return DeckActionResult.rejected(DECK_NAME_DUPLICATE_MESSAGE)

	var old_display_name := DeckNaming.display_name(deck_file)
	if not DeckStorage.rename_deck(deck_file, new_file):
		push_warning(
			"Deck rename failed (source=%s, target=%s)" % [deck_file, new_file]
		)
		return DeckActionResult.rejected(RENAME_FAILED_MESSAGE)
	return DeckActionResult.completed(
		"'%s' → '%s' 이름 변경 완료" % [old_display_name, trimmed_name],
		new_file
	)


static func delete(deck_file: String) -> DeckActionResult:
	if not DeckStorage.deck_exists(deck_file):
		return DeckActionResult.rejected(DELETE_DECK_NOT_FOUND_MESSAGE)

	var display_name := DeckNaming.display_name(deck_file)
	if not DeckStorage.delete_deck(deck_file):
		push_warning("Deck delete failed (source=%s)" % deck_file)
		return DeckActionResult.rejected(DELETE_DECK_FAILED_MESSAGE)
	return DeckActionResult.completed("'%s' 삭제 완료" % display_name, deck_file)


static func export(deck_file: String, target_path: String) -> DeckActionResult:
	var markdown_path := ensure_markdown_extension(target_path)
	var result := DeckStorage.export_deck_result(deck_file, markdown_path)
	if result == DeckStorage.ExportResult.OK:
		return DeckActionResult.completed(
			"'%s' 내보내기 완료" % markdown_path.uri_decode().get_file(),
			deck_file,
			markdown_path
		)

	push_warning(
		"Deck export failed (result=%s, source=%s, target=%s)"
		% [result, deck_file, markdown_path]
	)
	return DeckActionResult.rejected(export_error_message(result))


static func import_from_path(source_path: String) -> DeckActionResult:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return DeckActionResult.rejected(IMPORT_FAILED_MESSAGE)

	var content_error := deck_content_error(source.get_as_text())
	if not content_error.is_empty():
		return DeckActionResult.rejected(content_error)

	var imported: Variant = DeckStorage.import_deck(source_path)
	if imported is not String:
		return DeckActionResult.rejected(IMPORT_FAILED_MESSAGE)

	var imported_file := imported as String
	return DeckActionResult.completed(
		"'%s' 가져오기 완료" % DeckNaming.display_name(imported_file),
		imported_file
	)


static func ensure_markdown_extension(target_path: String) -> String:
	if target_path.to_lower().ends_with(DeckNaming.EXTENSION):
		return target_path
	return "%s%s" % [target_path, DeckNaming.EXTENSION]


static func export_error_message(result: DeckStorage.ExportResult) -> String:
	match result:
		DeckStorage.ExportResult.DECK_NOT_FOUND:
			return EXPORT_DECK_NOT_FOUND_MESSAGE
		DeckStorage.ExportResult.TARGET_OPEN_FAILED:
			return EXPORT_TARGET_OPEN_FAILED_MESSAGE
		DeckStorage.ExportResult.WRITE_FAILED:
			return EXPORT_WRITE_FAILED_MESSAGE
		_:
			return EXPORT_UNKNOWN_FAILED_MESSAGE


static func deck_content_error(deck_text: String) -> String:
	if deck_text.strip_edges().is_empty():
		return EMPTY_DECK_MESSAGE
	if DeckParser.parse(deck_text).is_empty():
		return BROKEN_DECK_MESSAGE
	return ""


static func clipboard_content_error(markdown_text: String) -> String:
	if markdown_text.strip_edges().is_empty():
		return CLIPBOARD_EMPTY_MESSAGE
	if DeckParser.parse(markdown_text).is_empty():
		return CLIPBOARD_BROKEN_MESSAGE
	return ""


static func is_deck_file_taken(deck_file: String) -> bool:
	for existing_file in DeckStorage.list_deck_files():
		if existing_file.to_lower() == deck_file.to_lower():
			return true
	return false
