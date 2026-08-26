class_name AppSettings
extends RefCounted

var last_deck_file := ""
var deck_dir := ""
var shuffle_study := false
var haptics_enabled := true

func to_json() -> String:
	return JSON.stringify(
		{
			"LastDeckFile": last_deck_file,
			"DeckDir": deck_dir,
			"ShuffleStudy": shuffle_study,
			"HapticsEnabled": haptics_enabled,
		},
		"\t"
	)

static func from_json(json: String) -> AppSettings:
	var settings := AppSettings.new()

	if json.strip_edges().is_empty():
		return settings

	var parser := JSON.new()
	var error := parser.parse(json)

	if error != OK:
		return settings

	var parsed: Variant = parser.data
	if parsed is not Dictionary:
		return settings

	var data := parsed as Dictionary

	if data.get("LastDeckFile", "") is String:
		settings.last_deck_file = data.get("LastDeckFile", "")

	if data.get("DeckDir", "") is String:
		settings.deck_dir = data.get("DeckDir", "")

	if data.get("ShuffleStudy", false) is bool:
		settings.shuffle_study = data.get("ShuffleStudy", false)

	if data.get("HapticsEnabled", true) is bool:
		settings.haptics_enabled = data.get("HapticsEnabled", true)

	return settings
