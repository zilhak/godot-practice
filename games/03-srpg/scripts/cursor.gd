class_name Cursor
extends Node2D

const MOVE_INITIAL_DELAY: float = 0.25
const MOVE_REPEAT_DELAY: float = 0.08

@export var grid_path: NodePath
@export var color: Color = Color(1.0, 0.95, 0.2, 0.9)
@export var thickness: float = 3.0

var grid: Grid
var cell: Vector2i = Vector2i(0, 0)
var _move_timer: float = 0.0
var _last_dir: Vector2i = Vector2i.ZERO

func _ready() -> void:
	grid = get_node(grid_path) as Grid
	_snap_to_cell()

func _process(delta: float) -> void:
	_handle_keyboard(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse()

func _handle_keyboard(delta: float) -> void:
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("cursor_up"):
		dir.y -= 1
	if Input.is_action_pressed("cursor_down"):
		dir.y += 1
	if Input.is_action_pressed("cursor_left"):
		dir.x -= 1
	if Input.is_action_pressed("cursor_right"):
		dir.x += 1

	if dir == Vector2i.ZERO:
		_last_dir = Vector2i.ZERO
		_move_timer = 0.0
		return

	if dir != _last_dir:
		_try_move(dir)
		_last_dir = dir
		_move_timer = MOVE_INITIAL_DELAY
		return

	_move_timer -= delta
	if _move_timer <= 0.0:
		_try_move(dir)
		_move_timer = MOVE_REPEAT_DELAY

func _handle_mouse() -> void:
	var mouse_local: Vector2 = grid.to_local(get_global_mouse_position())
	var hover := grid.local_to_grid(mouse_local)
	if grid.in_bounds(hover) and hover != cell:
		cell = hover
		_snap_to_cell()

func _try_move(dir: Vector2i) -> void:
	var next := cell + dir
	if grid.in_bounds(next):
		cell = next
		_snap_to_cell()

func _snap_to_cell() -> void:
	position = grid.grid_to_local(cell)
	queue_redraw()

func _draw() -> void:
	var w := Grid.TILE_W / 2.0
	var h := Grid.TILE_H / 2.0
	var pts := PackedVector2Array([
		Vector2(0, -h),
		Vector2(w, 0),
		Vector2(0, h),
		Vector2(-w, 0),
		Vector2(0, -h),
	])
	draw_polyline(pts, color, thickness, true)
