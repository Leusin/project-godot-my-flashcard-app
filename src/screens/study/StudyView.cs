using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// Study 화면의 배치만 담당한다. 학습 규칙과 진행도 갱신은 모른다.
// 카드 표시는 CardView에 맡기고, 버튼 눌림은 시그널로만 알린다.
public partial class StudyView : Control
{
	[Signal] public delegate void AgainPressedEventHandler();
	[Signal] public delegate void GoodPressedEventHandler();
	[Signal] public delegate void BackPressedEventHandler();
	[Signal] public delegate void EditPressedEventHandler();

	private Label _remainingLabel = null!;
	private Label _deckLabel = null!;
	private CardView _card = null!;

	public override void _Ready()
	{
		this._remainingLabel = this.GetNode<Label>("%RemainingLabel");
		this._deckLabel = this.GetNode<Label>("%DeckLabel");
		this._card = this.GetNode<CardView>("%Card");

		// 비율의 출처는 CardView 상수 하나. 씬에는 값을 두지 않는다.
		this.GetNode<AspectRatioContainer>("%CardAspect").Ratio = CardView.AspectRatio;

		this.GetNode<Button>("%BackButton").Pressed +=
			() => this.EmitSignal(SignalName.BackPressed);
		this.GetNode<Button>("%EditButton").Pressed +=
			() => this.EmitSignal(SignalName.EditPressed);
		this.GetNode<Button>("%AgainButton").Pressed +=
			() => this.EmitSignal(SignalName.AgainPressed);
		this.GetNode<Button>("%GoodButton").Pressed +=
			() => this.EmitSignal(SignalName.GoodPressed);
	}

	public void ShowDeckName(string deckName)
	{
		this._deckLabel.Text = deckName;
	}

	public void ShowCard(
		string question, string answer, int wrongCount, CardStatus status, int remaining)
	{
		this._card.ShowCard(question, answer, wrongCount, status);
		this._remainingLabel.Text = $"남은 카드 {remaining}";
	}
}
