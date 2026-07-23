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
	[Signal] public delegate void EditRequestedEventHandler(string question);

	private StudyView _studyView = null!;
	private Control _doneView = null!;
	private StudySession _session = null!;
	private Progress _progress = new();
	private string _deckFile = "";
	private StudyOrder _order = StudyOrder.Sequential;

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
		this._studyView.EditPressed += this.OnEditPressed;

		// 덱을 받기 전까지는 빈 세션. StartDeck 전에 눌려도 큐가 없어 아무 일도 하지 않는다.
		this._session = new StudySession(Array.Empty<Card>());
		this.ShowCurrent();
	}

	// order는 허브(Deck Home)에서 고른 값 — 세션을 새로 만들 때마다(재시작 포함) 다시 적용한다.
	public void StartDeck(string deckFile, StudyOrder order)
	{
		this._deckFile = deckFile;
		this._order = order;
		this._progress = DeckStorage.LoadProgress(deckFile);
		this._studyView.ShowDeckName(DeckNaming.DisplayName(deckFile));
		this.StartSession();
	}

	private void StartSession()
	{
		var cards = DeckOrdering.Apply(
			this._order, DeckParser.Parse(DeckStorage.ReadDeck(this._deckFile)));
		this._session = new StudySession(cards);
		this.ShowCurrent();
	}

	// ✏는 지금 보는 카드의 편집 요청이다. 어느 카드인지(Question이 곧 카드 식별자)만 실어 올린다.
	private void OnEditPressed()
	{
		var card = this._session.Current;
		if (card != null)
		{
			this.EmitSignal(SignalName.EditRequested, card.Question);
		}
	}

	// 편집기에서 현재 카드가 바뀌어 돌아왔다. 세션의 카드를 교체하고 진행도를 다시 읽는다 —
	// 편집이 저장한 진행도를 낡은 메모리 사본으로 덮어쓰지 않기 위해서다.
	public void OnCurrentCardEdited(Card card)
	{
		this._session.ReplaceCurrent(card);
		this._progress = DeckStorage.LoadProgress(this._deckFile);
		this.ShowCurrent();
	}

	// 편집기에서 현재 카드가 삭제되어 돌아왔다. 세션은 다음 카드로 넘어간다 (마지막이었다면 완료 화면).
	public void OnCurrentCardDeleted()
	{
		this._session.Next();
		this._progress = DeckStorage.LoadProgress(this._deckFile);
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
				this._progress.GetWrongCount(card.Question),
				this._progress.GetStatus(card.Question), this._session.Remaining);
		}
	}
}
