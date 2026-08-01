# Migration test fixtures

GDScript 마이그레이션에서 실제 사용자 데이터를 건드리지 않고 parser와 progress 호환성을 검사하기 위한 고정 입력이다.

| 파일 | 기대 결과 |
| --- | --- |
| `empty_deck.md` | `DeckParser.parse()` 결과는 빈 배열이다. |
| `cards_edge_cases.md` | 순서대로 Apple, Empty answer, Last card 세 장이다. Apple의 답은 두 줄이고, Empty answer의 답은 빈 문자열이다. |
| `duplicate_questions.md` | 세 장을 모두 보존하며, Same question 두 장을 중복 제거하지 않는다. |
| `progress_legacy.json` | Apple WrongCount는 3, 상태는 NEW다. Zero의 WrongCount는 0이고 기본값이라 재직렬화하면 생략될 수 있다. |
| `progress_current.json` | Apple은 WrongCount 3/LEARNING, Banana는 WrongCount 0/MASTERED다. |
| `progress_malformed.json` | JSON 읽기 실패를 안전하게 처리해 빈 Progress가 된다. |

이 파일들은 GDScript 테스트가 읽기만 한다. 저장소 CRUD 테스트가 필요할 때는 `user://` 아래 별도 임시 경로를 사용한다.
