using System.Text.Json;

namespace MyFlashCard.Core;

// 앱을 다시 켰을 때 이어가기 위한 값과 그 직렬화만 담당한다. 파일 IO는 모른다.
public sealed class AppSettings
{
	// 덱 파일 이름. 그 덱이 아직 있는지는 확인하지 않는다.
	public string LastDeckFile { get; set; } = "";

	// 덱(원본 md)을 둘 폴더. 빈 값이면 기본(user://decks)을 쓴다.
	public string DeckDir { get; set; } = "";

	// 허브 화면 Order 드롭다운의 마지막 선택. 덱마다 다르지 않고 전역 기본값 하나.
	public bool ShuffleStudy { get; set; }

	public string ToJson()
	{
		return JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
	}

	public static AppSettings FromJson(string json)
	{
		if (string.IsNullOrWhiteSpace(json))
		{
			return new AppSettings();
		}

		try
		{
			return JsonSerializer.Deserialize<AppSettings>(json) ?? new AppSettings();
		}
		catch (JsonException)
		{
			// 깨진 설정은 기본값으로 시작한다 (앱 실행을 막지 않는 게 우선).
			return new AppSettings();
		}
	}
}
