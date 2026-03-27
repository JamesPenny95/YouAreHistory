extends Control

# Displays a static background image with the score overlaid in large coloured
# text. Colour is interpolated: 0% = red, 50% = yellow, 100% = green.

@onready var score_label: Label = $ScoreLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var countdown_ring = $CountdownRing

var _countdown_remaining: float = 0.0
var _countdown_total: float = 10.0


func show_score(score: int, total: int) -> void:
	visible = true

	if total == 0:
		score_label.text = ""
		countdown_label.text = ""
		return

	score_label.text = "%d / %d" % [score, total]

	var pct: float = float(score) / float(total)
	score_label.add_theme_color_override("font_color", _score_colour(pct))
	update_countdown(_countdown_total, _countdown_total)


func update_countdown(remaining: float, total: float) -> void:
	_countdown_remaining = max(remaining, 0.0)
	_countdown_total = max(total, 0.001)
	countdown_label.text = str(int(ceil(_countdown_remaining)))
	countdown_ring.set_progress(_countdown_remaining / _countdown_total)


func _score_colour(pct: float) -> Color:
	# 0.0 = red, 0.5 = yellow, 1.0 = green
	var low := Color(0.78, 0.18, 0.16, 1)
	var mid := Color(0.89, 0.72, 0.16, 1)
	var high := Color(0.17, 0.58, 0.25, 1)
	if pct <= 0.5:
		return low.lerp(mid, pct * 2.0)
	else:
		return mid.lerp(high, (pct - 0.5) * 2.0)
