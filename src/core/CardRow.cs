namespace MyFlashCard.Core;

// 카드 목록에 한 줄로 보여줄 사실: 질문과 틀린 횟수. 답과 파일 위치는 모른다.
public sealed record CardRow(
	string Question,
	int WrongCount);
