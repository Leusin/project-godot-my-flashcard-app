using System.Collections.Generic;

namespace MyFlashCard.Core;

// 세션 큐 규칙만 담당한다. UI·저장·WrongCount 갱신은 모른다.
// 순서는 받은 카드 순서 그대로 (v0.1은 고정 순서).
// Again/Good 같은 판정은 여기서 구분하지 않는다 — 어느 쪽이든 다음 카드로 넘어간다.
public sealed class StudySession
{
	private readonly Queue<Card> _queue;

	public StudySession(IEnumerable<Card> cards)
	{
		this._queue = new Queue<Card>(cards);
	}

	public Card? Current => this._queue.Count > 0 ? this._queue.Peek() : null;
	public bool IsFinished => this._queue.Count == 0;
	public int Remaining => this._queue.Count;

	// 현재 카드를 끝내고 다음으로 넘어간다. 한 번 나온 카드는 이번 세션에 다시 나오지 않는다.
	public void Next()
	{
		if (this._queue.Count > 0)
		{
			this._queue.Dequeue();
		}
	}
}
