class_name Unit
extends Node2D

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.PLAYER
@export var cell: Vector2i = Vector2i.ZERO
@export var unit_name: String = "Unit"
@export var max_hp: int = 10
@export var move_range: int = 4
@export var attack_power: int = 3

var hp: int = 10

const BODY_W: float = 28.0
const BODY_H: float = 38.0

var grid: Grid

func _ready() -> void:
	hp = max_hp
	_snap_to_cell()

func bind_grid(g: Grid) -> void:
	grid = g
	_snap_to_cell()

func _snap_to_cell() -> void:
	if grid != null:
		position = grid.grid_to_local(cell)
	queue_redraw()

func team_color() -> Color:
	if team == Team.PLAYER:
		return Color(0.35, 0.55, 0.95)
	return Color(0.9, 0.35, 0.35)

func _draw() -> void:
	# 본체: 셀 중앙 위에 세워둔 직사각형 (발은 셀 중앙)
	var body_rect := Rect2(-BODY_W / 2.0, -BODY_H, BODY_W, BODY_H)
	draw_rect(body_rect, team_color(), true)
	draw_rect(body_rect, Color(0, 0, 0, 0.6), false, 1.5)

	# 머리
	var head_center := Vector2(0, -BODY_H - 6)
	draw_circle(head_center, 6.0, team_color())
	draw_arc(head_center, 6.0, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.5, true)

	# HP 바
	var bar_w := BODY_W
	var bar_h := 3.0
	var bar_y := -BODY_H - 18
	var ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.6), true)
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * ratio, bar_h), Color(0.3, 0.95, 0.3), true)
