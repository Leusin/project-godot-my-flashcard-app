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
