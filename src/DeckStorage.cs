using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 덱·진행도·설정 파일의 위치와 읽고 쓰기만 담당한다.
public static class DeckStorage
{
	public const string DefaultDecksDir = "user://decks";
	public const string ProgressDir = "user://progress";
	public const string SettingsPath = "user://settings.json";

	// 첫 실행에 목록이 비어 보이지 않도록 넣어주는 예시 덱.
	private const string SampleDeckPath = "res://sample_deck.md";

	private static string _decksDir = DefaultDecksDir;

	public static string DecksDir => _decksDir;

	public static void SetDecksDir(string dir)
	{
		_decksDir = string.IsNullOrEmpty(dir) ? DefaultDecksDir : dir;
	}

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

	public static bool ExportDeck(string deckFile, string targetPath)
	{
		if (!DeckExists(deckFile))
		{
			return false;
		}

		using var file = FileAccess.Open(targetPath, FileAccess.ModeFlags.Write);
		if (file == null)
		{
			return false;
		}

		file.StoreString(ReadDeck(deckFile));
		return true;
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

	// 덱 이름을 바꾼다. 진행도는 덱 이름으로 키를 잡으므로(ProgressFileName) 진행도 파일도 함께 옮긴다.
	// 새 이름의 고유성은 부르는 쪽이 보장한다 (WriteDeck과 같은 계약).
	public static bool RenameDeck(string oldFile, string newFile)
	{
		if (oldFile == newFile || !DeckExists(oldFile))
		{
			return false;
		}

		if (DirAccess.RenameAbsolute(DeckPath(oldFile), DeckPath(newFile)) != Error.Ok)
		{
			return false;
		}

		var oldProgress = ProgressPath(oldFile);
		if (FileAccess.FileExists(oldProgress))
		{
			DirAccess.RenameAbsolute(oldProgress, ProgressPath(newFile));
		}

		return true;
	}

	// 덱을 한 부 복제한다. 이름이 겹치지 않게 번호를 붙이고, 진행도(틀린 횟수·상태)도 함께 복사한다.
	// 만든 파일 이름을 돌려주고, 원본이 없으면 null.
	public static string? DuplicateDeck(string deckFile)
	{
		if (!DeckExists(deckFile))
		{
			return null;
		}

		var newFile = DeckNaming.UniqueFileName(deckFile, ListDeckFiles());
		if (!WriteDeck(newFile, ReadDeck(deckFile)))
		{
			return null;
		}

		// 진행도가 없으면 빈 파일을 만들지 않는다 (파일 목록을 가볍게 유지).
		if (FileAccess.FileExists(ProgressPath(deckFile)))
		{
			SaveProgress(newFile, LoadProgress(deckFile));
		}

		return newFile;
	}

	// 덱을 지운다. 진행도 파일도 함께 지운다 (덱과 짝이므로 남길 이유가 없다).
	public static bool DeleteDeck(string deckFile)
	{
		if (!DeckExists(deckFile))
		{
			return false;
		}

		DirAccess.RemoveAbsolute(DeckPath(deckFile));

		var progress = ProgressPath(deckFile);
		if (FileAccess.FileExists(progress))
		{
			DirAccess.RemoveAbsolute(progress);
		}

		return true;
	}

	// 기본 폴더가 비었을 때만 예시 덱을 넣는다. 사용자가 지운 덱을 되살리지 않고,
	// 사용자가 지정한 폴더(Drive 동기화 등)에는 앱이 파일을 끼워넣지 않기 위해서다.
	public static void SeedSampleIfEmpty()
	{
		if (_decksDir != DefaultDecksDir || ListDeckFiles().Count > 0)
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
