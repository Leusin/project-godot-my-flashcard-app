using System.Collections.Generic;

namespace MyFlashCard.Core;

// 세션 큐 규칙만 담당한다. UI·저장·WrongCount 갱신은 모른다.
// 순서는 받은 카드 순서 그대로 (섞는 건 세션을 만들기 전의 일).
// Again/Good 같은 판정은 여기서 구분하지 않는다 — 어느 쪽이든 다음 카드로 넘어간다.
public sealed class StudySession
{
	private readonly List<Card> _cards;
	private int _position;

	public StudySession(IEnumerable<Card> cards)
	{
		this._cards = new List<Card>(cards);
	}

	public Card? Current => this._position < this._cards.Count ? this._cards[this._position] : null;
	public bool IsFinished => this._position >= this._cards.Count;
	public int Remaining => this._cards.Count - this._position;

	// 현재 카드를 끝내고 다음으로 넘어간다. 한 번 나온 카드는 이번 세션에 다시 나오지 않는다.
	public void Next()
	{
		if (this._position < this._cards.Count)
		{
			this._position++;
		}
	}

	// 세션 중 편집으로 현재 카드의 내용이 바뀌었을 때 교체한다. 카드가 없으면 아무 일도 하지 않는다.
	public void ReplaceCurrent(Card card)
	{
		if (this._position < this._cards.Count)
		{
			this._cards[this._position] = card;
		}
	}
}
