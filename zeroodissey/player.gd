extends CharacterBody2D
class_name PlayerUnit

signal unit_right_clicked(unit: PlayerUnit, mouse_pos: Vector2)
signal died(unit: PlayerUnit)

# =========================
# STATS
# =========================
@export var max_hp: int = 10
@export var damage: int = 3
@export var move_points: int = 6

var current_hp: int

# =========================
# TURNO
# =========================
enum TurnState {
	CAN_MOVE,
	CAN_ACT,
	TURN_DONE
}

var turn_state: TurnState = TurnState.CAN_MOVE

# =========================
# NODES
# =========================
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

# =========================
# READY
# =========================
func _ready() -> void:
	current_hp = max_hp
	area.input_event.connect(_on_area_input)

# =========================
# INPUT NA UNIDADE
# =========================
func _on_area_input(viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			unit_right_clicked.emit(self, event.global_position)

# =========================
# VISUAL
# =========================
func set_selected(value: bool) -> void:
	sprite.modulate = Color.YELLOW if value else Color.WHITE

# =========================
# TURNO
# =========================
func start_turn() -> void:
	turn_state = TurnState.CAN_MOVE

func can_move() -> bool:
	return turn_state == TurnState.CAN_MOVE

func can_act() -> bool:
	return turn_state == TurnState.CAN_ACT

func finish_move() -> void:
	if turn_state == TurnState.CAN_MOVE:
		turn_state = TurnState.CAN_ACT

func finish_action() -> void:
	turn_state = TurnState.TURN_DONE

# =========================
# COMBATE
# =========================
func receive_damage(amount: int) -> void:
	current_hp -= amount
	print(name, " recebeu ", amount, " de dano. HP:", current_hp)

	if current_hp <= 0:
		die()

func attack(target: PlayerUnit) -> void:
	if not can_act():
		return

	if target == self:
		return

	print(name, " atacou ", target.name)
	target.receive_damage(damage)
	finish_action()

func die() -> void:
	print(name, " morreu")
	died.emit(self)
	queue_free()
