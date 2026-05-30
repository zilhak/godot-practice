class_name MoveOverlay
extends Node2D

@export var grid_path: NodePath
@export var color: Color = Color(0.3, 0.65, 1.0, 0.35)
@export var border_color: Color = Color(0.5, 0.85, 1.0, 0.9)

var grid: Grid
var cells: Array[Vector2i] = []

func _ready() -> void:
	grid = get_node(grid_path) as Grid

func set_cells(new_cells: Array[Vector2i]) -> void:
	cells = new_cells
	queue_redraw()

func clear() -> void:
	cells = []
	queue_redraw()

func _draw() -> void:
	if grid == null:
		return
	var w := Grid.TILE_W / 2.0
	var h := Grid.TILE_H / 2.0
	for c in cells:
		var center := grid.grid_to_local(c)
		var pts := PackedVector2Array([
			center + Vector2(0, -h),
			center + Vector2(w, 0),
			center + Vector2(0, h),
			center + Vector2(-w, 0),
		])
		draw_colored_polygon(pts, color)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), border_color, 1.5, true)
