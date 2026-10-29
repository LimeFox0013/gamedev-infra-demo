extends Node2D

const WIDTH := 144
const PERIOD := 160
const HORIZON := 216
const CITY_SPEED := 0.2
const CLOUD_SPEED := 0.08
const BUSH_SPEED := 0.5
const CLOUD := [[2, 0, 10, 3], [0, 2, 14, 3], [4, 4, 8, 3]]
const BANDS := [[0, "4ec0ca"], [110, "63cbd1"], [140, "7ad6d8"], [165, "98e2de"], [185, "b5ecea"]]

var scroll := 0.0
var _buildings: Array = []
var _clouds: Array = []


func _ready() -> void:
	var rng := LFRandom.new(11)
	var x := 0
	while x < PERIOD:
		var w := rng.randi_range(10, 18)
		_buildings.append([x, mini(w, PERIOD - x), rng.randi_range(16, 44)])
		x += w + rng.randi_range(0, 3)
	for i in 4:
		_clouds.append([i * 40 + rng.randi_range(0, 20), rng.randi_range(30, 100)])


func _process(_delta: float) -> void:
	queue_redraw()


func _wrapped(x: float, factor: float) -> float:
	return floorf(fposmod(x - scroll * factor, PERIOD))


func _draw() -> void:
	for i in BANDS.size():
		var end: int = BANDS[i + 1][0] if i + 1 < BANDS.size() else HORIZON
		draw_rect(Rect2(0, BANDS[i][0], WIDTH, end - BANDS[i][0]), Color(BANDS[i][1]))
	for cloud in _clouds:
		_draw_cloud(_wrapped(cloud[0], CLOUD_SPEED), cloud[1])
	for b in _buildings:
		var px := _wrapped(b[0], CITY_SPEED)
		for shift in [0, -PERIOD]:
			_draw_building(px + shift, b[1], b[2])
	for i in range(-1, 12):
		var bx := floorf(fposmod(i * 14.0 - scroll * BUSH_SPEED, 168.0)) - 14.0
		draw_rect(Rect2(bx, HORIZON - 8, 14, 8), Color("5cb04a"))
		draw_rect(Rect2(bx + 2, HORIZON - 10, 10, 2), Color("5cb04a"))
		draw_rect(Rect2(bx + 3, HORIZON - 10, 4, 1), Color("86d46a"))
		draw_rect(Rect2(bx, HORIZON - 3, 14, 3), Color("3f8f3c"))


func _draw_cloud(x: float, y: float) -> void:
	for shift in [0, -PERIOD]:
		for part in CLOUD:
			var rect := Rect2(x + shift + part[0] * 3, y + part[1] * 3, part[2] * 3, part[3] * 3)
			draw_rect(rect, Color("f2fffa"))
			draw_rect(Rect2(rect.position.x, rect.end.y - 2, rect.size.x, 2), Color("cdeee6"))


func _draw_building(x: float, w: float, h: float) -> void:
	var top := HORIZON - 8 - h
	draw_rect(Rect2(x, top, w, h), Color("b4dcc8"))
	draw_rect(Rect2(x, top, 1, h), Color("d6f0e0"))
	draw_rect(Rect2(x + w - 2, top, 2, h), Color("98c4b0"))
	for wy in range(int(top) + 3, HORIZON - 12, 6):
		for wx in range(int(x) + 3, int(x + w) - 4, 5):
			draw_rect(Rect2(wx, wy, 2, 3), Color("8cb8a4"))
