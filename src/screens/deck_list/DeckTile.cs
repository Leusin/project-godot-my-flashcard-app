using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 덱 목록의 타일 하나. 이름·카드 수를 표시하고, 열림(탭)과 메뉴 요청만 사실로 알린다.
// 저장소·파싱·메뉴 내용은 모른다 — 어느 덱인지와 메뉴를 열 위치만 위로 올린다.
public partial class DeckTile : Button
{
	[Signal] public delegate void ChosenEventHandler(string deckFile);
	[Signal] public delegate void MenuRequestedEventHandler(string deckFile, Vector2 atPosition);

	// 타일은 카드 비율의 고정 크기. HFlowContainer가 창 폭에 맞춰 줄을 바꾼다.
	// 수치의 출처는 씬이 아니라 상수다 — 에디터가 씬을 덮어써도 값이 살아남는다 (CardView와 같은 규칙).
	public const float TileWidth = 360.0f;
	public static readonly float TileHeight = TileWidth / CardView.AspectRatio;

	private Label _nameLabel = null!;
	private Label _countLabel = null!;
	private Button _menuButton = null!;
	private string _deckFile = "";

	public override void _Ready()
	{
		this._nameLabel = this.GetNode<Label>("%NameLabel");
		this._countLabel = this.GetNode<Label>("%CountLabel");
		this._menuButton = this.GetNode<Button>("%MenuButton");

		this.CustomMinimumSize = new Vector2(TileWidth, TileHeight);
		this.Pressed += () => this.EmitSignal(SignalName.Chosen, this._deckFile);
		this._menuButton.Pressed += this.OnMenuPressed;
	}

	// 씬을 트리에 넣은 뒤(=_Ready 실행 후) 부른다.
	public void Setup(DeckInfo deck)
	{
		this._deckFile = deck.FileName;
		this._nameLabel.Text = deck.DisplayName;
		this._countLabel.Text = $"{deck.CardCount} Cards";
	}

	// 메뉴는 ⋯ 버튼 아래에서 연다. 어느 덱인지는 목록 뷰가 알아야 하므로 함께 올린다.
	private void OnMenuPressed()
	{
		var at = this._menuButton.GetScreenPosition() + new Vector2(0.0f, this._menuButton.Size.Y);
		this.EmitSignal(SignalName.MenuRequested, this._deckFile, at);
	}
}
