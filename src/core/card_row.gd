class_name CardRow
extends RefCounted

var question: String
var wrong_count: int

func _init(p_question: String, p_wrong_count: int) -> void:
	question = p_question
	wrong_count = p_wrong_count
