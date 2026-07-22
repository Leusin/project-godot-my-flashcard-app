using System.Collections.Generic;
using System.Text.Json;

namespace MyFlashCard.Core;

// Question → WrongCount 기록과 그 직렬화만 담당한다. 파일 IO는 모른다.
// 카드 식별자는 Question 텍스트 (DESIGN.md 진행도 저장).
public sealed class Progress
{
	private readonly Dictionary<string, int> _wrongCounts;

	public Progress() : this(new Dictionary<string, int>())
	{
	}

	private Progress(Dictionary<string, int> wrongCounts)
	{
		this._wrongCounts = wrongCounts;
	}

	public int GetWrongCount(string question)
	{
		return this._wrongCounts.TryGetValue(question, out var count) ? count : 0;
	}

	public void AddWrong(string question)
	{
		this._wrongCounts[question] = this.GetWrongCount(question) + 1;
	}

	// 질문 텍스트가 진행도의 키다. 그래서 카드의 질문을 고치면 옛 키의 기록이 미아가 된다.
	// 새 질문에 이미 기록이 있으면 합친다.
	// 옮길 기록이 없거나 새 질문이 비면 아무 것도 하지 않는다.
	public void Rename(string oldQuestion, string newQuestion)
	{
		if (oldQuestion == newQuestion || string.IsNullOrEmpty(newQuestion))
		{
			return;
		}

		if (!this._wrongCounts.TryGetValue(oldQuestion, out var moved))
		{
			return;
		}

		this._wrongCounts.Remove(oldQuestion);
		this._wrongCounts[newQuestion] = this.GetWrongCount(newQuestion) + moved;
	}

	// 카드를 지울 때 그 질문의 기록도 지운다. 기록이 없으면 아무 일도 하지 않는다.
	public void Remove(string question)
	{
		this._wrongCounts.Remove(question);
	}

	public string ToJson()
	{
		return JsonSerializer.Serialize(
			this._wrongCounts, new JsonSerializerOptions { WriteIndented = true });
	}

	public static Progress FromJson(string json)
	{
		if (string.IsNullOrWhiteSpace(json))
		{
			return new Progress();
		}

		try
		{
			var dict = JsonSerializer.Deserialize<Dictionary<string, int>>(json);
			return new Progress(dict ?? new Dictionary<string, int>());
		}
		catch (JsonException)
		{
			// 깨진 파일은 빈 진행도로 시작한다 (학습을 막지 않는 게 우선).
			return new Progress();
		}
	}
}
