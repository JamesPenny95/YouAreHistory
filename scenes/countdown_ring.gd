extends Control

var progress: float = 1.0


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var radius: float = min(size.x, size.y) * 0.5 - 6.0
	var start_angle: float = -PI * 0.5
	var end_angle: float = start_angle + TAU * progress

	draw_arc(center, radius, 0.0, TAU, 96, Color(1, 1, 1, 0.18), 8.0, true)
	if progress > 0.0:
		draw_arc(center, radius, start_angle, end_angle, 96, Color(1, 1, 1, 1), 8.0, true)