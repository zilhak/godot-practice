class_name CombatFormula
extends RefCounted

# 전투 수치 공식 모음. 모두 static.
#
# 명중률(%) = 100 - 적의 회피 + 나의 명중
# 데미지   = 나의 공격력 - 적의 방어력  (최소 0)
# 치명타   = 치명타율(%)로 판정, 발생 시 데미지 +50%

const CRIT_MULTIPLIER: float = 1.5

static func hit_chance(attacker: TrooperData, defender: TrooperData) -> int:
	if attacker == null or defender == null:
		return 0
	var v: int = 100 - defender.get_evasion() + attacker.get_hit()
	return clampi(v, 0, 100)

static func base_damage(attacker: TrooperData, defender: TrooperData) -> int:
	if attacker == null or defender == null:
		return 0
	return maxi(0, attacker.get_attack() - defender.get_defense())

# 치명타 적용 후 최종 데미지.
static func apply_crit(dmg: int, is_crit: bool) -> int:
	if not is_crit:
		return dmg
	return int(round(dmg * CRIT_MULTIPLIER))

# 한 번의 공격을 굴려서 결과를 반환한다.
# rng 를 주입받아 테스트/리플레이 시 결정론적으로 굴릴 수 있다.
# 반환: { "hit": bool, "crit": bool, "damage": int }
static func resolve_attack(attacker: TrooperData, defender: TrooperData, rng: RandomNumberGenerator) -> Dictionary:
	var hit_pct: int = hit_chance(attacker, defender)
	var roll: int = rng.randi_range(1, 100)
	if roll > hit_pct:
		return {"hit": false, "crit": false, "damage": 0}
	var crit_roll: int = rng.randi_range(1, 100)
	var is_crit: bool = crit_roll <= attacker.get_crit_rate()
	var dmg: int = apply_crit(base_damage(attacker, defender), is_crit)
	return {"hit": true, "crit": is_crit, "damage": dmg}
