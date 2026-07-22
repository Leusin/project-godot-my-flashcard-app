namespace MyFlashCard.Core;

// 카드의 학습 상태. 사용자가 수동으로 정하는 표시용 라벨이고, 학습 동작에는 영향을 주지 않는다.
public enum CardStatus
{
	New,
	Learning,
	Mastered,
}
