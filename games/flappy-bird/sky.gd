extends Node2D

const WIDTH := 144
const HORIZON := 216
const STAR_COUNT := 42
const BANDS := [[0, "0a0a22"], [60, "120f33"], [100, "1b1342"], [135, "29184d"], [165, "3c1f55"], [190, "56275c"]]
const STAR_COLORS := ["ffffff", "e8d8ff", "ffd0d0"]

var _stars: Array = []


func _ready() -> void:
	var rng := LFRandom.new(5)
	for i in STAR_COUNT:
		_stars.append([rng.randi_range(0, WIDTH - 2), rng.randi_range(2, 150), rng.randi_range(0, 5) == 0, rng.pick(STAR_COLORS)])


func _draw() -> void:
	for i in BANDS.size():
		var end: int = BANDS[i + 1][0] if i + 1 < BANDS.size() else HORIZON
		draw_rect(Rect2(0, BANDS[i][0], WIDTH, end - BANDS[i][0]), Color(BANDS[i][1]))
	for star in _stars:
		var color := Color(star[3])
		draw_rect(Rect2(star[0], star[1], 1, 1), color)
		if star[2]:
			draw_rect(Rect2(star[0] - 1, star[1], 3, 1), Color(color, 0.5))
			draw_rect(Rect2(star[0], star[1] - 1, 1, 3), Color(color, 0.5))
