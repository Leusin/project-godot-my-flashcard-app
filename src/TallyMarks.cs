using Godot;

namespace MyFlashCard;

// 주어진 수를 작대기 표시로 그리기만 한다. 그 수가 무엇을 세는지는 모른다.
// 5개마다 한 묶음이고, 다섯 번째는 앞의 넷을 가로지르는 사선으로 긋는다.
public partial class TallyMarks : Control
{
	private const int GroupSize = 5;
	private const float BarWidth = 2.0f;
	private const float BarGap = 5.0f;      // 묶음 안에서 작대기 사이
	private const float GroupGap = 9.0f;    // 묶음과 묶음 사이
	private const float BarHeight = 16.0f;
	private const float SlashOverhang = 2.0f;

	private int _count;

	public int Count
	{
		get => this._count;
		set
		{
			this._count = Mathf.Max(0, value);
			// 개수가 0이어도 높이는 유지한다. 카드마다 윗줄이 들쭉날쭉하지 않게.
			this.CustomMinimumSize = new Vector2(this.TotalWidth(), BarHeight);
			this.QueueRedraw();
		}
	}

	public override void _Draw()
	{
		if (this._count <= 0)
		{
			return;
		}

		var color = this.GetThemeColor("font_color", "Label");
		var height = this.Size.Y > 0.0f ? this.Size.Y : BarHeight;
		var x = 0.0f;
		var remaining = this._count;

		while (remaining > 0)
		{
			var inGroup = Mathf.Min(GroupSize, remaining);
			var bars = Mathf.Min(inGroup, GroupSize - 1);

			for (var i = 0; i < bars; i++)
			{
				var barX = x + (i * BarGap);
				this.DrawLine(
					new Vector2(barX, 0.0f), new Vector2(barX, height), color, BarWidth);
			}

			if (inGroup == GroupSize)
			{
				this.DrawLine(
					new Vector2(x - SlashOverhang, height),
					new Vector2(x + ((GroupSize - 2) * BarGap) + SlashOverhang, 0.0f),
					color, BarWidth);
			}

			x += GroupWidth(inGroup) + GroupGap;
			remaining -= inGroup;
		}
	}

	private static float GroupWidth(int inGroup)
	{
		var bars = Mathf.Min(inGroup, GroupSize - 1);
		return ((bars - 1) * BarGap) + BarWidth;
	}

	// 한 줄로만 그린다. 수가 아주 커지면 카드 폭을 넘어 잘린다.
	private float TotalWidth()
	{
		var width = 0.0f;
		var remaining = this._count;

		while (remaining > 0)
		{
			var inGroup = Mathf.Min(GroupSize, remaining);
			width += GroupWidth(inGroup) + GroupGap;
			remaining -= inGroup;
		}

		return Mathf.Max(0.0f, width - GroupGap);
	}
}
