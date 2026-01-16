extends Node2D

# =========================
# UNIDADES
# =========================
@onready var units: Node2D = $Units
var selected_unit: PlayerUnit = null

@onready var camera: Camera2D = $Camera2D
@onready var spawn_points: Node2D = $SpawnPoints
@export var player_unit_scene: PackedScene
@onready var ground: TileMapLayer = $Map/Ground

# =========================
# UI
# =========================
@onready var context_menu: PopupMenu = $UI/UnitContextMenu

# =========================
# ESTADO
# =========================
enum UnitMode { NONE, MOVE, ATTACK }
var unit_mode: UnitMode = UnitMode.NONE


var turn_index: int = 0
var turn_order: Array[PlayerUnit] = []

# =========================
# READY
# =========================
func _ready() -> void:
	camera.make_current()

	# 1️⃣ Monta ordem de turnos
	for node in units.get_children():
		var unit := node as PlayerUnit
		if unit:
			turn_order.append(unit)
			unit.unit_right_clicked.connect(_on_unit_right_clicked)

	# 2️⃣ Aplica spawn points
	var spawn_list := spawn_points.get_children()

	for i in range(min(spawn_list.size(), turn_order.size())):
		var unit := turn_order[i]
		unit.global_position = snap_to_grid(spawn_list[i].global_position)

	context_menu.id_pressed.connect(_on_menu_option_selected)

	# 3️⃣ Inicia turno
	if turn_order.size() > 0:
		start_turn()




# =========================
# TURNOS
# =========================
func start_turn() -> void:
	unit_mode = UnitMode.NONE
	selected_unit = turn_order[turn_index]
	selected_unit.start_turn()
	select_unit(selected_unit)

func end_turn() -> void:
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

func enter_attack_mode() -> void:
	if not selected_unit.can_act():
		return

	unit_mode = UnitMode.ATTACK


# =========================
# MENU
# =========================
func _on_menu_option_selected(id: int) -> void:
	match id:
		0:
			enter_move_mode()
		1:
			enter_attack_mode()
		2:
			selected_unit.finish_action()
			end_turn()
		3:
			end_turn()



func enter_move_mode() -> void:
	if not selected_unit.can_move():
		return

	unit_mode = UnitMode.MOVE

# =========================
# INPUT GLOBAL
# =========================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if unit_mode == UnitMode.MOVE:
				move_selected_to_mouse()

			elif unit_mode == UnitMode.ATTACK:
				try_attack_at_mouse()


# =========================
# MOVIMENTO (GODOT 4 CORRETO)
# =========================
func move_selected_to_mouse() -> void:
	if selected_unit == null:
		return

	var tile := world_to_tile(get_global_mouse_position())

	# Validação básica
	if not is_tile_walkable(tile):
		return

	selected_unit.global_position = tile_to_world(tile)
	selected_unit.finish_move()
	unit_mode = UnitMode.NONE


# =========================
# VISUAL
# =========================
func select_unit(unit: PlayerUnit) -> void:
	if selected_unit:
		selected_unit.set_selected(false)

	selected_unit = unit
	selected_unit.set_selected(true)
	
func try_attack_at_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	var space := get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true

	var result: Array = space.intersect_point(query)

	for hit: Dictionary in result:
		var collider: Object = hit["collider"]

		if collider is Area2D:
			var unit: Node = collider.get_parent()

			if unit is PlayerUnit and unit != selected_unit:
				selected_unit.attack(unit)
				unit_mode = UnitMode.NONE
			return
			
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(world_pos))

func tile_to_world(tile: Vector2i) -> Vector2:
	return ground.map_to_local(tile)
	
func snap_to_grid(world_pos: Vector2) -> Vector2:
	var tile := world_to_tile(world_pos)
	return tile_to_world(tile)

func is_tile_walkable(tile: Vector2i) -> bool:
	return ground.get_cell_source_id(tile) != -1
