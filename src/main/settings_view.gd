class_name SettingsView
extends VBoxContainer

# 설정 화면의 node wiring과 파일 선택 dialog를 소유한다.
# 설정 저장, 백업 실행, 외부 링크 열기는 MainApp이 맡는다.

signal back_pressed
signal haptics_toggled(enabled: bool)
signal privacy_policy_pressed
signal copy_ai_prompt_pressed
signal backup_path_selected(path: String)
signal restore_path_selected(path: String)

@onready var back_button: Button = $Header/LeftActions/BackFromSettingsButton
@onready var learning_section: VBoxContainer = $SettingsScroll/Content/LearningSection
@onready var interaction_title: Label = (
	$SettingsScroll/Content/LearningSection/InteractionTitle
)
@onready var interaction_panel: PanelContainer = (
	$SettingsScroll/Content/LearningSection/InteractionPanel
)
@onready var haptics_toggle: CheckButton = (
	$SettingsScroll/Content/LearningSection/InteractionPanel/Margin/InteractionContent/HapticsRow/HapticsToggle
)
@onready var create_backup_button: Button = (
	$SettingsScroll/Content/DataSection/DataPanel/Margin/DataActions/CreateBackupButton
)
@onready var restore_backup_button: Button = (
	$SettingsScroll/Content/DataSection/DataPanel/Margin/DataActions/RestoreBackupButton
)
@onready var ai_prompt_preview_label: Label = (
	$SettingsScroll/Content/TipsSection/TipsPanel/Margin/TipsContent/PromptPreviewPanel/Margin/AiPromptPreviewLabel
)
@onready var copy_ai_prompt_button: Button = (
	$SettingsScroll/Content/TipsSection/TipsPanel/Margin/TipsContent/CopyAiPromptButton
)
@onready var privacy_policy_link: LinkButton = (
	$SettingsScroll/Content/InfoSection/InfoPanel/Margin/Content/PrivacyPolicyLink
)
@onready var app_version_label: Label = (
	$SettingsScroll/Content/InfoSection/InfoPanel/Margin/Content/AppVersionLabel
)
@onready var backup_dialog: FileDialog = $BackupDialog
@onready var restore_dialog: FileDialog = $RestoreDialog


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	haptics_toggle.toggled.connect(_on_haptics_toggled)
	privacy_policy_link.pressed.connect(_on_privacy_policy_pressed)
	copy_ai_prompt_button.pressed.connect(_on_copy_ai_prompt_pressed)
	create_backup_button.pressed.connect(_on_create_backup_pressed)
	restore_backup_button.pressed.connect(_on_restore_backup_pressed)
	backup_dialog.file_selected.connect(
		func(path: String) -> void: backup_path_selected.emit(path)
	)
	restore_dialog.file_selected.connect(
		func(path: String) -> void: restore_path_selected.emit(path)
	)
	_configure_backup_dialog(backup_dialog, FileDialog.FILE_MODE_SAVE_FILE)
	_configure_backup_dialog(restore_dialog, FileDialog.FILE_MODE_OPEN_FILE)


func configure(
	ai_prompt: String,
	haptics_enabled: bool,
	interaction_settings_visible: bool
) -> void:
	ai_prompt_preview_label.text = ai_prompt
	haptics_toggle.button_pressed = haptics_enabled
	learning_section.visible = interaction_settings_visible
	interaction_title.visible = interaction_settings_visible
	interaction_panel.visible = interaction_settings_visible


func set_version(version: String) -> void:
	app_version_label.text = "버전 %s" % version


func _on_haptics_toggled(enabled: bool) -> void:
	haptics_toggled.emit(enabled)


func _on_privacy_policy_pressed() -> void:
	privacy_policy_pressed.emit()


func _on_copy_ai_prompt_pressed() -> void:
	copy_ai_prompt_pressed.emit()


func _on_create_backup_pressed() -> void:
	var backup_time := Time.get_time_string_from_system().replace(":", "")
	backup_dialog.current_file = "my-flashcard-backup-%s-%s.zip" % [
		Time.get_date_string_from_system(),
		backup_time,
	]
	backup_dialog.popup_file_dialog()


func _on_restore_backup_pressed() -> void:
	restore_dialog.popup_file_dialog()


func _configure_backup_dialog(dialog: FileDialog, file_mode: int) -> void:
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = file_mode
	dialog.use_native_dialog = true
	dialog.clear_filters()
	dialog.add_filter("*.zip", "Backup", "application/zip")
