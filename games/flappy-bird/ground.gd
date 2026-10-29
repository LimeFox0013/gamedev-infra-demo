extends Node2D

const TOP := 216
const WIDTH := 144
const HEIGHT := 40
const STRIPE := 16

var scroll := 0.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var offset := floori(scroll) % STRIPE
	draw_rect(Rect2(0, TOP, WIDTH, HEIGHT), Color("ded895"))
	draw_rect(Rect2(0, TOP + 10, WIDTH, 1), Color("d2b04c"))
	draw_rect(Rect2(0, TOP + 11, WIDTH, HEIGHT), Color("e8e0a8"))
	draw_rect(Rect2(0, TOP, WIDTH, 1), Color("3b2a2a"))
	draw_rect(Rect2(0, TOP + 1, WIDTH, 2), Color("b4ea5c"))
	draw_rect(Rect2(0, TOP + 3, WIDTH, 6), Color("73bf2e"))
	draw_rect(Rect2(0, TOP + 9, WIDTH, 1), Color("4c8a1c"))
	for r in 6:
		for x in range(-STRIPE, WIDTH + STRIPE, STRIPE):
			draw_rect(Rect2(x + r * 2 - offset, TOP + 3 + r, 8, 1), Color("9ce659"))
