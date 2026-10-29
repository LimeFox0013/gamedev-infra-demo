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
	draw_rect(Rect2(0, TOP, WIDTH, HEIGHT), Color("2a1a3c"))
	draw_rect(Rect2(0, TOP + 10, WIDTH, 1), Color("3b2850"))
	draw_rect(Rect2(0, TOP + 22, WIDTH, 1), Color("201430"))
	draw_rect(Rect2(0, TOP, WIDTH, 1), Color("120c26"))
	draw_rect(Rect2(0, TOP + 1, WIDTH, 2), Color("8a5cc0"))
	draw_rect(Rect2(0, TOP + 3, WIDTH, 6), Color("3b2468"))
	draw_rect(Rect2(0, TOP + 9, WIDTH, 1), Color("241446"))
	for r in 6:
		for x in range(-STRIPE, WIDTH + STRIPE, STRIPE):
			draw_rect(Rect2(x + r * 2 - offset, TOP + 3 + r, 8, 1), Color("e8801c"))
