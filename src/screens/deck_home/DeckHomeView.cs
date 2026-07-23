using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 덱 하나의 시작 화면(허브). 이름·카드 수를 보여주고 Study 시작(순서 선택)·Card List 진입·
// 덱 목록으로 돌아가기를 사실로만 알린다. 저장소·학습 규칙·카드 목록 내용은 모른다.
public partial class DeckHomeView : Control
{
	[Signal] public delegate void BackPressedEventHandler();
	[Signal] public delegate void StudyRequestedEventHandler(int order);
	[Signal] public delegate void CardListRequestedEventHandler();

	private Label _nameLabel = null!;
	private Label _countLabel = null!;
	private OptionButton _orderOption = null!;

	public override void _Ready()
	{
		this._nameLabel = this.GetNode<Label>("%NameLabel");
		this._countLabel = this.GetNode<Label>("%CountLabel");
		this._orderOption = this.GetNode<OptionButton>("%OrderOption");

		// 허브 패널은 학습 카드와 같은 비율 — "책상 위의 카드 한 장"으로 읽히고,
		// ▶ Study 전환 시 이 자리가 곧 카드가 된다. 비율의 출처는 CardView 상수 하나.
		this.GetNode<AspectRatioContainer>("%HomeAspect").Ratio = CardView.AspectRatio;

		// 표시 순서 = StudyOrder 값 순서. Selected가 곧 enum 값이다 (CardEditorView의 상태
		// 옵션과 같은 방식).
		this._orderOption.AddItem("Sequential", (int)StudyOrder.Sequential);
		this._orderOption.AddItem("Shuffle", (int)StudyOrder.Shuffle);

		this.GetNode<Button>("%BackButton").Pressed +=
			() => this.EmitSignal(SignalName.BackPressed);
		this.GetNode<Button>("%StudyButton").Pressed += () => this.EmitSignal(
			SignalName.StudyRequested, this._orderOption.Selected);
		this.GetNode<Button>("%CardListButton").Pressed +=
			() => this.EmitSignal(SignalName.CardListRequested);
	}

	public void ShowDeck(DeckInfo deck)
	{
		this._nameLabel.Text = deck.DisplayName;
		this._countLabel.Text = $"{deck.CardCount} Cards";
	}

	public void SetOrder(StudyOrder order)
	{
		this._orderOption.Selected = (int)order;
	}
}
