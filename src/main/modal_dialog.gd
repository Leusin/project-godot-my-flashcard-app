class_name ModalDialog
extends ColorRect

@export var title_text := "확인"
@export_multiline var description_text := ""
@export var input_visible := false
@export var input_placeholder := ""
@export var secondary_button_text := "취소"
@export var primary_button_text := "확인"
@export var panel_height := 360.0
@export_range(0.2, 0.5, 0.01) var input_panel_center_y_ratio := 0.28

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
	dialog_panel.custom_minimum_size = Vector2(600.0, panel_height)
	var center_y_ratio := input_panel_center_y_ratio if input_visible else 0.5
	dialog_panel.anchor_top = center_y_ratio
	dialog_panel.anchor_bottom = center_y_ratio
	dialog_panel.offset_left = -300.0
	dialog_panel.offset_top = -panel_height * 0.5
	dialog_panel.offset_right = 300.0
	dialog_panel.offset_bottom = panel_height * 0.5
