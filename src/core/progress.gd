class_name Progress
extends RefCounted

var _wrong_counts: Dictionary[String, int] = {}
var _statuses: Dictionary[String, CardStatus.Value] = {}

func get_wrong_count(question: String) -> int:
	return _wrong_counts.get(question, 0)

func add_wrong(question: String) -> void:
	_wrong_counts[question] = get_wrong_count(question) + 1

func set_wrong_count(question: String, count: int) -> void:
	if count <= 0:
		_wrong_counts.erase(question)
		return

	_wrong_counts[question] = count

func get_status(question: String) -> CardStatus.Value:
	return _statuses.get(question, CardStatus.Value.NEW)

func set_status(question: String, status: CardStatus.Value) -> void:
	if status == CardStatus.Value.NEW:
		_statuses.erase(question)
		return

	_statuses[question] = status

func remove(question: String) -> void:
	_wrong_counts.erase(question)
	_statuses.erase(question)

func rename(old_question: String, new_question: String) -> void:
	if old_question == new_question or new_question.is_empty():
		return

	if _wrong_counts.has(old_question):
		var moved_count := _wrong_counts[old_question]
		_wrong_counts.erase(old_question)
		_wrong_counts[new_question] = (
			get_wrong_count(new_question) + moved_count
		)

	if _statuses.has(old_question):
		var moved_status := _statuses[old_question]
		_statuses.erase(old_question)
		_statuses[new_question] = moved_status
