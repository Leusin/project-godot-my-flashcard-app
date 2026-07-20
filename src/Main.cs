using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 앱 진입점이자 세션 관리자. 덱 로드, 세션 진행, 진행도 저장을 조율한다.
// 뷰(StudyView)의 사실(버튼 눌림)을 구독해 해석(WrongCount 증가, 큐 갱신)한다.
public partial class Main : Control
{
    private const string DeckPath = "res://sample_deck.md";      // v0.1: 하드코딩
    private const string ProgressPath = "user://progress.json";

    private StudyView _studyView = null!;
    private Control _doneView = null!;
    private StudySession _session = null!;
    private Progress _progress = new();

    public override void _Ready()
    {
        _studyView = GetNode<StudyView>("%StudyView");
        _doneView = GetNode<Control>("%DoneView");
        GetNode<Button>("%RestartButton").Pressed += StartSession;

        _studyView.AgainPressed += OnAgain;
        _studyView.GoodPressed += OnGood;

        _progress = LoadProgress();
        StartSession();
    }

    private void StartSession()
    {
        var text = FileAccess.GetFileAsString(DeckPath);
        _session = new StudySession(DeckParser.Parse(text));
        ShowCurrent();
    }

    private void OnAgain()
    {
        var card = _session.Current;
        if (card == null)
            return;
        _progress.AddWrong(card.Question);
        SaveProgress();
        _session.Again();
        ShowCurrent();
    }

    private void OnGood()
    {
        _session.Good();
        ShowCurrent();
    }

    private void ShowCurrent()
    {
        var card = _session.Current;
        _studyView.Visible = card != null;
        _doneView.Visible = card == null;
        if (card != null)
            _studyView.ShowCard(card.Question, card.Answer,
                _progress.GetWrongCount(card.Question), _session.Remaining);
    }

    private Progress LoadProgress()
    {
        if (!FileAccess.FileExists(ProgressPath))
            return new Progress();
        return Progress.FromJson(FileAccess.GetFileAsString(ProgressPath));
    }

    private void SaveProgress()
    {
        using var file = FileAccess.Open(ProgressPath, FileAccess.ModeFlags.Write);
        file?.StoreString(_progress.ToJson());
    }
}
