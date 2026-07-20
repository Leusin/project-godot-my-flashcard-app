using Godot;

namespace MyFlashCard;

// 카드 한 장을 표시만 한다. 세션 규칙과 진행도 갱신은 모른다.
// 탭 → 답 공개(뷰 내부 표시 상태), Again/Good 버튼 눌림은 시그널로만 알린다.
public partial class StudyView : Control
{
    [Signal] public delegate void AgainPressedEventHandler();
    [Signal] public delegate void GoodPressedEventHandler();

    private Label _remainingLabel = null!;
    private Label _wrongCountLabel = null!;
    private Label _questionLabel = null!;
    private Label _answerLabel = null!;
    private Control _answerArea = null!;

    public override void _Ready()
    {
        _remainingLabel = GetNode<Label>("%RemainingLabel");
        _wrongCountLabel = GetNode<Label>("%WrongCountLabel");
        _questionLabel = GetNode<Label>("%QuestionLabel");
        _answerLabel = GetNode<Label>("%AnswerLabel");
        _answerArea = GetNode<Control>("%AnswerArea");

        GetNode<Button>("%AgainButton").Pressed += () => EmitSignal(SignalName.AgainPressed);
        GetNode<Button>("%GoodButton").Pressed += () => EmitSignal(SignalName.GoodPressed);
    }

    // 카드 영역 탭/클릭 → 답 공개 (씬의 CardPanel.gui_input 연결)
    public void OnCardGuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left })
            _answerArea.Visible = true;
    }

    public void ShowCard(string question, string answer, int wrongCount, int remaining)
    {
        _questionLabel.Text = question;
        _answerLabel.Text = answer;
        _wrongCountLabel.Text = wrongCount > 0 ? $"WrongCount {wrongCount}" : "";
        _remainingLabel.Text = $"남은 카드 {remaining}";
        _answerArea.Visible = false;
    }
}
