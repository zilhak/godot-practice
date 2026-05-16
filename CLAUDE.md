# godot-practice — Claude 작업 규칙

이 저장소는 Godot 4.6.2 + GDScript로 다양한 장르의 미니 게임을 만들어보는 연습용 모노레포입니다.

## 환경

- **엔진**: Godot 4.6.2 (Standard, GDScript only — .NET 버전 아님)
- **실행 파일**: `E:\IDE\Godot\godot.exe` (PATH 등록됨, `godot` 명령으로 호출 가능)
- **콘솔 버전**: `E:\IDE\Godot\godot_console.exe` (CLI 출력이 필요한 경우)
- **언어**: GDScript
- **OS**: Windows 11

### 자주 쓰는 명령

```powershell
godot --version                              # 버전 확인
godot --path games/01-pong                   # 특정 게임 에디터로 열기
godot --path games/01-pong --headless --quit # 임포트만 수행 (CI/사전 검증)
```

## 저장소 구조

```
godot-practice/
├── games/          # 각 폴더가 독립된 Godot 프로젝트 (project.godot 보유)
│   ├── 01-pong/
│   └── ...
├── shared/         # 여러 게임이 공유할 에셋/유틸 (필요 시 생성)
└── docs/           # 게임별 학습 노트 (필요 시 생성)
```

각 게임은 `games/<번호>-<이름>/project.godot`을 가진 **완전 독립 프로젝트**입니다. Godot 에디터에서 해당 폴더를 열어 작업합니다.

## 작업 규칙

### 커밋 규칙 (CRITICAL)

**기능 하나를 추가할 때마다 즉시 commit한다.**

- "기능 하나"의 단위 = 동작하는 최소 단위 (예: 패들 이동, 공 발사, 점수 표시 각각 별도 커밋)
- 여러 기능을 한 커밋에 몰아넣지 않는다.
- 리팩터링·버그 수정·에셋 추가도 별도 커밋으로 분리한다.
- 커밋 메시지는 한국어로, 무엇을 했는지 명확히 적는다. 예시:
  - `feat(pong): 좌측 패들 키보드 이동 구현`
  - `feat(pong): 공 초기 발사 방향 랜덤화`
  - `fix(pong): 벽 충돌 시 속도 누적 버그 수정`
  - `chore: .gitignore에 .godot/ 추가`

### 게임 추가 시 절차

1. `games/<번호>-<이름>/` 폴더 생성
2. Godot 에디터로 해당 폴더에 `project.godot` 생성 (또는 CLI로 빈 프로젝트 초기화)
3. README.md의 "게임 목록" 표에 항목 추가, 상태 갱신
4. 최소 동작 단위마다 커밋

### 임시 파일

전역 규칙(`~/.claude/CLAUDE.md`)에 따라 git에 올라가지 않을 임시 파일은 `.claude-workspace/` 하위에 둔다.

## 학습 목적

이 저장소는 **연습/학습**이 목적입니다. 따라서:
- 과한 추상화·설계보다 **돌아가는 작은 단위**를 우선한다.
- 각 게임 폴더의 README나 주석에 학습 포인트를 짧게 남기면 좋다.
- 다음 게임에서 같은 실수를 반복하지 않도록, 막혔던 부분은 메모로 남긴다.
