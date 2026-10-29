extends Node2D

const GAP := 52.0
const CAP_WIDTH := 22.0
const BODY_WIDTH := 18.0
const CAP_HEIGHT := 8.0
const BOTTOM := 224.0
const DARK := Color("3b2a2a")
const GREEN := Color("73bf2e")
const LIGHT := Color("b4ea5c")
const SHADE := Color("4c8a1c")

var gap_y := 100.0
var scored := false


func reset(new_gap_y: float, x: float) -> void:
	gap_y = new_gap_y
	scored = false
	position = Vector2(x, 0)
	queue_redraw()


func gap_top() -> float:
	return gap_y - GAP / 2.0


func gap_bottom() -> float:
	return gap_y + GAP / 2.0


func _draw() -> void:
	_part(-300.0, gap_top(), true)
	_part(gap_bottom(), BOTTOM, false)


func _part(y0: float, y1: float, cap_at_end: bool) -> void:
	var body_half := BODY_WIDTH / 2.0
	draw_rect(Rect2(-body_half, y0, BODY_WIDTH, y1 - y0), DARK)
	draw_rect(Rect2(-body_half + 1, y0, BODY_WIDTH - 2, y1 - y0), GREEN)
	draw_rect(Rect2(-body_half + 2, y0, 3, y1 - y0), LIGHT)
	draw_rect(Rect2(body_half - 5, y0, 4, y1 - y0), SHADE)
	var cap_y := y1 - CAP_HEIGHT if cap_at_end else y0
	var cap_half := CAP_WIDTH / 2.0
	draw_rect(Rect2(-cap_half, cap_y, CAP_WIDTH, CAP_HEIGHT), DARK)
	draw_rect(Rect2(-cap_half + 1, cap_y + 1, CAP_WIDTH - 2, CAP_HEIGHT - 2), GREEN)
	draw_rect(Rect2(-cap_half + 2, cap_y + 1, 3, CAP_HEIGHT - 2), LIGHT)
	draw_rect(Rect2(cap_half - 6, cap_y + 1, 5, CAP_HEIGHT - 2), SHADE)
