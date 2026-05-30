# godot-practice

Godot 4.6.2 + GDScript로 다양한 장르의 미니 게임을 만들어보는 연습용 모노레포.

## 구조

```
godot-practice/
├── games/          # 각 폴더가 독립된 Godot 프로젝트
│   ├── 01-pong/
│   ├── 02-...
│   └── ...
├── shared/         # 여러 게임이 공유할 에셋/유틸 (생기면 추가)
└── docs/           # 게임별 학습 노트 (생기면 추가)
```

각 게임은 `games/<번호>-<이름>/project.godot`을 가진 **완전 독립 프로젝트**입니다.
Godot 에디터에서 해당 폴더를 열어 작업합니다.

## 환경

- Godot 4.6.2 (Standard, GDScript only — .NET 버전 아님)
- 언어: GDScript
- 플랫폼: Windows 11

## 게임 목록

| # | 이름 | 장르 | 학습 포인트 | 상태 |
|---|------|------|-------------|------|
| 01 | Pong | 아케이드 | 노드/씬/시그널/충돌 기본기 | 완료 |
| 02 | Platformer | 액션 | CharacterBody2D/중력/공격/적 AI/스프라이트/애니메이션 | 진행 중 |
| 03 | SRPG | 시뮬레이션 | 아이소메트릭 좌표/BFS 이동범위/턴 매니저/단순 AI | 진행 중 |
