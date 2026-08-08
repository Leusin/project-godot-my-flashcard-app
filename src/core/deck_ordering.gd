class_name DeckOrdering
extends RefCounted


enum StudyOrder {
	SEQUENTIAL,
	SHUFFLE,
}

static func apply(order: StudyOrder, cards: Array[FlashCard]) -> Array[FlashCard]:
	var result: Array[FlashCard] = cards.duplicate()

	if order == StudyOrder.SHUFFLE:
		result.shuffle()

	return result
