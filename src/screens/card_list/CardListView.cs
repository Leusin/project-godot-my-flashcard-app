using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 카드 목록 화면의 배치만 담당한다. 저장소·파싱·학습 규칙은 모른다.
// 고른 카드·뒤로·내보내기, 그리고 카드 메뉴의 행동(복제/삭제)을 시그널로만 알린다.
public partial class CardListView : Control
{
	[Signal] public delegate void BackPressedEventHandler();
	[Signal] public delegate void CardChosenEventHandler(int index);
	[Signal] public delegate void AddCardRequestedEventHandler();
	[Signal] public delegate void ExportRequestedEventHandler(string targetPath);
	[Signal] public delegate void CardDuplicateRequestedEventHandler(int index);
	[Signal] public delegate void CardDeleteRequestedEventHandler(int index);

	private enum CardMenuId
	{
		Duplicate,
		Delete,
	}

	private const string EmptyText = "카드가 없습니다.";

	private static readonly PackedScene CardRowScene =
		GD.Load<PackedScene>("res://src/screens/card_list/card_row.tscn");

	private Label _deckLabel = null!;
	private VBoxContainer _cardBox = null!;
	private Label _emptyLabel = null!;
	private FileDialog _exportDialog = null!;
	private PopupMenu _cardMenu = null!;
	private ConfirmationDialog _deleteDialog = null!;

	private string _deckName = "";
	private IReadOnlyList<CardRow> _rows = new List<CardRow>();
	private int _menuTargetIndex = -1;

	public override void _Ready()
	{
		this._deckLabel = this.GetNode<Label>("%DeckLabel");
		this._cardBox = this.GetNode<VBoxContainer>("%CardBox");
		this._emptyLabel = this.GetNode<Label>("%EmptyLabel");
		this._exportDialog = this.GetNode<FileDialog>("%ExportDialog");
		this._cardMenu = this.GetNode<PopupMenu>("%CardMenu");
		this._deleteDialog = this.GetNode<ConfirmationDialog>("%DeleteDialog");

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

		this._cardMenu.AddItem("복제", (int)CardMenuId.Duplicate);
		this._cardMenu.AddSeparator();
		this._cardMenu.AddItem("삭제", (int)CardMenuId.Delete);
		this._cardMenu.IdPressed += this.OnCardMenuId;
		this._deleteDialog.Confirmed +=
			() => this.EmitSignal(SignalName.CardDeleteRequested, this._menuTargetIndex);
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
		this._rows = rows;
		foreach (var child in this._cardBox.GetChildren())
		{
			// 해제는 프레임 끝에 일어나므로, 새 목록과 섞이지 않게 먼저 떼어낸다.
			this._cardBox.RemoveChild(child);
			child.QueueFree();
		}

		this._emptyLabel.Visible = rows.Count == 0;

		for (var i = 0; i < rows.Count; i++)
		{
			var row = CardRowScene.Instantiate<CardRowView>();
			this._cardBox.AddChild(row);
			// AddChild로 _Ready가 끝난 뒤라야 라벨이 채워진다.
			row.Setup(rows[i], i);
			row.Chosen += this.OnRowChosen;
			row.MenuRequested += this.OpenCardMenu;
		}
	}

	private void OnRowChosen(int index)
	{
		this.EmitSignal(SignalName.CardChosen, index);
	}

	private void OpenCardMenu(int index, Vector2 atPosition)
	{
		this._menuTargetIndex = index;
		this._cardMenu.ResetSize();
		this._cardMenu.Position = (Vector2I)atPosition;
		this._cardMenu.Popup();
	}

	private void OnCardMenuId(long id)
	{
		switch ((CardMenuId)id)
		{
			case CardMenuId.Duplicate:
				this.EmitSignal(SignalName.CardDuplicateRequested, this._menuTargetIndex);
				break;
			case CardMenuId.Delete:
				this.OpenDeleteDialog();
				break;
		}
	}

	private void OpenDeleteDialog()
	{
		var question = this._menuTargetIndex >= 0 && this._menuTargetIndex < this._rows.Count
			? this._rows[this._menuTargetIndex].Question
			: "";
		this._deleteDialog.DialogText = $"'{question}' 카드를 삭제할까요?\n되돌릴 수 없습니다.";
		this._deleteDialog.PopupCentered();
	}
}
