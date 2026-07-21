using System;
using System.Collections.Generic;

namespace MyFlashCard.Core;

// 덱 파일 이름 규칙만 담당한다. 파일 IO와 화면은 모른다.
public static class DeckNaming
{
	public const string Extension = ".md";

	// Windows 파일 시스템이 대소문자를 구분하지 않으므로 이름 충돌도 같은 기준으로 본다.
	private static readonly StringComparer NameComparer = StringComparer.OrdinalIgnoreCase;

	// md가 원본이므로 표시 이름도 파일 이름이 정한다.
	public static string DisplayName(string fileName)
	{
		var name = fileName.Trim();
		if (name.EndsWith(Extension, StringComparison.OrdinalIgnoreCase))
		{
			name = name[..^Extension.Length];
		}

		return name.Trim();
	}

	public static bool IsDeckFile(string fileName)
	{
		return fileName.EndsWith(Extension, StringComparison.OrdinalIgnoreCase)
			&& DisplayName(fileName).Length > 0;
	}

	// 같은 이름이 이미 있으면 "이름 (2)"부터 빈 번호를 찾는다. 가져오기가 기존 덱을 덮어쓰지 않게.
	public static string UniqueFileName(string fileName, IEnumerable<string> existing)
	{
		var taken = new HashSet<string>(existing, NameComparer);
		if (!taken.Contains(fileName))
		{
			return fileName;
		}

		var stem = DisplayName(fileName);
		for (var n = 2; ; n++)
		{
			var candidate = $"{stem} ({n}){Extension}";
			if (!taken.Contains(candidate))
			{
				return candidate;
			}
		}
	}

	// 진행도는 덱마다 따로 남는다. 파일 이름을 그대로 쓰면 덱을 지웠을 때 짝을 찾기 쉽다.
	public static string ProgressFileName(string deckFileName)
	{
		return $"{DisplayName(deckFileName)}.json";
	}
}
