class_name TrooperData
extends Resource

# 9칸 편성의 한 슬롯에 들어가는 "병사 정의".
# 병종(class_data) + 등급(level) + 추가 보정치(modifiers) 의 조합이다.
# 등급은 1~3 으로 사실상 자원처럼 소모되는 개념. 시스템은 지금 비워두고
# 가능성만 열어둔다. (예: 같은 전사 1등급 vs 3등급 → 스탯 차이)

@export var class_data: ClassData
@export_range(1, 3) var level: int = 1

# 자유 보정치 통 (예: {"element": "fire", "hp_bonus": 5, "atk_bonus": 1}).
# 스키마를 강제하지 않고, 시스템이 명확해지면 정식 필드로 승격한다.
@export var modifiers: Dictionary = {}

func get_max_hp() -> int:
	if class_data == null:
		return 0
	var v: int = class_data.base_max_hp + class_data.hp_per_level * (level - 1)
	return v + int(modifiers.get("hp_bonus", 0))

func get_attack() -> int:
	if class_data == null:
		return 0
	var v: int = class_data.base_atk + class_data.atk_per_level * (level - 1)
	return v + int(modifiers.get("atk_bonus", 0))

func get_defense() -> int:
	if class_data == null:
		return 0
	var v: int = class_data.base_def + class_data.def_per_level * (level - 1)
	return v + int(modifiers.get("def_bonus", 0))

func get_hit() -> int:
	if class_data == null:
		return 0
	return class_data.base_hit + int(modifiers.get("hit_bonus", 0))

func get_evasion() -> int:
	if class_data == null:
		return 0
	return class_data.base_evasion + int(modifiers.get("evasion_bonus", 0))

func get_crit_rate() -> int:
	if class_data == null:
		return 0
	return class_data.base_crit_rate + int(modifiers.get("crit_bonus", 0))
