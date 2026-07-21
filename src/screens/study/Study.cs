using System;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 세션 관리자. 받은 덱을 로드해 세션을 진행하고 진행도를 저장한다.
// 뷰(StudyView)의 사실(버튼 눌림)을 구독해 해석(WrongCount 증가, 큐 갱신)한다.
// 어떤 덱을 열지는 스스로 정하지 않고, 화면을 떠나고 싶다는 사실만 시그널로 알린다.
public partial class Study : Control
{
	[Signal] public delegate void ExitRequestedEventHandler();

	private StudyView _studyView = null!;
	private Control _doneView = null!;
	private StudySession _session = null!;
	private Progress _progress = new();
	private string _deckFile = "";

	public override void _Ready()
	{
		this._studyView = this.GetNode<StudyView>("%StudyView");
		this._doneView = this.GetNode<Control>("%DoneView");
		this.GetNode<Button>("%RestartButton").Pressed += this.StartSession;
		this.GetNode<Button>("%DoneDecksButton").Pressed +=
			() => this.EmitSignal(SignalName.ExitRequested);

		this._studyView.AgainPressed += this.OnAgain;
		this._studyView.GoodPressed += this.OnGood;
		this._studyView.BackPressed += () => this.EmitSignal(SignalName.ExitRequested);

		// 덱을 받기 전까지는 빈 세션. StartDeck 전에 눌려도 큐가 없어 아무 일도 하지 않는다.
		this._session = new StudySession(Array.Empty<Card>());
		this.ShowCurrent();
	}

	public void StartDeck(string deckFile)
	{
		this._deckFile = deckFile;
		this._progress = DeckStorage.LoadProgress(deckFile);
		this._studyView.ShowDeckName(DeckNaming.DisplayName(deckFile));
		this.StartSession();
	}

	private void StartSession()
	{
		this._session = new StudySession(DeckParser.Parse(DeckStorage.ReadDeck(this._deckFile)));
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
		DeckStorage.SaveProgress(this._deckFile, this._progress);
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
}
