# HealthBar.gd
extends Node2D

@export var max_width := 24

@onready var bar: ColorRect = $Bar

func set_health(current: int, max: int) -> void:
	var ratio : float = clamp(float(current) / float(max), 0.0, 1.0)
	bar.size.x = max_width * ratio
