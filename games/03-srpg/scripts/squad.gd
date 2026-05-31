class_name Squad
extends Node2D

# 맵 한 칸을 차지하는 "캐릭터(=소대)". 9명까지의 병사를 가지고 있고
# 실제 데미지 계산은 전투 화면(추후)이 담당한다.
# 이 클래스는 맵 차원의 위치/이동/사상자 수만 다룬다.

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.PLAYER
@export var cell: Vector2i = Vector2i.ZERO
@export var character: CharacterData

var alive_count: int = 0
var max_alive: int = 0
var move_range: int = 0
var has_acted: bool = false
var grid: Grid

signal move_finished
signal died

const BODY_W: float = 36.0
const BODY_H: float = 44.0
const MOVE_TIME_PER_STEP: float = 0.12

func _ready() -> void:
	if character != null:
		max_alive = character.base_formation.size()
		alive_count = max_alive
		move_range = character.move_range
	_snap_to_cell()

func bind_grid(g: Grid) -> void:
	grid = g
	_snap_to_cell()

func display_name() -> String:
	return character.display_name if character != null else "Squad"

func _snap_to_cell() -> void:
	if grid != null:
		position = grid.grid_to_local(cell)
	queue_redraw()

func team_color() -> Color:
	var base: Color = Color(0.35, 0.55, 0.95) if team == Team.PLAYER else Color(0.9, 0.35, 0.35)
	if has_acted:
		return base.darkened(0.45)
	return base

func mark_acted() -> void:
	has_acted = true
	queue_redraw()

func clear_acted() -> void:
	has_acted = false
	queue_redraw()

func move_along(path: Array) -> void:
	if path.size() <= 1:
		return
	var tween := create_tween()
	for i in range(1, path.size()):
		var next_cell: Vector2i = path[i]
		var target := grid.grid_to_local(next_cell)
		tween.tween_property(self, "position", target, MOVE_TIME_PER_STEP)
	tween.tween_callback(_on_move_done.bind(path[path.size() - 1]))

func _on_move_done(final_cell: Vector2i) -> void:
	cell = final_cell
	move_finished.emit()

# 전투 화면이 만들어지기 전 placeholder. 추후 전투 결과를 반영하는 형태로 교체된다.
func take_casualties(count: int) -> void:
	alive_count = max(0, alive_count - count)
	queue_redraw()
	if alive_count == 0:
		died.emit()
		queue_free()

func _draw() -> void:
	var body_rect := Rect2(-BODY_W / 2.0, -BODY_H, BODY_W, BODY_H)
	draw_rect(body_rect, team_color(), true)
	draw_rect(body_rect, Color(0, 0, 0, 0.6), false, 1.5)

	var font: Font = ThemeDB.fallback_font
	var label_size: int = 12

	# 이름 + 생존자 수 한 줄
	var label: String = "%s (%d/%d)" % [display_name(), alive_count, max_alive]
	var label_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, label_size).x
	draw_string(font, Vector2(-label_w / 2.0, -BODY_H - 14), label,
		HORIZONTAL_ALIGNMENT_CENTER, -1, label_size, Color.WHITE)

	# 생존자 바
	var bar_w: float = BODY_W
	var bar_h: float = 3.0
	var bar_y: float = -BODY_H - 6
	var ratio: float = float(alive_count) / float(max_alive) if max_alive > 0 else 0.0
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.6), true)
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * ratio, bar_h), Color(0.3, 0.95, 0.3), true)
