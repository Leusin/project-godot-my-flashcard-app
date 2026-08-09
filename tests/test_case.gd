class_name TestCase
extends Node

# 검사 한 묶음. 결과를 세기만 하고 앱을 끝내지 않는다 —
# 종료 시점은 모든 테스트의 결과를 다 아는 TestRunner만 정할 수 있다.

var checks := 0
var failures := 0

func _ready() -> void:
	# tests.tscn의 자식으로 실행될 때는 중앙 TestRunner가 담당한다.
	if get_tree().current_scene != self:
		return

	print("# %s" % name)
	run_tests()
	print("")
	print("RESULT: %d checks, %d failures" % [checks, failures])

	if failures > 0:
		push_error("FAIL: %d checks failed" % failures)

	get_tree().quit(failures)

# 하위 테스트가 구현한다. _ready()가 아니라 러너가 부르는 것은
# 실행 순서와 결과 수집을 한 곳에서 쥐기 위해서다.
func run_tests() -> void:
	push_error("FAIL: %s가 run_tests()를 구현하지 않았다" % name)
	failures += 1


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: %s" % description)
		return

	failures += 1
	push_error("FAIL: %s" % description)
