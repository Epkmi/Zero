extends CharacterBody2D
class_name Unit

signal unit_right_clicked(unit: Unit, mouse_pos: Vector2)
signal died(unit: Unit)


@export var max_hp := 10
@export var damage := 3
@export var armor_class := 10
@export var attack_range := 1
@export var move_points := 6

var current_hp := 0

enum TurnState {
	CAN_MOVE_AND_ACT,
	TURN_DONE
}
var turn_state := TurnState.CAN_MOVE_AND_ACT

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar := $HealthBar

var has_moved := false
var has_acted := false


func _ready() -> void:
	current_hp = max_hp
	area.input_event.connect(_on_area_input)
	health_bar.set_health(current_hp, max_hp)


func _on_area_input(viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		unit_right_clicked.emit(self, event.global_position)

func set_selected(value: bool) -> void:
	sprite.modulate = Color.YELLOW if value else Color.WHITE

func start_turn() -> void:
	has_moved = false
	has_acted = false
	turn_state = TurnState.CAN_MOVE_AND_ACT


func can_move() -> bool:
	return not has_moved

func can_act() -> bool:
	return not has_acted


func finish_move() -> void:
	has_moved = true
	check_end_turn()

func get_attack_tiles(origin: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []

	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			if x == 0 and y == 0:
				continue

			var dx : int = abs(x)
			var dy : int = abs(y)

			if attack_range == 1:
				if max(dx, dy) == 1:
					tiles.append(origin + Vector2i(x, y))
			else:
				if dx + dy <= attack_range:
					tiles.append(origin + Vector2i(x, y))

	return tiles



func finish_action() -> void:
	has_acted = true
	check_end_turn()


func check_end_turn() -> void:
	if has_moved and has_acted:
		turn_state = TurnState.TURN_DONE


func force_end_turn() -> void:
	turn_state = TurnState.TURN_DONE

func is_in_attack_range(a: Vector2i, b: Vector2i) -> bool:
	var dx : int = abs(a.x - b.x)
	var dy : int = abs(a.y - b.y)

	if attack_range == 1:
		# inclui diagonais
		return max(dx, dy) == 1

	# range > 1 mantém lógica antiga (manhattan)
	return dx + dy <= attack_range




func attack(target: Unit, attacker_tile: Vector2i, target_tile: Vector2i) -> int:
	if not can_act():
		return -1

	if not is_in_attack_range(attacker_tile, target_tile):
		print("Alvo fora do alcance (range:", attack_range, ")")
		return -1

	var roll: int = randi_range(1, 20)
	print(name, " rolou D20:", roll, " contra CA:", target.armor_class)

	var final_damage := damage

	if roll == 20:
		final_damage *= 2

	if roll >= target.armor_class:
		target.receive_damage(final_damage)
		print("ACERTO!")
	else:
		print("ERRO!")

	has_acted = true
	check_end_turn()

	return roll

func receive_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = max(current_hp, 0)

	health_bar.set_health(current_hp, max_hp)

	print(name, " HP:", current_hp)

	if current_hp <= 0:
		die()

func die() -> void:
	died.emit(self)
	queue_free()
