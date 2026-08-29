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

	avoider.queue_free()
