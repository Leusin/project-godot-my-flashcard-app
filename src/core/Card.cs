namespace MyFlashCard.Core;

// Markdown에서 파싱된 카드 한 장. 진행도와 상태는 모른다.
public sealed record Card(string Question, string Answer);
