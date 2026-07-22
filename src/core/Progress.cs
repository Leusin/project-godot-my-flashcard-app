using System;
using System.Collections.Generic;
using System.Text.Json;

namespace MyFlashCard.Core;

// Question → 카드별 상태(틀린 횟수 + 표시용 라벨)와 그 직렬화만 담당한다. 파일 IO는 모른다.
// 카드 식별자는 Question 텍스트 (DESIGN.md 진행도 저장). 원본 md가 아니라 이쪽에 사는 파생 데이터다.
public sealed class Progress
{
	private readonly Dictionary<string, int> _wrongCounts;
	private readonly Dictionary<string, CardStatus> _statuses;

	public Progress()
		: this(new Dictionary<string, int>(), new Dictionary<string, CardStatus>())
	{
	}

	private Progress(Dictionary<string, int> wrongCounts, Dictionary<string, CardStatus> statuses)
	{
		this._wrongCounts = wrongCounts;
		this._statuses = statuses;
	}

	public int GetWrongCount(string question)
	{
		return this._wrongCounts.TryGetValue(question, out var count) ? count : 0;
	}

	public void AddWrong(string question)
	{
		this._wrongCounts[question] = this.GetWrongCount(question) + 1;
	}

	// 편집기에서 손으로 고친 값. 0이면 기록을 비워 파일을 가볍게 유지한다.
	public void SetWrongCount(string question, int count)
	{
		if (count <= 0)
		{
			this._wrongCounts.Remove(question);
		}
		else
		{
			this._wrongCounts[question] = count;
		}
	}

	// 기록이 없으면 New. New는 저장하지 않아(기본값) 파일이 상태로 가득 차지 않는다.
	public CardStatus GetStatus(string question)
	{
		return this._statuses.TryGetValue(question, out var status) ? status : CardStatus.New;
	}

	public void SetStatus(string question, CardStatus status)
	{
		if (status == CardStatus.New)
		{
			this._statuses.Remove(question);
		}
		else
		{
			this._statuses[question] = status;
		}
	}

	// 질문 텍스트가 진행도의 키다. 그래서 카드의 질문을 고치면 옛 키의 기록이 미아가 된다.
	// 틀린 횟수는 새 질문에 이미 있으면 합치고, 상태는 옮기는 카드 것으로 덮는다.
	// 옮길 기록이 없거나 새 질문이 비면 아무 것도 하지 않는다.
	public void Rename(string oldQuestion, string newQuestion)
	{
		if (oldQuestion == newQuestion || string.IsNullOrEmpty(newQuestion))
		{
			return;
		}

		if (this._wrongCounts.TryGetValue(oldQuestion, out var moved))
		{
			this._wrongCounts.Remove(oldQuestion);
			this._wrongCounts[newQuestion] = this.GetWrongCount(newQuestion) + moved;
		}

		if (this._statuses.TryGetValue(oldQuestion, out var status))
		{
			this._statuses.Remove(oldQuestion);
			this._statuses[newQuestion] = status;
		}
	}

	// 카드를 지울 때 그 질문의 기록도 지운다. 기록이 없으면 아무 것도 하지 않는다.
	public void Remove(string question)
	{
		this._wrongCounts.Remove(question);
		this._statuses.Remove(question);
	}

	public string ToJson()
	{
		var entries = new Dictionary<string, Entry>();
		foreach (var question in this.Questions())
		{
			entries[question] = new Entry
			{
				Wrong = this.GetWrongCount(question),
				Status = this.GetStatus(question),
			};
		}

		return JsonSerializer.Serialize(entries, SerializerOptions);
	}

	public static Progress FromJson(string json)
	{
		if (string.IsNullOrWhiteSpace(json))
		{
			return new Progress();
		}

		try
		{
			return Parse(json);
		}
		catch (JsonException)
		{
			// 깨진 파일은 빈 진행도로 시작한다 (학습을 막지 않는 게 우선).
			return new Progress();
		}
	}

	private HashSet<string> Questions()
	{
		var questions = new HashSet<string>(this._wrongCounts.Keys);
		questions.UnionWith(this._statuses.Keys);
		return questions;
	}

	// 옛 형식(질문→숫자)과 새 형식(질문→{wrong, status})을 값 종류로 구분해 둘 다 읽는다.
	// 옛 진행도 파일의 틀린 횟수를 잃지 않기 위해서다.
	private static Progress Parse(string json)
	{
		var progress = new Progress();
		using var doc = JsonDocument.Parse(json);
		if (doc.RootElement.ValueKind != JsonValueKind.Object)
		{
			return progress;
		}

		foreach (var prop in doc.RootElement.EnumerateObject())
		{
			if (prop.Value.ValueKind == JsonValueKind.Number)
			{
				progress.SetWrongCount(prop.Name, prop.Value.GetInt32());
			}
			else if (prop.Value.ValueKind == JsonValueKind.Object)
			{
				if (prop.Value.TryGetProperty("wrong", out var wrong)
					&& wrong.ValueKind == JsonValueKind.Number)
				{
					progress.SetWrongCount(prop.Name, wrong.GetInt32());
				}

				if (prop.Value.TryGetProperty("status", out var status)
					&& status.ValueKind == JsonValueKind.String
					&& Enum.TryParse<CardStatus>(status.GetString(), true, out var parsed))
				{
					progress.SetStatus(prop.Name, parsed);
				}
			}
		}

		return progress;
	}

	// camelCase라야 직렬화 키(wrong/status)가 Parse가 읽는 이름과 맞는다.
	private static readonly JsonSerializerOptions SerializerOptions = new()
	{
		WriteIndented = true,
		PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
		Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() },
	};

	private sealed class Entry
	{
		public int Wrong { get; set; }
		public CardStatus Status { get; set; }
	}
}
