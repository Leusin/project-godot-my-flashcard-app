class_name ModalDialog
extends ColorRect

@export var title_text := "확인"
@export_multiline var description_text := ""
@export var input_visible := false
@export var input_placeholder := ""
@export var secondary_button_text := "취소"
@export var primary_button_text := "확인"
@export var panel_height := 360.0
@export var bottom_margin := 40.0

# Android 시스템 바에 시트가 겹치지 않도록 App이 안전 영역 하단 값을 넣어 준다.
var bottom_inset := 0.0

@onready var dialog_panel: PanelContainer = $KeyboardShift/DialogPanel
@onready var title_label: Label = $KeyboardShift/DialogPanel/Margin/Content/DialogTitle
@onready var description_label: Label = $KeyboardShift/DialogPanel/Margin/Content/DialogDescription
@onready var dialog_input: LineEdit = $KeyboardShift/DialogPanel/Margin/Content/DialogInput
@onready var error_label: Label = $KeyboardShift/DialogPanel/Margin/Content/DialogError
@onready var secondary_button: Button = $KeyboardShift/DialogPanel/Margin/Content/Buttons/SecondaryButton
@onready var primary_button: Button = $KeyboardShift/DialogPanel/Margin/Content/Buttons/PrimaryButton


func _ready() -> void:
	apply_configuration()


func apply_configuration() -> void:
	title_label.text = title_text
	description_label.text = description_text
	description_label.visible = not description_text.is_empty()
	dialog_input.visible = input_visible
	dialog_input.placeholder_text = input_placeholder
	error_label.hide()
	secondary_button.text = secondary_button_text
	primary_button.text = primary_button_text
	_layout_panel()


func set_bottom_inset(inset: float) -> void:
	bottom_inset = inset
	_layout_panel()


func _layout_panel() -> void:
	dialog_panel.custom_minimum_size = Vector2(600.0, panel_height)
	dialog_panel.anchor_left = 0.5
	dialog_panel.anchor_right = 0.5
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog_panel.offset_left = -300.0
	dialog_panel.offset_right = 300.0
	dialog_panel.offset_bottom = -(bottom_margin + bottom_inset)
	dialog_panel.offset_top = -(bottom_margin + bottom_inset + panel_height)
