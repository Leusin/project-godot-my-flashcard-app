class_name DeckParser
extends RefCounted

const QUESTION_PREFIX := "# "

static func parse(text: String) -> Array[FlashCard]:
	var cards: Array[FlashCard]
	
	if text.is_empty():
		return cards
	
	var question := ""
	var answer_lines: Array[String] = []
	
	for raw_line: String in text.split("\n"): # 라인 피드(LF)로 구분해서 가져온다	
		var line = raw_line.trim_suffix("\r") # 캐리지 리턴(CR) 제거
		
		if line.begins_with(QUESTION_PREFIX):
			if not question.is_empty():
				var answer := "\n".join(answer_lines).strip_edges()
				cards.append(FlashCard.new(question, answer))
				
			question = line.substr(QUESTION_PREFIX.length()).strip_edges()
			answer_lines.clear()
			
		elif not question.is_empty():
			answer_lines.append(line)
		
	# 마지막 카드 저장
	if not question.is_empty():
		var answer := "\n".join(answer_lines).strip_edges()
		cards.append(FlashCard.new(question, answer))
		
	return cards
