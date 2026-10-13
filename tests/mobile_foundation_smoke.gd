extends TestCase

# addons/mobile_foundation 모듈의 경계값 검사를 이 프로젝트의 harness에 잇는다.
# 순수 계산은 모듈 안(MobileFoundationChecks)에 있어 다른 프로젝트로 그대로 옮겨진다.
# 새 프로젝트에서는 이 파일만 그쪽 harness에 맞춰 다시 쓰면 된다.


func run_tests() -> void:
	MobileFoundationChecks.run(
		func(passed: bool, description: String) -> void: check(passed, description)
	)
	# 노드 동작은 SceneTree에서 확인한다.
	_check_keyboard_avoider_node()
	_check_reorder_gesture()


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
