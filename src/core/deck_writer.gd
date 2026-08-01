class_name DeckWriter
extends RefCounted

const QUESTION_PREFIX := "# "

static func to_markdown(cards: Array[FlashCard]) -> String:
	var lines: PackedStringArray
	
	for card: FlashCard in cards:
		lines.append("%s%s" % [QUESTION_PREFIX, card.question])
		
		if not card.answer.is_empty():
			lines.append("%s" % [card.answer])
			
	if lines.is_empty():
		return ""
	
	return "\n".join(lines) + "\n"
