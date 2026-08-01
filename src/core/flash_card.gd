class_name FlashCard
extends RefCounted

var question: String
var answer: String

func _init(p_question: String, p_answer: String) -> void:
	question = p_question
	answer = p_answer
