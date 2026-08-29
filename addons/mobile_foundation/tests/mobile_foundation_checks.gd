class_name MobileFoundationChecks
extends RefCounted

# 모듈 전체의 경계값 검사. 어떤 테스트 harness에도 매이지 않는다.
#
# report는 func(passed: bool, description: String) -> void 형태의 Callable이다.
# 쓰는 쪽에서 자기 harness의 단언 함수를 넘기면 그대로 결과가 흘러 들어간다.
# harness가 없다면 print만 하는 Callable을 넘겨도 된다.
#
#	MobileFoundationChecks.run(func(ok, description): check(ok, description))


static func run(report: Callable) -> void:
	_check_drag_bounds(report)
	_check_list_insertion(report)
	_check_array_order(report)
	_check_safe_area(report)
	_check_keyboard_avoider(report)


static func _check_drag_bounds(report: Callable) -> void:
	var bounds := Rect2(0, 0, 300, 300)
	var size := Vector2(100, 100)

	report.call(
		DragBounds.clamped_position(Vector2(50, 50), size, Vector2.ONE, bounds)
		== Vector2(50, 50),
		"DragBounds: 안쪽 자리는 그대로 둔다"
	)
	report.call(
		DragBounds.clamped_position(Vector2(-40, -40), size, Vector2.ONE, bounds)
		== Vector2.ZERO,
		"DragBounds: 왼쪽 위로 넘치면 경계에 붙인다"
	)
	report.call(
		DragBounds.clamped_position(Vector2(999, 999), size, Vector2.ONE, bounds)
		== Vector2(200, 200),
		"DragBounds: 오른쪽 아래로 넘치면 경계에 붙인다"
	)
	report.call(
		DragBounds.clamped_position(Vector2(0, 0), size, Vector2.ONE, bounds)
		== Vector2.ZERO
		and DragBounds.clamped_position(Vector2(200, 200), size, Vector2.ONE, bounds)
		== Vector2(200, 200),
		"DragBounds: 경계에 딱 맞는 자리는 움직이지 않는다"
	)

	# 1.1배로 커지면 각 변이 5씩 밖으로 나오므로 그만큼 안쪽으로 묶여야 한다.
	var scaled := Vector2.ONE * 1.1
	report.call(
		DragBounds.clamped_position(Vector2(-40, -40), size, scaled, bounds)
		== Vector2(5, 5),
		"DragBounds: 커진 항목은 삐져나온 폭만큼 더 안쪽에서 멈춘다"
	)
	report.call(
		DragBounds.clamped_position(Vector2(999, 999), size, scaled, bounds)
		== Vector2(195, 195),
		"DragBounds: 커진 항목의 오른쪽 아래도 테두리가 잘리지 않는다"
	)
	report.call(
		DragBounds.clamped_position(
			Vector2(999, 999), Vector2(400, 400), Vector2.ONE, bounds
		) == Vector2.ZERO,
		"DragBounds: 항목이 영역보다 크면 시작 지점에 둔다"
	)
	report.call(
		DragBounds.clamped_position(
			Vector2(80, 80), size, Vector2.ONE, Rect2(0, 0, 0, 0)
		) == Vector2.ZERO,
		"DragBounds: 영역이 비어 있어도 시작 지점으로 묶는다"
	)

	# 영역이 원점에 있지 않아도 그 안쪽으로 묶여야 한다.
	var offset_bounds := Rect2(50, 20, 200, 200)
	report.call(
		DragBounds.clamped_position(Vector2(-999, -999), size, Vector2.ONE, offset_bounds)
		== Vector2(50, 20)
		and DragBounds.clamped_position(Vector2(999, 999), size, Vector2.ONE, offset_bounds)
		== Vector2(150, 120),
		"DragBounds: 원점에서 떨어진 영역도 그 경계를 쓴다"
	)


static func _check_list_insertion(report: Callable) -> void:
	report.call(
		ListInsertion.target_index(4, 0, 2, false) == 1
		and ListInsertion.target_index(4, 0, 2, true) == 2,
		"ListInsertion: 아래 항목의 앞뒤 경계를 최종 index로 바꾼다"
	)
	report.call(
		ListInsertion.target_index(4, 3, 1, false) == 1
		and ListInsertion.target_index(4, 3, 1, true) == 2,
		"ListInsertion: 위로 끌어도 앞뒤 경계를 최종 index로 바꾼다"
	)
	report.call(
		ListInsertion.target_index(4, 1, 0, true) == 1
		and ListInsertion.target_index(4, 1, 2, false) == 1,
		"ListInsertion: 현재 자리의 양쪽 경계는 순서를 유지한다"
	)
	report.call(
		ListInsertion.target_index(1, 0, 0, false) == -1
		and ListInsertion.target_index(3, 0, 0, true) == -1,
		"ListInsertion: 경계가 없거나 움직이는 항목 자체면 거부한다"
	)
	report.call(
		ListInsertion.target_index(3, -1, 1, true) == -1
		and ListInsertion.target_index(3, 3, 1, true) == -1
		and ListInsertion.target_index(3, 1, -1, true) == -1
		and ListInsertion.target_index(3, 1, 3, true) == -1,
		"ListInsertion: 범위 밖 index는 거부한다"
	)
	report.call(
		ListInsertion.target_index(0, 0, 0, true) == -1,
		"ListInsertion: 빈 목록은 거부한다"
	)
	report.call(
		ListInsertion.target_index(3, 0, 2, true) == 2
		and ListInsertion.target_index(3, 2, 0, false) == 0,
		"ListInsertion: 양 끝으로 옮기면 마지막과 첫 자리가 된다"
	)

	report.call(
		ListInsertion.insertion_index(3, 0, false) == 0
		and ListInsertion.insertion_index(3, 0, true) == 1
		and ListInsertion.insertion_index(3, 2, true) == 3,
		"ListInsertion: 새 항목은 경계 그대로 끼워 넣는다"
	)
	report.call(
		ListInsertion.insertion_index(0, 0, true) == 0
		and ListInsertion.insertion_index(3, -1, true) == 0
		and ListInsertion.insertion_index(3, 9, false) == 3,
		"ListInsertion: 새 항목의 범위 밖 경계는 양 끝으로 읽는다"
	)


static func _check_array_order(report: Callable) -> void:
	var items := ["A", "B", "C"]

	report.call(
		ArrayOrder.moved(items, 0, 2) == ["B", "C", "A"],
		"ArrayOrder: 아래로 옮기면 사이 항목이 앞으로 당겨진다"
	)
	report.call(
		ArrayOrder.moved(items, 2, 0) == ["C", "A", "B"],
		"ArrayOrder: 위로 옮기면 사이 항목이 뒤로 밀린다"
	)
	report.call(
		items == ["A", "B", "C"],
		"ArrayOrder: 원본 배열은 그대로 둔다"
	)
	report.call(
		ArrayOrder.moved(items, 1, 1) == ["A", "B", "C"],
		"ArrayOrder: 같은 자리로 옮기면 그대로다"
	)
	report.call(
		ArrayOrder.moved(items, 0, 99) == ["B", "C", "A"]
		and ArrayOrder.moved(items, 2, -99) == ["C", "A", "B"],
		"ArrayOrder: 범위를 넘는 목적지는 양 끝으로 묶는다"
	)
	report.call(
		ArrayOrder.moved(items, 5, 0) == ["A", "B", "C"]
		and ArrayOrder.moved(items, -1, 0) == ["A", "B", "C"],
		"ArrayOrder: 없는 항목을 옮기면 아무 일도 없다"
	)
	report.call(
		ArrayOrder.moved([], 0, 0) == []
		and ArrayOrder.moved(["only"], 0, 0) == ["only"],
		"ArrayOrder: 비었거나 하나뿐인 배열도 안전하다"
	)

	# 타입이 있는 배열을 넘겨도 원소가 유지되고, assign()으로 타입을 되찾을 수 있다.
	var typed: Array[int] = [1, 2, 3]
	var restored: Array[int] = []
	restored.assign(ArrayOrder.moved(typed, 0, 2))
	report.call(
		restored == [2, 3, 1] and typed == [1, 2, 3],
		"ArrayOrder: 타입이 있는 배열도 assign()으로 그대로 되받는다"
	)


static func _check_safe_area(report: Callable) -> void:
	# 창과 viewport가 같은 크기면 배율이 1이라 안전 영역이 그대로 여백이 된다.
	report.call(
		SafeArea.insets_in_viewport(
			Rect2i(0, 60, 1080, 2100), Vector2i(1080, 2200), Vector2(1080, 2200)
		) == Vector4(0, 60, 0, 40),
		"SafeArea: 배율이 1이면 안전 영역이 그대로 여백이 된다"
	)
	# viewport가 창의 절반이면 여백도 절반이다.
	report.call(
		SafeArea.insets_in_viewport(
			Rect2i(0, 60, 1080, 2100), Vector2i(1080, 2200), Vector2(540, 1100)
		) == Vector4(0, 30, 0, 20),
		"SafeArea: viewport가 작으면 여백도 같은 비율로 줄어든다"
	)
	report.call(
		SafeArea.insets_in_viewport(
			Rect2i(30, 0, 1020, 2200), Vector2i(1080, 2200), Vector2(1080, 2200)
		) == Vector4(30, 0, 30, 0),
		"SafeArea: 가로로 누운 화면의 좌우 여백도 구한다"
	)
	report.call(
		SafeArea.insets_in_viewport(
			Rect2i(0, 0, 1080, 2200), Vector2i(1080, 2200), Vector2(1080, 2200)
		) == Vector4.ZERO,
		"SafeArea: 안전 영역이 창 전체면 여백이 없다"
	)
	report.call(
		SafeArea.insets_in_viewport(
			Rect2i(0, 0, 0, 0), Vector2i(0, 0), Vector2(720, 1280)
		) == Vector4.ZERO
		and SafeArea.insets_in_viewport(
			Rect2i(0, 0, 100, 100), Vector2i(-10, 100), Vector2(720, 1280)
		) == Vector4.ZERO,
		"SafeArea: 창 크기를 아직 모르면 여백을 0으로 둔다"
	)
	# 안전 영역이 창보다 넓게 보고되어도 음수 여백을 만들지 않는다.
	report.call(
		SafeArea.insets_in_viewport(
			Rect2i(-20, -20, 1200, 2400), Vector2i(1080, 2200), Vector2(1080, 2200)
		) == Vector4.ZERO,
		"SafeArea: 창 밖까지 걸친 안전 영역도 음수 여백을 만들지 않는다"
	)
	# 데스크톱에서 부르는 것만으로 DisplayServer 조회가 새지 않아야 한다.
	report.call(
		SafeArea.is_handheld() or SafeArea.current_insets(Vector2(720, 1280)) == Vector4.ZERO,
		"SafeArea: 손에 드는 기기가 아니면 여백을 묻지 않는다"
	)


static func _check_keyboard_avoider(report: Callable) -> void:
	report.call(
		KeyboardInsetAvoider.scaled_keyboard_height(
			1100, Vector2i(1080, 2200), Vector2(540, 1100)
		) == 550.0,
		"KeyboardInsetAvoider: 키보드 높이를 viewport 배율로 환산한다"
	)
	report.call(
		KeyboardInsetAvoider.scaled_keyboard_height(0, Vector2i(1080, 2200), Vector2(540, 1100))
		== 0.0
		and KeyboardInsetAvoider.scaled_keyboard_height(100, Vector2i(1080, 0), Vector2(540, 1100))
		== 0.0
		and KeyboardInsetAvoider.scaled_keyboard_height(100, Vector2i(1080, 2200), Vector2(540, 0))
		== 0.0,
		"KeyboardInsetAvoider: 키보드나 화면 높이가 없으면 0이다"
	)

	# 화면 1000, 키보드 400, 여백 24면 보이는 아래끝은 576이다.
	report.call(
		KeyboardInsetAvoider.required_shift(500.0, 400.0, 400.0, 1000.0) == 0.0,
		"KeyboardInsetAvoider: 이미 키보드 위에 있으면 올리지 않는다"
	)
	report.call(
		KeyboardInsetAvoider.required_shift(600.0, 500.0, 400.0, 1000.0) == 24.0,
		"KeyboardInsetAvoider: 가려진 만큼만 올린다"
	)
	report.call(
		KeyboardInsetAvoider.required_shift(576.0, 500.0, 400.0, 1000.0) == 0.0,
		"KeyboardInsetAvoider: 아래끝이 경계에 딱 닿으면 올리지 않는다"
	)
	# 위끝이 20이면 16까지만 올릴 수 있어 4보다 더 올라가지 않는다.
	report.call(
		KeyboardInsetAvoider.required_shift(900.0, 20.0, 400.0, 1000.0) == 4.0,
		"KeyboardInsetAvoider: 위끝이 화면 밖으로 밀려나지 않는 선에서 멈춘다"
	)
	report.call(
		KeyboardInsetAvoider.required_shift(900.0, 10.0, 400.0, 1000.0) == 0.0,
		"KeyboardInsetAvoider: 더 올릴 자리가 없으면 그대로 둔다"
	)
	report.call(
		KeyboardInsetAvoider.required_shift(900.0, 500.0, 0.0, 1000.0) == 0.0
		and KeyboardInsetAvoider.required_shift(900.0, 500.0, 400.0, 0.0) == 0.0,
		"KeyboardInsetAvoider: 키보드가 없거나 화면이 없으면 올리지 않는다"
	)
	report.call(
		KeyboardInsetAvoider.required_shift(600.0, 500.0, 400.0, 1000.0, 0.0, 0.0) == 0.0,
		"KeyboardInsetAvoider: 여백을 0으로 주면 경계까지 꽉 쓴다"
	)
