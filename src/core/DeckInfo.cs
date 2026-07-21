namespace MyFlashCard.Core;

// 목록에 한 줄로 보여줄 덱의 사실. 파일 위치와 진행도는 모른다.
public sealed record DeckInfo(
	string FileName,
	string DisplayName,
	int CardCount);
