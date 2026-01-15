extends CharacterBody2D
class_name PlayerUnit

signal unit_right_clicked(unit: PlayerUnit, mouse_pos: Vector2)

@export var move_points: int = 6

enum TurnState { CAN_MOVE, CAN_ACT, TURN_DONE }
var turn_state: TurnState = TurnState.CAN_MOVE

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area.input_event.connect(_on_area_input)

func _on_area_input(viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			unit_right_clicked.emit(self, event.global_position)

# -------------------------
# VISUAL
# -------------------------
func set_selected(value: bool) -> void:
	sprite.modulate = Color.YELLOW if value else Color.WHITE

# -------------------------
# TURNO
# -------------------------
func start_turn() -> void:
	turn_state = TurnState.CAN_MOVE

func can_move() -> bool:
	return turn_state == TurnState.CAN_MOVE

func finish_move() -> void:
	turn_state = TurnState.CAN_ACT

func finish_action() -> void:
	turn_state = TurnState.TURN_DONE
