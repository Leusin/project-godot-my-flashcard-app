# 코딩 컨벤션과 설계 원칙

## 책임과 의존 방향

- core는 UI·파일 IO를 모르는 `RefCounted` 기반 순수 로직이다. Scene Tree 없이 테스트할 수 있어야 한다.
- storage는 UI를 모른다. main 계층이 저장·학습·편집 서비스를 연결하고 화면 전환을 결정한다.
- 작은 UI는 상위를 직접 찾지 않고 `tapped`, `swiped` 같은 사실을 signal로 보낸다. 판정과 저장 정책은 상위에서 해석한다.
- 전역 접근이 편하다는 이유만으로 autoload나 Node를 추가하지 않는다.

## GDScript 스타일

- 파일·함수·변수는 `snake_case`, `class_name`과 enum 타입은 `PascalCase`를 사용한다.
- 가능한 곳에는 반환형, 매개변수형, typed array를 적는다.
- 노드 참조는 `@onready`로 한 번 캐시하고 구체적인 노드 타입을 지정한다.
- 반복 사용하는 scene/resource는 `preload`, 런타임 선택이 필요한 경우만 `load`한다.
- 들여쓰기는 탭이며 `.editorconfig`가 기준이다.
- 긴 함수 호출과 조건은 프로젝트의 기존 GDScript formatting을 따른다.

## Signal과 입력

- signal 이름은 발생한 사실을 표현한다: `tapped`, `menu_requested`, `dismissed`.
- 같은 signal을 화면 재진입 때 중복 연결하지 않는다.
- 드래그와 탭이 겹치는 UI는 이동 임계값과 입력 잠금을 명시한다.
- 투명한 전체 화면 `Control`도 hit-test를 막을 수 있으므로 `mouse_filter`와 노드 z-order를 확인한다.

## 주석

- 코드로 드러나지 않는 이유와 제약만 적는다.
- 코드와 어긋난 주석은 즉시 고친다.
- 옛 구현의 사용처를 설명하는 주석을 남겨 dead code를 정당화하지 않는다.

## 테스트 경계

- core/storage 계약은 headless 자동 테스트로 고정한다.
- 씬 배선은 실제 노드 타입과 signal 경로를 smoke test한다.
- 클릭 감각, 애니메이션 속도, 색·간격은 자동 테스트 후 실제 PC와 모바일에서 확인한다.
