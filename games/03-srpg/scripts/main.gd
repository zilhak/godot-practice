extends Node2D

const UnitScript: Script = preload("res://scripts/unit.gd")

enum State { IDLE, UNIT_SELECTED, MOVING }

@onready var board: Node2D = $Board
@onready var grid: Grid = $Board/Grid
@onready var cursor: Cursor = $Board/Cursor
@onready var move_overlay: MoveOverlay = $Board/MoveOverlay
@onready var units_root: Node2D = $Board/Units

var units: Array[Unit] = []
var state: int = State.IDLE
var selected_unit: Unit = null
var reachable_cells: Array[Vector2i] = []
var move_parents: Dictionary = {}

func _ready() -> void:
	_spawn_initial_units()

func _unhandled_input(event: InputEvent) -> void:
	if state == State.MOVING:
		return
	if event.is_action_pressed("confirm"):
		_on_confirm()
	elif event.is_action_pressed("cancel"):
		_on_cancel()

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

func unit_at(cell: Vector2i) -> Unit:
	for u in units:
		if u.cell == cell:
			return u
	return null

func _on_confirm() -> void:
	if state == State.IDLE:
		var u := unit_at(cursor.cell)
		if u != null and u.team == Unit.Team.PLAYER and not u.has_acted:
			_select_unit(u)
	elif state == State.UNIT_SELECTED:
		if cursor.cell in reachable_cells:
			_commit_move(cursor.cell)

func _on_cancel() -> void:
	if state == State.UNIT_SELECTED:
		_deselect_unit()

func _select_unit(u: Unit) -> void:
	selected_unit = u
	state = State.UNIT_SELECTED
	_compute_reachable(u)
	move_overlay.set_cells(reachable_cells)

func _deselect_unit() -> void:
	selected_unit = null
	state = State.IDLE
	reachable_cells = []
	move_parents = {}
	move_overlay.clear()

func _commit_move(target: Vector2i) -> void:
	var path := _build_path(selected_unit.cell, target)
	state = State.MOVING
	move_overlay.clear()
	var u := selected_unit
	u.move_finished.connect(_on_move_finished, CONNECT_ONE_SHOT)
	u.move_along(path)

func _on_move_finished() -> void:
	selected_unit = null
	reachable_cells = []
	move_parents = {}
	state = State.IDLE

func _build_path(from: Vector2i, to: Vector2i) -> Array:
	var rev: Array = [to]
	var cur := to
	while cur != from:
		if not move_parents.has(cur):
			break
		cur = move_parents[cur]
		rev.append(cur)
	rev.reverse()
	return rev

# 4방향 BFS — 이동력만큼 이동 가능한 셀 집합 (시작 셀 포함).
# 다른 유닛이 점유한 셀은 통과 불가, 단 시작 셀의 본인은 무시.
# 결과는 reachable_cells와 move_parents (셀 → 부모셀) 에 저장.
func _compute_reachable(unit: Unit) -> void:
	reachable_cells = []
	move_parents = {}
	var visited: Dictionary = {}
	var blocked: Dictionary = {}
	for other in units:
		if other != unit:
			blocked[other.cell] = true

	var queue: Array = [[unit.cell, 0]]
	visited[unit.cell] = true
	reachable_cells.append(unit.cell)

	while not queue.is_empty():
		var head: Array = queue.pop_front()
		var cur: Vector2i = head[0]
		var dist: int = head[1]
		if dist == unit.move_range:
			continue
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = cur + d
			if visited.has(n):
				continue
			if not grid.in_bounds(n):
				continue
			if blocked.has(n):
				continue
			visited[n] = true
			move_parents[n] = cur
			reachable_cells.append(n)
			queue.push_back([n, dist + 1])
