class_name Progress
extends RefCounted

var _wrong_counts: Dictionary[String, int] = {}
var _statuses: Dictionary[String, CardStatus.Value] = {}
var _favorites: Dictionary[String, bool] = {}

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


func is_favorite(question: String) -> bool:
	return _favorites.get(question, false)


func set_favorite(question: String, favorite: bool) -> void:
	if not favorite:
		_favorites.erase(question)
		return
	_favorites[question] = true

func remove(question: String) -> void:
	_wrong_counts.erase(question)
	_statuses.erase(question)
	_favorites.erase(question)

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

	if _favorites.has(old_question):
		_favorites.erase(old_question)
		_favorites[new_question] = true


func to_json() -> String:
	var questions: Dictionary[String, bool] = {}
	for question in _wrong_counts:
		questions[question] = true
	for question in _statuses:
		questions[question] = true
	for question in _favorites:
		questions[question] = true

	var entries: Dictionary = {}
	for question in questions:
		entries[question] = {
			"wrong": get_wrong_count(question),
			"status": _status_to_string(get_status(question)),
			"favorite": is_favorite(question),
		}

	return JSON.stringify(entries, "\t")


static func from_json(json: String) -> Progress:
	var progress := Progress.new()
	if json.strip_edges().is_empty():
		return progress

	var parser := JSON.new()
	if parser.parse(json) != OK:
		return progress

	var parsed: Variant = parser.data
	if parsed is not Dictionary:
		return progress

	var data := parsed as Dictionary
	for question: String in data:
		var value: Variant = data[question]
		if value is int or value is float:
			progress.set_wrong_count(question, int(value))
			continue

		if value is not Dictionary:
			continue

		var entry := value as Dictionary
		var wrong: Variant = entry.get("wrong")
		if wrong is int or wrong is float:
			progress.set_wrong_count(question, int(wrong))

		var status: Variant = entry.get("status")
		if status is String:
			progress.set_status(question, _status_from_string(status as String))

		var favorite: Variant = entry.get("favorite")
		if favorite is bool:
			progress.set_favorite(question, favorite as bool)

	return progress


static func _status_to_string(status: CardStatus.Value) -> String:
	match status:
		CardStatus.Value.LEARNING:
			return "LEARNING"
		CardStatus.Value.MASTERED:
			return "MASTERED"
		_:
			return "NEW"


static func _status_from_string(status: String) -> CardStatus.Value:
	match status.to_upper():
		"LEARNING":
			return CardStatus.Value.LEARNING
		"MASTERED":
			return CardStatus.Value.MASTERED
		_:
			return CardStatus.Value.NEW
