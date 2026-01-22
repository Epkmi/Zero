extends Node2D

# =========================
# NODES
# =========================
@onready var camera: Camera2D = $Camera2D
@onready var units: Node2D = $Units
@onready var spawn_points: Node2D = $SpawnPoints
@onready var ground: TileMapLayer = $Map/Ground
@onready var context_menu: PopupMenu = $UI/UnitContextMenu
@onready var dice_display := $UI/DiceDisplay

# =========================
# ESTADO
# =========================
enum UnitMode { NONE, MOVE, ATTACK }
var unit_mode := UnitMode.NONE
var allowed_tiles: Array[Vector2i] = []

var turn_order: Array[Unit] = []
var selected_unit: Unit = null

var turn_index := 0

# =========================
# READY
# =========================
func _ready() -> void:
	camera.make_current()
	collect_units()
	place_units_on_spawn()
	print_turn_order()

	context_menu.id_pressed.connect(_on_menu_option_selected)

	if turn_order.size() > 0:
		start_turn()

# =========================
# SETUP
# =========================
func collect_units() -> void:
	turn_order.clear()

	for node in units.get_children():
		if node is Unit:
			var unit := node as Unit
			turn_order.append(unit)
			unit.unit_right_clicked.connect(_on_unit_right_clicked)


func place_units_on_spawn() -> void:
	var spawns := spawn_points.get_children()

	for i in range(min(spawns.size(), turn_order.size())):
		turn_order[i].global_position = snap_to_grid(spawns[i].global_position)

func print_turn_order() -> void:
	print("===== TURN ORDER =====")
	for u in turn_order:
		print(u.name, " | ID:", u.get_instance_id())
	print("======================")

# =========================
# TURNOS
# =========================
func start_turn() -> void:
	selected_unit = turn_order[turn_index]
	selected_unit.start_turn()
	select_unit(selected_unit)
	print("INÍCIO DO TURNO:", selected_unit.name)
	var tile := world_to_tile(selected_unit.global_position)
	print("UNIT TILE:", tile)
	print("UNIT WORLD:", selected_unit.global_position)
	print("TILE WORLD:", tile_to_world(tile))


func end_turn():
	$MovementOverlay.clear()
	allowed_tiles.clear()
	unit_mode = UnitMode.NONE

	selected_unit.set_selected(false)

	turn_index = (turn_index + 1) % turn_order.size()
	start_turn()


# =========================
# SELEÇÃO
# =========================
func select_unit(unit: Unit) -> void:
	if selected_unit:
		selected_unit.set_selected(false)

	selected_unit = unit
	selected_unit.set_selected(true)

# =========================
# MENU
# =========================
func _on_unit_right_clicked(unit: Unit, mouse_pos: Vector2) -> void:
	if unit != selected_unit:
		return

	context_menu.position = mouse_pos
	context_menu.popup()

func _on_menu_option_selected(id: int) -> void:
	match id:
		0: enter_move_mode()
		1: enter_attack_mode()
		2:
			selected_unit.finish_action()
			end_turn()
		3:
			selected_unit.force_end_turn()
			end_turn()

func enter_move_mode():
	if not selected_unit.can_move():
		return

	unit_mode = UnitMode.MOVE
	allowed_tiles = get_movable_tiles(selected_unit)

	$MovementOverlay.show_tiles(
	allowed_tiles,
	ground,
	Color(0, 0.6, 1, 0.4)
)




func enter_attack_mode() -> void:
	if not selected_unit.can_act():
		return

	unit_mode = UnitMode.ATTACK

	var origin := world_to_tile(selected_unit.global_position)
	var tiles := selected_unit.get_attack_tiles(origin)

	$MovementOverlay.show_tiles(
	tiles,
	ground,
	Color(1, 0.2, 0.2, 0.4)
)




# =========================
# INPUT GLOBAL
# =========================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# BOTÃO DIREITO → MENU OU CÂMERA
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if _clicked_on_ui():
				return
			if _clicked_on_unit():
				return

			# clique limpo no mapa
			camera.pan_to(get_global_mouse_position())

		# BOTÃO ESQUERDO → AÇÕES
		if event.button_index == MOUSE_BUTTON_LEFT:
			if unit_mode == UnitMode.MOVE:
				move_selected_to_mouse()
			elif unit_mode == UnitMode.ATTACK:
				try_attack_at_mouse()


func _clicked_on_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null

func _clicked_on_unit() -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true

	for hit in space.intersect_point(query):
		if hit.collider is Area2D:
			return true

	return false

# =========================
# MOVIMENTO
# =========================
func move_selected_to_mouse():
	if not selected_unit.can_move():
		return

	var tile := world_to_tile(get_global_mouse_position())

	if tile not in allowed_tiles:
		print("Tile fora do alcance")
		return

	selected_unit.global_position = tile_to_world(tile)
	selected_unit.finish_move()
	$MovementOverlay.clear()
	allowed_tiles.clear()
	unit_mode = UnitMode.NONE




func get_movable_tiles(unit: Unit) -> Array[Vector2i]:
	var origin := world_to_tile(unit.global_position)
	var result: Array[Vector2i] = []

	for x in range(-unit.move_points, unit.move_points + 1):
		for y in range(-unit.move_points, unit.move_points + 1):
			var dist: int = abs(x) + abs(y)
			if dist > unit.move_points:
				continue

			var tile := origin + Vector2i(x, y)
			if is_tile_walkable(tile):
				result.append(tile)

	return result


# =========================
# ATAQUE
# =========================
func try_attack_at_mouse() -> void:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	
	
	
	for hit in space.intersect_point(query):
		var collider = hit["collider"]
		if collider is Area2D:
			var target = collider.get_parent()
			if target is Unit and target != selected_unit:
				var roll := selected_unit.attack(
				target,
				world_to_tile(selected_unit.global_position),
				world_to_tile(target.global_position)
				)
				if roll != -1:
					dice_display.set_roll(roll)

				$MovementOverlay.clear()
				unit_mode = UnitMode.NONE

# só encerra se a própria Unit disser que acabou
				if selected_unit.turn_state == Unit.TurnState.TURN_DONE:
					end_turn()

				return
	

func _on_unit_died(unit: Unit) -> void:
	print("REMOVENDO DA TURN ORDER:", unit.name)

	var index := turn_order.find(unit)
	if index != -1:
		turn_order.remove_at(index)

	# Ajusta índice do turno
	if index <= turn_index and turn_index > 0:
		turn_index -= 1

	# Se morreu durante o turno atual
	if unit == selected_unit:
		if turn_order.size() > 0:
			turn_index %= turn_order.size()
			start_turn()


# =========================
# TILEMAP
# =========================
func world_to_tile(world_pos: Vector2) -> Vector2i:
	var local := ground.to_local(world_pos)
	var half := Vector2(ground.tile_set.tile_size) / 2.0
	return ground.local_to_map(local - half)


func tile_to_world(tile: Vector2i) -> Vector2:
	var pos: Vector2 = ground.map_to_local(tile)
	var half: Vector2 = Vector2(ground.tile_set.tile_size) / 2.0
	return ground.to_global(pos + half)




func snap_to_grid(world_pos: Vector2) -> Vector2:
	return tile_to_world(world_to_tile(world_pos))

func is_tile_walkable(tile: Vector2i) -> bool:
	return ground.get_cell_source_id(tile) != -1
