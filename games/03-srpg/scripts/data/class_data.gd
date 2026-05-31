class_name ClassData
extends Resource

# 병종 템플릿. 같은 병종을 가진 병사들은 이 베이스 스탯을 공유하고,
# 개별 차이는 TrooperData의 level / modifiers 에서 만들어진다.

enum AttackType { MELEE, RANGED, MAGIC }

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Base Stats")
@export var base_max_hp: int = 10
@export var base_atk: int = 3
@export var base_def: int = 0

@export_group("Combat")
@export var attack_type: AttackType = AttackType.MELEE
# 자기 열 기준 몇 열까지 때릴 수 있는지 (1=인접 열만, 3=후방에서도 전열까지)
@export_range(1, 3) var attack_range: int = 1

@export_group("Visuals")
@export var sprite: Texture2D
@export var icon: Texture2D

@export_group("Growth (per level above 1)")
@export var hp_per_level: int = 2
@export var atk_per_level: int = 1
@export var def_per_level: int = 0
