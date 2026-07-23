using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 덱 목록 화면의 배치만 담당한다. 저장소·파싱·학습 규칙은 모른다.
// 고른 덱·가져올 파일·덱 메뉴의 행동(이름 변경/내보내기/복제/삭제)을 시그널로만 알린다.
public partial class DeckListView : Control
{
	[Signal] public delegate void DeckChosenEventHandler(string deckFile);
	[Signal] public delegate void ImportRequestedEventHandler(string sourcePath);
	[Signal] public delegate void DeckFolderChosenEventHandler(string dir);
	[Signal] public delegate void NewDeckRequestedEventHandler(string name);
	[Signal] public delegate void DeckRenameRequestedEventHandler(string deckFile, string newName);
	[Signal] public delegate void DeckDuplicateRequestedEventHandler(string deckFile);
	[Signal] public delegate void DeckDeleteRequestedEventHandler(string deckFile);
	[Signal] public delegate void DeckExportRequestedEventHandler(string deckFile, string targetPath);

	// 항목 순서와 무관하게 눌린 항목을 식별하는 값. AddItem에 넘긴 id로 되돌아온다.
	private enum DeckMenuId
	{
		Rename,
		Export,
		Duplicate,
		Delete,
	}

	// 덱이 하나도 없을 때 목록 자리에 대신 놓는 안내.
	private const string EmptyText = "덱이 없습니다.\n아래에서 md 파일을 가져오세요.";

	private static readonly PackedScene DeckTileScene =
		GD.Load<PackedScene>("res://src/screens/deck_list/deck_tile.tscn");

	private HFlowContainer _deckBox = null!;
	private Label _emptyLabel = null!;
	private Label _folderLabel = null!;
	private Button _addTile = null!;
	private FileDialog _importDialog = null!;
	private FileDialog _folderDialog = null!;
	private ConfirmationDialog _newDeckDialog = null!;
	private LineEdit _newDeckName = null!;

	private PopupMenu _deckMenu = null!;
	private ConfirmationDialog _renameDialog = null!;
	private LineEdit _renameName = null!;
	private ConfirmationDialog _deleteDialog = null!;
	private FileDialog _exportDialog = null!;

	// 메뉴·다이얼로그가 대상으로 삼는 덱. 메뉴를 열 때 정해지고 확정할 때까지 유지된다.
	private string _menuTargetDeck = "";

	public override void _Ready()
	{
		this._deckBox = this.GetNode<HFlowContainer>("%DeckBox");
		this._emptyLabel = this.GetNode<Label>("%EmptyLabel");
		this._folderLabel = this.GetNode<Label>("%FolderLabel");
		this._addTile = this.GetNode<Button>("%AddTile");
		this._importDialog = this.GetNode<FileDialog>("%ImportDialog");
		this._folderDialog = this.GetNode<FileDialog>("%FolderDialog");
		this._newDeckDialog = this.GetNode<ConfirmationDialog>("%NewDeckDialog");
		this._newDeckName = this.GetNode<LineEdit>("%NewDeckName");
		this._deckMenu = this.GetNode<PopupMenu>("%DeckMenu");
		this._renameDialog = this.GetNode<ConfirmationDialog>("%RenameDialog");
		this._renameName = this.GetNode<LineEdit>("%RenameName");
		this._deleteDialog = this.GetNode<ConfirmationDialog>("%DeleteDialog");
		this._exportDialog = this.GetNode<FileDialog>("%ExportDialog");

		this._emptyLabel.Text = EmptyText;

		this._deckBox.AddThemeConstantOverride("h_separation", AppTheme.SpaceLg);
		this._deckBox.AddThemeConstantOverride("v_separation", AppTheme.SpaceLg);
		this._deckBox.Alignment = FlowContainer.AlignmentMode.Center;
		this._deckBox.LastWrapAlignment = FlowContainer.LastWrapAlignmentMode.Begin;

		// 새 덱 타일은 씬에 있고, 크기·색만 코드가 넣는다 (수치는 DeckTile 상수, 색은 AppTheme 토큰).
		this._addTile.CustomMinimumSize = new Vector2(DeckTile.TileWidth, DeckTile.TileHeight);
		this.GetNode<Label>("%AddLabel").AddThemeColorOverride("font_color", AppTheme.SurfaceTextMuted);
		this._addTile.Pressed += this.OpenNewDeckDialog;

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

		this.SetupDeckMenu();
	}

	// 덱 메뉴와 그 행동을 확정하는 다이얼로그를 배선한다. 항목은 코드로 채운다(순서=책임 한곳).
	private void SetupDeckMenu()
	{
		this._deckMenu.AddItem("이름 변경", (int)DeckMenuId.Rename);
		this._deckMenu.AddItem("내보내기", (int)DeckMenuId.Export);
		this._deckMenu.AddItem("복제", (int)DeckMenuId.Duplicate);
		this._deckMenu.AddSeparator();
		this._deckMenu.AddItem("삭제", (int)DeckMenuId.Delete);
		this._deckMenu.IdPressed += this.OnDeckMenuId;

		this._renameDialog.Confirmed += this.OnRenameConfirmed;
		this._renameDialog.RegisterTextEnter(this._renameName);
		this._deleteDialog.Confirmed +=
			() => this.EmitSignal(SignalName.DeckDeleteRequested, this._menuTargetDeck);

		this._exportDialog.Access = FileDialog.AccessEnum.Filesystem;
		this._exportDialog.FileMode = FileDialog.FileModeEnum.SaveFile;
		this._exportDialog.Filters = ["*.md ; Markdown"];
		this._exportDialog.UseNativeDialog = true;
		this._exportDialog.FileSelected +=
			path => this.EmitSignal(SignalName.DeckExportRequested, this._menuTargetDeck, path);
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
			// 새 덱 타일은 씬에 상주하므로 지우지 않는다. 동적으로 넣은 덱 타일만 걷어낸다.
			if (child is DeckTile tile)
			{
				this._deckBox.RemoveChild(tile);
				tile.QueueFree();
			}
		}

		// 덱이 없어도 "새 덱" 타일은 늘 있으니 빈 안내는 숨긴다.
		this._emptyLabel.Visible = false;

		foreach (var deck in decks)
		{
			var tile = DeckTileScene.Instantiate<DeckTile>();
			this._deckBox.AddChild(tile);
			// AddChild로 _Ready가 끝난 뒤라야 라벨이 채워진다.
			tile.Setup(deck);
			tile.Chosen += this.OnTileChosen;
			tile.MenuRequested += this.OpenDeckMenu;
		}

		// 새 덱 타일은 항상 마지막 칸에 둔다.
		this._deckBox.MoveChild(this._addTile, this._deckBox.GetChildCount() - 1);
	}

	private void OnTileChosen(string deckFile)
	{
		this.EmitSignal(SignalName.DeckChosen, deckFile);
	}

	private void OpenDeckMenu(string deckFile, Vector2 atPosition)
	{
		this._menuTargetDeck = deckFile;
		this._deckMenu.ResetSize();
		this._deckMenu.Position = (Vector2I)atPosition;
		this._deckMenu.Popup();
	}

	private void OnDeckMenuId(long id)
	{
		switch ((DeckMenuId)id)
		{
			case DeckMenuId.Rename:
				this.OpenRenameDialog();
				break;
			case DeckMenuId.Export:
				this.OpenExportDialog();
				break;
			case DeckMenuId.Duplicate:
				this.EmitSignal(SignalName.DeckDuplicateRequested, this._menuTargetDeck);
				break;
			case DeckMenuId.Delete:
				this.OpenDeleteDialog();
				break;
		}
	}

	private void OpenRenameDialog()
	{
		this._renameName.Text = DeckNaming.DisplayName(this._menuTargetDeck);
		this._renameDialog.PopupCentered();
		this._renameName.SelectAll();
		this._renameName.GrabFocus();
	}

	private void OnRenameConfirmed()
	{
		var name = this._renameName.Text.Trim();
		if (name.Length > 0)
		{
			this.EmitSignal(SignalName.DeckRenameRequested, this._menuTargetDeck, name);
		}
	}

	private void OpenExportDialog()
	{
		this._exportDialog.CurrentFile = $"{DeckNaming.DisplayName(this._menuTargetDeck)}.md";
		this._exportDialog.PopupCentered();
	}

	private void OpenDeleteDialog()
	{
		this._deleteDialog.DialogText =
			$"'{DeckNaming.DisplayName(this._menuTargetDeck)}' 덱을 삭제할까요?\n되돌릴 수 없습니다.";
		this._deleteDialog.PopupCentered();
	}

	private void OpenNewDeckDialog()
	{
		this._newDeckName.Text = "";
		this._newDeckDialog.PopupCentered();
	}

	private void OnNewDeckConfirmed()
	{
		var name = this._newDeckName.Text.Trim();
		if (name.Length > 0)
		{
			this.EmitSignal(SignalName.NewDeckRequested, name);
		}
	}
}
