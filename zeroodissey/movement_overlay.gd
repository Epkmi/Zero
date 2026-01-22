extends Node2D

var tiles: Array[Vector2i] = []
var tilemap: TileMapLayer
var color := Color.WHITE

func _ready():
	z_index = 10

func show_tiles(new_tiles: Array[Vector2i], map: TileMapLayer, c: Color) -> void:
	tiles = new_tiles
	tilemap = map
	color = c
	queue_redraw()

func clear() -> void:
	tiles.clear()
	queue_redraw()

func _draw() -> void:
	if tilemap == null:
		return

	var tile_size := tilemap.tile_set.tile_size

	for tile in tiles:
		# posição WORLD do CANTO da tile
		var world_pos := tilemap.to_global(tilemap.map_to_local(tile))

		# converte para espaço do overlay
		var local_pos := to_local(world_pos)

		draw_rect(
			Rect2(local_pos, tile_size),
			color
		)
