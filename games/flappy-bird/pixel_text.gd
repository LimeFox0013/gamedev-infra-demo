extends Node2D

const GLYPHS := {
	"A": "010101111101101", "B": "110101110101110", "C": "011100100100011",
	"D": "110101101101110", "E": "111100110100111", "F": "111100110100100",
	"G": "011100101101011", "H": "101101111101101", "I": "111010010010111",
	"J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
	"M": "101111111101101", "N": "110101101101101", "O": "010101101101010",
	"P": "110101110100100", "Q": "010101101111011", "R": "110101110101101",
	"S": "011100010001110", "T": "111010010010010", "U": "101101101101111",
	"V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
	"Y": "101101010010010", "Z": "111001010100111",
	"0": "111101101101111", "1": "010110010010111", "2": "111001111100111",
	"3": "111001111001111", "4": "101101111001001", "5": "111100111001111",
	"6": "111100111101111", "7": "111001001010010", "8": "111101111101111",
	"9": "111101111001111", "-": "000000111000000", ":": "000010000010000",
}
const LINE_GAP := 2
const PADDING := 5

@export var text := "":
	set(value):
		text = value
		queue_redraw()
@export var pixel := 1
@export var color := Color.WHITE
@export var outline := Color("3b2a2a")
@export var box := false
@export var box_color := Color("ded895")


func _line_width(line: String) -> int:
	return maxi(line.length() * 4 * pixel - pixel, 0)


func _draw() -> void:
	var lines := text.split("\n")
	var width := 0
	for line in lines:
		width = maxi(width, _line_width(line))
	var height := lines.size() * (5 + LINE_GAP) * pixel - LINE_GAP * pixel
	if box:
		var rect := Rect2(-width / 2.0 - PADDING, -PADDING, width + PADDING * 2, height + PADDING * 2)
		draw_rect(rect.grow(1), outline)
		draw_rect(rect, box_color)
		draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, 1)), Color.WHITE.lerp(box_color, 0.5))
	var layers := [1] if box else [0, 1]
	for layer in layers:
		var y := 0
		for line in lines:
			var x := -int(_line_width(line) / 2.0)
			for ch in line:
				if GLYPHS.has(ch):
					_glyph(GLYPHS[ch], x, y, color if layer == 1 else outline, layer == 0)
				x += 4 * pixel
			y += (5 + LINE_GAP) * pixel


func _glyph(bits: String, x: int, y: int, col: Color, grow: bool) -> void:
	for i in bits.length():
		if bits[i] == "1":
			var rect := Rect2(x + (i % 3) * pixel, y + floori(i / 3.0) * pixel, pixel, pixel)
			draw_rect(rect.grow(1) if grow else rect, col)
