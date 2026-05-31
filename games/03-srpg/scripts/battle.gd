extends Node2D

const SquadScript: Script = preload("res://scripts/squad.gd")

const CHARACTER_PATHS := {
	"test1": "res://data/characters/test1.tres",
	"test2": "res://data/characters/test2.tres",
	"test_enemy1": "res://data/characters/test_enemy1.tres",
	"test_enemy2": "res://data/characters/test_enemy2.tres",
}

enum State { IDLE, UNIT_SELECTED, MOVING, AWAITING_ACTION, AWAITING_ATTACK, ENEMY_THINKING, GAME_OVER }
enum Phase { PLAYER, ENEMY }

@onready var board: Node2D = $Board
@onready var grid: Grid = $Board/Grid
@onready var cursor: Cursor = $Board/Cursor
@onready var move_overlay: MoveOverlay = $Board/MoveOverlay
@onready var attack_overlay: MoveOverlay = $Board/AttackOverlay
@onready var squads_root: Node2D = $Board/Squads
@onready var hud_phase_label: Label = $HUD/PhaseLabel
@onready var hud_hint_label: Label = $HUD/HintLabel
@onready var action_menu: PanelContainer = $HUD/ActionMenu
@onready var attack_button: Button = $HUD/ActionMenu/VBox/AttackButton
@onready var wait_button: Button = $HUD/ActionMenu/VBox/WaitButton
@onready var result_panel: Control = $HUD/ResultPanel
@onready var result_title: Label = $HUD/ResultPanel/Title
@onready var result_hint: Label = $HUD/ResultPanel/Hint

var squads: Array[Squad] = []
var state: int = State.IDLE
var phase: int = Phase.PLAYER
var turn_number: int = 1
var selected_squad: Squad = null
var reachable_cells: Array[Vector2i] = []
var move_parents: Dictionary = {}
var attack_targets: Array[Vector2i] = []
var attackable_enemy_cells: Array[Vector2i] = []
var pending_squad: Squad = null
var pending_attack_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	attack_button.pressed.connect(_on_attack_button_pressed)
	wait_button.pressed.connect(_on_wait_button_pressed)
	_spawn_initial_squads()
	_begin_player_phase()

func _unhandled_input(event: InputEvent) -> void:
	if state == State.GAME_OVER:
		if event.is_action_pressed("confirm") or _is_mouse_left_pressed(event):
			get_tree().reload_current_scene()
		return
	if state == State.MOVING or state == State.ENEMY_THINKING:
		return
	if state == State.AWAITING_ACTION:
		if event.is_action_pressed("cancel"):
			_on_wait_button_pressed()
		return
	if phase != Phase.PLAYER:
		return
	if event.is_action_pressed("end_turn"):
		_end_player_phase()
	elif event.is_action_pressed("confirm") or _is_mouse_left_pressed(event):
		_on_confirm()
	elif event.is_action_pressed("cancel") or _is_mouse_right_pressed(event):
		_on_cancel()

func _is_mouse_left_pressed(event: InputEvent) -> bool:
	return event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed

func _is_mouse_right_pressed(event: InputEvent) -> bool:
	return event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_RIGHT \
		and event.pressed

func _spawn_initial_squads() -> void:
	_spawn_squad("test1", Squad.Team.PLAYER, Vector2i(0, 7))
	_spawn_squad("test2", Squad.Team.PLAYER, Vector2i(2, 7))
	_spawn_squad("test_enemy1", Squad.Team.ENEMY, Vector2i(5, 0))
	_spawn_squad("test_enemy2", Squad.Team.ENEMY, Vector2i(7, 0))

func _spawn_squad(char_id: String, team: Squad.Team, cell: Vector2i) -> Squad:
	var c: CharacterData = load(CHARACTER_PATHS[char_id]) as CharacterData
	var s: Squad = SquadScript.new() as Squad
	s.character = c
	s.team = team
	s.cell = cell
	squads_root.add_child(s)
	s.bind_grid(grid)
	squads.append(s)
	return s

func squad_at(cell: Vector2i) -> Squad:
	for s in squads:
		if s.cell == cell:
			return s
	return null

func _on_confirm() -> void:
	if state == State.IDLE:
		var u := squad_at(cursor.cell)
		if u != null and u.team == Squad.Team.PLAYER and not u.has_acted:
			_select_squad(u)
	elif state == State.UNIT_SELECTED:
		if cursor.cell in reachable_cells:
			_commit_move(cursor.cell)
		elif cursor.cell in attackable_enemy_cells:
			_commit_move_then_attack(cursor.cell)
	elif state == State.AWAITING_ATTACK:
		if cursor.cell in attack_targets:
			_commit_attack(cursor.cell)
		elif cursor.cell == pending_squad.cell:
			_finish_action()

func _on_cancel() -> void:
	if state == State.UNIT_SELECTED:
		_deselect_squad()
	elif state == State.AWAITING_ATTACK:
		_finish_action()

func _select_squad(u: Squad) -> void:
	selected_squad = u
	state = State.UNIT_SELECTED
	_compute_reachable(u)
	_compute_attackable_enemies(u)
	move_overlay.set_cells(reachable_cells)
	attack_overlay.set_cells(attackable_enemy_cells)

func _deselect_squad() -> void:
	selected_squad = null
	state = State.IDLE
	reachable_cells = []
	move_parents = {}
	attackable_enemy_cells = []
	move_overlay.clear()
	attack_overlay.clear()

# UNIT_SELECTED 상태에서 빨간색으로 표시할 적 셀들.
# reachable 셀에서 인접한 적 셀 + 본인 시작 위치에서 인접한 적 셀.
func _compute_attackable_enemies(unit: Squad) -> void:
	attackable_enemy_cells = []
	var seen: Dictionary = {}
	for c in reachable_cells:
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			var v := squad_at(n)
			if v != null and v.team != unit.team:
				seen[n] = true
				attackable_enemy_cells.append(n)

func _commit_move(target: Vector2i) -> void:
	move_overlay.clear()
	attack_overlay.clear()
	if target == selected_squad.cell:
		_on_move_finished()
		return
	state = State.MOVING
	var u := selected_squad
	u.move_finished.connect(_on_move_finished, CONNECT_ONE_SHOT)
	u.move_along(_build_path(u.cell, target))

# 적 셀을 직접 지정 → 인접 reachable 셀로 이동 후 자동 공격.
func _commit_move_then_attack(enemy_cell: Vector2i) -> void:
	var stand: Vector2i = _best_stand_cell_for_attack(selected_squad, enemy_cell)
	pending_attack_cell = enemy_cell
	_commit_move(stand)

func _best_stand_cell_for_attack(unit: Squad, enemy_cell: Vector2i) -> Vector2i:
	# 인접 후보들 중 reachable이면서 이동 비용이 가장 짧은 셀.
	var best: Vector2i = unit.cell
	var best_cost: int = 1_000_000
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var c: Vector2i = enemy_cell + d
		if not (c in reachable_cells):
			continue
		var cost: int = _build_path(unit.cell, c).size() - 1
		if cost < best_cost:
			best_cost = cost
			best = c
	return best

func _on_move_finished() -> void:
	pending_squad = selected_squad
	selected_squad = null
	reachable_cells = []
	move_parents = {}
	attackable_enemy_cells = []
	if pending_attack_cell != Vector2i(-1, -1):
		var target_cell := pending_attack_cell
		pending_attack_cell = Vector2i(-1, -1)
		_commit_attack(target_cell)
		return
	_show_action_menu()

func _show_action_menu() -> void:
	attack_targets = _find_attack_targets(pending_squad)
	state = State.AWAITING_ACTION
	attack_button.disabled = attack_targets.is_empty()
	_position_action_menu()
	action_menu.visible = true
	if not attack_button.disabled:
		attack_button.grab_focus()
	else:
		wait_button.grab_focus()

func _position_action_menu() -> void:
	# 메뉴 크기가 아직 0일 수 있으므로 한 프레임 대기 후 위치 보정.
	action_menu.position = Vector2.ZERO
	action_menu.reset_size()
	var unit_screen: Vector2 = board.global_position + grid.grid_to_local(pending_squad.cell)
	var menu_size: Vector2 = action_menu.size
	if menu_size == Vector2.ZERO:
		menu_size = Vector2(140, 80)
	var target: Vector2 = unit_screen + Vector2(Grid.TILE_W / 2.0 + 8.0, -menu_size.y / 2.0)
	var vp: Vector2 = get_viewport_rect().size
	# 오른쪽 화면 밖이면 유닛 왼쪽으로 띄움.
	if target.x + menu_size.x > vp.x - 8.0:
		target.x = unit_screen.x - Grid.TILE_W / 2.0 - 8.0 - menu_size.x
	target.x = clampf(target.x, 8.0, vp.x - menu_size.x - 8.0)
	target.y = clampf(target.y, 8.0, vp.y - menu_size.y - 8.0)
	action_menu.position = target

func _hide_action_menu() -> void:
	action_menu.visible = false

func _on_attack_button_pressed() -> void:
	if state != State.AWAITING_ACTION:
		return
	_hide_action_menu()
	_enter_attack_selection()

func _on_wait_button_pressed() -> void:
	if state != State.AWAITING_ACTION:
		return
	_hide_action_menu()
	_finish_action()

func _enter_attack_selection() -> void:
	attack_targets = _find_attack_targets(pending_squad)
	if attack_targets.is_empty():
		_finish_action()
		return
	# 인접 적이 1명이면 선택 메뉴 생략하고 자동 공격.
	if attack_targets.size() == 1:
		_commit_attack(attack_targets[0])
		return
	state = State.AWAITING_ATTACK
	attack_overlay.set_cells(attack_targets)
	cursor.cell = attack_targets[0]
	cursor._snap_to_cell()

func _find_attack_targets(unit: Squad) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var c: Vector2i = unit.cell + d
		var v := squad_at(c)
		if v != null and v.team != unit.team:
			out.append(c)
	return out

func _commit_attack(target_cell: Vector2i) -> void:
	var target := squad_at(target_cell)
	if target == null:
		return
	# TODO: 전투 화면 진입 → 결과 반영. 지금은 placeholder로 1명만 사상자 처리.
	target.take_casualties(1)
	if target.alive_count == 0:
		squads.erase(target)
	_finish_action()

func _finish_action() -> void:
	attack_targets = []
	pending_attack_cell = Vector2i(-1, -1)
	attack_overlay.clear()
	_hide_action_menu()
	if pending_squad != null and is_instance_valid(pending_squad):
		pending_squad.mark_acted()
	pending_squad = null
	state = State.IDLE
	if _check_game_end():
		return
	_check_phase_end()

func _check_phase_end() -> void:
	if phase == Phase.PLAYER and _all_acted(Squad.Team.PLAYER):
		_end_player_phase()
	elif phase == Phase.ENEMY and _all_acted(Squad.Team.ENEMY):
		_end_enemy_phase()

func _all_acted(team: int) -> bool:
	for u in squads:
		if u.team == team and not u.has_acted:
			return false
	return true

func _team_squads(team: int) -> Array[Squad]:
	var out: Array[Squad] = []
	for u in squads:
		if u.team == team:
			out.append(u)
	return out

func _begin_player_phase() -> void:
	phase = Phase.PLAYER
	state = State.IDLE
	for u in squads:
		u.clear_acted()
	_update_hud()

func _end_player_phase() -> void:
	if state == State.UNIT_SELECTED:
		_deselect_squad()
	_begin_enemy_phase()

func _begin_enemy_phase() -> void:
	phase = Phase.ENEMY
	state = State.ENEMY_THINKING
	for u in squads:
		u.clear_acted()
	_update_hud()
	await _run_enemy_turns()
	if state == State.GAME_OVER:
		return
	_end_enemy_phase()

func _run_enemy_turns() -> void:
	for enemy in _team_squads(Squad.Team.ENEMY):
		if not is_instance_valid(enemy):
			continue
		await get_tree().create_timer(0.3).timeout
		await _ai_take_turn(enemy)
		if is_instance_valid(enemy):
			enemy.mark_acted()
		if _check_game_end():
			return

func _ai_take_turn(enemy: Squad) -> void:
	var targets := _team_squads(Squad.Team.PLAYER)
	if targets.is_empty():
		return

	var r := _bfs_reachable(enemy)
	var reach: Array = r.cells
	var parents: Dictionary = r.parents

	# 이동 후 가장 가까운 아군과의 맨해튼 거리가 최소가 되는 셀.
	# 동률이면 출발 셀에서의 BFS 거리가 짧은 쪽 (이동 적게).
	var best_cell: Vector2i = enemy.cell
	var best_score: int = 1_000_000
	for c in reach:
		var nearest_d: int = 1_000_000
		for t in targets:
			var d: int = absi(c.x - t.cell.x) + absi(c.y - t.cell.y)
			if d < nearest_d:
				nearest_d = d
		var move_cost: int = _build_path_with(parents, enemy.cell, c).size() - 1
		var score: int = nearest_d * 100 + move_cost
		if score < best_score:
			best_score = score
			best_cell = c

	if best_cell != enemy.cell:
		var path := _build_path_with(parents, enemy.cell, best_cell)
		enemy.move_along(path)
		await enemy.move_finished

	# 인접 아군 공격 (placeholder, 전투 화면 도입 시 교체)
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var c: Vector2i = enemy.cell + d
		var v := squad_at(c)
		if v != null and v.team == Squad.Team.PLAYER:
			v.take_casualties(1)
			if v.alive_count == 0:
				squads.erase(v)
			break

func _end_enemy_phase() -> void:
	turn_number += 1
	_begin_player_phase()

func _check_game_end() -> bool:
	var players_alive: int = _team_squads(Squad.Team.PLAYER).size()
	var enemies_alive: int = _team_squads(Squad.Team.ENEMY).size()
	if enemies_alive == 0:
		_show_result(true)
		return true
	if players_alive == 0:
		_show_result(false)
		return true
	return false

func _show_result(victory: bool) -> void:
	state = State.GAME_OVER
	if result_panel == null:
		return
	result_title.text = "VICTORY" if victory else "DEFEAT"
	result_title.add_theme_color_override("font_color",
		Color(0.95, 0.85, 0.3) if victory else Color(0.95, 0.4, 0.4))
	result_hint.text = "Press Space / Enter to restart"
	result_panel.visible = true

func _update_hud() -> void:
	if hud_phase_label == null:
		return
	var phase_text := "Player Phase" if phase == Phase.PLAYER else "Enemy Phase"
	hud_phase_label.text = "Turn %d — %s" % [turn_number, phase_text]
	hud_hint_label.text = "좌클릭/Space:선택·확정   우클릭/Esc:취소   F6:턴 종료"

func _build_path(from: Vector2i, to: Vector2i) -> Array:
	return _build_path_with(move_parents, from, to)

# 4방향 BFS — 이동력만큼 이동 가능한 셀 집합 (시작 셀 포함).
# 다른 유닛이 점유한 셀은 통과 불가, 단 시작 셀의 본인은 무시.
# 결과는 reachable_cells와 move_parents (셀 → 부모셀) 에 저장.
func _compute_reachable(unit: Squad) -> void:
	var r := _bfs_reachable(unit)
	reachable_cells = r.cells
	move_parents = r.parents

func _bfs_reachable(unit: Squad) -> Dictionary:
	var cells: Array[Vector2i] = []
	var parents: Dictionary = {}
	var visited: Dictionary = {}
	var blocked: Dictionary = {}
	for other in squads:
		if other != unit:
			blocked[other.cell] = true

	var queue: Array = [[unit.cell, 0]]
	visited[unit.cell] = true
	cells.append(unit.cell)

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
			parents[n] = cur
			cells.append(n)
			queue.push_back([n, dist + 1])
	return {"cells": cells, "parents": parents}

func _build_path_with(parents: Dictionary, from: Vector2i, to: Vector2i) -> Array:
	var rev: Array = [to]
	var cur := to
	while cur != from:
		if not parents.has(cur):
			break
		cur = parents[cur]
		rev.append(cur)
	rev.reverse()
	return rev
