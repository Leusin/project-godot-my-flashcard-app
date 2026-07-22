using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 덱 목록 화면의 배치만 담당한다. 저장소·파싱·학습 규칙은 모른다.
// 어떤 덱을 골랐는지, 어떤 파일을 가져오라고 했는지는 시그널로만 알린다.
public partial class DeckListView : Control
{
	[Signal] public delegate void DeckChosenEventHandler(string deckFile);
	[Signal] public delegate void ImportRequestedEventHandler(string sourcePath);
	[Signal] public delegate void DeckFolderChosenEventHandler(string dir);
	[Signal] public delegate void NewDeckRequestedEventHandler(string name);

	// 타일은 고정 크기(카드 비율). HFlowContainer가 창 폭에 맞춰 알아서 줄을 바꾼다.
	private const float TileWidth = 360.0f;
	private static readonly float TileHeight = TileWidth / CardView.AspectRatio;

	// 덱이 하나도 없을 때 목록 자리에 대신 놓는 안내.
	private const string EmptyText = "덱이 없습니다.\n아래에서 md 파일을 가져오세요.";

	private HFlowContainer _deckBox = null!;
	private Label _emptyLabel = null!;
	private Label _folderLabel = null!;
	private FileDialog _importDialog = null!;
	private FileDialog _folderDialog = null!;
	private ConfirmationDialog _newDeckDialog = null!;
	private LineEdit _newDeckName = null!;

	public override void _Ready()
	{
		this._deckBox = this.GetNode<HFlowContainer>("%DeckBox");
		this._emptyLabel = this.GetNode<Label>("%EmptyLabel");
		this._folderLabel = this.GetNode<Label>("%FolderLabel");
		this._importDialog = this.GetNode<FileDialog>("%ImportDialog");
		this._folderDialog = this.GetNode<FileDialog>("%FolderDialog");
		this._newDeckDialog = this.GetNode<ConfirmationDialog>("%NewDeckDialog");
		this._newDeckName = this.GetNode<LineEdit>("%NewDeckName");

		this._emptyLabel.Text = EmptyText;

		this._deckBox.AddThemeConstantOverride("h_separation", AppTheme.SpaceLg);
		this._deckBox.AddThemeConstantOverride("v_separation", AppTheme.SpaceLg);
		this._deckBox.Alignment = FlowContainer.AlignmentMode.Center;
		this._deckBox.LastWrapAlignment = FlowContainer.LastWrapAlignmentMode.Begin;

		this._newDeckDialog.Confirmed += this.OnNewDeckConfirmed;
		this._newDeckDialog.RegisterTextEnter(this._newDeckName);

		this._importDialog.Access = FileDialog.AccessEnum.Filesystem;
		this._importDialog.FileMode = FileDialog.FileModeEnum.OpenFile;
		this._importDialog.Filters = ["*.md ; Markdown"];
		this._importDialog.UseNativeDialog = true;
		this._importDialog.FileSelected +=
			path => this.EmitSignal(SignalName.ImportRequested, path);

		this._folderDialog.Access = FileDialog.AccessEnum.Filesystem;
		this._folderDialog.FileMode = FileDialog.FileModeEnum.OpenDir;
		this._folderDialog.UseNativeDialog = true;
		this._folderDialog.DirSelected +=
			dir => this.EmitSignal(SignalName.DeckFolderChosen, dir);

		this.GetNode<Button>("%ImportButton").Pressed +=
			() => this._importDialog.PopupCentered();
		this.GetNode<Button>("%FolderButton").Pressed +=
			() => this._folderDialog.PopupCentered();
	}

	// 덱이 실제로 저장되는 폴더 (사용자가 보게 OS 절대 경로로).
	public void ShowFolder(string path)
	{
		this._folderLabel.Text = $"덱 폴더: {path}";
	}

	public void ShowDecks(IReadOnlyList<DeckInfo> decks)
	{
		foreach (var child in this._deckBox.GetChildren())
		{
			// 해제는 프레임 끝에 일어나므로, 새 목록과 섞이지 않게 먼저 떼어낸다.
			this._deckBox.RemoveChild(child);
			child.QueueFree();
		}

		// 덱이 없어도 "새 덱" 타일은 늘 있으니 빈 안내는 숨긴다.
		this._emptyLabel.Visible = false;

		foreach (var deck in decks)
		{
			this._deckBox.AddChild(this.MakeTile(deck));
		}

		// 마지막 칸은 새 덱 추가 타일.
		this._deckBox.AddChild(this.MakeAddTile());
	}

	private void OnNewDeckConfirmed()
	{
		var name = this._newDeckName.Text.Trim();
		if (name.Length > 0)
		{
			this.EmitSignal(SignalName.NewDeckRequested, name);
		}
	}

	// 새 덱 추가 타일. 다른 타일과 같은 크기, 누르면 이름을 묻는다.
	private Button MakeAddTile()
	{
		var tile = new Button { 
			CustomMinimumSize = new Vector2(TileWidth, TileHeight) 
		};

		tile.Pressed += () =>
		{
			this._newDeckName.Text = "";
			this._newDeckDialog.PopupCentered();
		};

		var label = new Label
		{
			Text = "＋ 새 덱",
			HorizontalAlignment = HorizontalAlignment.Center,
			VerticalAlignment = VerticalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		label.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
		label.AddThemeFontSizeOverride("font_size", AppTheme.FontSubtitle);
		label.AddThemeColorOverride("font_color", AppTheme.SurfaceTextMuted);

		tile.AddChild(label);
		return tile;
	}

	// 덱 하나 = 카드 모양 타일. 버튼 위에 덱 이름·카드 수를 얹고, 얹은 라벨은
	// 클릭을 삼키지 않게 마우스를 통과시켜 타일(버튼)이 눌리게 한다.
	private Button MakeTile(DeckInfo deck)
	{
		var tile = new Button { CustomMinimumSize = new Vector2(TileWidth, TileHeight) };
		var fileName = deck.FileName;
		tile.Pressed += () => this.EmitSignal(SignalName.DeckChosen, fileName);

		var box = new VBoxContainer
		{
			MouseFilter = Control.MouseFilterEnum.Ignore,
			Alignment = BoxContainer.AlignmentMode.Center,
		};
		box.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
		box.OffsetLeft = AppTheme.SpaceSm;
		box.OffsetTop = AppTheme.SpaceSm;
		box.OffsetRight = -AppTheme.SpaceSm;
		box.OffsetBottom = -AppTheme.SpaceSm;

		var name = new Label
		{
			Text = deck.DisplayName,
			HorizontalAlignment = HorizontalAlignment.Center,
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		name.AddThemeFontSizeOverride("font_size", AppTheme.FontSubtitle);
		name.AddThemeColorOverride("font_color", AppTheme.SurfaceText);

		var count = new Label
		{
			Text = $"{deck.CardCount} Cards",
			HorizontalAlignment = HorizontalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		count.AddThemeFontSizeOverride("font_size", AppTheme.FontCaption);
		count.AddThemeColorOverride("font_color", AppTheme.SurfaceTextMuted);

		box.AddChild(name);
		box.AddChild(count);
		tile.AddChild(box);
		return tile;
	}
}
