extends RefCounted

const PALETTE := {
	"K": Color("2a1a2e"),
	"Y": Color("f8d63a"),
	"D": Color("e0a21c"),
	"W": Color("f4f4ff"),
	"O": Color("f4742b"),
	"R": Color("e0342a"),
	"L": Color("fff0a0"),
	"P": Color("6b3a8c"),
}


static func make(rows: Array) -> ImageTexture:
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			var key: String = rows[y][x]
			if PALETTE.has(key):
				img.set_pixel(x, y, PALETTE[key])
	return ImageTexture.create_from_image(img)
