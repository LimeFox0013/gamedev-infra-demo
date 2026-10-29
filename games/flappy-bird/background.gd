extends Node2D

const PERIOD := 160
const HORIZON := 216
const CITY_SPEED := 0.2
const CLOUD_SPEED := 0.08
const FRONT_SPEED := 0.5
const FRONT_STEP := 14
const CLOUD := [[2, 0, 10, 3], [0, 2, 14, 3], [4, 4, 8, 3]]

var scroll := 0.0
var _buildings: Array = []
var _clouds: Array = []


func _ready() -> void:
	var rng := LFRandom.new(11)
	var x := 0
	while x < PERIOD:
		var w := rng.randi_range(10, 18)
		_buildings.append([x, mini(w, PERIOD - x), rng.randi_range(16, 44), rng.randi_range(0, 2)])
		x += w + rng.randi_range(0, 3)
	for i in 4:
		_clouds.append([i * 40 + rng.randi_range(0, 20), rng.randi_range(40, 120)])


func _process(_delta: float) -> void:
	queue_redraw()


func _wrapped(x: float, factor: float) -> float:
	return floorf(fposmod(x - scroll * factor, PERIOD))


func _draw() -> void:
	for cloud in _clouds:
		_draw_cloud(_wrapped(cloud[0], CLOUD_SPEED), cloud[1])
	for b in _buildings:
		var px := _wrapped(b[0], CITY_SPEED)
		for shift in [0, -PERIOD]:
			_draw_building(px + shift, b[1], b[2], b[3])
	for i in range(-1, 12):
		var fx := floorf(fposmod(i * float(FRONT_STEP) - scroll * FRONT_SPEED, 168.0)) - FRONT_STEP
		match i % 4:
			1:
				_draw_tombstone(fx + 3)
			3:
				_draw_pumpkin(fx + 2)
			_:
				_draw_hedge(fx)


func _draw_cloud(x: float, y: float) -> void:
	for shift in [0, -PERIOD]:
		for part in CLOUD:
			var rect := Rect2(x + shift + part[0] * 3, y + part[1] * 3, part[2] * 3, part[3] * 3)
			draw_rect(rect, Color("2b2150"))
			draw_rect(Rect2(rect.position.x, rect.end.y - 2, rect.size.x, 2), Color("1c1538"))


func _draw_building(x: float, w: float, h: float, roof: int) -> void:
	var top := HORIZON - 8 - h
	draw_rect(Rect2(x, top, w, h), Color("140e2a"))
	draw_rect(Rect2(x, top, 1, h), Color("22183e"))
	if roof == 1:
		for j in mini(int(w / 2.0), 7):
			draw_rect(Rect2(x + j, top - j - 1, w - j * 2, 1), Color("140e2a"))
	elif roof == 2:
		draw_rect(Rect2(x + w / 2.0 - 1, top - 8, 2, 8), Color("140e2a"))
	for wy in range(int(top) + 3, HORIZON - 12, 6):
		for wx in range(int(x) + 3, int(x + w) - 4, 5):
			var lit := (wx * 7 + wy * 13) % 5 == 0
			draw_rect(Rect2(wx, wy, 2, 3), Color("f2a23a") if lit else Color("1e1638"))


func _draw_hedge(x: float) -> void:
	draw_rect(Rect2(x, HORIZON - 8, 14, 8), Color("1c1236"))
	draw_rect(Rect2(x + 2, HORIZON - 10, 10, 2), Color("1c1236"))
	draw_rect(Rect2(x + 3, HORIZON - 10, 4, 1), Color("2c2050"))


func _draw_tombstone(x: float) -> void:
	draw_rect(Rect2(x, HORIZON - 12, 8, 12), Color("3a3358"))
	draw_rect(Rect2(x + 1, HORIZON - 13, 6, 1), Color("3a3358"))
	draw_rect(Rect2(x + 3, HORIZON - 10, 2, 5), Color("262042"))
	draw_rect(Rect2(x + 2, HORIZON - 9, 4, 1), Color("262042"))
	draw_rect(Rect2(x, HORIZON - 12, 1, 12), Color("524a78"))


func _draw_pumpkin(x: float) -> void:
	draw_rect(Rect2(x + 4, HORIZON - 12, 2, 2), Color("3a6a2a"))
	draw_rect(Rect2(x, HORIZON - 10, 10, 8), Color("e8801c"))
	draw_rect(Rect2(x + 1, HORIZON - 11, 8, 1), Color("e8801c"))
	draw_rect(Rect2(x, HORIZON - 4, 10, 2), Color("a84e0e"))
	draw_rect(Rect2(x + 2, HORIZON - 8, 2, 2), Color("ffd23a"))
	draw_rect(Rect2(x + 6, HORIZON - 8, 2, 2), Color("ffd23a"))
	draw_rect(Rect2(x + 3, HORIZON - 5, 4, 1), Color("ffd23a"))
