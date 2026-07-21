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
		this.DeckNamingRules();
		this.SettingsRoundTrip();
		this.DeckStorageRoundTrip();
		this.TallyWidth();
		this.CardFlip();
		this.SceneSmokeTest();
		this.AppSmokeTest();

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

	private void SettingsRoundTrip()
	{
		var settings = new AppSettings { LastDeckFile = "영어단어.md" };
		this.Check(AppSettings.FromJson(settings.ToJson()).LastDeckFile == "영어단어.md",
			"설정: 마지막 덱 직렬화 왕복");
		this.Check(AppSettings.FromJson("").LastDeckFile == "", "설정: 빈 JSON은 기본값");
		this.Check(AppSettings.FromJson("{깨진 json").LastDeckFile == "", "설정: 깨진 JSON은 기본값");
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

		card.ShowCard("질문", "답", 0);
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

		card.ShowCard("다음 질문", "다음 답", 3);
		this.Check(card.GetNode<TallyMarks>("%Tally").Count == 3, "카드: 틀린 횟수가 작대기로 전달됨");
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
		study.StartDeck(TestDeckFile);
		this.Check(studyView.Visible && !done.Visible, "씬: 덱을 받으면 Study 화면 표시");
		this.Check(study.GetNode<Label>("%DeckLabel").Text == DeckNaming.DisplayName(TestDeckFile),
			"씬: 상단바에 덱 이름 표시");

		// 판정 버튼은 답을 보기 전에도 누를 수 있어야 한다.
		var card = study.GetNode<CardView>("%Card");
		this.Check(study.GetNode<Control>("%ButtonRow").Visible, "씬: 판정 버튼은 처음부터 표시");

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
		this.Check(exitRequested, "씬: ← Decks는 ExitRequested로 전달");

		study.QueueFree();

		// 재실행 시뮬레이션: 저장된 진행도가 새 Study 인스턴스에 로드되는지
		using (var file = FileAccess.Open(progressPath, FileAccess.ModeFlags.Write))
		{
			var firstQuestion = JsonSerializer.Serialize(deck[0].Question);
			file?.StoreString($"{{{firstQuestion}: 5}}");
		}
		var second = packed.Instantiate<Study>();
		this.AddChild(second);
		second.StartDeck(TestDeckFile);
		var savedTally = second.GetNode<CardView>("%Card").GetNode<TallyMarks>("%Tally");
		this.Check(savedTally.Count == 5, "씬: 재실행 시 저장된 WrongCount가 작대기 수로 표시");
		second.QueueFree();

		RemoveTestDeck();
	}

	// app.tscn 배선 검증: 덱 목록 → 덱 선택 → Study → 뒤로. 마지막 덱은 설정에 남는다.
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

		var deckList = app.GetNode<DeckListView>("%DeckListView");
		var study = app.GetNode<Study>("%Study");
		this.Check(deckList.Visible && !study.Visible, "앱: 마지막 덱이 없으면 덱 목록부터");

		var deckBox = deckList.GetNode<VBoxContainer>("%DeckBox");
		this.Check(deckBox.GetChildCount() == DeckStorage.ListDeckFiles().Count,
			"앱: 저장소의 덱 수만큼 목록에 나온다");
		this.Check(!deckList.GetNode<Label>("%EmptyLabel").Visible,
			"앱: 덱이 있으면 빈 목록 안내는 숨긴다");

		deckList.EmitSignal(DeckListView.SignalName.DeckChosen, TestDeckFile);
		this.Check(study.Visible && !deckList.Visible, "앱: 덱을 고르면 Study로 전환");
		this.Check(DeckStorage.LoadSettings().LastDeckFile == TestDeckFile,
			"앱: 고른 덱이 마지막 덱으로 저장됨");

		study.EmitSignal(Study.SignalName.ExitRequested);
		this.Check(deckList.Visible && !study.Visible, "앱: 뒤로 가면 덱 목록으로 전환");

		app.QueueFree();

		// 재실행 시뮬레이션: 마지막 덱이 있으면 목록을 건너뛴다.
		var second = GD.Load<PackedScene>("res://src/app.tscn").Instantiate<Control>();
		this.AddChild(second);
		this.Check(second.GetNode<Study>("%Study").Visible, "앱: 재실행 시 마지막 덱으로 바로 시작");
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
}
