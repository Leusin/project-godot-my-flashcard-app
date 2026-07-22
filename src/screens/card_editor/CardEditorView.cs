using Godot;

namespace MyFlashCard;

// 카드 편집 화면의 배치만 담당한다. 저장·파싱·진행도는 모른다.
// 화면을 나갈 때(←) 현재 입력값을 사실로 알린다 — 저장 여부는 위(App)가 해석한다.
public partial class CardEditorView : Control
{
	[Signal] public delegate void EditingDoneEventHandler(string question, string answer);
	[Signal] public delegate void DeleteRequestedEventHandler();

	private Label _deckLabel = null!;
	private LineEdit _questionEdit = null!;
	private TextEdit _answerEdit = null!;

	public override void _Ready()
	{
		this._deckLabel = this.GetNode<Label>("%DeckLabel");
		// 질문은 마크다운에서 "# 한 줄"이라 한 줄만 받는다 (여러 줄이면 왕복이 깨진다).
		this._questionEdit = this.GetNode<LineEdit>("%QuestionEdit");
		this._answerEdit = this.GetNode<TextEdit>("%AnswerEdit");

		this.GetNode<Button>("%BackButton").Pressed += () => this.EmitSignal(
			SignalName.EditingDone, this._questionEdit.Text, this._answerEdit.Text);
		this.GetNode<Button>("%DeleteButton").Pressed +=
			() => this.EmitSignal(SignalName.DeleteRequested);
	}

	public void ShowDeckName(string deckName)
	{
		this._deckLabel.Text = deckName;
	}

	public void ShowCard(string question, string answer)
	{
		this._questionEdit.Text = question;
		this._answerEdit.Text = answer;
	}
}
