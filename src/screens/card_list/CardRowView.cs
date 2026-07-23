using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 카드 목록의 한 줄. 질문·틀린 횟수를 표시하고, 열림(탭)과 메뉴 요청만 사실로 알린다.
// 답·파일 위치·메뉴 내용은 모른다 — 어느 카드인지와 메뉴를 열 위치만 위로 올린다.
public partial class CardRowView : Button
{
	[Signal] public delegate void ChosenEventHandler(int index);
	[Signal] public delegate void MenuRequestedEventHandler(int index, Vector2 atPosition);

	private const int RowHeight = 64;

	private Label _question = null!;
	private Label _count = null!;
	private Button _menuButton = null!;
	private int _index = -1;

	public override void _Ready()
	{
		this._question = this.GetNode<Label>("%Question");
		this._count = this.GetNode<Label>("%Count");
		this._menuButton = this.GetNode<Button>("%MenuButton");

		this.CustomMinimumSize = new Vector2(0.0f, RowHeight);
		this.Pressed += () => this.EmitSignal(SignalName.Chosen, this._index);
		this._menuButton.Pressed += this.OnMenuPressed;
	}

	// 씬을 트리에 넣은 뒤(=_Ready 실행 후) 부른다.
	public void Setup(CardRow row, int index)
	{
		this._index = index;
		this._question.Text = row.Question;
		this._count.Text = $"틀림 {row.WrongCount}";
	}

	// 메뉴는 ⋯ 버튼 아래에서 연다. 어느 카드인지는 목록 뷰가 알아야 하므로 함께 올린다.
	private void OnMenuPressed()
	{
		var at = this._menuButton.GetScreenPosition() + new Vector2(0.0f, this._menuButton.Size.Y);
		this.EmitSignal(SignalName.MenuRequested, this._index, at);
	}
}
