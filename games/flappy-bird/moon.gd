extends Node2D

const RADIUS := 18
const HALOS := [[26, Color(0.8, 0.1, 0.15, 0.10)], [23, Color(0.8, 0.1, 0.15, 0.16)], [20, Color(0.8, 0.1, 0.15, 0.26)]]
const CRATERS := [Rect2(-7, -5, 4, 3), Rect2(3, 1, 5, 4), Rect2(-4, 7, 3, 2), Rect2(5, -9, 2, 2), Rect2(-10, 2, 2, 2)]


func _disc(center: Vector2, r: int, color: Color) -> void:
	for dy in range(-r, r + 1):
		var half := roundi(sqrt(float(r * r - dy * dy)))
		draw_rect(Rect2(center.x - half, center.y + dy, half * 2 + 1, 1), color)


func _draw() -> void:
	for halo in HALOS:
		_disc(Vector2.ZERO, halo[0], halo[1])
	_disc(Vector2.ZERO, RADIUS, Color("8e1520"))
	_disc(Vector2(-1, -1), RADIUS - 2, Color("c0262d"))
	_disc(Vector2(-3, -4), RADIUS - 8, Color("d9473f"))
	for crater in CRATERS:
		draw_rect(crater, Color("9a1c28"))
