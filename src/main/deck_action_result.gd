class_name DeckActionResult
extends RefCounted

var succeeded := false
var message := ""
var deck_file := ""
var target_path := ""
var changed := false


func _init(
	action_succeeded: bool,
	result_message: String = "",
	result_deck_file: String = "",
	result_target_path: String = "",
	did_change: bool = false
) -> void:
	succeeded = action_succeeded
	message = result_message
	deck_file = result_deck_file
	target_path = result_target_path
	changed = did_change


static func completed(
	result_message: String = "",
	result_deck_file: String = "",
	result_target_path: String = "",
	did_change: bool = true
) -> DeckActionResult:
	return DeckActionResult.new(
		true,
		result_message,
		result_deck_file,
		result_target_path,
		did_change
	)


static func rejected(result_message: String) -> DeckActionResult:
	return DeckActionResult.new(false, result_message)
