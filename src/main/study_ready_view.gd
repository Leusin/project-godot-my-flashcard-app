class_name StudyReadyView
extends VBoxContainer

# 학습 준비 화면의 골격. 받은 요약을 그리고 버튼 입력을 사실 그대로 올린다.
# 어떤 범위로 학습을 시작할지, 이어하기 기록이 유효한지 같은 해석은 main.gd가 맡는다.

signal back_pressed
signal menu_pressed(anchor: Control)
signal continue_pressed
signal manage_cards_pressed
signal start_study_pressed

@onready var back_button: Button = $Header/LeftActions/BackToLibraryButton
@onready var menu_button: Button = $Header/RightActions/ReadyDeckMenuButton

@onready var overview: VBoxContainer = (
	$DeckStage/DeckStack/DeckCover/Margin/OverviewContent
)

var _has_resume := false
var _resume_scope := -1
var _resume_order := -1
var _primary_styles: Dictionary = {}
var _secondary_styles: Dictionary = {}

@onready var completion_label: Label = overview.get_node("CompletionLabel")
@onready var deck_name_label: Label = overview.get_node("ReadyDeckNameLabel")
@onready var total_count_label: Label = overview.get_node("Stats/Total/ReadyTotalCountLabel")
@onready var new_count_label: Label = overview.get_node("Stats/New/ReadyNewCountLabel")
@onready var learning_count_label: Label = overview.get_node("Stats/Learning/ReadyLearningCountLabel")
@onready var mastered_count_label: Label = overview.get_node("Stats/Mastered/ReadyMasteredCountLabel")
@onready var mastery_progress: ProgressBar = overview.get_node("MasteryProgress")
@onready var continue_button: Button = overview.get_node("ContinueStudyButton")
@onready var manage_cards_button: Button = overview.get_node("ManageCardsButton")

@onready var scope_option: OptionButton = overview.get_node("SettingsInset/StudySettings/Scope/StudyScopeOption")
@onready var order_option: OptionButton = overview.get_node("SettingsInset/StudySettings/Order/StudyOrderOption")
@onready var start_button: Button = overview.get_node("StartStudyButton")


func _ready() -> void:
	for state in ["normal", "hover", "pressed"]:
		_primary_styles[state] = continue_button.get_theme_stylebox(state)
		_secondary_styles[state] = start_button.get_theme_stylebox(state)
	scope_option.item_selected.connect(func(_index: int) -> void: _refresh_primary_action())
	order_option.item_selected.connect(func(_index: int) -> void: _refresh_primary_action())
	_refresh_primary_action()
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit(menu_button))
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	manage_cards_button.pressed.connect(func() -> void: manage_cards_pressed.emit())
	start_button.pressed.connect(func() -> void: start_study_pressed.emit())


# 범위와 순서의 의미는 App이 정하므로 표시 문구와 id를 그대로 받는다.
func clear_options() -> void:
	scope_option.clear()
	order_option.clear()


func add_scope_option(label: String, id: int) -> void:
	scope_option.add_item(label, id)


func add_order_option(label: String, id: int) -> void:
	order_option.add_item(label, id)


func selected_scope() -> int:
	return scope_option.get_selected_id()


func selected_order() -> int:
	return order_option.get_selected_id()


func select_scope(id: int) -> void:
	scope_option.select(scope_option.get_item_index(id))
	_refresh_primary_action()


func select_order(id: int) -> void:
	order_option.select(order_option.get_item_index(id))
	_refresh_primary_action()


func render_summary(
	deck_name: String,
	total_count: int,
	new_count: int,
	learning_count: int,
	mastered_count: int
) -> void:
	deck_name_label.text = deck_name
	total_count_label.text = str(total_count)
	new_count_label.text = str(new_count)
	learning_count_label.text = str(learning_count)
	mastered_count_label.text = str(mastered_count)
	mastery_progress.max_value = maxi(total_count, 1)
	mastery_progress.value = mastered_count
	completion_label.text = "완료 %d / %d장" % [mastered_count, total_count]


func set_continue_action(label: String, scope: int, order: int) -> void:
	_has_resume = true
	_resume_scope = scope
	_resume_order = order
	continue_button.text = label
	continue_button.show()
	start_button.text = "새로 시작"
	_refresh_primary_action()


func hide_continue_action() -> void:
	_has_resume = false
	continue_button.hide()
	start_button.text = "학습 시작"
	_refresh_primary_action()


func _refresh_primary_action() -> void:
	var matches_resume := (
		_has_resume
		and selected_scope() == _resume_scope
		and selected_order() == _resume_order
	)
	_set_primary(continue_button, matches_resume)
	_set_primary(start_button, not matches_resume)


func _set_primary(button: Button, primary: bool) -> void:
	var styles := _primary_styles if primary else _secondary_styles
	for state in styles:
		button.add_theme_stylebox_override(state, styles[state])
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color.WHITE if primary else Color.BLACK)
