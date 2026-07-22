using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 카드 목록 화면의 배치만 담당한다. 저장소·파싱·학습 규칙은 모른다.
// 카드를 표시하고, 어떤 카드를 골랐는지·뒤로 가기를 시그널로 알린다 (편집은 위가 해석).
public partial class CardListView : Control
{
	[Signal] public delegate void BackPressedEventHandler();
	[Signal] public delegate void CardChosenEventHandler(int index);
	[Signal] public delegate void AddCardRequestedEventHandler();

	private const int QuestionFontSize = 22;
	private const int RowHeight = 56;
	private const string EmptyText = "카드가 없습니다.";

	private Label _deckLabel = null!;
	private VBoxContainer _cardBox = null!;
	private Label _emptyLabel = null!;

	public override void _Ready()
	{
		this._deckLabel = this.GetNode<Label>("%DeckLabel");
		this._cardBox = this.GetNode<VBoxContainer>("%CardBox");
		this._emptyLabel = this.GetNode<Label>("%EmptyLabel");

		this._emptyLabel.Text = EmptyText;
		this.GetNode<Button>("%BackButton").Pressed +=
			() => this.EmitSignal(SignalName.BackPressed);
		this.GetNode<Button>("%AddButton").Pressed +=
			() => this.EmitSignal(SignalName.AddCardRequested);
	}

	public void ShowDeckName(string deckName)
	{
		this._deckLabel.Text = deckName;
	}

	public void ShowCards(IReadOnlyList<CardRow> rows)
	{
		foreach (var child in this._cardBox.GetChildren())
		{
			// 해제는 프레임 끝에 일어나므로, 새 목록과 섞이지 않게 먼저 떼어낸다.
			this._cardBox.RemoveChild(child);
			child.QueueFree();
		}

		this._emptyLabel.Visible = rows.Count == 0;

		for (var i = 0; i < rows.Count; i++)
		{
			this._cardBox.AddChild(this.MakeRow(rows[i], i));
		}
	}

	// 행 전체가 탭 대상이라 Button으로 만들고, 그 위에 질문·횟수를 얹는다.
	// 얹은 라벨은 클릭을 삼키지 않도록 마우스를 통과시켜 버튼이 눌리게 한다.
	private Button MakeRow(CardRow row, int index)
	{
		var button = new Button
		{
			CustomMinimumSize = new Vector2(0.0f, RowHeight),
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
			Flat = true,
		};
		button.Pressed += () => this.EmitSignal(SignalName.CardChosen, index);

		var line = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
		line.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);

		var question = new Label
		{
			Text = row.Question,
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
			VerticalAlignment = VerticalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
			// 긴 질문이 틀린 횟수를 밀어내지 않도록 한 줄로 자른다.
			TextOverrunBehavior = TextServer.OverrunBehavior.TrimEllipsis,
		};
		question.AddThemeFontSizeOverride("font_size", QuestionFontSize);

		var count = new Label
		{
			Text = $"틀림 {row.WrongCount}",
			VerticalAlignment = VerticalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		count.AddThemeFontSizeOverride("font_size", QuestionFontSize);

		line.AddChild(question);
		line.AddChild(count);
		button.AddChild(line);
		return button;
	}
}
