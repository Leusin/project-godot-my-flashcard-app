using System.Collections.Generic;

namespace MyFlashCard.Core;

// 세션 큐 규칙만 담당한다. UI·저장·WrongCount 갱신은 모른다.
// 순서는 받은 카드 순서 그대로 (v0.1은 고정 순서).
public sealed class StudySession
{
    private readonly Queue<Card> _queue;

    public StudySession(IEnumerable<Card> cards)
    {
        _queue = new Queue<Card>(cards);
    }

    public Card? Current => _queue.Count > 0 ? _queue.Peek() : null;
    public bool IsFinished => _queue.Count == 0;
    public int Remaining => _queue.Count;

    // Again: 현재 카드를 큐 맨 뒤로 보낸다 (DESIGN.md 학습 규칙).
    public void Again()
    {
        if (_queue.Count > 0)
            _queue.Enqueue(_queue.Dequeue());
    }

    // Good: 현재 카드를 이번 세션에서 완료 처리한다.
    public void Good()
    {
        if (_queue.Count > 0)
            _queue.Dequeue();
    }
}
