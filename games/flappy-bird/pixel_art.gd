extends RefCounted

const PALETTE := {
	"K": Color("3b2a2a"),
	"Y": Color("f8d63a"),
	"D": Color("e0a21c"),
	"W": Color("ffffff"),
	"O": Color("f4742b"),
	"R": Color("d9402a"),
	"L": Color("fff0a0"),
}


static func make(rows: Array) -> ImageTexture:
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			var key: String = rows[y][x]
			if PALETTE.has(key):
				img.set_pixel(x, y, PALETTE[key])
	return ImageTexture.create_from_image(img)
