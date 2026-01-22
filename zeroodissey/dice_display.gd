extends CanvasLayer

@onready var label: Label = $Panel/Label

func set_roll(value: int) -> void:
	label.text = str(value)

	if value == 20:
		label.modulate = Color.GREEN
	else:
		label.modulate = Color.WHITE
