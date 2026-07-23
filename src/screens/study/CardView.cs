using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 카드 한 장의 겉모습만 담당한다. 세션 규칙·판정 버튼은 모르고,
// 틀린 횟수도 받아서 보여주기만 한다. 탭하면 앞뒤를 뒤집는 것까지가 자기 일이다.
//
// 카드는 앞/뒤 모두 흰 종이에 가깝다 (B안). 뒷면은 버튼 호버와 같은 색으로 톤만 아주 살짝
// 낮춰 "상태가 바뀌었다"를 알리고, 질문이 작고 흐린 회상 배너로 물러난다 — 정렬은 앞뒤가
// 같아 "같은 필드가 작아졌다"로 읽히고, 위계는 채도가 아니라 명도·크기·여백이 만든다.
public partial class CardView : PanelContainer
{
	// 트럼프 카드(2.5×3.5인치 ≈ 0.71)를 참고
	public const float AspectRatio = 0.7f;
	private const float MinTextWidth = 100.0f;

	private const int QuestionFontFront = 36;
	private const int QuestionFontBack = 22;

	private const float QuestionStretch = 1.2f;
	private const float AnswerStretch = 8.8f;

	// 질문은 앞/뒤 모두 가운데 정렬 — 뒷면에서 크기·투명도만 줄고 위치는 그대로다.
	private const HorizontalAlignment QuestionHAlign = HorizontalAlignment.Center;
	private const HorizontalAlignment AnswerHAlign = HorizontalAlignment.Left;

	// 답은 위에서부터 읽어 내려간다. 질문은 짧은 편이라 가운데가 자연스럽다.
	private const VerticalAlignment QuestionVAlign = VerticalAlignment.Center;
	private const VerticalAlignment AnswerVAlign = VerticalAlignment.Top;

	// 뒷면에서 질문은 회상 배너로 물러난다. 색은 그대로 두고 알파만 낮춘다 (카드 자체는 안 바뀐다).
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
	private StyleBoxFlat _frontPanel = null!;
	private StyleBoxFlat _backPanel = null!;

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

		// 글자색은 앞/뒤 공통 (두 표면 모두 밝아서 어두운 잉크색이 그대로 잘 읽힌다).
		this._questionLabel.AddThemeColorOverride("font_color", AppTheme.SurfaceText);
		this._answerLabel.AddThemeColorOverride("font_color", AppTheme.SurfaceText);
		this._statusLabel.AddThemeColorOverride("font_color", AppTheme.SurfaceText);
		this._tally.MarkColor = AppTheme.SurfaceText;

		this._frontPanel = Panel(AppTheme.CardFront);
		this._backPanel = Panel(AppTheme.CardBack);
	}

	private static StyleBoxFlat Panel(Color bg)
	{
		var box = new StyleBoxFlat { BgColor = bg };
		box.SetCornerRadiusAll(AppTheme.Radius);
		box.SetContentMarginAll(16.0f);
		// 학습 화면의 주인공이라 은은한 그림자로 살짝 띄운다.
		box.ShadowColor = new Color(0.0f, 0.0f, 0.0f, 0.08f);
		box.ShadowSize = 16;
		box.ShadowOffset = new Vector2(0.0f, 4.0f);
		return box;
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
		this.AddThemeStyleboxOverride("panel", visible ? this._backPanel : this._frontPanel);

		this._questionLabel.AddThemeFontSizeOverride(
			"font_size", visible ? QuestionFontBack : QuestionFontFront);
		// 뒷면에서 질문은 작아지고 흐려진다 (회상 배너). 정렬은 앞뒤가 같다.
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
