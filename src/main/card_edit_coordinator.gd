class_name CardEditCoordinator
extends RefCounted

# 카드 입력 검증부터 저장 후 학습 snapshot 동기화까지 한 흐름으로 묶는다.
# 화면 전환과 알림 표시는 MainApp이 맡는다.

enum EditorOrigin {
	CARD_LIST,
	NEW_DECK,
	STUDY,
	CARD_DETAIL,
}

enum DetailOrigin {
	CARD_LIST,
	STUDY_RESULT,
}

enum SaveContext {
	STANDARD,
	NEW_DECK,
	STUDY,
	STUDY_RESULT,
}

const CARD_QUESTION_EMPTY_MESSAGE := "질문을 입력하세요."
const CARD_ANSWER_HEADING_MESSAGE := "답의 줄 시작에는 '# '를 사용할 수 없습니다."
const CARD_SAVE_FAILED_MESSAGE := "카드를 저장하지 못했습니다. 저장 공간을 확인하세요."

class SaveResult:
	extends RefCounted

	var succeeded := false
	var progress_saved := false
	var message := ""
	var context: SaveContext = SaveContext.STANDARD


static func context_for(
	editor_origin: int,
	detail_origin: int,
	detail_result_index: int,
	result_count: int
) -> SaveContext:
	if editor_origin == EditorOrigin.NEW_DECK:
		return SaveContext.NEW_DECK
	if editor_origin == EditorOrigin.STUDY:
		return SaveContext.STUDY
	if (
		editor_origin == EditorOrigin.CARD_DETAIL
		and detail_origin == DetailOrigin.STUDY_RESULT
		and detail_result_index >= 0
		and detail_result_index < result_count
	):
		return SaveContext.STUDY_RESULT
	return SaveContext.STANDARD


static func save(
	workspace: CardWorkspace,
	run: StudyRun,
	plan: StudyPlan,
	context: SaveContext,
	detail_result_index: int,
	raw_question: String,
	raw_answer: String,
	wrong_count: int,
	status: CardStatus.Value
) -> SaveResult:
	var result := SaveResult.new()
	result.context = context
	var question := raw_question.strip_edges()
	var answer := raw_answer.replace("\r\n", "\n").strip_edges()
	if question.is_empty():
		result.message = CARD_QUESTION_EMPTY_MESSAGE
		return result
	if _answer_has_question_heading(answer):
		result.message = CARD_ANSWER_HEADING_MESSAGE
		return result
	if (
		context == SaveContext.NEW_DECK
		and DeckActionService.is_deck_file_taken(workspace.deck_file)
	):
		result.message = DeckActionService.DECK_NAME_DUPLICATE_MESSAGE
		return result

	var workspace_result := workspace.save_card(
		question,
		answer,
		wrong_count,
		status,
		context != SaveContext.STUDY
	)
	if not workspace_result.succeeded:
		result.message = CARD_SAVE_FAILED_MESSAGE
		return result

	match context:
		SaveContext.STUDY:
			run.replace_current(workspace_result.card, workspace_result.progress)
			plan.replace_cards(
				workspace.deck_file,
				workspace.cards,
				workspace_result.markdown.hash()
			)
			run.sync_resume(plan)
		SaveContext.STUDY_RESULT:
			var active_index := plan.active_index_at(detail_result_index)
			run.replace_result(
				detail_result_index,
				active_index,
				workspace_result.card,
				workspace_result.progress
			)
			plan.replace_cards(
				workspace.deck_file,
				workspace.cards,
				workspace_result.markdown.hash()
			)

	result.succeeded = true
	result.progress_saved = workspace_result.progress_saved
	return result


static func _answer_has_question_heading(answer: String) -> bool:
	for line in answer.replace("\r\n", "\n").split("\n"):
		if line.begins_with("# "):
			return true
	return false
