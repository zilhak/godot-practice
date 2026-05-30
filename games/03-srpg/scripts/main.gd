extends Node2D

const UnitScript: Script = preload("res://scripts/unit.gd")

@onready var board: Node2D = $Board
@onready var grid: Grid = $Board/Grid
@onready var units_root: Node2D = $Board/Units

var units: Array[Unit] = []

func _ready() -> void:
	_spawn_initial_units()

func _spawn_initial_units() -> void:
	_spawn_unit("Knight", Unit.Team.PLAYER, Vector2i(0, 7), 12, 4, 4)
	_spawn_unit("Archer", Unit.Team.PLAYER, Vector2i(2, 7), 9, 5, 3)
	_spawn_unit("Goblin", Unit.Team.ENEMY, Vector2i(5, 0), 8, 3, 3)
	_spawn_unit("Orc", Unit.Team.ENEMY, Vector2i(7, 0), 14, 3, 4)

func _spawn_unit(name_: String, team: int, cell: Vector2i, max_hp: int, move_range: int, atk: int) -> Unit:
	var u: Unit = UnitScript.new() as Unit
	u.unit_name = name_
	u.team = team
	u.cell = cell
	u.max_hp = max_hp
	u.move_range = move_range
	u.attack_power = atk
	units_root.add_child(u)
	u.bind_grid(grid)
	units.append(u)
	return u
