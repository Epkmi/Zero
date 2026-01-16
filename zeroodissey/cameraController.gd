extends Camera2D

# =========================
# ZOOM
# =========================
@export var zoom_step := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 2.5

# =========================
# MOVIMENTO
# =========================
@export var move_speed := 800.0
@export var mouse_pan_button := MOUSE_BUTTON_RIGHT

var target_position: Vector2

# =========================
# READY
# =========================
func _ready():
	target_position = global_position

# =========================
# INPUT
# =========================
func _unhandled_input(event: InputEvent) -> void:

	# ---------- ZOOM ----------
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(-zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom_step)

	# ---------- MOVE CAMERA ----------
	if event is InputEventMouseButton:
		if event.button_index == mouse_pan_button and event.pressed:
			var world_pos := get_global_mouse_position()
			target_position = world_pos

# =========================
# PROCESS (MOVIMENTO SUAVE)
# =========================
func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, delta * 5)

# =========================
# ZOOM HANDLER
# =========================
func _set_zoom(amount: float) -> void:
	var new_zoom := zoom.x + amount
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
