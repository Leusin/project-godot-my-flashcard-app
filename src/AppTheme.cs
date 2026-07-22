using Godot;

namespace MyFlashCard;

// 앱 전체 룩의 출처. Theme를 코드로 구성해 App 루트에 걸면 자식 화면 전체가 상속받는다.
// 씬(.tres)이 아니라 코드에 두는 이유는 다른 수치들과 같다 — 에디터가 덮어써도 값이 살아남는다.
//
// 톤: 살짝 따뜻한 중성색 캔버스(종이) 위에 흰 표면, 강조색은 인디고 하나만.
// 오래 보는 공부 화면이라 채도와 대비를 낮추고, 위계는 색 대신 크기·간격으로 만든다.
//
// 모든 수치는 디자인 해상도(720×1280) 기준 px다. 기본 창(375×667)에서는 절반 크기로 보인다.
public static class AppTheme
{
	// ── 팔레트 ──────────────────────────────────────────────────────
	// 중성색은 순수 회색 대신 노랑기를 아주 살짝 섞었다 (형광등 같은 차가움을 피한다).

	private static readonly Color Canvas = Rgb(0xF7, 0xF6, 0xF2);         // 창 배경 (따뜻한 오프화이트)
	private static readonly Color Surface = Colors.White;                 // 카드·버튼·입력창
	private static readonly Color SurfaceHover = Rgb(0xF6, 0xF5, 0xF1);
	private static readonly Color SurfacePressed = Rgb(0xEC, 0xEA, 0xE4);
	private static readonly Color Border = Rgb(0xE4, 0xE1, 0xD9);
	private static readonly Color BorderHover = Rgb(0xD2, 0xCE, 0xC4);

	// 강조는 인디고 하나. hover/pressed는 같은 색상의 명도만 낮춘다.
	private static readonly Color Accent = Rgb(0x5B, 0x7C, 0xFA);
	private static readonly Color AccentHover = Rgb(0x4A, 0x6B, 0xF0);
	private static readonly Color AccentPressed = Rgb(0x3E, 0x5C, 0xDB);

	// 글자는 순검정 대신 따뜻한 잉크색 (흰 표면과의 대비 약 12:1, 충분한 접근성).
	private static readonly Color Ink = Rgb(0x37, 0x35, 0x2F);
	private static readonly Color InkMuted = Rgb(0x78, 0x77, 0x74);

	public static readonly Color Success = Rgb(0x1F, 0xA9, 0x71);
	public static readonly Color Warning = Rgb(0xD9, 0x8E, 0x04);
	public static readonly Color Error = Rgb(0xDC, 0x43, 0x43);

	// 화면 코드가 쓰는 공개 이름. 캔버스가 밝아서 지금은 잉크색 하나로 수렴한다.
	public static readonly Color SurfaceText = Ink;
	public static readonly Color SurfaceTextMuted = InkMuted;
	public static readonly Color CanvasText = Ink;
	public static readonly Color CanvasTextMuted = InkMuted;

	// 카드 표면. 앞/뒤 모두 이 색 하나 — 뒷면을 따로 칠하지 않는다 (B안).
	public static readonly Color CardFront = Surface;

	// ── 타이포그래피 (Pretendard Variable) ──────────────────────────
	// 4단계면 충분하다. 단계가 많으면 위계가 오히려 흐려진다.

	public const int FontTitle = 36;      // 화면 제목
	public const int FontSubtitle = 28;   // 타일 이름, 다이얼로그 제목
	public const int FontBody = 24;       // 기본값
	public const int FontCaption = 18;    // 보조 정보 (경로, 카드 수, 입력 라벨)

	// ── 간격·모서리 ─────────────────────────────────────────────────
	// 간격은 8배수 스케일에서 고른다. 임의 값 금지 — 화면마다 리듬이 같아진다.

	public const int SpaceXs = 8;
	public const int SpaceSm = 12;
	public const int SpaceMd = 16;
	public const int SpaceLg = 24;
	public const int SpaceXl = 32;

	// 작은 요소(버튼·입력)는 12, 큰 표면(카드·타일·다이얼로그)은 16.
	// 요소가 클수록 모서리도 커야 같은 곡률로 보인다.
	public const int RadiusMd = 12;
	public const int RadiusLg = 16;
	public const int Radius = RadiusLg;   // 기존 호출부(CardView) 호환

	public static Color ClearColor => Canvas;

	// ── 테마 조립 ───────────────────────────────────────────────────

	public static Theme Build()
	{
		var theme = new Theme
		{
			DefaultFont = GD.Load<Font>("res://assets/fonts/PretendardVariable.ttf"),
			DefaultFontSize = FontBody,
		};

		foreach (var type in new[] { "Button", "OptionButton", "MenuButton" })
		{
			BuildButton(theme, type);
		}

		BuildAccentButton(theme);
		BuildGhostButton(theme);
		BuildDangerButton(theme);

		foreach (var type in new[] { "CheckBox", "CheckButton" })
		{
			BuildToggle(theme, type);
		}

		foreach (var type in new[] { "LineEdit", "TextEdit" })
		{
			BuildInput(theme, type);
		}

		theme.SetColor("font_color", "SpinBox", Ink);

		BuildLabel(theme);
		BuildPanels(theme);
		BuildItemList(theme);
		BuildPopupMenu(theme);
		BuildDialogs(theme);
		BuildScrollbars(theme);

		return theme;
	}

	// ── 컨트롤별 스타일 ─────────────────────────────────────────────

	// 기본 버튼: 흰 표면 + 얇은 테두리. hover는 배경보다 테두리 변화가 주인공이다
	// (밝은 톤에서는 배경 변화가 잘 안 보인다). 포커스 링은 테두리 밖에 반투명으로.
	private static void BuildButton(Theme theme, string type)
	{
		theme.SetStylebox("normal", type, Filled(Surface, Border, 1, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("hover", type, Filled(SurfaceHover, BorderHover, 1, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("pressed", type, Filled(SurfacePressed, BorderHover, 1, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("disabled", type, Filled(Canvas, Border, 1, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("focus", type, FocusRing(RadiusMd));

		theme.SetColor("font_color", type, Ink);
		theme.SetColor("font_hover_color", type, Ink);
		theme.SetColor("font_pressed_color", type, Ink);
		theme.SetColor("font_focus_color", type, Ink);
		theme.SetColor("font_disabled_color", type, InkMuted);
	}

	// 주요 행동 버튼 (씬에서 theme_type_variation = "AccentButton"으로 선택).
	// 화면에 하나만 두는 것이 원칙 — 강조가 여럿이면 강조가 아니다.
	private static void BuildAccentButton(Theme theme)
	{
		const string type = "AccentButton";
		theme.SetTypeVariation(type, "Button");
		theme.SetStylebox("normal", type, Filled(Accent, Accent, 0, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("hover", type, Filled(AccentHover, AccentHover, 0, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("pressed", type, Filled(AccentPressed, AccentPressed, 0, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("focus", type, FocusRing(RadiusMd));

		foreach (var key in new[] { "font_color", "font_hover_color", "font_pressed_color", "font_focus_color" })
		{
			theme.SetColor(key, type, Colors.White);
		}
	}

	// 상단바 내비게이션용 (← 뒤로 등). 테두리 없이 가볍게, hover에만 옅은 잉크 필름.
	private static void BuildGhostButton(Theme theme)
	{
		const string type = "GhostButton";
		theme.SetTypeVariation(type, "Button");
		theme.SetStylebox("normal", type, Transparent(RadiusMd, SpaceSm, SpaceXs));
		theme.SetStylebox("hover", type, Filled(WithAlpha(Ink, 0.06f), default, 0, RadiusMd, SpaceSm, SpaceXs));
		theme.SetStylebox("pressed", type, Filled(WithAlpha(Ink, 0.10f), default, 0, RadiusMd, SpaceSm, SpaceXs));
		theme.SetStylebox("focus", type, FocusRing(RadiusMd));

		theme.SetColor("font_color", type, InkMuted);
		theme.SetColor("font_hover_color", type, Ink);
		theme.SetColor("font_pressed_color", type, Ink);
		theme.SetColor("font_focus_color", type, Ink);
	}

	// 파괴적 행동(삭제)용. 평소엔 조용히(고스트), 색으로만 위험을 알린다.
	private static void BuildDangerButton(Theme theme)
	{
		const string type = "DangerButton";
		theme.SetTypeVariation(type, "Button");
		theme.SetStylebox("normal", type, Transparent(RadiusMd, SpaceSm, SpaceXs));
		theme.SetStylebox("hover", type, Filled(WithAlpha(Error, 0.08f), default, 0, RadiusMd, SpaceSm, SpaceXs));
		theme.SetStylebox("pressed", type, Filled(WithAlpha(Error, 0.14f), default, 0, RadiusMd, SpaceSm, SpaceXs));
		theme.SetStylebox("focus", type, FocusRing(RadiusMd));

		foreach (var key in new[] { "font_color", "font_hover_color", "font_pressed_color", "font_focus_color" })
		{
			theme.SetColor(key, type, Error);
		}
	}

	// 체크 계열은 버튼처럼 채우지 않는다 — 상태 표시가 주인공이라 배경은 조용히.
	// 기본 아이콘은 어두운 테마용이라, 처음 쓰는 시점에 밝은 배경용 SVG로 교체할 것.
	private static void BuildToggle(Theme theme, string type)
	{
		var quiet = Transparent(RadiusMd, SpaceXs, SpaceXs / 2);
		foreach (var key in new[] { "normal", "hover", "pressed", "disabled", "hover_pressed" })
		{
			theme.SetStylebox(key, type, quiet);
		}
		theme.SetStylebox("focus", type, FocusRing(RadiusMd));

		theme.SetColor("font_color", type, Ink);
		theme.SetColor("font_hover_color", type, Ink);
		theme.SetColor("font_pressed_color", type, Ink);
		theme.SetColor("font_disabled_color", type, InkMuted);
	}

	// 입력창 포커스는 링 대신 테두리 자체를 강조색으로 — 데스크톱 폼 관례.
	private static void BuildInput(Theme theme, string type)
	{
		theme.SetStylebox("normal", type, Filled(Surface, Border, 1, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("focus", type, Filled(Surface, Accent, 2, RadiusMd, SpaceMd, SpaceSm));
		theme.SetStylebox("read_only", type, Filled(Canvas, Border, 1, RadiusMd, SpaceMd, SpaceSm));

		theme.SetColor("font_color", type, Ink);
		theme.SetColor("font_placeholder_color", type, InkMuted);
		theme.SetColor("caret_color", type, Accent);
		theme.SetColor("selection_color", type, WithAlpha(Accent, 0.25f));
	}

	private static void BuildLabel(Theme theme)
	{
		theme.SetColor("font_color", "Label", Ink);

		// 보조 정보용 (씬에서 theme_type_variation = "CaptionLabel"). 색·크기를 한 번에 낮춘다.
		theme.SetTypeVariation("CaptionLabel", "Label");
		theme.SetColor("font_color", "CaptionLabel", InkMuted);
		theme.SetFontSize("font_size", "CaptionLabel", FontCaption);
	}

	// 카드·타일 표면. 그림자는 "떠 있다"는 느낌만 주는 최소치 —
	// 경계는 테두리가 담당하고 그림자는 깊이만 담당한다.
	private static void BuildPanels(Theme theme)
	{
		var panel = Filled(Surface, Border, 1, RadiusLg, SpaceMd, SpaceMd);
		panel.ShadowColor = WithAlpha(Colors.Black, 0.05f);
		panel.ShadowSize = 12;
		panel.ShadowOffset = new Vector2(0.0f, 3.0f);

		theme.SetStylebox("panel", "PanelContainer", panel);
		theme.SetStylebox("panel", "Panel", panel);

		// 스크롤 영역 자체는 투명 — 배경은 캔버스가 담당한다.
		theme.SetStylebox("panel", "ScrollContainer", new StyleBoxEmpty());
	}

	private static void BuildItemList(Theme theme)
	{
		theme.SetStylebox("panel", "ItemList", Filled(Surface, Border, 1, RadiusMd, SpaceXs, SpaceXs));
		theme.SetStylebox("focus", "ItemList", FocusRing(RadiusMd));
		theme.SetStylebox("hovered", "ItemList", Filled(SurfaceHover, default, 0, SpaceXs, 0.0f, 0.0f));
		theme.SetStylebox("selected", "ItemList", Filled(WithAlpha(Accent, 0.12f), default, 0, SpaceXs, 0.0f, 0.0f));
		theme.SetStylebox("selected_focus", "ItemList", Filled(WithAlpha(Accent, 0.16f), default, 0, SpaceXs, 0.0f, 0.0f));

		theme.SetColor("font_color", "ItemList", Ink);
		theme.SetColor("font_selected_color", "ItemList", Ink);
	}

	private static void BuildPopupMenu(Theme theme)
	{
		var panel = Filled(Surface, Border, 1, RadiusMd, SpaceXs, SpaceXs);
		panel.ShadowColor = WithAlpha(Colors.Black, 0.10f);
		panel.ShadowSize = 20;
		panel.ShadowOffset = new Vector2(0.0f, 4.0f);
		theme.SetStylebox("panel", "PopupMenu", panel);
		theme.SetStylebox("hover", "PopupMenu", Filled(SurfaceHover, default, 0, SpaceXs, SpaceSm, SpaceXs / 2));

		theme.SetColor("font_color", "PopupMenu", Ink);
		theme.SetColor("font_hover_color", "PopupMenu", Ink);
		theme.SetColor("font_disabled_color", "PopupMenu", InkMuted);
	}

	// 다이얼로그는 화면에서 가장 높은 레이어라 그림자도 가장 크다.
	private static void BuildDialogs(Theme theme)
	{
		foreach (var type in new[] { "AcceptDialog", "ConfirmationDialog" })
		{
			var panel = Filled(Surface, Border, 1, RadiusLg, SpaceMd, SpaceMd);
			panel.ShadowColor = WithAlpha(Colors.Black, 0.16f);
			panel.ShadowSize = 32;
			panel.ShadowOffset = new Vector2(0.0f, 8.0f);
			theme.SetStylebox("panel", type, panel);

			theme.SetColor("title_color", type, Ink);
			theme.SetFontSize("title_font_size", type, FontSubtitle);
		}
	}

	// macOS식 플로팅 그래버: 트랙은 없애고 손잡이만 옅게.
	private static void BuildScrollbars(Theme theme)
	{
		foreach (var type in new[] { "VScrollBar", "HScrollBar" })
		{
			theme.SetStylebox("scroll", type, new StyleBoxEmpty());
			theme.SetStylebox("grabber", type, Filled(WithAlpha(Ink, 0.18f), default, 0, SpaceXs, 0.0f, 0.0f));
			theme.SetStylebox("grabber_highlight", type, Filled(WithAlpha(Ink, 0.30f), default, 0, SpaceXs, 0.0f, 0.0f));
			theme.SetStylebox("grabber_pressed", type, Filled(WithAlpha(Ink, 0.38f), default, 0, SpaceXs, 0.0f, 0.0f));
		}
	}

	// ── 스타일박스 헬퍼 ─────────────────────────────────────────────

	private static StyleBoxFlat Filled(
		Color bg, Color border, int borderWidth, int radius, float hPad, float vPad)
	{
		var box = new StyleBoxFlat { BgColor = bg, BorderColor = border };
		box.SetBorderWidthAll(borderWidth);
		box.SetCornerRadiusAll(radius);
		box.ContentMarginLeft = hPad;
		box.ContentMarginRight = hPad;
		box.ContentMarginTop = vPad;
		box.ContentMarginBottom = vPad;
		return box;
	}

	private static StyleBoxFlat Transparent(int radius, float hPad, float vPad)
	{
		return Filled(Colors.Transparent, default, 0, radius, hPad, vPad);
	}

	// 포커스 링은 컨트롤 테두리 밖에 반투명으로 겹친다 — 레이아웃을 밀지 않는다.
	private static StyleBoxFlat FocusRing(int radius)
	{
		var box = new StyleBoxFlat { BgColor = Colors.Transparent, BorderColor = WithAlpha(Accent, 0.5f) };
		box.SetBorderWidthAll(3);
		box.SetCornerRadiusAll(radius + 2);
		box.SetExpandMarginAll(3.0f);
		return box;
	}

	private static Color WithAlpha(Color color, float alpha)
	{
		return new Color(color.R, color.G, color.B, alpha);
	}

	private static Color Rgb(int r, int g, int b)
	{
		return Color.Color8((byte)r, (byte)g, (byte)b);
	}
}
