class_name Grid
extends Node2D

const TILE_W: int = 64
const TILE_H: int = 32

@export var cols: int = 8
@export var rows: int = 8

@export var color_a: Color = Color(0.22, 0.34, 0.22)
@export var color_b: Color = Color(0.28, 0.42, 0.28)
@export var line_color: Color = Color(0, 0, 0, 0.35)

func grid_to_local(cell: Vector2i) -> Vector2:
	var x := (cell.x - cell.y) * (TILE_W / 2.0)
	var y := (cell.x + cell.y) * (TILE_H / 2.0)
	return Vector2(x, y)

func local_to_grid(local_pos: Vector2) -> Vector2i:
	var gx := local_pos.x / (TILE_W / 2.0)
	var gy := local_pos.y / (TILE_H / 2.0)
	var cx := int(floor((gx + gy) / 2.0))
	var cy := int(floor((gy - gx) / 2.0))
	return Vector2i(cx, cy)

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < cols and cell.y >= 0 and cell.y < rows

func _diamond_points(cell: Vector2i) -> PackedVector2Array:
	var c := grid_to_local(cell)
	return PackedVector2Array([
		c + Vector2(0, -TILE_H / 2.0),
		c + Vector2(TILE_W / 2.0, 0),
		c + Vector2(0, TILE_H / 2.0),
		c + Vector2(-TILE_W / 2.0, 0),
	])

func _draw() -> void:
	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			var pts := _diamond_points(cell)
			var fill := color_a if (x + y) % 2 == 0 else color_b
			draw_colored_polygon(pts, fill)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), line_color, 1.0, true)
