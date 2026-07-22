using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 앱 진입점. 
// 화면 전환과 마지막 사용 덱 기억 담당한다.
public partial class App : Control
{
	private DeckListView _deckList = null!;
	private Study _study = null!;
	private CardListView _cardList = null!;
	private CardEditorView _cardEditor = null!;

	// 지금 보고 있는 덱. Study와 카드 목록이 같은 덱을 가리키게 App이 들고 있는다.
	private string _currentDeck = "";

	// 설정을 통째로 들고 읽고-고쳐-쓴다. 마지막 덱만 저장하다 덱 폴더 설정을 날리지 않게.
	private AppSettings _settings = new();

	// 편집 중인 카드의 정체성. 질문은 편집으로 바뀌므로 위치(index)로 기억하고,
	// 옛 질문·답은 실제로 바뀌었는지 판단하고 진행도를 이사하기 위해 들고 있는다.
	private int _editingIndex = -1;
	private string _editingOldQuestion = "";
	private string _editingOldAnswer = "";

	public override void _Ready()
	{
		this._deckList = this.GetNode<DeckListView>("%DeckListView");
		this._study = this.GetNode<Study>("%Study");
		this._cardList = this.GetNode<CardListView>("%CardListView");
		this._cardEditor = this.GetNode<CardEditorView>("%CardEditorView");

		this._deckList.DeckChosen += this.OpenDeck;
		this._deckList.ImportRequested += this.OnImportRequested;
		this._deckList.DeckFolderChosen += this.ChangeDeckFolder;
		this._study.ExitRequested += this.ShowDeckList;
		this._study.EditRequested += this.ShowCardList;
		this._cardList.BackPressed += this.ShowStudy;
		this._cardList.CardChosen += this.EditCard;
		this._cardList.AddCardRequested += this.AddCard;
		this._cardEditor.EditingDone += this.OnEditingDone;
		this._cardEditor.DeleteRequested += this.OnDeleteRequested;

		this._settings = DeckStorage.LoadSettings();
		DeckStorage.SetDecksDir(this._settings.DeckDir);
		DeckStorage.SeedSampleIfEmpty();

		if (DeckStorage.DeckExists(this._settings.LastDeckFile))
		{
			this.OpenDeck(this._settings.LastDeckFile);
		}
		else
		{
			this.ShowDeckList();
		}
	}

	private void OpenDeck(string deckFile)
	{
		this._currentDeck = deckFile;
		this._settings.LastDeckFile = deckFile;
		DeckStorage.SaveSettings(this._settings);
		this._study.StartDeck(deckFile);
		this.ShowStudy();
	}

	// 덱 폴더를 바꾼다. 그 폴더의 md를 그대로 읽는다 — 기존 덱을 옮기지 않는다 (폴더가 곧 원본).
	private void ChangeDeckFolder(string dir)
	{
		this._settings.DeckDir = dir;
		DeckStorage.SaveSettings(this._settings);
		DeckStorage.SetDecksDir(dir);
		this.ShowDeckList();
	}

	private void ShowStudy()
	{
		this.ShowOnly(this._study);
	}

	private void ShowDeckList()
	{
		this._deckList.ShowDecks(this.CollectDecks());
		// 사용자에겐 user:// 대신 실제 OS 경로를 보여준다.
		this._deckList.ShowFolder(ProjectSettings.GlobalizePath(DeckStorage.DecksDir));
		this.ShowOnly(this._deckList);
	}

	private void ShowCardList()
	{
		this._cardList.ShowDeckName(DeckNaming.DisplayName(this._currentDeck));
		this._cardList.ShowCards(this.CollectRows(this._currentDeck));
		this.ShowOnly(this._cardList);
	}

	// 화면 하나만 보이게 한다. 새 화면을 추가하면 여기에만 더한다.
	private void ShowOnly(Control screen)
	{
		this._deckList.Visible = screen == this._deckList;
		this._study.Visible = screen == this._study;
		this._cardList.Visible = screen == this._cardList;
		this._cardEditor.Visible = screen == this._cardEditor;
	}

	private void EditCard(int index)
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck));
		if (index < 0 || index >= cards.Count)
		{
			return;
		}

		var card = cards[index];
		this._editingIndex = index;
		this._editingOldQuestion = card.Question;
		this._editingOldAnswer = card.Answer;

		this._cardEditor.ShowDeckName(DeckNaming.DisplayName(this._currentDeck));
		this._cardEditor.ShowCard(card.Question, card.Answer);
		this.ShowOnly(this._cardEditor);
	}

	// 새 카드는 빈 편집기로 연다. index -1은 "기존 카드가 아님" — 저장 때 덱 끝에 붙인다.
	private void AddCard()
	{
		this._editingIndex = -1;
		this._editingOldQuestion = "";
		this._editingOldAnswer = "";

		this._cardEditor.ShowDeckName(DeckNaming.DisplayName(this._currentDeck));
		this._cardEditor.ShowCard("", "");
		this.ShowOnly(this._cardEditor);
	}

	private void OnEditingDone(string question, string answer)
	{
		var newQuestion = question.Trim();
		var changed = newQuestion.Length > 0 &&
			(newQuestion != this._editingOldQuestion || answer != this._editingOldAnswer);
		if (changed)
		{
			this.SaveCardEdit(newQuestion, answer);
		}

		this.ShowCardList();
	}

	private void SaveCardEdit(string newQuestion, string newAnswer)
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck));
		var card = new Card(newQuestion, newAnswer);
		if (this._editingIndex >= 0 && this._editingIndex < cards.Count)
		{
			cards[this._editingIndex] = card;
		}
		else
		{
			cards.Add(card);
		}

		DeckStorage.WriteDeck(this._currentDeck, DeckWriter.ToMarkdown(cards));

		var progress = DeckStorage.LoadProgress(this._currentDeck);
		// 새 카드면 옛 질문이 ""이라 Rename은 아무 일도 하지 않는다.
		progress.Rename(this._editingOldQuestion, newQuestion);
		DeckStorage.SaveProgress(this._currentDeck, progress);
	}

	// 편집기의 삭제. 새 카드였다면(index -1) 지울 게 없으니 그냥 취소로 목록에 돌아간다.
	private void OnDeleteRequested()
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck));
		if (this._editingIndex >= 0 && this._editingIndex < cards.Count)
		{
			var removed = cards[this._editingIndex].Question;
			cards.RemoveAt(this._editingIndex);
			DeckStorage.WriteDeck(this._currentDeck, DeckWriter.ToMarkdown(cards));

			// 남은 카드가 그 질문을 안 쓸 때만 진행도를 지운다 (중복 질문의 기록은 지킨다).
			if (!DeckHasQuestion(cards, removed))
			{
				var progress = DeckStorage.LoadProgress(this._currentDeck);
				progress.Remove(removed);
				DeckStorage.SaveProgress(this._currentDeck, progress);
			}
		}

		this.ShowCardList();
	}

	private static bool DeckHasQuestion(List<Card> cards, string question)
	{
		foreach (var card in cards)
		{
			if (card.Question == question)
			{
				return true;
			}
		}

		return false;
	}

	// 가져온 덱은 곧바로 열지 않는다. 목록에 들어온 것을 확인하고 고르는 편이 덜 놀랍다.
	private void OnImportRequested(string sourcePath)
	{
		if (DeckStorage.Import(sourcePath) == null)
		{
			GD.PushWarning($"덱을 가져오지 못했습니다: {sourcePath}");
		}

		this.ShowDeckList();
	}

	private List<DeckInfo> CollectDecks()
	{
		var decks = new List<DeckInfo>();
		foreach (var fileName in DeckStorage.ListDeckFiles())
		{
			var cards = DeckParser.Parse(DeckStorage.ReadDeck(fileName));
			decks.Add(new DeckInfo(fileName, DeckNaming.DisplayName(fileName), cards.Count));
		}

		return decks;
	}

	private List<CardRow> CollectRows(string deckFile)
	{
		var progress = DeckStorage.LoadProgress(deckFile);
		var rows = new List<CardRow>();
		foreach (var card in DeckParser.Parse(DeckStorage.ReadDeck(deckFile)))
		{
			rows.Add(new CardRow(card.Question, progress.GetWrongCount(card.Question)));
		}

		return rows;
	}
}
