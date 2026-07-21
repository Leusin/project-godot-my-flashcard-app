using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 앱 저장소(user://)에 있는 덱·진행도·설정 파일의 위치와 읽고 쓰기만 담당한다.
// 파싱·학습 규칙·화면은 모른다.
public static class DeckStorage
{
	public const string DecksDir = "user://decks";
	public const string ProgressDir = "user://progress";
	public const string SettingsPath = "user://settings.json";

	// 첫 실행에 목록이 비어 보이지 않도록 넣어주는 예시 덱.
	private const string SampleDeckPath = "res://sample_deck.md";

	public static string DeckPath(string deckFile)
	{
		return $"{DecksDir}/{deckFile}";
	}

	public static bool DeckExists(string deckFile)
	{
		return !string.IsNullOrEmpty(deckFile) && FileAccess.FileExists(DeckPath(deckFile));
	}

	// 파일 이름만, 이름순.
	public static List<string> ListDeckFiles()
	{
		var decks = new List<string>();
		if (!DirAccess.DirExistsAbsolute(DecksDir))
		{
			return decks;
		}

		foreach (var fileName in DirAccess.GetFilesAt(DecksDir))
		{
			if (DeckNaming.IsDeckFile(fileName))
			{
				decks.Add(fileName);
			}
		}

		decks.Sort(string.CompareOrdinal);
		return decks;
	}

	public static string ReadDeck(string deckFile)
	{
		return FileAccess.GetFileAsString(DeckPath(deckFile));
	}

	// 앱 저장소로 복사한다. 복사한 뒤로는 이쪽이 원본이다 (DESIGN.md Import).
	// 저장된 파일 이름을 돌려주고, 읽지 못하면 null.
	public static string? Import(string sourcePath)
	{
		using var source = FileAccess.Open(sourcePath, FileAccess.ModeFlags.Read);
		if (source == null)
		{
			return null;
		}

		var text = source.GetAsText();
		var fileName = DeckNaming.UniqueFileName(sourcePath.GetFile(), ListDeckFiles());
		return WriteDeck(fileName, text) ? fileName : null;
	}

	public static bool WriteDeck(string deckFile, string text)
	{
		EnsureDir(DecksDir);
		using var file = FileAccess.Open(DeckPath(deckFile), FileAccess.ModeFlags.Write);
		if (file == null)
		{
			return false;
		}

		file.StoreString(text);
		return true;
	}

	// 덱이 하나도 없을 때만 예시 덱을 넣는다. 사용자가 지운 덱을 되살리지 않기 위해서다.
	public static void SeedSampleIfEmpty()
	{
		if (ListDeckFiles().Count > 0)
		{
			return;
		}

		WriteDeck(SampleDeckPath.GetFile(), FileAccess.GetFileAsString(SampleDeckPath));
	}

	public static string ProgressPath(string deckFile)
	{
		return $"{ProgressDir}/{DeckNaming.ProgressFileName(deckFile)}";
	}

	public static Progress LoadProgress(string deckFile)
	{
		var path = ProgressPath(deckFile);
		if (!FileAccess.FileExists(path))
		{
			return new Progress();
		}

		return Progress.FromJson(FileAccess.GetFileAsString(path));
	}

	public static void SaveProgress(string deckFile, Progress progress)
	{
		EnsureDir(ProgressDir);
		using var file = FileAccess.Open(ProgressPath(deckFile), FileAccess.ModeFlags.Write);
		file?.StoreString(progress.ToJson());
	}

	public static AppSettings LoadSettings()
	{
		if (!FileAccess.FileExists(SettingsPath))
		{
			return new AppSettings();
		}

		return AppSettings.FromJson(FileAccess.GetFileAsString(SettingsPath));
	}

	public static void SaveSettings(AppSettings settings)
	{
		using var file = FileAccess.Open(SettingsPath, FileAccess.ModeFlags.Write);
		file?.StoreString(settings.ToJson());
	}

	private static void EnsureDir(string dir)
	{
		if (!DirAccess.DirExistsAbsolute(dir))
		{
			DirAccess.MakeDirRecursiveAbsolute(dir);
		}
	}
}
