extends Node

const RATE := 22050
const SOUNDS := {
	"flap": [380.0, 760.0, 0.1, 0.25],
	"score": [988.0, 1319.0, 0.18, 0.25],
	"hit": [260.0, 70.0, 0.28, 0.35],
}

var _players := {}


func _ready() -> void:
	for key in SOUNDS:
		var spec: Array = SOUNDS[key]
		var player := AudioStreamPlayer.new()
		player.name = key.capitalize()
		player.stream = _tone(spec[0], spec[1], spec[2], spec[3])
		add_child(player, true)
		_players[key] = player


func play(key: String) -> void:
	_players[key].play()


static func _tone(from_hz: float, to_hz: float, seconds: float, volume: float) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += lerpf(from_hz, to_hz, t) / RATE
		var wave := 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0
		data.encode_s16(i * 2, int(wave * volume * (1.0 - t) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
