using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 카드 한 장의 겉모습만 담당한다. 세션 규칙·판정 버튼은 모르고,
// 틀린 횟수도 받아서 보여주기만 한다. 탭하면 앞뒤를 뒤집는 것까지가 자기 일이다.
//
// 카드는 앞/뒤 모두 흰 종이다 (B안). 뒷면임은 색을 칠하는 대신 좌측의 얇은 강조 선 하나로만
// 신호하고, 질문은 회상 배너로 물러나 답과 같은 왼쪽 정렬 열에 선다 — 위계는 색이 아니라
// 레이아웃·타이포그래피·여백이 만든다.
public partial class CardView : PanelContainer
{
	// 트럼프 카드(2.5×3.5인치 ≈ 0.71)를 참고
	public const float AspectRatio = 0.7f;
	private const float MinTextWidth = 100.0f;

	private const int QuestionFontFront = 36;
	private const int QuestionFontBack = 22;

	private const float QuestionStretch = 1.2f;
	private const float AnswerStretch = 8.8f;

	// 질문은 앞면(주인공, 짧은 편)에서 가운데, 뒷면(회상 배너)에서는 답과 같은 왼쪽 열로.
	private const HorizontalAlignment QuestionHAlignFront = HorizontalAlignment.Center;
	private const HorizontalAlignment QuestionHAlignBack = HorizontalAlignment.Left;
	private const HorizontalAlignment AnswerHAlign = HorizontalAlignment.Left;

	// 답은 위에서부터 읽어 내려간다. 질문은 짧은 편이라 가운데가 자연스럽다.
	private const VerticalAlignment QuestionVAlign = VerticalAlignment.Center;
	private const VerticalAlignment AnswerVAlign = VerticalAlignment.Top;

	// 뒷면에서 질문은 회상 배너로 물러난다. 색은 그대로 두고 알파만 낮춘다 (카드 자체는 안 바뀐다).
	private static readonly Color QuestionTintFront = Colors.White;
	private static readonly Color QuestionTintBack = new(1.0f, 1.0f, 1.0f, 0.45f);

	// 뒷면에서는 질문을 스크롤시키지 않는다. 이 줄 수까지만 보이고 나머지는 …으로 줄인다.
	private const int QuestionLinesBack = 3;

	// 뒷면(답)임을 알리는 유일한 색 신호 — 칠이 아니라 3px 캡슐형 선 하나 (B안 핵심).
	private const float StripeWidth = 3.0f;
	private const float StripeInsetX = 10.0f;
	private const float StripeInsetY = 24.0f;
	private const int StripeRadius = 2;

	private Label _questionLabel = null!;
	private Label _answerLabel = null!;
	private Control _answerArea = null!;
	private ScrollContainer _questionScroll = null!;
	private ScrollContainer _answerScroll = null!;
	private TallyMarks _tally = null!;
	private Label _statusLabel = null!;
	private StyleBoxFlat _stripeBox = null!;
	private bool _showingAnswer;

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

		this._questionLabel.HorizontalAlignment = QuestionHAlignFront;
		this._answerLabel.HorizontalAlignment = AnswerHAlign;
		this._questionLabel.VerticalAlignment = QuestionVAlign;
		this._answerLabel.VerticalAlignment = AnswerVAlign;

		// 카드 표면은 앞/뒤 공통. 한 번만 만들어 건다 — 뒤집어도 다시 칠하지 않는다.
		this.AddThemeStyleboxOverride("panel", Panel());
		this._questionLabel.AddThemeColorOverride("font_color", AppTheme.SurfaceText);
		this._answerLabel.AddThemeColorOverride("font_color", AppTheme.SurfaceText);
		this._statusLabel.AddThemeColorOverride("font_color", AppTheme.SurfaceText);
		this._tally.MarkColor = AppTheme.SurfaceText;

		var stripeColor = AppTheme.CardBack;
		stripeColor.A = 0.85f;
		this._stripeBox = new StyleBoxFlat { BgColor = stripeColor };
		this._stripeBox.SetCornerRadiusAll(StripeRadius);
	}

	private static StyleBoxFlat Panel()
	{
		var box = new StyleBoxFlat { BgColor = AppTheme.CardFront };
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
		this._showingAnswer = visible;
		this.QueueRedraw();

		this._questionLabel.AddThemeFontSizeOverride(
			"font_size", visible ? QuestionFontBack : QuestionFontFront);
		// 뒷면에서 질문은 흐려지고(회상 배너), 답과 같은 왼쪽 열에 선다.
		this._questionLabel.Modulate = visible ? QuestionTintBack : QuestionTintFront;
		this._questionLabel.HorizontalAlignment = visible ? QuestionHAlignBack : QuestionHAlignFront;

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

	// 뒷면(답)임을 알리는 유일한 색 신호. 카드 전체를 칠하는 대신 이 선 하나로 끝낸다.
	public override void _Draw()
	{
		if (!this._showingAnswer)
		{
			return;
		}

		var rect = new Rect2(
			StripeInsetX, StripeInsetY, StripeWidth, this.Size.Y - (StripeInsetY * 2.0f));
		this.DrawStyleBox(this._stripeBox, rect);
	}
}
