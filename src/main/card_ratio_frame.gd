class_name CardRatioFrame
extends PanelContainer

# 편집 화면의 프레임도 학습·상세 카드와 같은 2:3 비율을 지킨다.
# 부모 Stage 안에서 자유 배치로 살며, Stage 크기가 바뀔 때마다 가운데로 다시 맞춘다.

const CARD_ASPECT_RATIO := 2.0 / 3.0

@onready var card_stage: Control = get_parent() as Control


func _ready() -> void:
	card_stage.resized.connect(fit_to_stage)
	fit_to_stage()


func fit_to_stage() -> void:
	var card_rect := AspectFit.centered_rect(
		Rect2(Vector2.ZERO, card_stage.size),
		CARD_ASPECT_RATIO
	)
	position = card_rect.position
	size = card_rect.size
