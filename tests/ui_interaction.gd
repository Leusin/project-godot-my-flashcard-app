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
	_check(library.current_order() == ["a.md", "b.md", "c.md"], "실제 포인터: 길게 누른 뒤 드래그해도 덱 순서 유지")
	_check(selected.is_empty(), "실제 포인터: 이동 후 덱 열림 방지")
	library.free()

	var action_row := load("res://src/main/settings_action_row.tscn").instantiate() as Button
	root.add_child(action_row)
	action_row.size = Vector2(640, 140)
	var row_clicks: Array[int] = []
	action_row.pressed.connect(func() -> void: row_clicks.append(1))
	await process_frame
	await process_frame
	for child_path in ["Margin/Content/Text/Title", "Margin/Content/Text/Description", "Margin/Content/Arrow"]:
		var hit := (action_row.get_node(child_path) as Control).get_global_rect().get_center()
		await _button(hit, true)
		await _button(hit, false)
	_check(row_clicks.size() == 3, "실제 포인터: 설정 행 제목·설명·화살표 모두 클릭 가능")
	action_row.free()

	var view := load("res://src/main/card_list_view.tscn").instantiate() as CardListView
	root.add_child(view)
	view.size = Vector2(720, 1280)
	var cards: Array[FlashCard] = [FlashCard.new("resilient", "회복력이 있는"), FlashCard.new("concise", "간결한"), FlashCard.new("momentum", "추진력"), FlashCard.new("긴 질문도 잘 표시될까요?", "여러 줄로 작성한 답변입니다.\n아래 내용도 검색됩니다.")]
	view.render("출퇴근 복습", cards)
	await process_frame
	await process_frame
	await _button(view.sort_button.get_global_rect().get_center(), true)
	await _button(view.sort_button.get_global_rect().get_center(), false)
	await process_frame
	_check(view.sort_menu.visible, "실제 포인터: 공통 정렬 메뉴 열기")
	await _button(view.sort_items[1].get_global_rect().get_center(), true)
	await _button(view.sort_items[1].get_global_rect().get_center(), false)
	_check(not view.sort_menu.visible, "실제 포인터: 정렬 선택 후 메뉴 닫기")
	await process_frame
	_check(view.rows.get_child(0).card_index == 1, "질문 오름차순: 원본 index 보존")
	var progress := Progress.new()
	progress.set_wrong_count("momentum", 8)
	view.render("출퇴근 복습", cards, progress)
	view.sort_items[2].pressed.emit()
	await process_frame
	_check(view.rows.get_child(0).card_index == 2, "오답 많은 순: 8회 카드가 먼저 표시")
	view.sort_items[1].pressed.emit()
	await _button(view.sort_button.get_global_rect().get_center(), true)
	await _button(view.sort_button.get_global_rect().get_center(), false)
	await _button(Vector2(10, 800), true)
	await _button(Vector2(10, 800), false)
	_check(not view.sort_menu.visible, "실제 포인터: 바깥 클릭으로 메뉴 닫기")
	view.search_field.text = "회복"
	view.search_field.text_changed.emit("회복")
	await process_frame
	await process_frame
	_check(not view.rows.get_child(0).visible and view.rows.get_child(2).visible, "검색: 정렬 후에도 올바른 카드 필터")
	var opened: Array[int] = []
	view.card_selected.connect(func(index: int) -> void: opened.append(index))
	var result := view.rows.get_child(2) as CardCollectionRow
	var point := result.question_label.get_global_rect().get_center()
	await _button(point, true)
	await _button(point, false)
	_check(opened == [0], "실제 포인터: 검색 결과 선택은 원본 index")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/search-preview.png")
		view.search_field.text = ""
		view.search_field.text_changed.emit("")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/card-list-preview.png")
	view.search_field.text = ""
	view.search_field.text_changed.emit("")
	view.sort_button.pressed.emit()
	var old_menu_position := view.sort_menu.menu_panel.global_position
	root.size = Vector2i(1100, 900)
	await process_frame
	await process_frame
	view.size = root.get_visible_rect().size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var menu_rect := view.sort_menu.menu_panel.get_global_rect()
	var anchor_rect := view.sort_button.get_global_rect()
	_check(not view.sort_menu.menu_panel.global_position.is_equal_approx(old_menu_position), "메뉴: 레이아웃 변경 후 위치 갱신")
	_check(is_equal_approx(menu_rect.position.y, anchor_rect.end.y + 4), "메뉴: 크기 변경 후에도 버튼 바로 아래 표시")
	view.sort_menu.dismiss()
	view.free()
	var study := load("res://src/main/study_view.tscn").instantiate() as StudyFlowView
	root.add_child(study)
	study.set_deck_name("출퇴근 복습")
	study.show_card(FlashCard.new("resilient", "회복력이 있는"), 0, "NEW", 4, true)
	study.gesture_surface.haptics_enabled = false
	for viewport_size in [Vector2i(720, 1280), Vector2i(1100, 900)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		study.size = root.get_visible_rect().size
		await process_frame
		await process_frame
		var surface := study.gesture_surface
		var swipe_start := surface.get_global_rect().get_center()
		var screen_transform := root.get_final_transform()
		await _button(screen_transform * swipe_start, true)
		await _motion(screen_transform * (swipe_start + Vector2(0, -140)))
		_check(surface.position.y < 0.0,
			"스와이프: 위로 드래그하면 카드만 이동")
		await _motion(screen_transform * (swipe_start + Vector2(0, 140)))
		_check(surface.position.y > 0.0,
			"스와이프: 방향을 바꾸면 카드 이동 방향도 전환")
		surface.cancel_drag()
		await _button(screen_transform * swipe_start, false)
		_check(surface.position.is_zero_approx(),
			"스와이프: 취소하면 카드 위치 복원")
	root.size = Vector2i(720, 1280)
	await process_frame
	study.size = root.get_visible_rect().size
	var swipe_actions: Array[int] = []
	study.gesture_surface.swiped.connect(func(direction: int) -> void: swipe_actions.append(direction))
	for answer_visible in [true, false]:
		study.show_card(FlashCard.new("긴 질문입니다.\n".repeat(80), "긴 답변입니다.\n".repeat(80)), 0, "NEW", 2, true)
		study.set_answer_visible(answer_visible)
		await process_frame
		await process_frame
		var scroll := study.answer_scroll if answer_visible else study.question_scroll
		var scroll_start := scroll.get_global_rect().get_center()
		await _touch(scroll_start, true)
		await _touch_motion(scroll_start - Vector2(0, 120), Vector2(0, -120))
		_check(scroll.scroll_vertical == 120 and study.gesture_surface.position.is_zero_approx(),
			"긴 카드: 터치 드래그로 내용만 스크롤")
		await _touch_motion(scroll_start - Vector2(0, 60), Vector2(0, 60))
		_check(scroll.scroll_vertical == 60, "긴 카드: 드래그 방향을 바꾸면 내용도 되돌아감")
		await _touch(scroll_start - Vector2(0, 60), false)
		scroll.scroll_vertical = 0
		await _button(scroll_start, true)
		await _motion(scroll_start - Vector2(0, 120))
		await _button(scroll_start - Vector2(0, 120), false)
		_check(scroll.scroll_vertical == 120 and swipe_actions.is_empty()
			and study.is_answer_visible() == answer_visible,
			"긴 카드: 마우스로도 스크롤하며 판정이나 카드 뒤집기를 실행하지 않음")
	study.free()
	var detail := load("res://src/main/card_detail_view.tscn").instantiate() as CardDetailView
	root.add_child(detail)
	detail.size = root.get_visible_rect().size
	detail.card_surface.animations_enabled = false
	detail.present("긴 카드 확인", FlashCard.new("긴 질문입니다.\n".repeat(80), "긴 답변입니다.\n".repeat(80)), 2, "LEARNING", true, "뒤로")
	for detail_answer_visible in [false, true]:
		await process_frame
		await process_frame
		var detail_scroll := detail.answer_scroll if detail_answer_visible else detail.question_scroll
		var detail_start := detail_scroll.get_global_rect().get_center()
		await _touch(detail_start, true)
		await _touch_motion(detail_start - Vector2(0, 120), Vector2(0, -120))
		await _touch(detail_start - Vector2(0, 120), false)
		_check(detail_scroll.scroll_vertical == 120
			and detail.answer_scroll.visible == detail_answer_visible,
			"카드 상세: 터치 드래그로 내용을 읽으며 카드를 뒤집지 않음")
		detail_scroll.scroll_vertical = 0
		await _button(detail_start, true)
		await _motion(detail_start - Vector2(0, 120))
		await _button(detail_start - Vector2(0, 120), false)
		_check(detail_scroll.scroll_vertical == 120
			and detail.answer_scroll.visible == detail_answer_visible,
			"카드 상세: 마우스 드래그로 내용을 읽으며 카드를 뒤집지 않음")
		await _button(detail_start, true)
		await _button(detail_start, false)
		_check(detail.answer_scroll.visible != detail_answer_visible,
			"카드 상세: 짧은 탭으로만 앞뒷면 전환")
	detail.free()
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


func _touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = down
	event.position = point
	Input.parse_input_event(event)
	await process_frame


func _touch_motion(point: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = point
	event.relative = relative
	Input.parse_input_event(event)
	await process_frame


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)
