# 코딩 컨벤션과 설계 원칙

## 1. 책임 경계

각 스크립트는 자기 책임만 안다. 파서·카드 데이터·입력 표면은 화면 전환이나 저장 정책을 직접 결정하지 않는다.

## 2. 의존 방향

하위는 상위를 호출하지 않는다.

- `src/core/`는 UI와 파일 IO를 모른다.
- `DeckStorage`는 UI를 모른다.
- 작은 UI 컴포넌트는 `main.gd`를 직접 찾지 않고 signal을 보낸다.
- `main.gd`가 하위 signal을 구독해 앱 규칙을 해석한다.

## 3. 사실과 해석 분리

- 사실: 카드가 오른쪽으로 드래그됨, 버튼이 눌림, Markdown에서 카드 12장이 파싱됨
- 해석: GOOD 처리, WrongCount 증가, 세션 완료, 다음 화면 표시

하위는 사실을 반환하거나 signal로 발신하고, 상위가 의미를 부여한다.

## 4. 순수 로직

파서, writer, 학습 큐, 진행도 직렬화는 `RefCounted` 기반으로 만들고 Scene Tree 없이 테스트할 수 있어야 한다. 전역 접근이 편하다는 이유만으로 autoload나 `Node`를 추가하지 않는다.

## 5. GDScript 스타일

- 파일·함수·변수는 `snake_case`, `class_name`과 enum 타입은 `PascalCase`를 사용한다.
- 가능한 곳에는 반환형, 매개변수형, typed array를 적는다.
- 노드 참조는 `@onready`로 한 번 캐시하고 구체적인 노드 타입을 지정한다.
- 반복 사용하는 scene/resource는 `preload`, 런타임 선택이 필요한 경우만 `load`한다.
- 들여쓰기는 탭이며 `.editorconfig`가 기준이다.
- 긴 함수 호출과 조건은 프로젝트의 기존 GDScript formatting을 따른다.

## 6. Signal과 입력

- signal 이름은 발생한 사실을 표현한다: `tapped`, `menu_requested`, `dismissed`.
- 같은 signal을 화면 재진입 때 중복 연결하지 않는다.
- 드래그와 탭이 겹치는 UI는 이동 임계값과 입력 잠금을 명시한다.
- 투명한 전체 화면 `Control`도 hit-test를 막을 수 있으므로 `mouse_filter`와 노드 z-order를 확인한다.

## 7. 주석

- 코드로 드러나지 않는 이유와 제약만 적는다.
- 코드와 어긋난 주석은 즉시 고친다.
- 옛 구현의 사용처를 설명하는 주석을 남겨 dead code를 정당화하지 않는다.

## 8. 테스트 경계

- core/storage 계약은 headless 자동 테스트로 고정한다.
- 씬 배선은 실제 노드 타입과 signal 경로를 smoke test한다.
- 클릭 감각, 애니메이션 속도, 색·간격은 자동 테스트 후 실제 PC와 모바일에서 확인한다.
