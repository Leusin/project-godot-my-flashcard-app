class_name DeckLibraryOrder
extends RefCounted

static func sorted_files(files: Array[String], mode: String, recent: Array[String]) -> Array[String]:
	var sorted := files.duplicate()
	sorted.sort_custom(func(a: String, b: String) -> bool:
		if mode == "recent":
			var a_rank := recent.find(a)
			var b_rank := recent.find(b)
			if a_rank != b_rank:
				if a_rank == -1:
					return false
				if b_rank == -1:
					return true
				return a_rank < b_rank
		var comparison := DeckNaming.display_name(a).naturalnocasecmp_to(DeckNaming.display_name(b))
		return a < b if comparison == 0 else comparison < 0
	)
	return sorted
