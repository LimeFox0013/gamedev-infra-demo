extends Node2D

const GAP := 52.0
const CAP_WIDTH := 22.0
const CAP_HEIGHT := 8.0
const BODY_WIDTH := 18.0
const PIECE := 2
const BOTTOM := 218
const TOP_EXTENT := 600.0
const ATLAS_SIZE := Vector2i(22, 10)
const BODY_SRC := Vector2i(2, 8)
const DARK := Color("3b2a2a")
const GREEN := Color("73bf2e")
const LIGHT := Color("b4ea5c")
const SHADE := Color("4c8a1c")

static var _atlas: ImageTexture

var gap_y := 100.0
var scored := false
var cell_pos := PackedVector2Array()
var cell_src := PackedVector2Array()


static func atlas() -> ImageTexture:
	if _atlas == null:
		var img := Image.create(ATLAS_SIZE.x, ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
		_paint(img, Rect2i(0, 0, 22, 8), [Rect2i(1, 1, 20, 6), Rect2i(2, 1, 3, 6), Rect2i(16, 1, 5, 6)])
		_paint(img, Rect2i(2, 8, 18, 2), [Rect2i(3, 8, 16, 2), Rect2i(4, 8, 3, 2), Rect2i(15, 8, 4, 2)])
		_atlas = ImageTexture.create_from_image(img)
	return _atlas


static func _paint(img: Image, outer: Rect2i, inner: Array) -> void:
	img.fill_rect(outer, DARK)
	for i in inner.size():
		img.fill_rect(inner[i], [GREEN, LIGHT, SHADE][i])


func reset(new_gap_y: float, x: float) -> void:
	gap_y = roundf(new_gap_y)
	scored = false
	position = Vector2(x, 0)
	_build_cells()
	queue_redraw()


func gap_top() -> float:
	return gap_y - GAP / 2.0


func gap_bottom() -> float:
	return gap_y + GAP / 2.0


func solid_rects() -> Array[Rect2]:
	var body := BODY_WIDTH / 2.0
	var cap := CAP_WIDTH / 2.0
	var top_cap_y := gap_top() - CAP_HEIGHT
	var bottom_body_y := gap_bottom() + CAP_HEIGHT
	return [
		Rect2(-body, -TOP_EXTENT, BODY_WIDTH, top_cap_y + TOP_EXTENT),
		Rect2(-cap, top_cap_y, CAP_WIDTH, CAP_HEIGHT),
		Rect2(-cap, gap_bottom(), CAP_WIDTH, CAP_HEIGHT),
		Rect2(-body, bottom_body_y, BODY_WIDTH, BOTTOM - bottom_body_y),
	]


func hits(center: Vector2, half_size: Vector2) -> bool:
	var box := Rect2(center - position - half_size, half_size * 2.0)
	for rect in solid_rects():
		if box.intersects(rect):
			return true
	return false


func _build_cells() -> void:
	cell_pos.clear()
	cell_src.clear()
	var cap_y := int(gap_top()) - int(CAP_HEIGHT)
	_add_cap(cap_y)
	for y in range(cap_y - PIECE, -PIECE - 1, -PIECE):
		_add_body(y)
	cap_y = int(gap_bottom())
	_add_cap(cap_y)
	for y in range(cap_y + int(CAP_HEIGHT), BOTTOM, PIECE):
		_add_body(y)


func _add_cap(y: int) -> void:
	for row in int(CAP_HEIGHT / PIECE):
		for col in int(CAP_WIDTH / PIECE):
			cell_pos.append(Vector2(-CAP_WIDTH / 2.0 + col * PIECE, y + row * PIECE))
			cell_src.append(Vector2(col * PIECE, row * PIECE))


func _add_body(y: int) -> void:
	for col in int(BODY_WIDTH / PIECE):
		cell_pos.append(Vector2(-BODY_WIDTH / 2.0 + col * PIECE, y))
		cell_src.append(Vector2(BODY_SRC.x + col * PIECE, BODY_SRC.y))


func _draw() -> void:
	var texture := atlas()
	for i in cell_pos.size():
		draw_texture_rect_region(
			texture, Rect2(cell_pos[i], Vector2(PIECE, PIECE)), Rect2(cell_src[i], Vector2(PIECE, PIECE)))
