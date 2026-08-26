class_name DeckNaming

const EXTENSION := ".md"
const INVALID_DISPLAY_NAME_CHARACTERS := '<>:"/\\|?*'

# 덱 이름은 그대로 파일 이름이 된다. Android/Linux는 파일 이름을 255 byte로 자르는데
# 한글은 UTF-8에서 한 자당 3 byte라 이름만으로 85자가 상한이다.
# 여기에 진행도 파일의 ".json"과 중복 시 붙는 " (2)"까지 들어가야 하므로 넉넉히 낮춰 잡는다.
const MAX_DISPLAY_NAME_LENGTH := 40

# 확장자를 제거하고 표시할 이름
static func display_name(file_name: String) -> String:
	var name := file_name.strip_edges()
	if name.to_lower().ends_with(EXTENSION):
		name = name.left(name.length() - EXTENSION.length())
	return name.strip_edges()
		
# MarkDown 인지 확인
static func is_deck_file(file_name: String) -> bool:
	return (file_name.to_lower().ends_with(EXTENSION) 
		&& display_name(file_name).length() > 0)


static func is_valid_display_name(display: String) -> bool:
	var trimmed := display.strip_edges()
	if trimmed.is_empty() or trimmed == "." or trimmed == ".." or trimmed.ends_with("."):
		return false

	if trimmed.length() > MAX_DISPLAY_NAME_LENGTH:
		return false

	for character in INVALID_DISPLAY_NAME_CHARACTERS:
		if trimmed.contains(character):
			return false

	return true


static func deck_file_name(display: String) -> String:
	return "%s%s" % [display.strip_edges(), EXTENSION]

# 기존 이름과 겹치는 경우  (2), (3) ... 붙이기
static func unique_file_name(file_name: String, existing: Array) -> String:
	# 대소문자 비교를 하지 않는 윈도우 환경 고려해서
	var taken: Dictionary = {}
	for i in existing.size():
		var normalized_name = existing[i].to_lower()
		taken[normalized_name] = true
	
	if not taken.has(file_name.to_lower()):
		return file_name

	var stem := base_display_name(display_name(file_name))
	var number := 2
	var candidate := numbered_file_name(stem, number)

	while taken.has(candidate.to_lower()):
		number += 1
		candidate = numbered_file_name(stem, number)

	return candidate


# "이름 (2)"처럼 이미 붙은 번호는 떼고 센다.
# 그러지 않으면 복제한 덱을 다시 복제할 때 "이름 (2) (2)"가 된다.
static func base_display_name(display: String) -> String:
	var trimmed := display.strip_edges()
	if not trimmed.ends_with(")"):
		return trimmed

	var open_index := trimmed.rfind(" (")
	if open_index <= 0:
		return trimmed

	var inside := trimmed.substr(open_index + 2, trimmed.length() - open_index - 3)
	if inside.is_empty() or not inside.is_valid_int():
		return trimmed

	return trimmed.left(open_index).strip_edges()


# 번호를 붙여도 이름 길이 상한을 넘지 않도록 밑동을 줄인다.
static func numbered_file_name(stem: String, number: int) -> String:
	var suffix := " (%d)" % number
	var room := MAX_DISPLAY_NAME_LENGTH - suffix.length()
	var shortened := stem if stem.length() <= room else stem.left(room).strip_edges()
	return "%s%s%s" % [shortened, suffix, EXTENSION]
			
# 덱 파일명에서 진행도 파일명 만들기
static func progress_file_name(deck_file_name: String) -> String:
	return "%s.json" % display_name(deck_file_name)
