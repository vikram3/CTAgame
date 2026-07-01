extends Node2D

@export var tile_map_layer: TileMapLayer
@export var enabled: bool = true
@export var line_color: Color = Color.YELLOW
@export var point_color: Color = Color.RED

func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()

func _draw() -> void:
	if not enabled or not tile_map_layer:
		return

	for coords in tile_map_layer.get_used_cells():
		var tile_data := tile_map_layer.get_cell_tile_data(coords)
		if not tile_data:
			continue

		var local_pos := tile_map_layer.map_to_local(coords)
		var sort_y := local_pos.y + tile_data.y_sort_origin

		var line_start := Vector2(local_pos.x - 16, sort_y)
		var line_end := Vector2(local_pos.x + 16, sort_y)
		draw_line(line_start, line_end, line_color, 1.5)
		draw_circle(Vector2(local_pos.x, sort_y), 2, point_color)
