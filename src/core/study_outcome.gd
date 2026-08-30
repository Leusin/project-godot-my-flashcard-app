class_name StudyOutcome
extends RefCounted

enum Value {
	PENDING,
	AGAIN,
	GOOD,
	SKIP,
}


static func display_text(outcome: int) -> String:
	match outcome:
		Value.GOOD:
			return "GOOD"
		Value.AGAIN:
			return "AGAIN"
		Value.SKIP:
			return "SKIP"
		_:
			return "—"
