extends SceneTree

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(720, 1280)
	var library := load("res://src/main/library_view.tscn").instantiate() as LibraryView
	root.add_child(library)
	library.size = Vector2(720, 1280)
	var decks: Array[DeckInfo] = [DeckInfo.new("a.md", "영어", 10), DeckInfo.new("b.md", "개발", 20), DeckInfo.new("c.md", "여행", 30)]
	library.render(decks)
	await process_frame
	await process_frame
	var selected: Array[String] = []
	library.deck_selected.connect(func(file: String) -> void: selected.append(file))
	var tile := library.deck_list.get_child(0) as DeckTileView
	var start := tile.deck_button.get_global_rect().get_center()
	await _button(start, true)
	await _button(start, false)
	_check(selected == ["a.md"], "실제 포인터: 덱 짧은 탭")
	selected.clear()
	await _button(start, true)
	tile._gesture._process(0.5)
	await process_frame
	var target := (library.deck_list.get_child(1) as Control).get_global_rect().end - Vector2(1, 10)
	await _motion(target)
	await _button(target, false)
	_check(library.current_order() == ["b.md", "a.md", "c.md"], "실제 포인터: 길게 눌러 덱 이동")
	_check(selected.is_empty(), "실제 포인터: 이동 후 덱 열림 방지")
	library.free()

	var view := load("res://src/main/card_list_view.tscn").instantiate() as CardListView
	root.add_child(view)
	view.size = Vector2(720, 1280)
	var cards: Array[FlashCard] = [FlashCard.new("resilient", "회복력이 있는"), FlashCard.new("concise", "간결한"), FlashCard.new("momentum", "추진력"), FlashCard.new("긴 질문도 잘 표시될까요?", "여러 줄로 작성한 답변입니다.\n아래 내용도 검색됩니다.")]
	view.render("출퇴근 복습", cards)
	await process_frame
	await process_frame
	var moves: Array[Vector2i] = []
	view.card_move_requested.connect(func(a: int, b: int) -> void: moves.append(Vector2i(a, b)))
	var row := view.rows.get_child(0) as CardCollectionRow
	start = row.reorder_handle.get_global_rect().get_center()
	target = (view.rows.get_child(1) as Control).get_global_rect().end - Vector2(25, 1)
	await _button(start, true)
	await _motion(target)
	await _button(target, false)
	_check(moves == [Vector2i(0, 1)], "실제 포인터: 카드 손잡이 이동")
	view.search_field.text = "회복"
	view.search_field.text_changed.emit("회복")
	await process_frame
	await process_frame
	_check(not view.rows.get_child(0).visible and view.rows.get_child(1).visible, "검색: 재정렬 후에도 올바른 카드 필터")
	var opened: Array[int] = []
	view.card_selected.connect(func(index: int) -> void: opened.append(index))
	var result := view.rows.get_child(1) as CardCollectionRow
	var point := result.question_label.get_global_rect().get_center()
	await _button(point, true)
	await _button(point, false)
	_check(opened == [1], "실제 포인터: 검색 결과 선택은 원본 index")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/search-preview.png")
		view.search_field.text = ""
		view.search_field.text_changed.emit("")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/card-list-preview.png")
	view.free()
	print("UI RESULT: %d checks, %d failures" % [checks, failures])
	quit(failures)


func _button(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	await process_frame


func _motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	await process_frame


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)
