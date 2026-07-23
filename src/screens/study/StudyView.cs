using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// Study 화면의 배치만 담당한다. 학습 규칙과 진행도 갱신은 모른다.
// 카드 표시는 CardView에 맡기고, 판정 사실은 시그널로만 알린다.
// 판정 더미(버튼)는 카드 뒤에 깔린 "목적지"다: 카드 위 커서 위치가 방향을 정하고,
// 카드는 커서 반대쪽으로 비켜나며 들린다 — 커서 바로 밑에서 더미가 드러난다.
// 드러난 더미를 누르면 카드가 비켜나던 방향 그대로 떠나고 다음 카드가 바로 놓인다 —
// 조작감은 버튼이 아니라 카드에 있다.
public partial class StudyView : Control
{
	[Signal] public delegate void AgainPressedEventHandler();
	[Signal] public delegate void GoodPressedEventHandler();
	[Signal] public delegate void BackPressedEventHandler();
	[Signal] public delegate void EditPressedEventHandler();

	// ── 판정 모션 값 (전부 임시값 — 조작감 값은 사람이 실행해 보고 확정한다) ──
	private const float LeanAngleDeg = 10f;   // 커서를 비켜날 때 기우는 각도
	private const float LeanShift = 28.0f;     // 비켜나는 가로 이동(px)
	private const float LeanLift = 20.0f;      // 비켜날 때 책상에서 들리는 높이(px)
	private const float LeanTime = 0.18f;      // 기울기 전환 시간
	private const float ExitAngleDeg = 16.0f;  // 더미로 떠날 때 기울기
	private const float ExitTime = 0.28f;      // 화면 밖까지 나가는 시간
	private const float EnterScale = 0.985f;   // 다음 카드: 시작 스케일 (더미에서 집는 느낌)
	private const float EnterTime = 0.10f;     // 다음 카드: 안착 시간

	// 카드 위 커서 위치 → 방향. 양 끝 40%가 더미 구역, 가운데 20%는 중립(탭=앞뒤 전환 전용).
	private const float ZoneSplit = 0.4f;

	// 더미는 평소 카드 뒤에 조용히 깔려 있다 (위치는 늘 그대로 — 움직이는 것은 카드뿐이다.
	// 기하학적으로 "기운 쪽이 실제로 드러나는" 가림은 불가능해서, 드러남의 마무리는 투명도가 맡는다).
	private const float PileAlphaResting = 0.4f;

	private Label _remainingLabel = null!;
	private Label _deckLabel = null!;
	private CardView _card = null!;
	private Control _cardHolder = null!;
	private Button _againButton = null!;
	private Button _goodButton = null!;

	private Tween? _leanTween;
	private Tween? _settleTween;
	private Tween? _pileTween;
	private bool _gradeAnimating;
	private int _leanDir;

	public override void _Ready()
	{
		this._remainingLabel = this.GetNode<Label>("%RemainingLabel");
		this._deckLabel = this.GetNode<Label>("%DeckLabel");
		this._card = this.GetNode<CardView>("%Card");
		this._cardHolder = this.GetNode<Control>("%CardHolder");
		this._againButton = this.GetNode<Button>("%AgainButton");
		this._goodButton = this.GetNode<Button>("%GoodButton");

		// 비율의 출처는 CardView 상수 하나. 씬에는 값을 두지 않는다.
		this.GetNode<AspectRatioContainer>("%CardAspect").Ratio = CardView.AspectRatio;

		// 회전 피벗은 카드 아래 가운데 — 종이를 손에 쥐고 기울이는 느낌이 난다.
		this._card.Resized += () =>
			this._card.PivotOffset = new Vector2(this._card.Size.X / 2.0f, this._card.Size.Y);

		this._againButton.Modulate = new Color(1.0f, 1.0f, 1.0f, PileAlphaResting);
		this._goodButton.Modulate = new Color(1.0f, 1.0f, 1.0f, PileAlphaResting);

		this.GetNode<Button>("%BackButton").Pressed += () =>
		{
			if (!this._gradeAnimating)
			{
				this.EmitSignal(SignalName.BackPressed);
			}
		};
		this.GetNode<Button>("%EditButton").Pressed += () =>
		{
			// 카드가 더미로 날아가는 중의 편집은 어느 카드인지 애매하므로 받지 않는다.
			if (!this._gradeAnimating)
			{
				this.EmitSignal(SignalName.EditPressed);
			}
		};

		this._againButton.Pressed += () => this.PlayGradeExit(-1, SignalName.AgainPressed);
		this._goodButton.Pressed += () => this.PlayGradeExit(1, SignalName.GoodPressed);
	}

	// 호버는 버튼이 아니라 카드가 주인이다. 커서 위치를 프레임마다 읽어 방향을 정한다 —
	// 숨은 버튼의 hover 이벤트에 기대지 않아, 카드 내용(스크롤 등)이 이벤트를 먹어도 안전하다.
	public override void _Process(double delta)
	{
		if (!this.IsVisibleInTree() || this._gradeAnimating)
		{
			return;
		}

		var dir = this.PointerDirection();
		if (dir != this._leanDir)
		{
			this.Lean(dir);
		}
	}

	// 카드가 비켜날 방향(커서 반대쪽). 커서가 왼쪽 구역이면 카드는 오른쪽으로 물러나
	// 커서 밑의 더미가 드러난다. 커서가 드러난 더미 위로 내려가도 같은 방향을 유지해
	// 카드가 되돌아오며 더미를 덮어버리지 않게 한다.
	private int PointerDirection()
	{
		var local = this._cardHolder.GetLocalMousePosition();
		var size = this._cardHolder.Size;
		if (local.X >= 0.0f && local.X <= size.X && local.Y >= 0.0f && local.Y <= size.Y)
		{
			if (local.X < size.X * ZoneSplit)
			{
				return 1;
			}

			if (local.X > size.X * (1.0f - ZoneSplit))
			{
				return -1;
			}

			return 0;
		}

		var mouse = this.GetGlobalMousePosition();
		if (this._againButton.GetGlobalRect().HasPoint(mouse))
		{
			return -1;
		}

		if (this._goodButton.GetGlobalRect().HasPoint(mouse))
		{
			return 1;
		}

		return 0;
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
		this.PlayEnterSettle();
	}

	// dir: 카드가 비켜나는 방향. -1 = 왼쪽으로 물러남(커서는 오른쪽, ← Again 드러남),
	// +1 = 오른쪽으로 물러남(커서는 왼쪽, Got it → 드러남), 0 = 중립.
	// 더미(버튼)는 그대로 두고 카드만 기울며 들린다.
	private void Lean(int dir)
	{
		this._leanDir = dir;
		if (this._gradeAnimating)
		{
			return;
		}

		this._leanTween?.Kill();
		this._leanTween = this.CreateTween();
		this._leanTween.SetParallel(true)
			.SetTrans(Tween.TransitionType.Sine)
			.SetEase(Tween.EaseType.Out);
		this._leanTween.TweenProperty(
			this._card, "rotation", dir * Mathf.DegToRad(LeanAngleDeg), LeanTime);
		this._leanTween.TweenProperty(this._card, "position:x", dir * LeanShift, LeanTime);
		this._leanTween.TweenProperty(
			this._card, "position:y", dir == 0 ? 0.0f : -LeanLift, LeanTime);

		this.EmphasizePile(dir);
	}

	// 커서 밑에서 드러나는 더미만 또렷해진다. 위치는 움직이지 않는다 — 드러남의 마무리만 투명도.
	private void EmphasizePile(int dir)
	{
		this._pileTween?.Kill();
		this._pileTween = this.CreateTween();
		this._pileTween.SetParallel(true)
			.SetTrans(Tween.TransitionType.Sine)
			.SetEase(Tween.EaseType.Out);
		this._pileTween.TweenProperty(
			this._againButton, "modulate:a", dir < 0 ? 1.0f : PileAlphaResting, LeanTime);
		this._pileTween.TweenProperty(
			this._goodButton, "modulate:a", dir > 0 ? 1.0f : PileAlphaResting, LeanTime);
	}

	// 기운 자세 그대로 이어서 화면 밖 더미로 나간다 (되돌아오는 순간이 없어야 한다).
	// 판정 사실은 카드가 물리적으로 떠난 뒤에 알린다 — 다음 카드는 그때 채워진다.
	private void PlayGradeExit(int dir, StringName signal)
	{
		if (this._gradeAnimating)
		{
			return;
		}

		this._gradeAnimating = true;
		this._leanTween?.Kill();
		this._settleTween?.Kill();
		// 날아가는 동안 카드 탭(앞뒤 전환)이 끼어들지 않게 입력을 막는다.
		this._card.MouseFilter = MouseFilterEnum.Ignore;

		var exit = this.CreateTween();
		exit.SetParallel(true)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.In);
		exit.TweenProperty(this._card, "rotation", dir * Mathf.DegToRad(ExitAngleDeg), ExitTime);
		exit.TweenProperty(this._card, "position:x", dir * this.Size.X, ExitTime);
		exit.Finished += () =>
		{
			// 다음 카드 내용이 같은 프레임에 채워지므로 리셋은 화면에 보이지 않는다.
			this._card.Rotation = 0.0f;
			this._card.Position = Vector2.Zero;
			this._card.MouseFilter = MouseFilterEnum.Stop;
			this._leanDir = 0;
			this.EmphasizePile(0);
			this._gradeAnimating = false;
			this.EmitSignal(signal);
			// 커서가 아직 더미 위라면 다음 프레임 폴링이 다음 카드를 다시 기울인다.
		};
	}

	// 다음 카드가 더미에서 집어 올려져 놓이는 짧은 안착.
	private void PlayEnterSettle()
	{
		this._settleTween?.Kill();
		this._card.Scale = new Vector2(EnterScale, EnterScale);
		this._settleTween = this.CreateTween();
		this._settleTween.SetTrans(Tween.TransitionType.Sine).SetEase(Tween.EaseType.Out);
		this._settleTween.TweenProperty(this._card, "scale", Vector2.One, EnterTime);
	}
}
