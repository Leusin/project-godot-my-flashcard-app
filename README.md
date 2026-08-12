# MyFlashCard App (가제)

Markdown으로 카드를 작성하고, 스와이프와 버튼으로 복습하는 모바일 중심 플래시카드 앱.

- Engine: Godot 4.7.1
- Language: GDScript
- Data: Markdown (`.md`), JSON
- Main scene: `src/main/main.tscn`
- 기획서: [docs/DESIGN.md](docs/DESIGN.md)
- 코드 가이드: [docs/CODE_GUIDE.md](docs/CODE_GUIDE.md)
- GDScript 전환 기록: [docs/MIGRATION_GDSCRIPT.md](docs/MIGRATION_GDSCRIPT.md)

## 실행과 테스트

일반 Godot 에디터에서 프로젝트를 열고 F6가 아니라 F5로 Main Scene을 실행한다.

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --log-file .godot/latest-test.log res://tests/tests.tscn
```

별도 .NET SDK나 `dotnet build`는 필요하지 않다.
