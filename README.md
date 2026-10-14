# My Simple Flash Card

Markdown 파일로 단어장을 만들고 복습하는 앱.

## 개발 스택

| 항목 | 사용 기술 |
| --- | --- |
| 엔진 | Godot 4.7 |
| 언어 | GDScript |
| UI | Godot Control, 씬, Theme |
| 데이터 | Markdown(카드), JSON(학습 기록, 설정) |
| 플랫폼 | Windows, Android |

## 주요 기능

- 덱과 카드 관리
- 카드 목록에서 상세를 열면 답이 있는 뒷면부터 표시, 탭으로 앞뒷면 전환
- Markdown 가져오기와 내보내기
- 검색과 정렬
- 복습과 이어하기
- 오답 재학습
- 백업과 복원

| 판정 | 상태 | 오답 횟수 |
| --- | --- | --- |
| 다시 볼게요 | LEARNING | +1 |
| 기억나요 | MASTERED | 유지 |

## 문서

- [개발 가이드](docs/DEVELOPMENT.md): 코드 구조, 코딩 규칙, 테스트와 Android 배포
- [개발 기록](docs/DEVLOG.md): 문제와 원인, 해결방안
- [에이전트 작업 규칙](AGENT.md)
