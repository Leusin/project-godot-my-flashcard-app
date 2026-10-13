class_name AppSettings
extends RefCounted

var last_deck_file := ""
var deck_dir := ""
var shuffle_study := false
var haptics_enabled := true
# 덱 목록에 보여 줄 차례. 앞이 위다.
var deck_order: Array[String] = []
var deck_sort := "name"
var card_sort := 0
var recent_decks: Array[String] = []

func to_json() -> String:
	return JSON.stringify(
		{
			"LastDeckFile": last_deck_file,
			"DeckDir": deck_dir,
			"ShuffleStudy": shuffle_study,
			"HapticsEnabled": haptics_enabled,
			"DeckOrder": deck_order,
			"DeckSort": deck_sort,
			"CardSort": card_sort,
			"RecentDecks": recent_decks,
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

	var stored_order: Variant = data.get("DeckOrder")
	if stored_order is Array:
		for entry: Variant in stored_order as Array:
			if entry is String and not (entry as String).is_empty():
				settings.deck_order.append(entry as String)

	if data.get("DeckSort") in ["name", "recent"]:
		settings.deck_sort = data["DeckSort"]
	var recent: Variant = data.get("RecentDecks", [])
	if recent is Array:
		for entry in recent:
			if entry is String and not entry.is_empty() and not settings.recent_decks.has(entry):
				settings.recent_decks.append(entry)
	if settings.recent_decks.is_empty() and not settings.last_deck_file.is_empty():
		settings.recent_decks.append(settings.last_deck_file)

	var card_sort_value: Variant = data.get("CardSort", 0)
	if (card_sort_value is float or card_sort_value is int) and card_sort_value >= 0 and card_sort_value <= 2 and card_sort_value == floorf(card_sort_value):
		settings.card_sort = int(card_sort_value)

	return settings
