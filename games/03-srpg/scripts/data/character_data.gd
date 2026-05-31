class_name CharacterData
extends Resource

# 맵 위 한 칸을 차지하는 "캐릭터(=소대)" 정의.
# 3x3 = 9칸 편성 베이스를 가지고, 실제 전투에서는 이 베이스를 토대로
# 변형 배치를 만들어 쓴다. (변형 결과는 런타임 Squad 쪽에서 관리)

const FORMATION_ROWS: int = 3
const FORMATION_COLS: int = 3
const FORMATION_SLOTS: int = FORMATION_ROWS * FORMATION_COLS  # 9

@export var id: StringName = &""
@export var display_name: String = ""
@export var portrait: Texture2D
@export var move_range: int = 4

# 길이 9 권장. index = row * 3 + col, null 이면 빈 슬롯.
# 인스펙터에서 9개 미만이어도 동작은 하지만, 접근 시 빈 슬롯으로 취급된다.
@export var base_formation: Array[TrooperData] = []

func get_slot(row: int, col: int) -> TrooperData:
	var idx: int = row * FORMATION_COLS + col
	if idx < 0 or idx >= base_formation.size():
		return null
	return base_formation[idx]
