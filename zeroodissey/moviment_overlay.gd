extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_movement_range(unit):
	movement_overlay.clear()

	var origin = world_to_tile(unit.global_position)
	var max_dist = unit.move_points

	for x in range(-max_dist, max_dist + 1):
		for y in range(-max_dist, max_dist + 1):
			var dist = abs(x) + abs(y)
			if dist <= max_dist:
				var tile = origin + Vector2i(x, y)

				if is_tile_walkable(tile):
					movement_overlay.set_cell(0, tile, 0, Vector2i.ZERO)


func is_tile_walkable(tile: Vector2i) -> bool:
	return tilemap.get_cell_source_id(0, tile) != -1
