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

	private const int DeckFontSize = 26;
	private const int DeckButtonHeight = 72;

	// 덱이 하나도 없을 때 목록 자리에 대신 놓는 안내.
	private const string EmptyText = "덱이 없습니다.\n아래에서 md 파일을 가져오세요.";

	private VBoxContainer _deckBox = null!;
	private Label _emptyLabel = null!;
	private FileDialog _importDialog = null!;

	public override void _Ready()
	{
		this._deckBox = this.GetNode<VBoxContainer>("%DeckBox");
		this._emptyLabel = this.GetNode<Label>("%EmptyLabel");
		this._importDialog = this.GetNode<FileDialog>("%ImportDialog");

		this._emptyLabel.Text = EmptyText;

		// 대화상자 설정의 출처는 씬이 아니라 여기다 (에디터가 씬을 덮어써도 살아남는다).
		this._importDialog.Access = FileDialog.AccessEnum.Filesystem;
		this._importDialog.FileMode = FileDialog.FileModeEnum.OpenFile;
		this._importDialog.Filters = ["*.md ; Markdown"];
		this._importDialog.UseNativeDialog = true;
		this._importDialog.FileSelected +=
			path => this.EmitSignal(SignalName.ImportRequested, path);

		this.GetNode<Button>("%ImportButton").Pressed +=
			() => this._importDialog.PopupCentered();
	}

	public void ShowDecks(IReadOnlyList<DeckInfo> decks)
	{
		foreach (var child in this._deckBox.GetChildren())
		{
			// 해제는 프레임 끝에 일어나므로, 새 목록과 섞이지 않게 먼저 떼어낸다.
			this._deckBox.RemoveChild(child);
			child.QueueFree();
		}

		this._emptyLabel.Visible = decks.Count == 0;

		foreach (var deck in decks)
		{
			var button = new Button
			{
				Text = $"{deck.DisplayName}    {deck.CardCount} Cards",
				CustomMinimumSize = new Vector2(0.0f, DeckButtonHeight),
			};
			button.AddThemeFontSizeOverride("font_size", DeckFontSize);

			var fileName = deck.FileName;
			button.Pressed += () => this.EmitSignal(SignalName.DeckChosen, fileName);
			this._deckBox.AddChild(button);
		}
	}
}
