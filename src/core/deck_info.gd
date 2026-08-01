class_name DeckInfo
extends RefCounted

var file_name: String
var display_name: String
var card_count: int

func _init(p_file_name: String, p_display_name: String, p_card_count: int) -> void:
	file_name = p_file_name
	display_name = p_display_name
	card_count = p_card_count
