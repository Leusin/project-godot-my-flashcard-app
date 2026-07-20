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
        ParserBasics();
        ParserEdgeCases();
        SessionQueue();
        ProgressRoundTrip();
        SceneSmokeTest();

        GD.Print($"tests: {_passed} passed, {_failed} failed");
        GetTree().Quit(_failed);
    }

    private void Check(bool condition, string name)
    {
        if (condition)
        {
            _passed++;
        }
        else
        {
            _failed++;
            GD.PrintErr($"FAIL: {name}");
        }
    }

    private void ParserBasics()
    {
        var cards = DeckParser.Parse("# Apple\n사과\n# Red\n빨간색\n");
        Check(cards.Count == 2, "파서: 카드 2장");
        Check(cards[0].Question == "Apple" && cards[0].Answer == "사과", "파서: 첫 카드 질문/답");
        Check(cards[1].Question == "Red" && cards[1].Answer == "빨간색", "파서: 둘째 카드 질문/답");

        var multiline = DeckParser.Parse("# Q\n첫 줄\n둘째 줄\n");
        Check(multiline[0].Answer == "첫 줄\n둘째 줄", "파서: 여러 줄 답 유지");
    }

    private void ParserEdgeCases()
    {
        Check(DeckParser.Parse("").Count == 0, "파서: 빈 문서");
        Check(DeckParser.Parse("질문 없는 내용\n그냥 텍스트").Count == 0, "파서: 첫 질문 이전 내용 무시");

        var emptyAnswer = DeckParser.Parse("# Q1\n# Q2\n답");
        Check(emptyAnswer.Count == 2 && emptyAnswer[0].Answer == "", "파서: 답 없는 카드 허용");

        Check(DeckParser.Parse("# \n답").Count == 0, "파서: 질문 빈 카드 버림");
        Check(DeckParser.Parse("#공백없음\n답").Count == 0, "파서: '# ' 없으면 질문 아님");

        var crlf = DeckParser.Parse("# Q\r\n답\r\n");
        Check(crlf.Count == 1 && crlf[0].Answer == "답", "파서: CRLF 처리");

        var padded = DeckParser.Parse("# Q\n\n답\n\n# Q2\n답2");
        Check(padded[0].Answer == "답", "파서: 답 앞뒤 공백 줄 제거");
    }

    private void SessionQueue()
    {
        var cards = DeckParser.Parse("# A\n1\n# B\n2\n# C\n3");
        var session = new StudySession(cards);

        Check(session.Current?.Question == "A", "세션: 첫 카드는 덱 순서대로");
        Check(session.Remaining == 3, "세션: 시작 시 남은 카드 수");

        session.Again();
        Check(session.Current?.Question == "B", "세션: Again 후 다음 카드");
        Check(session.Remaining == 3, "세션: Again은 카드를 줄이지 않음");

        session.Good();
        session.Good();
        Check(session.Current?.Question == "A", "세션: Again 카드가 맨 뒤에 다시 등장");

        session.Good();
        Check(session.IsFinished && session.Current == null, "세션: 전부 완료 시 종료");

        var single = new StudySession(DeckParser.Parse("# 하나\n1"));
        single.Again();
        Check(single.Current?.Question == "하나", "세션: 카드 1장 Again은 같은 카드 반복");
    }

    private void ProgressRoundTrip()
    {
        var p = new Progress();
        Check(p.GetWrongCount("없는질문") == 0, "진행도: 기록 없으면 0");

        p.AddWrong("Apple");
        p.AddWrong("Apple");
        p.AddWrong("Red");
        var restored = Progress.FromJson(p.ToJson());
        Check(restored.GetWrongCount("Apple") == 2, "진행도: 직렬화 왕복 (Apple=2)");
        Check(restored.GetWrongCount("Red") == 1, "진행도: 직렬화 왕복 (Red=1)");

        Check(Progress.FromJson("").GetWrongCount("x") == 0, "진행도: 빈 JSON은 빈 진행도");
        Check(Progress.FromJson("{깨진 json").GetWrongCount("x") == 0, "진행도: 깨진 JSON은 빈 진행도");
    }

    // main.tscn 배선 검증: 씬 로드 → 버튼 시그널로 세션 한 바퀴 → Done 화면.
    // Main이 진행도 파일을 쓰므로 백업 후 복원한다.
    private void SceneSmokeTest()
    {
        const string progressPath = "user://progress.json";
        string? backup = FileAccess.FileExists(progressPath)
            ? FileAccess.GetFileAsString(progressPath)
            : null;

        var packed = GD.Load<PackedScene>("res://src/main.tscn");
        Check(packed != null, "씬: main.tscn 로드");
        if (packed == null)
            return;

        var main = packed.Instantiate<Control>();
        AddChild(main);

        var study = main.GetNode<StudyView>("%StudyView");
        var done = main.GetNode<Control>("%DoneView");
        Check(study.Visible && !done.Visible, "씬: 시작 시 Study 화면 표시");

        // 샘플 덱 3장: 카드1 Again → 카드2,3 Good → 다시 온 카드1 Good
        study.EmitSignal(StudyView.SignalName.AgainPressed);
        study.EmitSignal(StudyView.SignalName.GoodPressed);
        study.EmitSignal(StudyView.SignalName.GoodPressed);
        Check(study.Visible && !done.Visible, "씬: Again 카드가 남아 세션 계속");

        study.EmitSignal(StudyView.SignalName.GoodPressed);
        Check(!study.Visible && done.Visible, "씬: 전부 완료 시 Done 화면 표시");

        Check(FileAccess.FileExists(progressPath), "씬: Again 시 진행도 파일 저장됨");

        main.QueueFree();

        // 재실행 시뮬레이션: 저장된 진행도가 새 Main 인스턴스에 로드되는지
        using (var file = FileAccess.Open(progressPath, FileAccess.ModeFlags.Write))
        {
            file?.StoreString("{\"HTTP 404\": 5}");
        }
        var second = packed.Instantiate<Control>();
        AddChild(second);
        var wrongLabel = second.GetNode<Label>("%WrongCountLabel");
        Check(wrongLabel.Text == "WrongCount 5", "씬: 재실행 시 저장된 WrongCount 표시");
        second.QueueFree();

        if (backup != null)
        {
            using var file = FileAccess.Open(progressPath, FileAccess.ModeFlags.Write);
            file?.StoreString(backup);
        }
        else if (FileAccess.FileExists(progressPath))
        {
            DirAccess.RemoveAbsolute(progressPath);
        }
    }
}
