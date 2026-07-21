using System.Collections.Generic;
using Godot;
using MyFlashCard.Core;

namespace MyFlashCard;

// 앱 진입점. 화면(덱 목록 ↔ Study) 전환과 마지막 사용 덱 기억만 담당한다.
// 학습 규칙과 카드 표시는 모른다.
public partial class App : Control
{
	private DeckListView _deckList = null!;
	private Study _study = null!;

	public override void _Ready()
	{
		this._deckList = this.GetNode<DeckListView>("%DeckListView");
		this._study = this.GetNode<Study>("%Study");

		this._deckList.DeckChosen += this.OpenDeck;
		this._deckList.ImportRequested += this.OnImportRequested;
		this._study.ExitRequested += this.ShowDeckList;

		DeckStorage.SeedSampleIfEmpty();

		var lastDeck = DeckStorage.LoadSettings().LastDeckFile;
		if (DeckStorage.DeckExists(lastDeck))
		{
			this.OpenDeck(lastDeck);
		}
		else
		{
			this.ShowDeckList();
		}
	}

	private void OpenDeck(string deckFile)
	{
		DeckStorage.SaveSettings(new AppSettings { LastDeckFile = deckFile });
		this._study.StartDeck(deckFile);
		this._deckList.Visible = false;
		this._study.Visible = true;
	}

	private void ShowDeckList()
	{
		this._deckList.ShowDecks(this.CollectDecks());
		this._study.Visible = false;
		this._deckList.Visible = true;
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
}
