using System.Collections.Generic;

namespace MyFlashCard.Core;

// Markdown 텍스트를 카드 목록으로 변환만 한다. 파일 IO와 진행도는 모른다.
public static class DeckParser
{
    // 규칙 (DESIGN.md "Markdown 형식"):
    // - 줄 시작 "# " = 질문, 다음 "# " 전까지의 줄들 = 답
    // - 첫 질문 이전의 내용은 무시
    // - 답의 앞뒤 공백은 제거, 질문이 빈 카드("# "만 있는 줄)는 버림
    // - 중복 질문 판단은 하지 않는다 (파서는 사실만 전달)
    public static List<Card> Parse(string text)
    {
        var cards = new List<Card>();
        if (string.IsNullOrEmpty(text))
            return cards;

        string? question = null;
        var answerLines = new List<string>();

        void Flush()
        {
            if (string.IsNullOrEmpty(question))
                return;
            cards.Add(new Card(question, string.Join("\n", answerLines).Trim()));
        }

        foreach (var rawLine in text.Split('\n'))
        {
            var line = rawLine.TrimEnd('\r');
            if (line.StartsWith("# "))
            {
                Flush();
                question = line[2..].Trim();
                answerLines.Clear();
            }
            else if (question != null)
            {
                answerLines.Add(line);
            }
        }
        Flush();
        return cards;
    }
}
