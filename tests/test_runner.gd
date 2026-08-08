extends Node

# 자식으로 붙은 TestCase를 순서대로 실행하고, 전체 실패 개수를 종료 코드로 돌려준다.
# quit()은 여기서만 부른다 — 개별 테스트가 부르면 먼저 부른 쪽이 이겨서 뒤 결과가 사라진다.


func _ready() -> void:
	var checks := 0
	var failures := 0

	for child in get_children():
		if child is not TestCase:
			continue

		var test_case := child as TestCase
		print("# %s" % test_case.name)
		test_case.run_tests()
		print("")
		checks += test_case.checks
		failures += test_case.failures

	print("RESULT: %d checks, %d failures" % [checks, failures])
	if failures > 0:
		push_error("FAIL: %d checks failed" % failures)

	# 종료 코드 = 실패 개수. 0이면 통과.
	get_tree().quit(failures)
