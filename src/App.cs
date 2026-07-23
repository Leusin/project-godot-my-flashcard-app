using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 앱 진입점. 
// 화면 전환과 마지막 사용 덱 기억 담당한다.
public partial class App : Control
{
	// 편집기에서 나갈 때 돌아갈 화면. 카드 목록(탭)과 Study(✏, 세션 유지) 양쪽에서 들어올 수
	// 있어 App이 들어온 곳을 기억했다가 그대로 돌려보낸다.
	private enum EditorReturn
	{
		CardList,
		Study,
	}

	private DeckListView _deckList = null!;
	private DeckHomeView _deckHome = null!;
	private Study _study = null!;
	private CardListView _cardList = null!;
	private CardEditorView _cardEditor = null!;

	// 지금 보고 있는 덱. 허브·Study·카드 목록이 같은 덱을 가리키게 App이 들고 있는다.
	private string _currentDeck = "";
	private EditorReturn _editorReturn = EditorReturn.CardList;

	// 설정을 통째로 들고 읽고-고쳐-쓴다. 마지막 덱만 저장하다 덱 폴더 설정을 날리지 않게.
	private AppSettings _settings = new();

	// 편집 중인 카드의 정체성. 질문은 편집으로 바뀌므로 위치(index)로 기억하고,
	// 옛 질문·답은 실제로 바뀌었는지 판단하고 진행도를 이사하기 위해 들고 있는다.
	private int _editingIndex = -1;
	private string _editingOldQuestion = "";
	private string _editingOldAnswer = "";
	private int _editingOldWrongCount;
	private CardStatus _editingOldStatus = CardStatus.New;

	public override void _Ready()
	{
		// 룩의 출처는 코드. 루트에 걸면 자식 화면 전체가 상속받는다.
		this.Theme = AppTheme.Build();

		this._deckList = this.GetNode<DeckListView>("%DeckListView");
		this._deckHome = this.GetNode<DeckHomeView>("%DeckHomeView");
		this._study = this.GetNode<Study>("%Study");
		this._cardList = this.GetNode<CardListView>("%CardListView");
		this._cardEditor = this.GetNode<CardEditorView>("%CardEditorView");

		this._deckList.DeckChosen += this.OpenDeck;
		this._deckList.ImportRequested += this.OnImportRequested;
		this._deckList.DeckFolderChosen += this.ChangeDeckFolder;
		this._deckList.NewDeckRequested += this.CreateDeck;
		this._deckList.DeckRenameRequested += this.RenameDeck;
		this._deckList.DeckDuplicateRequested += this.DuplicateDeck;
		this._deckList.DeckDeleteRequested += this.DeleteDeck;
		this._deckList.DeckExportRequested += this.OnDeckExportRequested;
		this._deckHome.BackPressed += this.ShowDeckList;
		this._deckHome.StudyRequested += this.OnStudyRequested;
		this._deckHome.CardListRequested += this.ShowCardList;
		this._study.ExitRequested += this.ShowDeckHome;
		this._study.EditRequested += this.OnStudyEditRequested;
		this._cardList.BackPressed += this.ShowDeckHome;
		this._cardList.CardChosen += this.EditCard;
		this._cardList.AddCardRequested += this.AddCard;
		this._cardList.ExportRequested += this.OnExportRequested;
		this._cardList.CardDuplicateRequested += this.DuplicateCard;
		this._cardList.CardDeleteRequested += this.DeleteCard;
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

	// 덱 하나를 "지금 보는 덱"으로 정하고 그 허브를 연다. 타일 탭과 앱 재실행(마지막 덱)이
	// 이 메서드 하나를 공유하므로 두 경로 모두 허브로 착지한다 (DESIGN의 "기본 진입 화면").
	private void OpenDeck(string deckFile)
	{
		this._currentDeck = deckFile;
		this._settings.LastDeckFile = deckFile;
		DeckStorage.SaveSettings(this._settings);
		this.ShowDeckHome();
	}

	// 빈 덱을 만들고 곧바로 카드 목록으로 보낸다 (거기서 카드를 추가한다). 이름이 겹치면 번호를 붙인다.
	private void CreateDeck(string name)
	{
		var fileName = DeckNaming.UniqueFileName(
			$"{name}{DeckNaming.Extension}", DeckStorage.ListDeckFiles());
		DeckStorage.WriteDeck(fileName, "");
		this.OpenDeck(fileName);
		this.ShowCardList();
	}

	// 덱 폴더를 바꾼다. 그 폴더의 md를 그대로 읽는다 — 기존 덱을 옮기지 않는다 (폴더가 곧 원본).
	private void ChangeDeckFolder(string dir)
	{
		this._settings.DeckDir = dir;
		DeckStorage.SaveSettings(this._settings);
		DeckStorage.SetDecksDir(dir);
		this.ShowDeckList();
	}

	// 덱 이름 변경. 진행도는 이름을 따라 함께 옮겨간다 (DeckStorage가 처리).
	private void RenameDeck(string deckFile, string newName)
	{
		var candidate = $"{newName}{DeckNaming.Extension}";
		// 이름이 그대로면 바꿀 게 없다.
		if (DeckNaming.DisplayName(candidate) == DeckNaming.DisplayName(deckFile))
		{
			return;
		}

		// 자기 자신은 충돌 대상에서 빼고, 다른 덱과 겹치면 번호를 붙인다.
		var others = DeckStorage.ListDeckFiles();
		others.Remove(deckFile);
		var newFile = DeckNaming.UniqueFileName(candidate, others);

		if (DeckStorage.RenameDeck(deckFile, newFile))
		{
			if (this._currentDeck == deckFile)
			{
				this._currentDeck = newFile;
			}

			if (this._settings.LastDeckFile == deckFile)
			{
				this._settings.LastDeckFile = newFile;
				DeckStorage.SaveSettings(this._settings);
			}
		}

		this.ShowDeckList();
	}

	private void DuplicateDeck(string deckFile)
	{
		DeckStorage.DuplicateDeck(deckFile);
		this.ShowDeckList();
	}

	// 덱 삭제. 지운 덱이 마지막 덱이었다면 기억을 지워 다음 실행에 목록부터 뜨게 한다.
	private void DeleteDeck(string deckFile)
	{
		DeckStorage.DeleteDeck(deckFile);

		if (this._currentDeck == deckFile)
		{
			this._currentDeck = "";
		}

		if (this._settings.LastDeckFile == deckFile)
		{
			this._settings.LastDeckFile = "";
			DeckStorage.SaveSettings(this._settings);
		}

		this.ShowDeckList();
	}

	private void OnDeckExportRequested(string deckFile, string targetPath)
	{
		if (!DeckStorage.ExportDeck(deckFile, targetPath))
		{
			GD.PushWarning($"덱을 내보내지 못했습니다: {targetPath}");
		}
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

	// 덱 하나의 허브. 이름·카드 수와 마지막으로 고른 Order를 보여준다.
	private void ShowDeckHome()
	{
		this._deckHome.ShowDeck(this.BuildDeckInfo(this._currentDeck));
		this._deckHome.SetOrder(
			this._settings.ShuffleStudy ? StudyOrder.Shuffle : StudyOrder.Sequential);
		this.ShowOnly(this._deckHome);
	}

	// 허브의 ▶ Study. 고른 Order를 다음에도 기본값으로 쓰도록 전역 설정에 남긴다.
	private void OnStudyRequested(int order)
	{
		var studyOrder = (StudyOrder)order;
		this._settings.ShuffleStudy = studyOrder == StudyOrder.Shuffle;
		DeckStorage.SaveSettings(this._settings);
		this._study.StartDeck(this._currentDeck, studyOrder);
		this.ShowStudy();
	}

	// Study의 ✏ = 지금 보는 카드의 편집. 질문(=카드 식별자)으로 자리를 찾아 편집기를 열고,
	// 나가면 세션이 이어지도록 Study로 돌아가게 한다.
	private void OnStudyEditRequested(string question)
	{
		var index = FindCardIndex(
			DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck)), question);
		if (index < 0)
		{
			return;
		}

		this._editorReturn = EditorReturn.Study;
		this.OpenEditor(index);
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
		this._deckHome.Visible = screen == this._deckHome;
		this._study.Visible = screen == this._study;
		this._cardList.Visible = screen == this._cardList;
		this._cardEditor.Visible = screen == this._cardEditor;
	}

	// 카드 목록에서 탭 → 편집기. 나가면 목록으로 돌아간다.
	private void EditCard(int index)
	{
		this._editorReturn = EditorReturn.CardList;
		this.OpenEditor(index);
	}

	private void OpenEditor(int index)
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck));
		if (index < 0 || index >= cards.Count)
		{
			return;
		}

		var card = cards[index];
		var progress = DeckStorage.LoadProgress(this._currentDeck);
		this._editingIndex = index;
		this._editingOldQuestion = card.Question;
		this._editingOldAnswer = card.Answer;
		this._editingOldWrongCount = progress.GetWrongCount(card.Question);
		this._editingOldStatus = progress.GetStatus(card.Question);

		this._cardEditor.ShowDeckName(DeckNaming.DisplayName(this._currentDeck));
		this._cardEditor.ShowCard(card.Question, card.Answer,
			this._editingOldWrongCount, this._editingOldStatus);
		this.ShowOnly(this._cardEditor);
	}

	// 새 카드는 빈 편집기로 연다. index -1은 "기존 카드가 아님" — 저장 때 덱 끝에 붙인다.
	private void AddCard()
	{
		this._editorReturn = EditorReturn.CardList;
		this._editingIndex = -1;
		this._editingOldQuestion = "";
		this._editingOldAnswer = "";
		this._editingOldWrongCount = 0;
		this._editingOldStatus = CardStatus.New;

		this._cardEditor.ShowDeckName(DeckNaming.DisplayName(this._currentDeck));
		this._cardEditor.ShowCard("", "", 0, CardStatus.New);
		this.ShowOnly(this._cardEditor);
	}

	private void OnEditingDone(string question, string answer, int wrongCount, int status)
	{
		var newQuestion = question.Trim();
		if (newQuestion.Length > 0)
		{
			this.SaveCardEdit(newQuestion, answer, wrongCount, (CardStatus)status);
		}

		if (this._editorReturn == EditorReturn.Study)
		{
			// 세션을 유지한 채 돌아간다. 메타(횟수·상태)만 바뀌어도 표시가 갱신되도록 알린다.
			if (newQuestion.Length > 0)
			{
				this._study.OnCurrentCardEdited(new Card(newQuestion, answer));
			}

			this.ShowStudy();
		}
		else
		{
			this.ShowCardList();
		}
	}

	// 실제로 바뀐 것만 저장한다. 내용(질문·답)이 바뀌었을 때만 md를 다시 쓴다 — 안 바뀌면 파일을 안 건드린다.
	private void SaveCardEdit(string newQuestion, string newAnswer, int wrongCount, CardStatus status)
	{
		var contentChanged =
			newQuestion != this._editingOldQuestion || newAnswer != this._editingOldAnswer;
		var metaChanged =
			wrongCount != this._editingOldWrongCount || status != this._editingOldStatus;
		if (!contentChanged && !metaChanged)
		{
			return;
		}

		if (contentChanged)
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
		}

		var progress = DeckStorage.LoadProgress(this._currentDeck);
		// 새 카드면 옛 질문이 ""이라 Rename은 아무 일도 하지 않는다. 그 뒤 편집기 값으로 확정한다.
		progress.Rename(this._editingOldQuestion, newQuestion);
		progress.SetWrongCount(newQuestion, wrongCount);
		progress.SetStatus(newQuestion, status);
		DeckStorage.SaveProgress(this._currentDeck, progress);
	}

	// 편집기의 삭제. 새 카드였다면(index -1) 지울 게 없으니 그냥 취소로 돌아간다.
	private void OnDeleteRequested()
	{
		this.DeleteCardAt(this._editingIndex);

		if (this._editorReturn == EditorReturn.Study)
		{
			this._study.OnCurrentCardDeleted();
			this.ShowStudy();
		}
		else
		{
			this.ShowCardList();
		}
	}

	// 카드 목록 메뉴의 복제. 같은 질문이라 진행도 키를 공유한다 (중복 질문과 같은 처리) — 진행도는 안 건드린다.
	private void DuplicateCard(int index)
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck));
		if (index < 0 || index >= cards.Count)
		{
			return;
		}

		var source = cards[index];
		cards.Insert(index + 1, new Card(source.Question, source.Answer));
		DeckStorage.WriteDeck(this._currentDeck, DeckWriter.ToMarkdown(cards));
		this.ShowCardList();
	}

	// 카드 목록 메뉴의 삭제. 편집기 삭제와 같은 처리(DeleteCardAt)를 index로 부른다.
	private void DeleteCard(int index)
	{
		this.DeleteCardAt(index);
		this.ShowCardList();
	}

	// 그 자리 카드를 덱에서 빼고 md 재저장. 범위 밖 index(-1 등)는 아무 일도 하지 않는다.
	private void DeleteCardAt(int index)
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(this._currentDeck));
		if (index < 0 || index >= cards.Count)
		{
			return;
		}

		var removed = cards[index].Question;
		cards.RemoveAt(index);
		DeckStorage.WriteDeck(this._currentDeck, DeckWriter.ToMarkdown(cards));

		// 남은 카드가 그 질문을 안 쓸 때만 진행도를 지운다 (중복 질문의 기록은 지킨다).
		if (FindCardIndex(cards, removed) < 0)
		{
			var progress = DeckStorage.LoadProgress(this._currentDeck);
			progress.Remove(removed);
			DeckStorage.SaveProgress(this._currentDeck, progress);
		}
	}

	// 질문으로 카드 자리를 찾는다 (첫 일치). 질문이 곧 카드 식별자라는 모델의 한계대로,
	// 같은 질문이 여럿이면 첫 카드를 고른다.
	private static int FindCardIndex(List<Card> cards, string question)
	{
		for (var i = 0; i < cards.Count; i++)
		{
			if (cards[i].Question == question)
			{
				return i;
			}
		}

		return -1;
	}

	private void OnExportRequested(string targetPath)
	{
		if (!DeckStorage.ExportDeck(this._currentDeck, targetPath))
		{
			GD.PushWarning($"덱을 내보내지 못했습니다: {targetPath}");
		}
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

	private DeckInfo BuildDeckInfo(string deckFile)
	{
		var cards = DeckParser.Parse(DeckStorage.ReadDeck(deckFile));
		return new DeckInfo(deckFile, DeckNaming.DisplayName(deckFile), cards.Count);
	}

	private List<DeckInfo> CollectDecks()
	{
		var decks = new List<DeckInfo>();
		foreach (var fileName in DeckStorage.ListDeckFiles())
		{
			decks.Add(this.BuildDeckInfo(fileName));
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
