# MyFlashCard App (가제)

## 개요

### 한 줄 소개

Markdown으로 카드를 작성하고, Reigns 스타일의 스와이프 UI로 복습하는 플래시카드 앱.

### 동기

기존 플래시카드 앱은 카드를 만드는 과정이 번거롭다. 공부를 하면서 빠르게 기록하고 싶지만, 카드 생성과 덱 관리에 시간이 많이 들어 결국 사용하지 않게 된다.

내가 만들고 싶은 앱은 Markdown 문서 하나만 편집하면 바로 복습할 수 있는 플래시카드 앱이다.

예시
- PC에서 Markdown으로 작성
- 모바일(Android)에서 바로 복습

### 대상 이용자

- 나
- Markdown 기반으로 공부하는 사람

## 목표

### 핵심 목표

1. 카드와 덱을 빠르게 편집할 수 있어야 한다.
2. 복습은 게임처럼 직관적이고 재미있어야 한다.

### 핵심 원칙

- Markdown이 원본(Source of Truth)이다.
- 앱은 Markdown을 읽어 카드를 생성한다.
- 앱에서 수정한 내용은 Markdown에도 반영된다.
- 공부를 방해하지 않는 UX를 지향한다.


### 비목표 (Non Goals)

초기 버전에서는 다음 기능을 구현하지 않는다.

- 회원가입
- 클라우드 동기화
- AI 기능
- 학습 통계
- 이미지 및 미디어 첨부
- SRS(Spaced Repetition) 알고리즘

MVP에서는 빠른 카드 작성과 복습 경험에 집중한다.

## 기술 스택

| 항목 | 선택 |
| --- | --- |
| Engine | Godot 4 (.NET) |
| Language | C# |
| Data | Markdown (.md) |
| Progress | JSON |
| Version Control | Git |

## UX

### 사용자 흐름

```
사용 흐름
Markdown 작성 (PC 또는 앱)
↓
덱 선택
↓
Study
↓
카드 학습
↓
Again / Good / Pass
↓
진행도 저장

Edit
↓
카드 추가/삭제/수정
↓
Markdown 저장
```

### Deck - 시작 화면 (최근 덱)

앱을 실행하면 마지막으로 사용한 덱을 표시한다.

```markdown
← Decks
┌────────────────────┐
덱 이름
123 Cards

▶ Study [Order: Shuffle / Sequential ▼]
✏ Card List
└────────────────────┘
카드 수
```

- 기본 진입 화면
- 뒤로 가기 시 덱 목록으로 이동

### Deck List - 덱 목록

```markdown
 
□: □: □:
□: □: [＋ 새 덱 ]
📂 가져오기
```

- 덱 클릭 → Deck
- 각 덱 : → Deck Menu
- 드래그 하여 순서 변경
- 새 덱 생성
- Markdown 덱 가져오기

### Deck Menu - 덱 메뉴

```markdown
Rename
Export
Duplicate
Delete
```

### Card List - 카드 목록

```markdown
← Decks    덱이름    :
검색
────────────────
□ Apple (WrongCount) :
□ Red (WrongCount) :
────────────────
＋ 카드 추가
＋ Add Card
📝 Markdown
(드래그해서 순서 이동 가능)
```

- ← 뒤로가기
- 상단 : → Deck Menu
- 검색
- 드래그하여 카드 순서 변경 
- 각 카드 : → Card Menu

### Card Editor - 카드 편집

```markdown
←    덱이름    :
┌────────────────────────┐
WrongCount 12 ✏ 
[tag: NEW / LEARNING / MASTERED ▼]
질문 ✏
────────────────────────
답 ✏
└────────────────────────┘
```

- : → Card Menu

### Card Menu

```markdown
Duplicate
Delete
```

### Study - 카드 학습

카드 화면

```markdown
← Decks    덱이름    ✏
┌────────────────────────┐
[NEW / LEARNING / MASTERED]   WrongCount 12
────────────────────────
질문
────────────────────────
(탭) 
↓ 
답
────────────────────────
← Again
↑ Pass
↓ Previous
→ Good
(Long Press → Edit)
└────────────────────────┘
```

- 카드 탭으로 앞/뒤 전환
- 스와이프 또는 방향키 입력
- 진행도 자동 저장

---

## 데이터 규칙

### 진행도 저장

- Question을 카드 식별자로 사용한다.
- Question이 변경되면 진행도는 초기화된다.

### 카드 상태와 WrongCount

- 카드 상태(NEW / LEARNING / MASTERED)는 사용자가 Card Editor에서 수동으로 설정하는 표시용 라벨이다. 학습 동작에는 영향을 주지 않는다.
- WrongCount는 Again 시 자동으로 증가하며, Card Editor에서 수동으로 수정할 수도 있다.

### 학습 규칙

Again
- WrongCount 증가
- 이번 세션 마지막에 다시 등장

Good
- 이번 세션에서 완료

Pass
- 이번 세션에서 건너뛰기

### Import

Markdown 파일을 앱 내부 저장소로 복사하여 관리한다.
Export를 통해 Markdown 파일로 다시 내보낼 수 있다.

---

## Markdown 형식

문서 하나가 하나의 덱이다.
초기 버전에서는 최대한 단순한 문법을 사용한다.

예시

```markdown
# Apple
사과
# Red
빨간색
```

향후 필요에 따라 태그, 메타데이터 등의 문법을 확장할 수 있다.

---

## 향후 아이디어

초기 버전 완성 이후 검토한다.

- SRS 알고리즘
- 카드 상태 자동 전이, MASTERED 카드 Study 제외
- 코드 하이라이팅
- Markdown 렌더링
- 태그
- 검색
- Git 연동
- AI를 이용한 카드 자동 생성
