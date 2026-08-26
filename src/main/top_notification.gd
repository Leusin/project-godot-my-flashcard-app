class_name TopNotification
extends Control

const EDGE_MARGIN := 32.0
const HOST_HEIGHT := 144.0
const DEFAULT_DURATION := 2.5
const FADE_DURATION := 0.5

@onready var positioner: CenterContainer = $Positioner
@onready var message_label: Label = $Positioner/Panel/Message
@onready var dismiss_timer: Timer = $DismissTimer

var _fade_tween: Tween


func _ready() -> void:
	# 에디터에서 켜 두고 배치를 확인해도 실행 중에는 안내가 올 때만 보인다.
	hide()
	dismiss_timer.timeout.connect(_on_dismiss_timer_timeout)


func show_message(message: String, duration: float = DEFAULT_DURATION) -> void:
	if message.is_empty():
		hide_message()
		return

	_stop_fade()
	dismiss_timer.stop()
	message_label.text = message
	modulate.a = 1.0
	show()
	dismiss_timer.start(duration)


func hide_message() -> void:
	dismiss_timer.stop()
	_stop_fade()
	hide()
	modulate.a = 1.0


func set_safe_insets(safe_insets: Vector4) -> void:
	positioner.offset_left = EDGE_MARGIN + safe_insets.x
	positioner.offset_top = EDGE_MARGIN + safe_insets.y
	positioner.offset_right = -(EDGE_MARGIN + safe_insets.z)
	positioner.offset_bottom = positioner.offset_top + HOST_HEIGHT


func _on_dismiss_timer_timeout() -> void:
	_stop_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.finished.connect(_on_fade_finished)


func _on_fade_finished() -> void:
	_fade_tween = null
	hide()
	modulate.a = 1.0


func _stop_fade() -> void:
	if _fade_tween == null:
		return
	_fade_tween.kill()
	_fade_tween = null
