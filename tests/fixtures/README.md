# 테스트 데이터

파서와 학습 기록의 호환성을 확인하는 고정 입력입니다.

| 파일 | 기대 결과 |
| --- | --- |
| `empty_deck.md` | 카드 0개 |
| `cards_edge_cases.md` | Apple, Empty answer, Last card 순서로 3개. Apple은 두 줄 답, Empty answer는 빈 답 |
| `duplicate_questions.md` | 카드 3개 유지, Same question 중복 질문 2개 유지 |
| `progress_legacy.json` | Apple: 오답 3, NEW. Zero: 오답 0, NEW |
| `progress_current.json` | Apple: 오답 3, LEARNING. Banana: 오답 0, MASTERED |
| `progress_malformed.json` | 파싱 실패 시 빈 학습 기록 반환 |

- 고정 입력은 테스트에서 읽기만 사용
- 파일 생성과 수정 테스트는 `user://` 아래 별도 임시 경로 사용
