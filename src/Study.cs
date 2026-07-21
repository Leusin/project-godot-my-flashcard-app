using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 앱 진입점이자 세션 관리자. 덱 로드, 세션 진행, 진행도 저장을 조율한다.
// 뷰(StudyView)의 사실(버튼 눌림)을 구독해 해석(WrongCount 증가, 큐 갱신)한다.
public partial class Study : Control
{
	private const string DeckPath = "res://sample_deck.md";      // v0.1: 하드코딩
	private const string ProgressPath = "user://progress.json";

	private StudyView _studyView = null!;
	private Control _doneView = null!;
	private StudySession _session = null!;
	private Progress _progress = new();

	public override void _Ready()
	{
		this._studyView = this.GetNode<StudyView>("%StudyView");
		this._doneView = this.GetNode<Control>("%DoneView");
		this.GetNode<Button>("%RestartButton").Pressed += this.StartSession;

		this._studyView.AgainPressed += this.OnAgain;
		this._studyView.GoodPressed += this.OnGood;

		this._progress = this.LoadProgress();
		this.StartSession();
	}

	private void StartSession()
	{
		var text = FileAccess.GetFileAsString(DeckPath);
		this._session = new StudySession(DeckParser.Parse(text));
		this.ShowCurrent();
	}

	private void OnAgain()
	{
		var card = this._session.Current;
		if (card == null)
		{
			return;
		}

		this._progress.AddWrong(card.Question);
		this.SaveProgress();
		this._session.Next();
		this.ShowCurrent();
	}

	private void OnGood()
	{
		this._session.Next();
		this.ShowCurrent();
	}

	private void ShowCurrent()
	{
		var card = this._session.Current;
		this._studyView.Visible = card != null;
		this._doneView.Visible = card == null;
		if (card != null)
		{
			this._studyView.ShowCard(card.Question, card.Answer,
				this._progress.GetWrongCount(card.Question), this._session.Remaining);
		}
	}

	private Progress LoadProgress()
	{
		if (!FileAccess.FileExists(ProgressPath))
		{
			return new Progress();
		}

		return Progress.FromJson(FileAccess.GetFileAsString(ProgressPath));
	}

	private void SaveProgress()
	{
		using var file = FileAccess.Open(ProgressPath, FileAccess.ModeFlags.Write);
		file?.StoreString(this._progress.ToJson());
	}
}
