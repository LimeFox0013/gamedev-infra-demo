extends Node2D

const PixelArt := preload("res://pixel_art.gd")
const GRAVITY := 620.0
const FLAP_SPEED := -190.0
const MAX_FALL := 260.0
const RADIUS := 4.0
const TILT_STEP := PI / 12.0
const BODY := [
	"....KKKKKK......",
	"..KKYYYYYKWWK...",
	".KYYYYYYKWWWWK..",
	".KYYYYYYKWWKWK..",
	"KYYYYYYYYWWKWK..",
	"KYYYYYYYYYKKKKKK",
	"KYYYYYYYYKOOOOOK",
	".KYYYYYYKRRRRRK.",
	"..KDDDDDDKKKKK..",
	"....KKKKKK......",
]
const WINGS := {
	"up": [[2, 3, "WWWW"], [2, 4, "WWWWK"], [3, 5, "KKKK"]],
	"mid": [[2, 5, "WWWW"], [2, 6, "WWWWK"], [3, 7, "KKKK"]],
	"down": [[2, 6, "WWWW"], [2, 7, "WWWWK"], [3, 8, "KKKK"]],
}
const FLAP_ORDER := ["mid", "up", "mid", "down"]

var velocity := 0.0
var alive := true
var _time := 0.0
var _base_y := 0.0
var _textures := {}
var _sprite := Sprite2D.new()


func _ready() -> void:
	_base_y = position.y
	for key in WINGS:
		var rows := BODY.duplicate()
		for part in WINGS[key]:
			var row: String = rows[part[1]]
			for i in part[2].length():
				row[part[0] + i] = part[2][i]
			rows[part[1]] = row
		_textures[key] = PixelArt.make(rows)
	_sprite.name = "Sprite"
	_sprite.texture = _textures["mid"]
	add_child(_sprite, true)


func hover(delta: float) -> void:
	_time += delta
	position.y = _base_y + roundf(sin(_time * 5.0) * 3.0)
	_animate()


func flap() -> void:
	velocity = FLAP_SPEED


func step(delta: float) -> void:
	_time += delta
	velocity = minf(velocity + GRAVITY * delta, MAX_FALL)
	position.y += velocity * delta
	rotation = snappedf(clampf(velocity / 220.0, -0.45, 1.4), TILT_STEP)
	if alive:
		_animate()


func land(ground_y: float) -> void:
	position.y = ground_y - RADIUS
	velocity = 0.0
	rotation = 1.4


func _animate() -> void:
	if velocity > 120.0:
		_sprite.texture = _textures["mid"]
	else:
		_sprite.texture = _textures[FLAP_ORDER[int(_time * 14.0) % FLAP_ORDER.size()]]
