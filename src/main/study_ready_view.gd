class_name StudyReadyView
extends VBoxContainer

# 학습 준비 화면의 골격. 받은 요약을 그리고 버튼 입력을 사실 그대로 올린다.
# 어떤 범위로 학습을 시작할지, 이어하기 기록이 유효한지 같은 해석은 main.gd가 맡는다.

signal back_pressed
signal menu_pressed(anchor: Control)
signal continue_pressed
signal open_setup_pressed
signal manage_cards_pressed
signal start_study_pressed
signal cancel_setup_pressed

@onready var back_button: Button = $Header/LeftActions/BackToLibraryButton
@onready var menu_button: Button = $Header/RightActions/ReadyDeckMenuButton

@onready var overview: VBoxContainer = (
	$DeckStage/DeckStack/DeckCover/Margin/OverviewContent
)
@onready var setup: VBoxContainer = (
	$DeckStage/DeckStack/DeckCover/Margin/NewStudyContent
)

@onready var deck_name_label: Label = overview.get_node("ReadyDeckNameLabel")
@onready var total_count_label: Label = overview.get_node("Stats/Total/ReadyTotalCountLabel")
@onready var new_count_label: Label = overview.get_node("Stats/New/ReadyNewCountLabel")
@onready var learning_count_label: Label = overview.get_node("Stats/Learning/ReadyLearningCountLabel")
@onready var mastered_count_label: Label = overview.get_node("Stats/Mastered/ReadyMasteredCountLabel")
@onready var mastery_progress: ProgressBar = overview.get_node("MasteryProgress")
@onready var continue_button: Button = overview.get_node("ContinueStudyButton")
@onready var open_setup_button: Button = overview.get_node("OpenStudySetupButton")
@onready var manage_cards_button: Button = overview.get_node("ManageCardsButton")

@onready var setup_deck_name_label: Label = setup.get_node("SetupDeckNameLabel")
@onready var setup_description: Label = setup.get_node("SetupDescription")
@onready var scope_option: OptionButton = setup.get_node("StudyScopeOption")
@onready var order_option: OptionButton = setup.get_node("StudyOrderOption")
@onready var start_button: Button = setup.get_node("StartStudyButton")
@onready var cancel_setup_button: Button = setup.get_node("CancelStudySetupButton")


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit(menu_button))
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	open_setup_button.pressed.connect(func() -> void: open_setup_pressed.emit())
	manage_cards_button.pressed.connect(func() -> void: manage_cards_pressed.emit())
	start_button.pressed.connect(func() -> void: start_study_pressed.emit())
	cancel_setup_button.pressed.connect(func() -> void: cancel_setup_pressed.emit())


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
	scope_option.select(id)


func select_order(id: int) -> void:
	order_option.select(id)


func render_summary(
	deck_name: String,
	total_count: int,
	new_count: int,
	learning_count: int,
	mastered_count: int
) -> void:
	deck_name_label.text = deck_name
	setup_deck_name_label.text = deck_name
	total_count_label.text = str(total_count)
	new_count_label.text = str(new_count)
	learning_count_label.text = str(learning_count)
	mastered_count_label.text = str(mastered_count)
	mastery_progress.max_value = maxi(total_count, 1)
	mastery_progress.value = mastered_count


func show_overview() -> void:
	setup.hide()
	overview.show()


func show_setup(description: String, start_label: String) -> void:
	setup_description.text = description
	start_button.text = start_label
	overview.hide()
	setup.show()


func is_setup_visible() -> bool:
	return setup.visible


func set_continue_action(label: String) -> void:
	continue_button.text = label
	continue_button.show()


func hide_continue_action() -> void:
	continue_button.hide()
