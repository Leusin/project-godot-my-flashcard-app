using System.Text.Json;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard.Tests;

// 순수 로직 단위 테스트 러너. 헤드리스로 실행해 실패 개수를 종료 코드로 반환한다.
// 새 테스트는 _Ready()에 함수로 등록한다.
public partial class TestRunner : Node
{
	private int _passed;
	private int _failed;

	public override void _Ready()
	{
		this.ParserBasics();
		this.ParserEdgeCases();
		this.SessionQueue();
		this.ProgressRoundTrip();
		this.ProgressRename();
		this.ProgressRemove();
		this.ProgressStatus();
		this.DeckWriterRoundTrip();
		this.DeckNamingRules();
		this.DeckOrderingRules();
		this.SettingsRoundTrip();
		this.DeckStorageRoundTrip();
		this.DeckStorageCustomDir();
		this.DeckExport();
		this.DeckRenameStorage();
		this.DeckDuplicateStorage();
		this.DeckDeleteStorage();
		this.TallyWidth();
		this.CardFlip();
		this.SceneSmokeTest();
		this.AppSmokeTest();
		this.AppMenuActions();

		GD.Print($"tests: {this._passed} passed, {this._failed} failed");
		this.GetTree().Quit(this._failed);
	}

	private void Check(bool condition, string name)
	{
		if (condition)
		{
			this._passed++;
		}
		else
		{
			this._failed++;
			GD.PrintErr($"FAIL: {name}");
		}
	}

	private void ParserBasics()
	{
		var cards = DeckParser.Parse("# Apple\n사과\n# Red\n빨간색\n");
		this.Check(cards.Count == 2, "파서: 카드 2장");
		this.Check(cards[0].Question == "Apple" && cards[0].Answer == "사과", "파서: 첫 카드 질문/답");
		this.Check(cards[1].Question == "Red" && cards[1].Answer == "빨간색", "파서: 둘째 카드 질문/답");

		var multiline = DeckParser.Parse("# Q\n첫 줄\n둘째 줄\n");
		this.Check(multiline[0].Answer == "첫 줄\n둘째 줄", "파서: 여러 줄 답 유지");
	}

	private void ParserEdgeCases()
	{
		this.Check(DeckParser.Parse("").Count == 0, "파서: 빈 문서");
		this.Check(DeckParser.Parse("질문 없는 내용\n그냥 텍스트").Count == 0, "파서: 첫 질문 이전 내용 무시");

		var emptyAnswer = DeckParser.Parse("# Q1\n# Q2\n답");
		this.Check(emptyAnswer.Count == 2 && emptyAnswer[0].Answer == "", "파서: 답 없는 카드 허용");

		this.Check(DeckParser.Parse("# \n답").Count == 0, "파서: 질문 빈 카드 버림");
		this.Check(DeckParser.Parse("#공백없음\n답").Count == 0, "파서: '# ' 없으면 질문 아님");

		var crlf = DeckParser.Parse("# Q\r\n답\r\n");
		this.Check(crlf.Count == 1 && crlf[0].Answer == "답", "파서: CRLF 처리");

		var padded = DeckParser.Parse("# Q\n\n답\n\n# Q2\n답2");
		this.Check(padded[0].Answer == "답", "파서: 답 앞뒤 공백 줄 제거");
	}

	private void SessionQueue()
	{
		var cards = DeckParser.Parse("# A\n1\n# B\n2\n# C\n3");
		var session = new StudySession(cards);

		this.Check(session.Current?.Question == "A", "세션: 첫 카드는 덱 순서대로");
		this.Check(session.Remaining == 3, "세션: 시작 시 남은 카드 수");

		session.Next();
		this.Check(session.Current?.Question == "B", "세션: 다음 카드로 넘어감");
		this.Check(session.Remaining == 2, "세션: 넘어간 카드는 큐에서 빠짐");

		session.Next();
		session.Next();
		this.Check(session.IsFinished && session.Current == null, "세션: 전부 넘기면 종료");

		// 판정과 무관하게 한 번 나온 카드는 이번 세션에 다시 나오지 않는다.
		var single = new StudySession(DeckParser.Parse("# 하나\n1"));
		single.Next();
		this.Check(single.IsFinished, "세션: 카드 1장이면 한 번 넘기고 끝");

		var empty = new StudySession(DeckParser.Parse(""));
		empty.Next();
		this.Check(empty.IsFinished, "세션: 빈 덱에서 Next는 아무 일도 하지 않음");

		// 세션 중 편집: 현재 카드만 교체되고 순서·남은 수는 그대로다.
		var edit = new StudySession(DeckParser.Parse("# A\n1\n# B\n2"));
		edit.ReplaceCurrent(new Card("A2", "1e"));
		this.Check(edit.Current?.Question == "A2" && edit.Remaining == 2,
			"세션: ReplaceCurrent가 현재 카드만 바꾼다");
		edit.Next();
		this.Check(edit.Current?.Question == "B", "세션: 교체 후에도 다음 카드는 그대로");

		var finished = new StudySession(DeckParser.Parse("# A\n1"));
		finished.Next();
		finished.ReplaceCurrent(new Card("X", "x"));
		this.Check(finished.IsFinished && finished.Current == null,
			"세션: 끝난 세션의 ReplaceCurrent는 아무 일도 하지 않음");
	}

	private void ProgressRoundTrip()
	{
		var p = new Progress();
		this.Check(p.GetWrongCount("없는질문") == 0, "진행도: 기록 없으면 0");

		p.AddWrong("Apple");
		p.AddWrong("Apple");
		p.AddWrong("Red");
		var restored = Progress.FromJson(p.ToJson());
		this.Check(restored.GetWrongCount("Apple") == 2, "진행도: 직렬화 왕복 (Apple=2)");
		this.Check(restored.GetWrongCount("Red") == 1, "진행도: 직렬화 왕복 (Red=1)");

		this.Check(Progress.FromJson("").GetWrongCount("x") == 0, "진행도: 빈 JSON은 빈 진행도");
		this.Check(Progress.FromJson("{깨진 json").GetWrongCount("x") == 0, "진행도: 깨진 JSON은 빈 진행도");
	}

	// 카드 상태 라벨 + 수동 WrongCount. 상태는 진행도에 함께 살고, 옛 형식도 읽힌다.
	private void ProgressStatus()
	{
		var p = new Progress();
		this.Check(p.GetStatus("A") == CardStatus.New, "상태: 기록 없으면 New");

		p.SetStatus("A", CardStatus.Learning);
		this.Check(p.GetStatus("A") == CardStatus.Learning, "상태: 설정한 값 유지");

		p.SetWrongCount("A", 7);
		this.Check(p.GetWrongCount("A") == 7, "상태: WrongCount 수동 설정");
		p.SetWrongCount("A", 0);
		this.Check(p.GetWrongCount("A") == 0, "상태: WrongCount 0으로 설정");

		p.SetWrongCount("A", 3);
		p.SetStatus("A", CardStatus.Mastered);
		var round = Progress.FromJson(p.ToJson());
		this.Check(round.GetWrongCount("A") == 3 && round.GetStatus("A") == CardStatus.Mastered,
			"상태: 상태+횟수 직렬화 왕복");

		// 옛 형식(질문→숫자)도 그대로 읽힌다: 횟수는 유지, 상태는 New.
		var old = Progress.FromJson("{\"A\": 4}");
		this.Check(old.GetWrongCount("A") == 4 && old.GetStatus("A") == CardStatus.New,
			"상태: 옛 형식은 횟수만 읽고 상태는 New");

		// 질문을 고치면 상태도 카드를 따라온다.
		var moved = new Progress();
		moved.SetStatus("A", CardStatus.Learning);
		moved.Rename("A", "B");
		this.Check(moved.GetStatus("B") == CardStatus.Learning && moved.GetStatus("A") == CardStatus.New,
			"상태: Rename이 상태도 옮긴다");

		// 카드를 지우면 상태도 지워진다.
		moved.Remove("B");
		this.Check(moved.GetStatus("B") == CardStatus.New, "상태: Remove가 상태도 지운다");
	}

	// 내보내기: 지금 덱을 앱 밖 경로로 한 부 복사한다. 저장된 내용 그대로.
	private void DeckExport()
	{
		WriteTestDeck();
		var target = $"{OS.GetUserDataDir()}/__export_test.md";

		this.Check(DeckStorage.ExportDeck(TestDeckFile, target), "내보내기: 성공 시 true");
		this.Check(FileAccess.GetFileAsString(target) == TestDeckText,
			"내보내기: 저장된 덱 내용 그대로 복사");
		this.Check(!DeckStorage.ExportDeck("__없는덱.md", target),
			"내보내기: 없는 덱은 false");

		DirAccess.RemoveAbsolute(target);
		RemoveTestDeck();
	}

	// 덱 이름 변경: 덱 파일과 진행도 파일이 함께 새 이름으로 옮겨간다.
	private void DeckRenameStorage()
	{
		const string oldFile = "__rename_src.md";
		const string newFile = "__rename_dst.md";
		DeckStorage.WriteDeck(oldFile, "# Q\n1\n");
		var p = new Progress();
		p.AddWrong("Q");
		DeckStorage.SaveProgress(oldFile, p);

		this.Check(DeckStorage.RenameDeck(oldFile, newFile), "덱 이름변경: 성공 시 true");
		this.Check(!DeckStorage.DeckExists(oldFile), "덱 이름변경: 옛 덱 파일은 사라진다");
		this.Check(DeckStorage.DeckExists(newFile), "덱 이름변경: 새 이름으로 존재");
		this.Check(DeckStorage.LoadProgress(newFile).GetWrongCount("Q") == 1,
			"덱 이름변경: 진행도가 새 이름을 따라온다");
		this.Check(DeckStorage.LoadProgress(oldFile).GetWrongCount("Q") == 0,
			"덱 이름변경: 옛 이름엔 진행도가 남지 않는다");
		this.Check(!DeckStorage.RenameDeck("__없는덱.md", "__x.md"), "덱 이름변경: 없는 덱은 false");

		DirAccess.RemoveAbsolute(DeckStorage.DeckPath(newFile));
		if (FileAccess.FileExists(DeckStorage.ProgressPath(newFile)))
		{
			DirAccess.RemoveAbsolute(DeckStorage.ProgressPath(newFile));
		}
	}

	// 덱 복제: 번호를 붙인 새 이름으로 내용과 진행도가 함께 복사된다.
	private void DeckDuplicateStorage()
	{
		const string src = "__dup_src.md";
		DeckStorage.WriteDeck(src, "# Q\n1\n");
		var p = new Progress();
		p.AddWrong("Q");
		p.AddWrong("Q");
		DeckStorage.SaveProgress(src, p);

		var copy = DeckStorage.DuplicateDeck(src);
		this.Check(copy == "__dup_src (2).md", "덱 복제: 번호를 붙인 새 이름");
		this.Check(DeckStorage.DeckExists(src) && DeckStorage.DeckExists(copy ?? ""),
			"덱 복제: 원본과 사본이 둘 다 있다");
		this.Check(DeckStorage.ReadDeck(copy ?? "") == "# Q\n1\n", "덱 복제: 내용 동일");
		this.Check(DeckStorage.LoadProgress(copy ?? "").GetWrongCount("Q") == 2,
			"덱 복제: 진행도도 복사된다");
		this.Check(DeckStorage.DuplicateDeck("__없는덱.md") == null, "덱 복제: 없는 덱은 null");

		DirAccess.RemoveAbsolute(DeckStorage.DeckPath(src));
		DirAccess.RemoveAbsolute(DeckStorage.ProgressPath(src));
		if (copy != null)
		{
			DirAccess.RemoveAbsolute(DeckStorage.DeckPath(copy));
			if (FileAccess.FileExists(DeckStorage.ProgressPath(copy)))
			{
				DirAccess.RemoveAbsolute(DeckStorage.ProgressPath(copy));
			}
		}
	}

	// 덱 삭제: 덱 파일과 진행도 파일이 함께 사라진다.
	private void DeckDeleteStorage()
	{
		const string file = "__del_target.md";
		DeckStorage.WriteDeck(file, "# Q\n1\n");
		var p = new Progress();
		p.AddWrong("Q");
		DeckStorage.SaveProgress(file, p);
		this.Check(FileAccess.FileExists(DeckStorage.ProgressPath(file)), "덱 삭제: 준비 - 진행도 존재");

		this.Check(DeckStorage.DeleteDeck(file), "덱 삭제: 성공 시 true");
		this.Check(!DeckStorage.DeckExists(file), "덱 삭제: 덱 파일이 사라진다");
		this.Check(!FileAccess.FileExists(DeckStorage.ProgressPath(file)),
			"덱 삭제: 진행도 파일도 사라진다");
		this.Check(!DeckStorage.DeleteDeck("__없는덱.md"), "덱 삭제: 없는 덱은 false");
	}

	// 진행도 삭제: 카드를 지우면 그 질문의 기록도 사라진다.
	private void ProgressRemove()
	{
		var p = new Progress();
		p.AddWrong("A");
		p.AddWrong("B");
		p.Remove("A");
		this.Check(p.GetWrongCount("A") == 0, "삭제: 지운 질문의 기록은 0");
		this.Check(p.GetWrongCount("B") == 1, "삭제: 다른 질문의 기록은 그대로");
		p.Remove("없는질문");
		this.Check(p.GetWrongCount("B") == 1, "삭제: 없는 질문 삭제는 아무 일도 하지 않음");
	}

	// 덱 저장. 기준은 왕복 안정성: 카드 → 텍스트 → 카드가 원래와 같아야 한다.
	private void DeckWriterRoundTrip()
	{
		var cards = DeckParser.Parse("# Apple\n사과\n# Red\n빨간색\n");
		var round = DeckParser.Parse(DeckWriter.ToMarkdown(cards));
		this.Check(round.Count == 2, "저장: 왕복 후 카드 수 유지");
		this.Check(round[0].Question == "Apple" && round[0].Answer == "사과",
			"저장: 왕복 후 첫 카드 유지");
		this.Check(round[1].Question == "Red" && round[1].Answer == "빨간색",
			"저장: 왕복 후 둘째 카드 유지");

		var multiline = DeckParser.Parse("# Q\n첫 줄\n둘째 줄\n");
		var multiRound = DeckParser.Parse(DeckWriter.ToMarkdown(multiline));
		this.Check(multiRound[0].Answer == "첫 줄\n둘째 줄", "저장: 여러 줄 답 왕복 유지");

		var empty = DeckParser.Parse("# Q1\n# Q2\n답");
		var emptyRound = DeckParser.Parse(DeckWriter.ToMarkdown(empty));
		this.Check(emptyRound.Count == 2 && emptyRound[0].Answer == "",
			"저장: 답 없는 카드 왕복 유지");

		this.Check(DeckWriter.ToMarkdown(new Card[0]).Length == 0, "저장: 빈 덱은 빈 텍스트");
		this.Check(DeckWriter.ToMarkdown(new[] { new Card("Q", "A") }) == "# Q\nA\n",
			"저장: 형식은 '# 질문' + 줄바꿈 + 답");
	}

	// 진행도 이사: 질문을 고쳐도 그 카드의 틀린 횟수가 따라온다.
	private void ProgressRename()
	{
		var moved = new Progress();
		moved.AddWrong("A");
		moved.AddWrong("A");
		moved.Rename("A", "B");
		this.Check(moved.GetWrongCount("B") == 2, "이사: 기록이 새 질문으로 옮겨진다");
		this.Check(moved.GetWrongCount("A") == 0, "이사: 옛 질문에는 기록이 남지 않는다");

		// 새 질문에 이미 기록이 있으면 합친다 (같은 질문 = 같은 카드).
		var merge = new Progress();
		merge.AddWrong("A");
		merge.AddWrong("A");
		merge.AddWrong("B");
		merge.Rename("A", "B");
		this.Check(merge.GetWrongCount("B") == 3, "이사: 겹치면 틀린 횟수를 합친다");

		var same = new Progress();
		same.AddWrong("A");
		same.Rename("A", "A");
		this.Check(same.GetWrongCount("A") == 1, "이사: 같은 질문으로의 이사는 아무 일도 하지 않는다");

		// 옮길 기록이 없으면 목적지를 건드리지 않는다.
		var absent = new Progress();
		absent.AddWrong("B");
		absent.Rename("A", "B");
		this.Check(absent.GetWrongCount("B") == 1, "이사: 기록 없는 카드는 목적지에 영향을 주지 않는다");

		// 빈 질문으로는 옮기지 않는다 (유효한 카드가 아니라 기록을 잃지 않게).
		var blank = new Progress();
		blank.AddWrong("A");
		blank.Rename("A", "");
		this.Check(blank.GetWrongCount("A") == 1, "이사: 빈 질문으로의 이사는 기록을 지우지 않는다");

		var restored = Progress.FromJson(moved.ToJson());
		this.Check(restored.GetWrongCount("B") == 2, "이사: 이사 후에도 직렬화 왕복 유지");
	}

	private void DeckNamingRules()
	{
		this.Check(DeckNaming.DisplayName("영어단어.md") == "영어단어", "덱 이름: 확장자를 뗀다");
		this.Check(DeckNaming.DisplayName("Deck.MD") == "Deck", "덱 이름: 확장자 대소문자 무시");
		this.Check(DeckNaming.IsDeckFile("a.md") && !DeckNaming.IsDeckFile("a.txt"),
			"덱 이름: md만 덱으로 본다");
		this.Check(!DeckNaming.IsDeckFile(".md"), "덱 이름: 이름이 빈 파일은 덱이 아니다");

		var existing = new[] { "a.md", "a (2).md" };
		this.Check(DeckNaming.UniqueFileName("b.md", existing) == "b.md",
			"덱 이름: 겹치지 않으면 그대로");
		this.Check(DeckNaming.UniqueFileName("a.md", existing) == "a (3).md",
			"덱 이름: 겹치면 비어 있는 번호를 찾는다");
		this.Check(DeckNaming.UniqueFileName("A.MD", existing) == "A (3).md",
			"덱 이름: 충돌 판단은 대소문자를 구분하지 않는다");

		this.Check(DeckNaming.ProgressFileName("영어단어.md") == "영어단어.json",
			"덱 이름: 진행도 파일은 덱 이름을 따른다");
	}

	// Order 적용: 무작위성 자체보다 "카드를 잃거나 늘리지 않는다"를 기준으로 본다
	// (TallyWidth가 정확한 픽셀 대신 상대 크기만 보는 것과 같은 실용적 기준).
	private void DeckOrderingRules()
	{
		var cards = DeckParser.Parse("# A\n1\n# B\n2\n# C\n3\n# D\n4\n# E\n5\n");

		var sequential = DeckOrdering.Apply(StudyOrder.Sequential, cards);
		this.Check(sequential.Count == cards.Count
			&& sequential[0].Question == "A" && sequential[4].Question == "E",
			"순서: Sequential은 받은 순서 그대로");

		var shuffled = DeckOrdering.Apply(StudyOrder.Shuffle, cards, new System.Random(42));
		this.Check(shuffled.Count == cards.Count, "순서: Shuffle도 카드 수는 그대로");
		var originalQuestions = new System.Collections.Generic.HashSet<string>();
		foreach (var card in cards)
		{
			originalQuestions.Add(card.Question);
		}

		var shuffledQuestions = new System.Collections.Generic.HashSet<string>();
		foreach (var card in shuffled)
		{
			shuffledQuestions.Add(card.Question);
		}

		this.Check(originalQuestions.SetEquals(shuffledQuestions),
			"순서: Shuffle은 카드를 잃거나 늘리지 않는다 (질문 집합 동일)");

		this.Check(DeckOrdering.Apply(StudyOrder.Shuffle, new System.Collections.Generic.List<Card>()).Count == 0,
			"순서: 빈 덱을 섞어도 빈 목록");
	}

	private void SettingsRoundTrip()
	{
		var settings = new AppSettings
		{
			LastDeckFile = "영어단어.md", DeckDir = "D:/Flashcards", ShuffleStudy = true,
		};
		var restored = AppSettings.FromJson(settings.ToJson());
		this.Check(restored.LastDeckFile == "영어단어.md", "설정: 마지막 덱 직렬화 왕복");
		this.Check(restored.DeckDir == "D:/Flashcards", "설정: 덱 폴더 직렬화 왕복");
		this.Check(restored.ShuffleStudy, "설정: Order 선택 직렬화 왕복");
		this.Check(AppSettings.FromJson("").LastDeckFile == "", "설정: 빈 JSON은 기본값");
		this.Check(AppSettings.FromJson("").DeckDir == "", "설정: 덱 폴더 기본값은 빈 값");
		this.Check(!AppSettings.FromJson("").ShuffleStudy, "설정: Order 기본값은 Sequential(false)");
		this.Check(AppSettings.FromJson("{깨진 json").LastDeckFile == "", "설정: 깨진 JSON은 기본값");
	}

	// 덱 폴더 바꾸기: 지정한 폴더(절대 경로 포함)로 덱 읽기/쓰기가 옮겨간다. 진행도는 user:// 고정.
	private void DeckStorageCustomDir()
	{
		var customDir = $"{OS.GetUserDataDir()}/__custom_deck_dir";
		DeckStorage.SetDecksDir(customDir);
		this.Check(DeckStorage.DecksDir == customDir, "덱 폴더: 절대 경로로 설정됨");

		DeckStorage.WriteDeck("custom.md", "# X\n1\n");
		this.Check(DeckStorage.DeckExists("custom.md"), "덱 폴더: 지정 폴더에 덱이 써진다");
		this.Check(DeckStorage.ListDeckFiles().Contains("custom.md"), "덱 폴더: 지정 폴더에서 목록을 읽는다");

		// 진행도는 폴더를 옮겨도 user://에 남는다.
		this.Check(DeckStorage.ProgressPath("custom.md") == "user://progress/custom.json",
			"덱 폴더: 진행도는 user://에 고정");

		DirAccess.RemoveAbsolute(DeckStorage.DeckPath("custom.md"));
		DirAccess.RemoveAbsolute(customDir);

		// 빈 값이면 기본으로 되돌아온다. 뒤 테스트가 기본 폴더를 쓰므로 반드시 복원한다.
		DeckStorage.SetDecksDir("");
		this.Check(DeckStorage.DecksDir == DeckStorage.DefaultDecksDir,
			"덱 폴더: 빈 값이면 기본 폴더로 복원");
	}

	// 앱 저장소를 실제로 건드리므로 전용 덱 파일만 쓰고 끝나면 지운다.
	private void DeckStorageRoundTrip()
	{
		WriteTestDeck();
		this.Check(DeckStorage.DeckExists(TestDeckFile), "저장소: 쓴 덱이 존재");
		this.Check(DeckStorage.ListDeckFiles().Contains(TestDeckFile), "저장소: 목록에 나온다");
		this.Check(DeckStorage.ReadDeck(TestDeckFile) == TestDeckText, "저장소: 내용 그대로 읽힌다");
		this.Check(!DeckStorage.DeckExists("__없는덱.md"), "저장소: 없는 덱은 존재하지 않음");

		var progress = new Progress();
		progress.AddWrong("A");
		DeckStorage.SaveProgress(TestDeckFile, progress);
		this.Check(DeckStorage.ProgressPath(TestDeckFile) == "user://progress/__test_deck.json",
			"저장소: 진행도는 덱마다 다른 파일");
		this.Check(DeckStorage.LoadProgress(TestDeckFile).GetWrongCount("A") == 1,
			"저장소: 진행도 왕복");
		this.Check(DeckStorage.LoadProgress("__없는덱.md").GetWrongCount("A") == 0,
			"저장소: 기록 없는 덱은 빈 진행도");

		// 같은 이름을 가져오면 덮어쓰지 않고 새 이름으로 들어온다.
		var imported = DeckStorage.Import(DeckStorage.DeckPath(TestDeckFile));
		this.Check(imported == "__test_deck (2).md", "저장소: 이름이 겹치면 번호를 붙여 가져온다");
		this.Check(DeckStorage.ReadDeck(imported ?? "") == TestDeckText, "저장소: 가져온 내용 동일");
		this.Check(DeckStorage.Import("user://__없는파일.md") == null,
			"저장소: 읽지 못한 파일은 가져오기 실패");

		if (imported != null)
		{
			DirAccess.RemoveAbsolute(DeckStorage.DeckPath(imported));
		}
		RemoveTestDeck();
		this.Check(!DeckStorage.DeckExists(TestDeckFile), "저장소: 정리 후 덱 없음");
	}

	// 작대기 표시. 그림 자체는 눈으로 봐야 하고, 여기서는 개수→크기 규칙만 확인한다.
	private void TallyWidth()
	{
		var tally = new TallyMarks();
		this.AddChild(tally);

		tally.Count = 0;
		this.Check(tally.CustomMinimumSize.X == 0.0f, "작대기: 0개면 폭 0");
		this.Check(tally.CustomMinimumSize.Y > 0.0f, "작대기: 0개여도 높이는 유지 (줄 흔들림 방지)");

		tally.Count = 3;
		var three = tally.CustomMinimumSize.X;
		tally.Count = 5;
		var five = tally.CustomMinimumSize.X;
		tally.Count = 6;
		var six = tally.CustomMinimumSize.X;
		this.Check(three > 0.0f && five > three, "작대기: 개수가 늘면 폭도 늘어남");
		this.Check(six > five, "작대기: 묶음이 넘어가면 묶음 간격만큼 더 넓어짐");

		tally.Count = -2;
		this.Check(tally.Count == 0, "작대기: 음수는 0으로 다룸");

		tally.QueueFree();
	}

	// 카드 앞뒤 전환. 탭 라우팅은 헤드리스에서 동작하지 않아 핸들러를 직접 부른다.
	private void CardFlip()
	{
		var card = GD.Load<PackedScene>("res://src/screens/study/card.tscn").Instantiate<CardView>();
		this.AddChild(card);

		var answerArea = card.GetNode<Control>("%AnswerArea");
		var questionLabel = card.GetNode<Label>("%QuestionLabel");
		this.Check(questionLabel.HorizontalAlignment == HorizontalAlignment.Center,
			"카드: 질문은 가운데 정렬");
		var answerLabel = card.GetNode<Label>("%AnswerLabel");
		this.Check(answerLabel.HorizontalAlignment == HorizontalAlignment.Left, "카드: 답은 좌측 정렬");
		this.Check(answerLabel.VerticalAlignment == VerticalAlignment.Top, "카드: 답은 위에서부터 시작");
		this.Check(questionLabel.VerticalAlignment == VerticalAlignment.Center,
			"카드: 질문은 세로 가운데");

		card.ShowCard("질문", "답", 0, CardStatus.New);
		this.Check(!answerArea.Visible, "카드: 새 카드는 앞면으로 시작");
		var frontFont = questionLabel.GetThemeFontSize("font_size");

		card.OnCardGuiInput(LeftClick());
		this.Check(answerArea.Visible, "카드: 탭하면 뒷면");
		this.Check(questionLabel.GetThemeFontSize("font_size") < frontFont,
			"카드: 뒷면에서는 질문 폰트가 작아짐");

		var questionScroll = questionLabel.GetParent<ScrollContainer>();
		this.Check(questionLabel.MaxLinesVisible > 0, "카드: 뒷면 질문은 줄 수가 제한됨");
		this.Check(questionLabel.TextOverrunBehavior == TextServer.OverrunBehavior.TrimWordEllipsis,
			"카드: 뒷면 질문은 넘치면 …으로 줄임");
		this.Check(questionScroll.VerticalScrollMode == ScrollContainer.ScrollMode.Disabled,
			"카드: 뒷면 질문은 스크롤하지 않음");
		this.Check(questionLabel.Modulate.A < 1.0f, "카드: 뒷면 질문은 흐리게");

		card.OnCardGuiInput(LeftClick());
		this.Check(!answerArea.Visible, "카드: 다시 탭하면 앞면");
		this.Check(questionLabel.GetThemeFontSize("font_size") == frontFont,
			"카드: 앞면으로 돌아오면 질문 폰트 복귀");
		this.Check(questionLabel.MaxLinesVisible < 0, "카드: 앞면 질문은 줄 수 제한 없음");
		this.Check(questionScroll.VerticalScrollMode == ScrollContainer.ScrollMode.Auto,
			"카드: 앞면 질문은 길면 스크롤");
		this.Check(questionLabel.Modulate.A == 1.0f, "카드: 앞면 질문은 원래 색으로 복귀");

		card.ShowCard("다음 질문", "다음 답", 3, CardStatus.Learning);
		this.Check(card.GetNode<TallyMarks>("%Tally").Count == 3, "카드: 틀린 횟수가 작대기로 전달됨");
		this.Check(card.GetNode<Label>("%StatusLabel").Text == "LEARNING", "카드: 상태 라벨 표시");
		this.Check(!answerArea.Visible, "카드: 뒷면 상태가 다음 카드로 넘어가지 않음");

		card.QueueFree();
	}

	private static InputEventMouseButton LeftClick()
	{
		return new InputEventMouseButton { ButtonIndex = MouseButton.Left, Pressed = true };
	}

	// 앱 저장소를 건드리는 테스트 전용 덱. 사용자의 덱과 섞이지 않게 이름을 따로 쓰고 끝나면 지운다.
	private const string TestDeckFile = "__test_deck.md";
	private const string TestDeckText = "# A\n1\n# B\n2\n# C\n3\n";

	private static void WriteTestDeck()
	{
		DeckStorage.WriteDeck(TestDeckFile, TestDeckText);
	}

	private static void RemoveTestDeck()
	{
		if (DeckStorage.DeckExists(TestDeckFile))
		{
			DirAccess.RemoveAbsolute(DeckStorage.DeckPath(TestDeckFile));
		}

		if (FileAccess.FileExists(DeckStorage.ProgressPath(TestDeckFile)))
		{
			DirAccess.RemoveAbsolute(DeckStorage.ProgressPath(TestDeckFile));
		}
	}

	// study.tscn 배선 검증: 씬 로드 → 덱 지정 → 버튼 시그널로 세션 한 바퀴 → Done 화면.
	private void SceneSmokeTest()
	{
		WriteTestDeck();

		var packed = GD.Load<PackedScene>("res://src/screens/study/study.tscn");
		this.Check(packed != null, "씬: study.tscn 로드");
		if (packed == null)
		{
			return;
		}

		var study = packed.Instantiate<Study>();
		this.AddChild(study);

		var studyView = study.GetNode<StudyView>("%StudyView");
		var done = study.GetNode<Control>("%DoneView");
		study.StartDeck(TestDeckFile, StudyOrder.Sequential);
		this.Check(studyView.Visible && !done.Visible, "씬: 덱을 받으면 Study 화면 표시");
		this.Check(study.GetNode<Label>("%DeckLabel").Text == DeckNaming.DisplayName(TestDeckFile),
			"씬: 상단바에 덱 이름 표시");

		// 판정 더미는 답을 보기 전에도 존재한다 (카드 뒤에 깔린 목적지).
		var card = study.GetNode<CardView>("%Card");
		this.Check(study.GetNode<Button>("%AgainButton").Visible
			&& study.GetNode<Button>("%GoodButton").Visible, "씬: 판정 더미는 처음부터 존재");

		// 비율 값은 씬이 아니라 CardView 상수가 출처다.
		var cardAspect = study.GetNode<AspectRatioContainer>("%CardAspect");
		this.Check(Mathf.IsEqualApprox(cardAspect.Ratio, CardView.AspectRatio),
			"씬: 카드 비율이 CardView.AspectRatio로 설정됨");

		// 라벨 최소 너비도 씬이 아니라 CardView가 넣는다.
		var questionMin = card.GetNode<Label>("%QuestionLabel").CustomMinimumSize.X;
		var answerMin = card.GetNode<Label>("%AnswerLabel").CustomMinimumSize.X;
		this.Check(questionMin > 0.0f && Mathf.IsEqualApprox(questionMin, answerMin),
			"씬: 질문·답 라벨에 최소 너비가 동일하게 설정됨");

		var deck = DeckParser.Parse(TestDeckText);

		// 판정 종류와 무관하게 카드는 한 번씩만 나온다. 첫 장만 Again으로 넘겨 본다.
		studyView.EmitSignal(StudyView.SignalName.AgainPressed);
		this.Check(studyView.Visible && !done.Visible, "씬: 카드가 남아 있으면 세션 계속");

		for (var i = 1; i < deck.Count; i++)
		{
			studyView.EmitSignal(StudyView.SignalName.GoodPressed);
		}
		this.Check(!studyView.Visible && done.Visible, "씬: 덱 장수만큼 넘기면 Done 화면 표시");

		var progressPath = DeckStorage.ProgressPath(TestDeckFile);
		this.Check(FileAccess.FileExists(progressPath), "씬: Again 시 그 덱의 진행도 파일 저장됨");

		// 뒤로 가기는 Study가 해석하지 않고 사실만 위로 알린다.
		var exitRequested = false;
		study.ExitRequested += () => exitRequested = true;
		studyView.EmitSignal(StudyView.SignalName.BackPressed);
		this.Check(exitRequested, "씬: ←는 ExitRequested로 전달");

		study.QueueFree();

		// 재실행 시뮬레이션: 저장된 진행도가 새 Study 인스턴스에 로드되는지
		using (var file = FileAccess.Open(progressPath, FileAccess.ModeFlags.Write))
		{
			var firstQuestion = JsonSerializer.Serialize(deck[0].Question);
			file?.StoreString($"{{{firstQuestion}: 5}}");
		}
		var second = packed.Instantiate<Study>();
		this.AddChild(second);
		second.StartDeck(TestDeckFile, StudyOrder.Sequential);
		var savedTally = second.GetNode<CardView>("%Card").GetNode<TallyMarks>("%Tally");
		this.Check(savedTally.Count == 5, "씬: 재실행 시 저장된 WrongCount가 작대기 수로 표시");
		second.QueueFree();

		RemoveTestDeck();
	}

	// app.tscn 배선 검증: 덱 목록 → 덱 선택 → Study → ✏ 카드 목록 → 뒤로. 마지막 덱은 설정에 남는다.
	// 실제 설정 파일을 쓰므로 백업 후 복원한다.
	private void AppSmokeTest()
	{
		var settingsBackup = FileAccess.FileExists(DeckStorage.SettingsPath)
			? FileAccess.GetFileAsString(DeckStorage.SettingsPath)
			: null;

		WriteTestDeck();
		// 마지막 덱이 없는 첫 실행 상태로 시작한다.
		DeckStorage.SaveSettings(new AppSettings());

		var app = GD.Load<PackedScene>("res://src/app.tscn").Instantiate<Control>();
		this.AddChild(app);

		this.Check(app.Theme != null, "앱: 테마가 루트에 적용됨 (자식 화면에 상속)");

		var deckList = app.GetNode<DeckListView>("%DeckListView");
		var deckHome = app.GetNode<DeckHomeView>("%DeckHomeView");
		var study = app.GetNode<Study>("%Study");
		this.Check(deckList.Visible && !study.Visible && !deckHome.Visible,
			"앱: 마지막 덱이 없으면 덱 목록부터");

		var deckBox = deckList.GetNode<HFlowContainer>("%DeckBox");
		// 덱 타일 + 마지막 "새 덱" 타일 하나.
		this.Check(deckBox.GetChildCount() == DeckStorage.ListDeckFiles().Count + 1,
			"앱: 저장소의 덱 수 + 새 덱 타일만큼 나온다");

		deckList.EmitSignal(DeckListView.SignalName.DeckChosen, TestDeckFile);
		this.Check(deckHome.Visible && !deckList.Visible, "앱: 덱을 고르면 허브로 전환");
		this.Check(DeckStorage.LoadSettings().LastDeckFile == TestDeckFile,
			"앱: 고른 덱이 마지막 덱으로 저장됨");

		deckHome.EmitSignal(DeckHomeView.SignalName.StudyRequested, (int)StudyOrder.Sequential);
		this.Check(study.Visible && !deckHome.Visible, "앱: 허브에서 ▶ Study를 누르면 Study로 전환");

		// ✏ → 카드 목록: 지금 덱의 카드가 저장된 틀린 횟수와 함께 나온다.
		var savedProgress = new Progress();
		savedProgress.AddWrong("A");
		savedProgress.AddWrong("A");
		savedProgress.AddWrong("A");
		DeckStorage.SaveProgress(TestDeckFile, savedProgress);

		var studyView = study.GetNode<StudyView>("%StudyView");
		var cardEditor = app.GetNode<CardEditorView>("%CardEditorView");
		studyView.EmitSignal(StudyView.SignalName.EditPressed);
		this.Check(cardEditor.Visible && !study.Visible, "앱: 세션 중 ✏는 현재 카드의 편집기를 연다");
		this.Check(cardEditor.GetNode<LineEdit>("%QuestionEdit").Text == "A",
			"앱: 세션 중 편집기에 지금 보는 카드가 채워진다");
		this.Check((int)cardEditor.GetNode<SpinBox>("%WrongCountSpin").Value == 3,
			"앱: 세션 중 편집기에 저장된 틀린 횟수가 채워진다");

		// A→A2로 고치고 ←: 세션이 유지된 채 Study로 돌아오고, 화면의 카드가 갱신된다.
		cardEditor.EmitSignal(CardEditorView.SignalName.EditingDone,
			"A2", "1", 3, (int)CardStatus.Learning);
		this.Check(study.Visible && !cardEditor.Visible, "앱: 세션 중 편집을 마치면 Study로 복귀");
		this.Check(study.GetNode<CardView>("%Card").GetNode<Label>("%QuestionLabel").Text == "A2",
			"앱: 복귀한 카드에 편집된 질문이 보인다");
		var edited = DeckParser.Parse(DeckStorage.ReadDeck(TestDeckFile));
		this.Check(edited[0].Question == "A2", "앱: 편집한 질문이 md에 반영됨");
		var afterEdit = DeckStorage.LoadProgress(TestDeckFile);
		this.Check(afterEdit.GetWrongCount("A2") == 3 && afterEdit.GetWrongCount("A") == 0,
			"앱: 질문을 고쳐도 진행도가 카드를 따라온다 (모델 A)");
		this.Check(afterEdit.GetStatus("A2") == CardStatus.Learning,
			"앱: 편집기에서 정한 상태가 저장됨");

		// 편집 직후 Again: 다시 읽은 진행도 위에 쌓여야 한다 — 낡은 메모리 사본으로 덮어쓰면
		// 방금 이사한 기록(A→A2)이 유실된다.
		studyView.EmitSignal(StudyView.SignalName.AgainPressed);
		var afterAgain = DeckStorage.LoadProgress(TestDeckFile);
		this.Check(afterAgain.GetWrongCount("A2") == 4 && afterAgain.GetWrongCount("A") == 0,
			"앱: 세션 중 편집 후 Again이 진행도를 덮어쓰지 않는다");

		// 세션 중 삭제: 지금 카드(B)를 지우면 세션이 다음 카드(C)로 넘어간다.
		studyView.EmitSignal(StudyView.SignalName.EditPressed);
		this.Check(cardEditor.GetNode<LineEdit>("%QuestionEdit").Text == "B",
			"앱: Again 뒤 ✏는 다음 카드를 연다");
		cardEditor.EmitSignal(CardEditorView.SignalName.DeleteRequested);
		this.Check(study.Visible && !cardEditor.Visible, "앱: 세션 중 삭제 후 Study로 복귀");
		this.Check(study.GetNode<CardView>("%Card").GetNode<Label>("%QuestionLabel").Text == "C",
			"앱: 삭제된 카드 대신 다음 카드가 보인다");
		var afterMidDelete = DeckParser.Parse(DeckStorage.ReadDeck(TestDeckFile));
		this.Check(afterMidDelete.Count == 2 && afterMidDelete[1].Question == "C",
			"앱: 세션 중 삭제가 md에서도 빠진다");

		study.EmitSignal(Study.SignalName.ExitRequested);
		this.Check(deckHome.Visible && !study.Visible, "앱: Study에서 뒤로 가면 허브로 전환");

		// 허브 ✏ → 카드 목록: 덱의 카드가 저장된 틀린 횟수와 함께 나온다. (덱은 지금 A2·C)
		var cardList = app.GetNode<CardListView>("%CardListView");
		deckHome.EmitSignal(DeckHomeView.SignalName.CardListRequested);
		this.Check(cardList.Visible && !deckHome.Visible, "앱: 허브 ✏로 카드 목록 진입");

		var cardBox = cardList.GetNode<VBoxContainer>("%CardBox");
		this.Check(cardBox.GetChildCount() == 2, "앱: 덱의 카드 수만큼 목록에 나온다");
		// 행은 CardRowView 씬(Button)이고, 질문·횟수는 그 안의 고유 이름으로 찾는다.
		var firstRow = cardBox.GetChild<CardRowView>(0);
		this.Check(firstRow.GetNode<Label>("%Question").Text == "A2",
			"앱: 카드 행에 질문이 덱 순서대로 표시");
		this.Check(firstRow.GetNode<Label>("%Count").Text.Contains("4"),
			"앱: 카드 행에 저장된 틀린 횟수 표시");

		// ＋ 카드 추가: 빈 편집기 → 저장 시 덱 끝에 붙고, 목록으로 돌아온다.
		cardList.EmitSignal(CardListView.SignalName.AddCardRequested);
		this.Check(cardEditor.Visible && cardEditor.GetNode<LineEdit>("%QuestionEdit").Text == "",
			"앱: 카드 추가는 빈 편집기로 연다");
		cardEditor.EmitSignal(CardEditorView.SignalName.EditingDone,
			"D", "4", 0, (int)CardStatus.New);
		this.Check(cardList.Visible && !cardEditor.Visible,
			"앱: 목록에서 연 편집기는 ←로 목록에 복귀");
		var added = DeckParser.Parse(DeckStorage.ReadDeck(TestDeckFile));
		this.Check(added.Count == 3 && added[2].Question == "D",
			"앱: 새 카드가 덱 끝에 추가됨");

		// 목록에서 삭제: 진행도가 있는 카드(A2)를 지우면 그 기록도 정리되고 목록으로 돌아온다.
		cardList.EmitSignal(CardListView.SignalName.CardChosen, 0);
		this.Check(cardEditor.Visible && cardEditor.GetNode<LineEdit>("%QuestionEdit").Text == "A2",
			"앱: 카드를 고르면 편집기로 전환");
		cardEditor.EmitSignal(CardEditorView.SignalName.DeleteRequested);
		this.Check(cardList.Visible && !cardEditor.Visible,
			"앱: 목록에서 연 편집기의 삭제는 목록으로 복귀");
		var afterDelete = DeckParser.Parse(DeckStorage.ReadDeck(TestDeckFile));
		this.Check(afterDelete.Count == 2 && afterDelete[0].Question == "C",
			"앱: 삭제한 카드가 덱에서 빠짐");
		this.Check(DeckStorage.LoadProgress(TestDeckFile).GetWrongCount("A2") == 0,
			"앱: 삭제한 카드의 진행도도 정리됨");

		cardList.EmitSignal(CardListView.SignalName.BackPressed);
		this.Check(deckHome.Visible && !cardList.Visible, "앱: 카드 목록 ←는 허브로 복귀");

		deckHome.EmitSignal(DeckHomeView.SignalName.BackPressed);
		this.Check(deckList.Visible && !deckHome.Visible, "앱: 허브에서 ← Decks 누르면 덱 목록으로");

		// 새 덱: 빈 덱을 만들고 곧바로 카드 목록으로 간다.
		const string newDeckFile = "__smoke_new.md";
		deckList.EmitSignal(DeckListView.SignalName.NewDeckRequested, "__smoke_new");
		this.Check(DeckStorage.DeckExists(newDeckFile), "앱: 새 덱을 만들면 빈 덱 파일이 생긴다");
		this.Check(cardList.Visible, "앱: 새 덱은 카드 목록으로 바로 연다");
		if (DeckStorage.DeckExists(newDeckFile))
		{
			DirAccess.RemoveAbsolute(DeckStorage.DeckPath(newDeckFile));
		}

		// 새 덱이 마지막 덱으로 저장됐으니, 재실행 검증을 위해 되돌린다.
		DeckStorage.SaveSettings(new AppSettings { LastDeckFile = TestDeckFile });

		app.QueueFree();

		// 재실행 시뮬레이션: 마지막 덱이 있으면 목록을 건너뛰고 그 덱의 허브로 바로 간다
		// (DESIGN의 "기본 진입 화면").
		var second = GD.Load<PackedScene>("res://src/app.tscn").Instantiate<Control>();
		this.AddChild(second);
		this.Check(second.GetNode<DeckHomeView>("%DeckHomeView").Visible,
			"앱: 재실행 시 마지막 덱의 허브로 바로 시작");
		second.QueueFree();

		RemoveTestDeck();

		if (settingsBackup != null)
		{
			using var file = FileAccess.Open(DeckStorage.SettingsPath, FileAccess.ModeFlags.Write);
			file?.StoreString(settingsBackup);
		}
		else if (FileAccess.FileExists(DeckStorage.SettingsPath))
		{
			DirAccess.RemoveAbsolute(DeckStorage.SettingsPath);
		}
	}

	// 덱/카드 메뉴 배선: App이 시그널을 받아 저장소·진행도·설정에 반영하는지. 파일·설정을 건드리므로 복원한다.
	private void AppMenuActions()
	{
		var settingsBackup = FileAccess.FileExists(DeckStorage.SettingsPath)
			? FileAccess.GetFileAsString(DeckStorage.SettingsPath)
			: null;

		const string deckFile = "__menu_deck.md";
		DeckStorage.WriteDeck(deckFile, "# A\n1\n# B\n2\n");
		// 마지막 덱으로 두면 앱이 곧장 그 덱의 허브로 시작한다 (Study는 신호로 직접 불러 시험한다).
		DeckStorage.SaveSettings(new AppSettings { LastDeckFile = deckFile });

		var app = GD.Load<PackedScene>("res://src/app.tscn").Instantiate<Control>();
		this.AddChild(app);

		var deckList = app.GetNode<DeckListView>("%DeckListView");
		var deckHome = app.GetNode<DeckHomeView>("%DeckHomeView");
		var cardList = app.GetNode<CardListView>("%CardListView");

		// 허브 ✏로 카드 목록에 들어가 카드 메뉴를 시험한다 (화면이 안 보여도 신호는 발신할 수 있다).
		deckHome.EmitSignal(DeckHomeView.SignalName.CardListRequested);

		// 카드 복제: index 0(A) 뒤에 사본이 들어간다 → A·A·B.
		cardList.EmitSignal(CardListView.SignalName.CardDuplicateRequested, 0);
		var afterDup = DeckParser.Parse(DeckStorage.ReadDeck(deckFile));
		this.Check(afterDup.Count == 3 && afterDup[1].Question == "A",
			"앱 메뉴: 카드 복제가 원본 뒤에 사본을 넣는다");

		// 카드 삭제(메뉴): 진행도 있는 카드 B(지금 index 2)를 지우면 그 기록도 정리된다.
		var bp = new Progress();
		bp.SetWrongCount("B", 2);
		DeckStorage.SaveProgress(deckFile, bp);
		cardList.EmitSignal(CardListView.SignalName.CardDeleteRequested, 2);
		var afterDel = DeckParser.Parse(DeckStorage.ReadDeck(deckFile));
		this.Check(afterDel.Count == 2 && afterDel[1].Question == "A",
			"앱 메뉴: 카드 삭제가 그 자리 카드를 뺀다");
		this.Check(DeckStorage.LoadProgress(deckFile).GetWrongCount("B") == 0,
			"앱 메뉴: 삭제한 카드의 진행도도 정리된다");

		// 덱 복제: 사본이 생긴다.
		deckList.EmitSignal(DeckListView.SignalName.DeckDuplicateRequested, deckFile);
		const string dupFile = "__menu_deck (2).md";
		this.Check(DeckStorage.DeckExists(dupFile), "앱 메뉴: 덱 복제로 사본이 생긴다");

		// 덱 이름 변경: 마지막 덱이면 설정도 새 이름을 따라온다.
		const string renamed = "__menu_renamed.md";
		deckList.EmitSignal(DeckListView.SignalName.DeckRenameRequested, deckFile, "__menu_renamed");
		this.Check(DeckStorage.DeckExists(renamed) && !DeckStorage.DeckExists(deckFile),
			"앱 메뉴: 덱 이름 변경이 파일 이름을 바꾼다");
		this.Check(DeckStorage.LoadSettings().LastDeckFile == renamed,
			"앱 메뉴: 마지막 덱이면 이름 변경이 설정에도 반영된다");

		// 덱 삭제: 마지막 덱을 지우면 설정의 마지막 덱이 비워진다.
		deckList.EmitSignal(DeckListView.SignalName.DeckDeleteRequested, renamed);
		this.Check(!DeckStorage.DeckExists(renamed), "앱 메뉴: 덱 삭제가 파일을 지운다");
		this.Check(DeckStorage.LoadSettings().LastDeckFile == "",
			"앱 메뉴: 마지막 덱을 지우면 설정이 비워진다");

		app.QueueFree();

		foreach (var f in new[] { deckFile, renamed, dupFile })
		{
			if (DeckStorage.DeckExists(f))
			{
				DirAccess.RemoveAbsolute(DeckStorage.DeckPath(f));
			}

			if (FileAccess.FileExists(DeckStorage.ProgressPath(f)))
			{
				DirAccess.RemoveAbsolute(DeckStorage.ProgressPath(f));
			}
		}

		if (settingsBackup != null)
		{
			using var file = FileAccess.Open(DeckStorage.SettingsPath, FileAccess.ModeFlags.Write);
			file?.StoreString(settingsBackup);
		}
		else if (FileAccess.FileExists(DeckStorage.SettingsPath))
		{
			DirAccess.RemoveAbsolute(DeckStorage.SettingsPath);
		}
	}
}
