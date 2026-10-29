extends Node2D

const PixelArt := preload("res://pixel_art.gd")

enum Kind { GHOST, BAT }

const GHOST_A := [
	"....KKKKKK....",
	"..KKWWWWWWKK..",
	".KWWWWWWWWWWK.",
	".KWWWWWWWWWWK.",
	"KWWWWWWWWWWWWK",
	"KWWKKWWWWKKWWK",
	"KWWKKWWWWKKWWK",
	"KWWKKWWWWKKWWK",
	"KWWWWWWWWWWWWK",
	"KWWWWWKKWWWWWK",
	"KWWWWWKKWWWWWK",
	"KWWWWWWWWWWWWK",
	"KWWWWWWWWWWWWK",
	"KWWWWWWWWWWWWK",
	"KWWKWWWKWWWKWK",
	".KK.KKK.KKK.K.",
]
const GHOST_B := [
	"....KKKKKK....",
	"..KKWWWWWWKK..",
	".KWWWWWWWWWWK.",
	".KWWWWWWWWWWK.",
	"KWWWWWWWWWWWWK",
	"KWWKKWWWWKKWWK",
	"KWWKKWWWWKKWWK",
	"KWWKKWWWWKKWWK",
	"KWWWWWWWWWWWWK",
	"KWWWWWKKWWWWWK",
	"KWWWWWKKWWWWWK",
	"KWWWWWWWWWWWWK",
	"KWWWWWWWWWWWWK",
	"KWWWWWWWWWWWWK",
	"KWKWWWKWWWKWWK",
	".K.KKK.KKK.KK.",
]
const BAT_UP := [
	"KK....K..K....KK",
	"KPK..KPKKPK..KPK",
	"KPPKKPPPPPPKKPPK",
	"KPPPPPRPPRPPPPPK",
	".KPPPKPPPPKPPPK.",
	"..KPKK.KK.KKPK..",
	"................",
	"................",
]
const BAT_DOWN := [
	"......K..K......",
	".....KPKKPK.....",
	".KK.KPPPPPPK.KK.",
	"KPPKPPRPPRPPKPPK",
	"KPPPKPPPPPPKPPPK",
	".KPPPKPPPPKPPPK.",
	"..KPPPKKKKPPPK..",
	"...KK........KK.",
]
const GHOST_SPEED := 30.0
const GHOST_DRIFT := 12.0
const BAT_SPEED := 80.0
const BAT_WAVE := 5.0
const BAT_WAVE_RATE := 6.0
const Y_MIN := 24.0
const Y_MAX := 190.0
const RADII := {Kind.GHOST: 5.0, Kind.BAT: 3.5}

static var _textures := {}

var kind := Kind.GHOST
var radius := 5.0
var _vy := 0.0
var _base_y := 0.0
var _time := 0.0
var _sprite := Sprite2D.new()


static func textures(of_kind: Kind) -> Array:
	if _textures.is_empty():
		_textures[Kind.GHOST] = [PixelArt.make(GHOST_A), PixelArt.make(GHOST_B)]
		_textures[Kind.BAT] = [PixelArt.make(BAT_UP), PixelArt.make(BAT_DOWN)]
	return _textures[of_kind]


func _ready() -> void:
	_sprite.name = "Sprite"
	add_child(_sprite, true)


func launch(new_kind: Kind, start: Vector2, drift_dir: float) -> void:
	kind = new_kind
	radius = RADII[kind]
	position = start
	_base_y = start.y
	_vy = GHOST_DRIFT * signf(drift_dir)
	_time = 0.0
	_sprite.modulate.a = 0.9 if kind == Kind.GHOST else 1.0
	_sprite.texture = textures(kind)[0]


func step(delta: float) -> void:
	_time += delta
	if kind == Kind.GHOST:
		position.x -= GHOST_SPEED * delta
		position.y += _vy * delta
		if position.y < Y_MIN or position.y > Y_MAX:
			position.y = clampf(position.y, Y_MIN, Y_MAX)
			_vy = -_vy
		_sprite.texture = textures(kind)[int(_time * 2.0) % 2]
	else:
		position.x -= BAT_SPEED * delta
		position.y = _base_y + sin(_time * BAT_WAVE_RATE) * BAT_WAVE
		_sprite.texture = textures(kind)[int(_time * 9.0) % 2]
