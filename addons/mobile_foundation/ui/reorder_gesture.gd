class_name ReorderGesture
extends Node

## gui_input의 마우스 이벤트(터치 에뮬레이션 포함)를 집기/끌기/스크롤로 구분한다.
## 화면 이동, 시각 효과, 목록 순서와 저장은 이 노드를 사용하는 쪽이 맡는다.
signal picked
signal dragged(offset: Vector2)
signal dropped(pointer: Vector2)
signal canceled
signal scrolled(offset: Vector2)

enum State { IDLE, PENDING, SCROLLING, DRAGGING }

@export var surface: Control
@export var hold_seconds := 0.45
@export var move_cancel_distance := 16.0

var state := State.IDLE
var blocks_selection := false
var _origin := Vector2.ZERO
var _elapsed := 0.0
var _generation := 0


func _ready() -> void:
	set_process(false)


func feed(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			cancel()
			_generation += 1
			blocks_selection = false
			_origin = event.global_position
			_elapsed = 0.0
			state = State.PENDING
			set_process(true)
			if hold_seconds <= 0.0:
				_pick()
		else:
			_release(event.global_position)
	elif event is InputEventMouseMotion and state != State.IDLE:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_release(event.global_position)
			return
		var offset: Vector2 = event.global_position - _origin
		if state == State.PENDING and offset.length() > move_cancel_distance:
			state = State.SCROLLING
			blocks_selection = true
		if state == State.SCROLLING:
			scrolled.emit(offset)
		elif state == State.DRAGGING:
			dragged.emit(offset)


func _process(delta: float) -> void:
	if is_instance_valid(surface) and not surface.is_visible_in_tree():
		cancel()
		return
	if state == State.PENDING:
		_elapsed += delta
		if _elapsed >= hold_seconds:
			_pick()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel()


func cancel() -> void:
	var was_dragging := state == State.DRAGGING
	if state != State.IDLE:
		blocks_selection = true
	state = State.IDLE
	set_process(false)
	if was_dragging:
		canceled.emit()


func scroll_started() -> void:
	if state == State.PENDING:
		state = State.SCROLLING
		blocks_selection = true


func _pick() -> void:
	state = State.DRAGGING
	blocks_selection = true
	picked.emit()


func _release(pointer: Vector2) -> void:
	var was_dragging := state == State.DRAGGING
	state = State.IDLE
	set_process(false)
	if was_dragging:
		dropped.emit(pointer)
	# Button.pressed와 gui_input release의 처리 순서에 상관없이 이번 클릭을 막는다.
	_clear_selection_block.call_deferred(_generation)


func _clear_selection_block(generation: int) -> void:
	if generation == _generation and state == State.IDLE:
		blocks_selection = false
