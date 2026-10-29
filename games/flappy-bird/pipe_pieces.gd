extends Node2D

const PipeScript := preload("res://pipe.gd")
const GRAVITY := 420.0
const BLAST := 300.0
const LIFETIME := 2.4
const FADE := 0.6

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _src := PackedVector2Array()
var _age := 0.0


func burst(pipe: Node2D, origin: Vector2, rng: RandomNumberGenerator) -> void:
	for i in pipe.cell_pos.size():
		var p: Vector2 = pipe.position + pipe.cell_pos[i]
		var away := p - origin
		var dist := maxf(away.length(), 1.0)
		var speed := BLAST / (1.0 + dist / 25.0) * rng.randf_range(0.5, 1.2)
		var kick := Vector2(rng.randf_range(-25.0, 25.0), rng.randf_range(-80.0, -10.0))
		_pos.append(p)
		_vel.append(away / dist * speed + kick)
		_src.append(pipe.cell_src[i])
	queue_redraw()


func piece_count() -> int:
	return _pos.size()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	for i in _pos.size():
		_vel[i] = Vector2(_vel[i].x, _vel[i].y + GRAVITY * delta)
		_pos[i] += _vel[i] * delta
	modulate.a = clampf((LIFETIME - _age) / FADE, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var texture := PipeScript.atlas()
	var size := Vector2(PipeScript.PIECE, PipeScript.PIECE)
	for i in _pos.size():
		draw_texture_rect_region(texture, Rect2(_pos[i].floor(), size), Rect2(_src[i], size))
