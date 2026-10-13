extends TestCase

# addons/mobile_foundation 모듈의 경계값 검사를 이 프로젝트의 harness에 잇는다.
# 순수 계산은 모듈 안(MobileFoundationChecks)에 있어 다른 프로젝트로 그대로 옮겨진다.
# 새 프로젝트에서는 이 파일만 그쪽 harness에 맞춰 다시 쓰면 된다.


func run_tests() -> void:
	MobileFoundationChecks.run(
		func(passed: bool, description: String) -> void: check(passed, description)
	)
	# 노드 두 개는 SceneTree가 있어야 확인할 수 있어 여기서 본다.
	_check_safe_area_margin()
	_check_keyboard_avoider_node()
	_check_list_reorder()
	_check_reorder_gesture()


func _check_safe_area_margin() -> void:
	var margin := SafeAreaMargin.new()
	margin.base_margin = 12.0
	add_child(margin)
	margin.apply_insets()

	# 헤드리스 테스트는 손에 드는 기기가 아니므로 안전 영역이 없다.
	check(
		margin.insets() == Vector4.ZERO,
		"SafeAreaMargin: 안전 영역이 없으면 기본 여백만 남는다"
	)
	check(
		margin.get_theme_constant("margin_left") == 12
		and margin.get_theme_constant("margin_top") == 12
		and margin.get_theme_constant("margin_right") == 12
		and margin.get_theme_constant("margin_bottom") == 12,
		"SafeAreaMargin: 네 변 모두에 여백을 넣는다"
	)

	margin.apply_bottom = false
	margin.base_margin = 0.0
	margin.apply_insets()
	check(
		margin.get_theme_constant("margin_bottom") == 0,
		"SafeAreaMargin: 꺼 둔 변은 안전 영역을 더하지 않는다"
	)

	var seen := []
	margin.insets_changed.connect(func(insets: Vector4) -> void: seen.append(insets))
	margin.apply_insets()
	check(
		seen.size() == 1 and seen[0] == Vector4.ZERO,
		"SafeAreaMargin: 다시 계산할 때마다 여백을 알린다"
	)

	margin.queue_free()


func _check_keyboard_avoider_node() -> void:
	var avoider := KeyboardInsetAvoider.new()
	add_child(avoider)

	check(
		avoider.position == Vector2.ZERO,
		"KeyboardInsetAvoider: 키보드가 없으면 제자리에 있다"
	)
	# 가상 키보드가 없는 플랫폼에서 _process를 켜 두면 매 frame 경고가 난다.
	check(
		avoider.is_processing() == DisplayServer.has_feature(
			DisplayServer.FEATURE_VIRTUAL_KEYBOARD
		),
		"KeyboardInsetAvoider: 가상 키보드가 없는 플랫폼에서는 _process를 끈다"
	)

	var resting_position := Vector2(37.0, 91.0)
	avoider.position = resting_position
	avoider._apply_shift(24.0, 1.0)
	check(
		avoider.position == Vector2(37.0, 67.0),
		"KeyboardInsetAvoider: 원래 X와 기준 Y를 보존한 채 필요한 만큼만 올린다"
	)
	avoider._apply_shift(0.0, 1.0)
	check(
		avoider.position == resting_position,
		"KeyboardInsetAvoider: 키보드가 닫히면 0이 아닌 원래 위치로 돌아온다"
	)
	avoider._apply_shift(18.0, 1.0)
	avoider.hide()
	avoider._process(0.0)
	check(
		avoider.position == resting_position,
		"KeyboardInsetAvoider: 숨겨질 때도 원래 위치를 복원한다"
	)

	avoider.queue_free()


func _check_list_reorder() -> void:
	# Container 자체는 자동 배치하지 않으므로 layout frame 대기 없이 좌표를 고정한다.
	var items := Container.new()
	items.position = Vector2(30, 40)
	add_child(items)
	var controls: Array[Control] = []
	for index in 4:
		var item := Control.new()
		items.add_child(item)
		item.position = Vector2(0, index * 60)
		item.size = Vector2(100, 40)
		controls.append(item)
	var reorder := ListReorder.new()
	reorder.items = items
	add_child(reorder)
	var moves: Array[Vector2i] = []
	reorder.reordered.connect(
		func(from_index: int, to_index: int) -> void:
			moves.append(Vector2i(from_index, to_index))
	)
	var first := controls[0]
	var last := controls[3]
	var end := last.get_global_rect().end
	check(reorder.target_at(first, end) == 3, "ListReorder: 세로 목록 끝으로 이동")
	check(
		reorder.target_at(last, first.get_global_rect().position) == 0,
		"ListReorder: 세로 목록 처음으로 이동"
	)
	check(
		reorder.target_at(first, controls[1].get_global_rect().position) == -1,
		"ListReorder: 바로 다음 항목 앞에 놓으면 제자리"
	)
	reorder.finish(first, end)
	check(moves.is_empty(), "ListReorder: 시작하지 않은 놓기는 무시")
	reorder.begin(first)
	check(first.get_index() == 0, "ListReorder: 집는 동안 순서는 유지")
	reorder.finish(controls[1], end)
	check(moves.is_empty(), "ListReorder: 다른 항목의 release는 무시")
	reorder.finish(first, end)
	check(
		first.get_index() == 3 and moves == [Vector2i(0, 3)],
		"ListReorder: 항목을 옮긴 뒤 변경 전후 index를 한 번 전달"
	)
	reorder.finish(first, end)
	check(moves.size() == 1, "ListReorder: 중복 release로 다시 저장하지 않음")
	reorder.begin(first)
	reorder.cancel()
	reorder.finish(first, controls[1].get_global_rect().position)
	check(first.get_index() == 3 and moves.size() == 1, "ListReorder: 취소하면 변경하지 않음")

	items.move_child(first, 0)
	reorder.begin(first)
	reorder.finish(first, controls[1].get_global_rect().position)
	check(moves.size() == 1, "ListReorder: 제자리 놓기는 변경 알림 없음")
	reorder.begin(first)
	items.remove_child(first)
	reorder.finish(first, end)
	check(moves.size() == 1, "ListReorder: 드래그 중 목록에서 빠진 항목은 무시")
	items.add_child(first)
	items.move_child(first, 0)

	# 두 줄로 감긴 타일에서도 가장 가까운 좌/우 경계로 삽입한다.
	reorder.layout = ListReorder.Layout.FLOW
	for index in 4:
		controls[index].position = Vector2((index % 2) * 120, (index / 2) * 60)
	check(
		reorder.target_at(first, controls[2].get_global_rect().position) == 1,
		"ListReorder: 다음 줄 첫 타일 앞에 놓기"
	)
	check(
		reorder.target_at(first, last.get_global_rect().end) == 3,
		"ListReorder: 다음 줄 마지막 타일 뒤에 놓기"
	)
	check(
		reorder.target_at(last, first.get_global_rect().position) == 0,
		"ListReorder: 이전 줄 첫 타일 앞으로 이동"
	)
	first.position += Vector2(500, 500)
	check(
		reorder.target_at(first, last.get_global_rect().end) == 3,
		"ListReorder: 손끝을 따라 움직인 항목은 위치 판정에서 제외"
	)
	reorder.begin(first)
	first.free()
	reorder.finish(null, end)
	check(moves.size() == 1, "ListReorder: 항목이 삭제되어도 놓기는 안전하게 무시")
	items.free()
	check(reorder.target_at(null, end) == -1, "ListReorder: 목록이 삭제되어도 안전")
	reorder.free()

	var single := Container.new()
	add_child(single)
	var only_item := Control.new()
	single.add_child(only_item)
	var single_reorder := ListReorder.new()
	single_reorder.items = single
	add_child(single_reorder)
	check(single_reorder.target_at(only_item, Vector2.ZERO) == -1, "ListReorder: 항목 하나는 옮길 곳 없음")
	only_item.free()
	check(single_reorder.target_at(null, Vector2.ZERO) == -1, "ListReorder: 빈 목록은 옮길 곳 없음")
	single_reorder.free()
	single.free()


func _check_reorder_gesture() -> void:
	var gesture := ReorderGesture.new()
	add_child(gesture)
	var events: Array[String] = []
	gesture.picked.connect(func() -> void: events.append("pick"))
	gesture.dropped.connect(func(_pointer: Vector2) -> void: events.append("drop"))
	gesture.canceled.connect(func() -> void: events.append("cancel"))
	gesture.scrolled.connect(func(_offset: Vector2) -> void: events.append("scroll"))
	gesture.dragged.connect(func(_offset: Vector2) -> void: events.append("drag"))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = Vector2(100, 100)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.global_position = press.global_position
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.global_position = Vector2(100, 140)
	gesture.feed(press)
	gesture._process(0.2)
	gesture.feed(release)
	check(events.is_empty() and not gesture.blocks_selection, "ReorderGesture: 짧은 탭은 선택 유지")
	gesture.feed(press)
	gesture.feed(motion)
	gesture._process(1.0)
	gesture.feed(release)
	check(events == ["scroll"] and gesture.blocks_selection, "ReorderGesture: 먼저 움직이면 스크롤, 집기와 선택 억제")
	events.clear()
	gesture.feed(press)
	gesture._process(0.45)
	gesture.feed(motion)
	gesture.feed(release)
	gesture.feed(release)
	check(events == ["pick", "drag", "drop"], "ReorderGesture: 길게 눌러 집고 끌고 한 번만 놓기")
	events.clear()
	gesture.hold_seconds = 0.0
	gesture.feed(press)
	check(events == ["pick"], "ReorderGesture: 손잡이는 기다리지 않고 집기")
	gesture.cancel()
	gesture.feed(release)
	check(events == ["pick", "cancel"], "ReorderGesture: 취소 후 손을 떼도 drop 없음")
	events.clear()
	gesture.hold_seconds = 0.45
	gesture.feed(press)
	gesture.scroll_started()
	gesture._process(1.0)
	check(events.is_empty() and gesture.blocks_selection, "ReorderGesture: 모바일 스크롤 시작 후 길게 누르기 취소")
	gesture.cancel()
	gesture.feed(press)
	gesture._process(0.45)
	motion.button_mask = 0
	gesture.feed(motion)
	check(events == ["pick", "drop"], "ReorderGesture: release 유실 시 버튼 상태로 종료")
	gesture.free()
