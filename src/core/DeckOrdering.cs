using System;
using System.Collections.Generic;

namespace MyFlashCard.Core;

// 학습 순서의 종류. 카드 자체나 세션 큐(StudySession)는 이 값을 모른다 —
// 세션을 만들기 전에 순서를 미리 정해서 넘기는 쪽(Study)만 안다.
public enum StudyOrder
{
	Sequential,
	Shuffle,
}

// 카드 목록에 학습 순서를 적용하는 규칙만 담당한다. 큐 관리·화면은 모른다.
public static class DeckOrdering
{
	// Sequential은 원본 순서를 그대로 복사해 돌려준다 (원본 리스트는 바꾸지 않는다).
	// Shuffle은 Fisher-Yates로 섞는다. rng를 생략하면 매번 다르고, 넘기면 테스트에서 재현 가능하다.
	public static List<Card> Apply(StudyOrder order, IReadOnlyList<Card> cards, Random? rng = null)
	{
		var result = new List<Card>(cards);
		if (order != StudyOrder.Shuffle)
		{
			return result;
		}

		rng ??= new Random();
		for (var i = result.Count - 1; i > 0; i--)
		{
			var j = rng.Next(i + 1);
			(result[i], result[j]) = (result[j], result[i]);
		}

		return result;
	}
}
