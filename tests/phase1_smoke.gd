extends Node

func _ready():
	print("# Phase 1 ready")
	print(DeckNaming.display_name("영어단어.md")) # 영어단어
	print(DeckNaming.display_name("Deck.MD"))    # Deck
	print(DeckNaming.display_name(" Deck.MD ")) # Deck
	
	print("---")
	
	print(DeckNaming.is_deck_file("Deck.MD"))   # true
	print(DeckNaming.is_deck_file("a.md"))       # true
	print(DeckNaming.is_deck_file(".md"))        # false
	
	print("---")
	
	var existing: Array[String] = ["a.md", "a (2).md"]
	print(DeckNaming.unique_file_name("A.MD", existing)) # A (3).md
	print(DeckNaming.unique_file_name("a.md", existing)) # a (3).md
	print(DeckNaming.unique_file_name("b.md", existing)) # b.md
	
	print("---")
	
	print(DeckNaming.progress_file_name("영어단어.md")) # 영어단어.json
	
	print("\n")
