class_name TopNotification
extends Control

const EDGE_MARGIN := 32.0
const TOP_OFFSET := 72.0
const HOST_HEIGHT := 144.0
const DEFAULT_DURATION := 2.5
const FADE_IN_DURATION := 0.18
const FADE_OUT_DURATION := 0.5

@onready var positioner: CenterContainer = $Positioner
@onready var message_label: Label = $Positioner/Panel/Message
@onready var dismiss_timer: Timer = $DismissTimer

var _fade_tween: Tween


func _ready() -> void:
	# 에디터에서 켜 두고 배치를 확인해도 실행 중에는 안내가 올 때만 보인다.
	hide()
	dismiss_timer.timeout.connect(_on_dismiss_timer_timeout)
	positioner.resized.connect(_update_message_width)


func show_message(message: String, duration: float = DEFAULT_DURATION) -> void:
	if message.is_empty():
		hide_message()
		return

	var was_visible := visible
	_stop_fade()
	dismiss_timer.stop()
	message_label.text = message
	_update_message_width()
	show()
	if was_visible:
		# 떠 있는 안내를 갈아 끼울 때는 곧바로 또렷하게 되돌린다.
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	dismiss_timer.start(duration)


func hide_message() -> void:
	dismiss_timer.stop()
	_stop_fade()
	hide()
	modulate.a = 1.0


func _update_message_width() -> void:
	var font := message_label.get_theme_font("font")
	var font_size := message_label.get_theme_font_size("font_size")
	var text_width := 0.0
	for line in message_label.text.split("\n"):
		text_width = maxf(text_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var panel := message_label.get_parent() as PanelContainer
	var padding := panel.get_theme_stylebox("panel").get_minimum_size().x
	message_label.custom_minimum_size.x = minf(ceilf(text_width), maxf(1.0, positioner.size.x - padding))


func set_safe_insets(safe_insets: Vector4) -> void:
	positioner.offset_left = EDGE_MARGIN + safe_insets.x
	positioner.offset_top = TOP_OFFSET + safe_insets.y
	positioner.offset_right = -(EDGE_MARGIN + safe_insets.z)
	positioner.offset_bottom = positioner.offset_top + HOST_HEIGHT


func _on_dismiss_timer_timeout() -> void:
	_stop_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
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
