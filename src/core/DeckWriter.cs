using System.Collections.Generic;
using System.Text;

namespace MyFlashCard.Core;

// 카드 목록을 Markdown 텍스트로 되돌린다. DeckParser.Parse의 짝이며, 파일 IO는 모른다.
public static class DeckWriter
{
	public static string ToMarkdown(IEnumerable<Card> cards)
	{
		var sb = new StringBuilder();
		foreach (var card in cards)
		{
			sb.Append("# ").Append(card.Question).Append('\n');

			// 빈 답은 줄을 만들지 않는다. 
			if (card.Answer.Length > 0)
			{
				sb.Append(card.Answer).Append('\n');
			}
		}

		return sb.ToString();
	}
}
