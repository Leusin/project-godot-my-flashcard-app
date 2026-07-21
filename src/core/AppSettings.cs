using System.Text.Json;

namespace MyFlashCard.Core;

// 앱을 다시 켰을 때 이어가기 위한 값과 그 직렬화만 담당한다. 파일 IO는 모른다.
public sealed class AppSettings
{
	// 덱 파일 이름. 그 덱이 아직 있는지는 확인하지 않는다.
	public string LastDeckFile { get; set; } = "";

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
