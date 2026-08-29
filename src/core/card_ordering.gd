class_name CardOrdering
extends RefCounted

# 덱 안에서 카드 한 장의 자리를 옮긴다.
# 진행도는 질문을 키로 쓰므로 순서를 바꿔도 학습 기록은 따라올 필요가 없다.


static func moved(
	cards: Array[FlashCard],
	from_index: int,
	to_index: int
) -> Array[FlashCard]:
	var result: Array[FlashCard] = []
	result.assign(ArrayOrder.moved(cards, from_index, to_index))
	return result
