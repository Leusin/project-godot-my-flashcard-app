class_name ReorderHandle
extends Button

signal drag_started
signal drag_moved(viewport_position: Vector2)
signal drag_finished

var _dragging := false


func _ready() -> void:
	button_down.connect(_begin_drag)
	button_up.connect(_finish_drag)
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			get_viewport().set_input_as_handled()
			drag_moved.emit(mouse_motion.position)
	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
		drag_moved.emit((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			get_viewport().set_input_as_handled()
			_finish_drag()
	elif event is InputEventScreenTouch:
		if not (event as InputEventScreenTouch).pressed:
			get_viewport().set_input_as_handled()
			_finish_drag()


func _begin_drag() -> void:
	if _dragging:
		return
	_dragging = true
	drag_started.emit()


func _finish_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	drag_finished.emit()


func is_dragging() -> bool:
	return _dragging


func _exit_tree() -> void:
	_dragging = false
