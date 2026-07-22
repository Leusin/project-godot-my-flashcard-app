using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 카드 한 장의 겉모습만 담당한다. 세션 규칙·판정 버튼은 모르고,
// 틀린 횟수도 받아서 보여주기만 한다. 탭하면 앞뒤를 뒤집는 것까지가 자기 일이다.
public partial class CardView : PanelContainer
{
	// 트럼프 카드(2.5×3.5인치 ≈ 0.71)를 참고
	public const float AspectRatio = 0.7f;
	private const float MinTextWidth = 100.0f;

	private const int QuestionFontFront = 36;
	private const int QuestionFontBack = 22;

	private const float QuestionStretch = 1.2f;
	private const float AnswerStretch = 8.8f;

	private const HorizontalAlignment QuestionHAlign = HorizontalAlignment.Center;
	private const HorizontalAlignment AnswerHAlign = HorizontalAlignment.Left;

	// 답은 위에서부터 읽어 내려간다. 질문은 짧은 편이라 가운데가 자연스럽다.
	private const VerticalAlignment QuestionVAlign = VerticalAlignment.Center;
	private const VerticalAlignment AnswerVAlign = VerticalAlignment.Top;

	// 뒷면에서 질문은 배경으로 물러난다. 배경색을 모르고도 어두워지도록 알파로 낮춘다.
	private static readonly Color QuestionTintFront = Colors.White;
	private static readonly Color QuestionTintBack = new(1.0f, 1.0f, 1.0f, 0.45f);

	// 뒷면에서는 질문을 스크롤시키지 않는다. 이 줄 수까지만 보이고 나머지는 …으로 줄인다.
	private const int QuestionLinesBack = 3;

	private Label _questionLabel = null!;
	private Label _answerLabel = null!;
	private Control _answerArea = null!;
	private ScrollContainer _questionScroll = null!;
	private ScrollContainer _answerScroll = null!;
	private TallyMarks _tally = null!;
	private Label _statusLabel = null!;

	public override void _Ready()
	{
		this._tally = this.GetNode<TallyMarks>("%Tally");
		this._statusLabel = this.GetNode<Label>("%StatusLabel");
		this._questionLabel = this.GetNode<Label>("%QuestionLabel");
		this._answerLabel = this.GetNode<Label>("%AnswerLabel");
		this._answerArea = this.GetNode<Control>("%AnswerArea");
		this._questionScroll = this._questionLabel.GetParent<ScrollContainer>();
		this._answerScroll = this._answerLabel.GetParent<ScrollContainer>();

		var minWidth = new Vector2(MinTextWidth, 0.0f);
		this._questionLabel.CustomMinimumSize = minWidth;
		this._answerLabel.CustomMinimumSize = minWidth;

		this._questionScroll.SizeFlagsStretchRatio = QuestionStretch;
		this._answerArea.SizeFlagsStretchRatio = AnswerStretch;

		this._questionLabel.HorizontalAlignment = QuestionHAlign;
		this._answerLabel.HorizontalAlignment = AnswerHAlign;
		this._questionLabel.VerticalAlignment = QuestionVAlign;
		this._answerLabel.VerticalAlignment = AnswerVAlign;
	}

	public void ShowCard(string question, string answer, int wrongCount, CardStatus status)
	{
		this._questionLabel.Text = question;
		this._answerLabel.Text = answer;
		this._tally.Count = wrongCount;
		this._statusLabel.Text = StatusText(status);
		this.SetAnswerVisible(false);

		// 앞 카드에서 내려둔 스크롤이 남아 새 카드의 첫 줄을 가리지 않게 한다.
		this._questionScroll.ScrollVertical = 0;
		this._answerScroll.ScrollVertical = 0;
	}

	private static string StatusText(CardStatus status)
	{
		return status switch
		{
			CardStatus.Learning => "LEARNING",
			CardStatus.Mastered => "MASTERED",
			_ => "NEW",
		};
	}

	// 카드 영역 탭/클릭 → 앞뒤 전환 (씬 루트의 gui_input 연결)
	public void OnCardGuiInput(InputEvent @event)
	{
		if (@event is not InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left })
		{
			return;
		}

		this.SetAnswerVisible(!this._answerArea.Visible);
	}

	private void SetAnswerVisible(bool visible)
	{
		this._answerArea.Visible = visible;
		this._questionLabel.AddThemeFontSizeOverride(
			"font_size", visible ? QuestionFontBack : QuestionFontFront);
		this._questionLabel.Modulate = visible ? QuestionTintBack : QuestionTintFront;

		// 앞면은 질문이 주인공이라 길면 스크롤해서 다 읽을 수 있어야 하고,
		// 뒷면은 답이 주인공이라 질문이 자리를 차지하면 안 된다.
		this._questionLabel.MaxLinesVisible = visible ? QuestionLinesBack : -1;
		this._questionLabel.TextOverrunBehavior = visible
			? TextServer.OverrunBehavior.TrimWordEllipsis
			: TextServer.OverrunBehavior.NoTrimming;
		this._questionScroll.VerticalScrollMode = visible
			? ScrollContainer.ScrollMode.Disabled
			: ScrollContainer.ScrollMode.Auto;
	}
}
