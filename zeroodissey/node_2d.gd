extends Node2D

# --- MAPA ---
@onready var ground: TileMapLayer = $Map/Ground
@onready var overlay: TileMapLayer = $MovementOverlay/Overlay

# --- UNIDADES ---
@onready var units: Node2D = $Units
var selected_unit: PlayerUnit = null

# --- UI ---
@onready var context_menu: PopupMenu = $UI/UnitContextMenu

# --- ESTADO ---
enum UnitMode { NONE, MOVE }
var unit_mode: UnitMode = UnitMode.NONE

var turn_index: int = 0
var turn_order: Array[PlayerUnit] = []


# =========================
# READY
# =========================
func _ready() -> void:
	for node in units.get_children():
		var unit := node as PlayerUnit
		if unit:
			unit.unit_right_clicked.connect(_on_unit_right_clicked)
			turn_order.append(unit)

	start_turn()


# =========================
# TURNOS
# =========================
func start_turn() -> void:
	selected_unit = turn_order[turn_index]
	selected_unit.start_turn()
	select_unit(selected_unit)

func end_turn() -> void:
	overlay.clear()
	unit_mode = UnitMode.NONE
	selected_unit.set_selected(false)

	turn_index = (turn_index + 1) % turn_order.size()
	start_turn()


# =========================
# CLIQUE NA UNIDADE
# =========================
func _on_unit_right_clicked(unit: PlayerUnit, mouse_pos: Vector2) -> void:
	if unit != selected_unit:
		return

	context_menu.position = mouse_pos
	context_menu.popup()


# =========================
# MENU
# =========================
func _on_menu_option_selected(id: int) -> void:
	match id:
		0: # mover
			if selected_unit.can_move():
				enter_move_mode()
		1, 2: # ações
			selected_unit.finish_action()
			end_turn()
		3: # passar turno
			end_turn()


func enter_move_mode() -> void:
	unit_mode = UnitMode.MOVE
	show_movement_range(selected_unit)


# =========================
# INPUT GLOBAL
# =========================
func _unhandled_input(event: InputEvent) -> void:
	if unit_mode == UnitMode.MOVE:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				try_move_selected(event.position)


# =========================
# MOVIMENTO
# =========================
func try_move_selected(mouse_pos: Vector2) -> void:
	var target_tile := mouse_to_tile(mouse_pos)

	if overlay.get_cell_source_id(target_tile) == -1:
		return

	selected_unit.global_position = tile_to_world(target_tile)
	overlay.clear()

	selected_unit.finish_move()
	unit_mode = UnitMode.NONE


# =========================
# RANGE
# =========================
func show_movement_range(unit: PlayerUnit) -> void:
	overlay.clear()

	var origin := world_to_tile(unit.global_position)
	var max_dist := unit.move_points

	for x in range(-max_dist, max_dist + 1):
		for y in range(-max_dist, max_dist + 1):
			var dist := abs(x) + abs(y)
			if dist <= max_dist:
				var tile := origin + Vector2i(x, y)
				if is_tile_walkable(tile):
					overlay.set_cell(tile, 0, Vector2i.ZERO)


func is_tile_walkable(tile: Vector2i) -> bool:
	return ground.get_cell_source_id(tile) != -1


# =========================
# CONVERSÕES (IMPORTANTÍSSIMO)
# =========================
func mouse_to_tile(mouse_pos: Vector2) -> Vector2i:
	var world_pos := get_viewport().get_camera_2d().screen_to_world(mouse_pos)
	return ground.local_to_map(world_pos)

func world_to_tile(pos: Vector2) -> Vector2i:
	return ground.local_to_map(pos)

func tile_to_world(tile: Vector2i) -> Vector2:
	return ground.map_to_local(tile)


# =========================
# VISUAL
# =========================
func select_unit(unit: PlayerUnit) -> void:
	if selected_unit:
		selected_unit.set_selected(false)

	selected_unit = unit
	selected_unit.set_selected(true)
