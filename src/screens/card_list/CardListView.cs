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
	[Signal] public delegate void ExportRequestedEventHandler(string targetPath);

	private const int RowHeight = 64;
	private const string EmptyText = "카드가 없습니다.";

	private Label _deckLabel = null!;
	private VBoxContainer _cardBox = null!;
	private Label _emptyLabel = null!;
	private FileDialog _exportDialog = null!;
	private string _deckName = "";

	public override void _Ready()
	{
		this._deckLabel = this.GetNode<Label>("%DeckLabel");
		this._cardBox = this.GetNode<VBoxContainer>("%CardBox");
		this._emptyLabel = this.GetNode<Label>("%EmptyLabel");
		this._exportDialog = this.GetNode<FileDialog>("%ExportDialog");

		this._emptyLabel.Text = EmptyText;

		this._exportDialog.Access = FileDialog.AccessEnum.Filesystem;
		this._exportDialog.FileMode = FileDialog.FileModeEnum.SaveFile;
		this._exportDialog.Filters = ["*.md ; Markdown"];
		this._exportDialog.UseNativeDialog = true;
		this._exportDialog.FileSelected +=
			path => this.EmitSignal(SignalName.ExportRequested, path);

		this.GetNode<Button>("%BackButton").Pressed +=
			() => this.EmitSignal(SignalName.BackPressed);
		this.GetNode<Button>("%AddButton").Pressed +=
			() => this.EmitSignal(SignalName.AddCardRequested);
		this.GetNode<Button>("%ExportButton").Pressed += this.OpenExportDialog;
	}

	public void ShowDeckName(string deckName)
	{
		this._deckName = deckName;
		this._deckLabel.Text = deckName;
	}

	private void OpenExportDialog()
	{
		this._exportDialog.CurrentFile = $"{this._deckName}.md";
		this._exportDialog.PopupCentered();
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
		// Flat이 아니라야 테마의 테두리 박스가 그려진다 (각 항목이 카드처럼 보이게).
		var button = new Button
		{
			CustomMinimumSize = new Vector2(0.0f, RowHeight),
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
		};
		button.Pressed += () => this.EmitSignal(SignalName.CardChosen, index);

		var line = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
		line.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
		// 테두리에 글자가 붙지 않게 좌우로 살짝 들여쓴다.
		line.OffsetLeft = AppTheme.SpaceMd;
		line.OffsetRight = -AppTheme.SpaceMd;

		var question = new Label
		{
			Text = row.Question,
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
			VerticalAlignment = VerticalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
			// 긴 질문이 틀린 횟수를 밀어내지 않도록 한 줄로 자른다.
			TextOverrunBehavior = TextServer.OverrunBehavior.TrimEllipsis,
		};
		question.AddThemeFontSizeOverride("font_size", AppTheme.FontBody);
		question.AddThemeColorOverride("font_color", AppTheme.SurfaceText);

		var count = new Label
		{
			Text = $"틀림 {row.WrongCount}",
			VerticalAlignment = VerticalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		count.AddThemeFontSizeOverride("font_size", AppTheme.FontCaption);
		count.AddThemeColorOverride("font_color", AppTheme.SurfaceTextMuted);

		line.AddChild(question);
		line.AddChild(count);
		button.AddChild(line);
		return button;
	}
}
