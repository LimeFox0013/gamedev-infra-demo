extends Node2D

enum State { READY, PLAYING, DEAD }

const PipeScript := preload("res://pipe.gd")
const PiecesScript := preload("res://pipe_pieces.gd")
const HauntScript := preload("res://haunt.gd")
const Sfx := preload("res://sfx.gd")
const GROUND_Y := 216.0
const BIRD_RADIUS := 4.0
const BIRD_HALF_SIZE := Vector2(7.0, 4.5)
const SCROLL_SPEED := 50.0
const PIPE_START_X := 160.0
const HAUNT_START_X := 160.0
const OFFSCREEN_X := -20.0
const SPAWN_SECONDS := 1.5
const OPENING_GAPS := [98.0, 150.0]
const GAP_MIN := 62.0
const GAP_MAX := 158.0
const GAP_STEP := 45.0
const OPENING_HAUNTS := [[HauntScript.Kind.GHOST, 175.0, 1.0], [HauntScript.Kind.BAT, 36.0, 1.0]]
const OPENING_HAUNT_SECONDS := 1.0
const HAUNT_SECONDS_MIN := 2.2
const HAUNT_SECONDS_MAX := 4.0
const HAUNT_Y_MIN := 30.0
const HAUNT_Y_MAX := 180.0
const RETRY_DELAY := 0.6
const BEST_PATH := "user://best.json"

var state := State.READY
var score := 0
var best := 0
var _dead_time := 0.0
var _last_gap_y := 0.0
var _pipes_spawned := 0
var _haunts_spawned := 0
var _rng := LFRandom.new()
var _spawn_timer := LFIntervalTimer.new(SPAWN_SECONDS)
var _haunt_timer := LFIntervalTimer.new(OPENING_HAUNT_SECONDS)
var _pipe_factory := LFFactory.new()
var _haunt_factory := LFFactory.new()
var _pipes: Array[Node2D] = []
var _haunts: Array[Node2D] = []
var _sfx := Sfx.new()

@onready var _background: Node2D = $Background
@onready var _ground: Node2D = $Ground
@onready var _bird: Node2D = $Bird
@onready var _score_label: Node2D = $Hud/Score
@onready var _hint: Node2D = $Hud/Hint
@onready var _panel: Node2D = $Hud/Panel
@onready var _flash: ColorRect = $Hud/Flash


func _ready() -> void:
	best = int(LFFile.load_json(BEST_PATH).get("best", 0))
	_pipe_factory.set_container($Obstacles)
	_pipe_factory.register(&"pipe", _make_pipe, _show_node, _hide_node)
	_haunt_factory.set_container($Haunts)
	_haunt_factory.register(&"ghost", _make_haunt.bind(HauntScript.Kind.GHOST), _show_node, _hide_node)
	_haunt_factory.register(&"bat", _make_haunt.bind(HauntScript.Kind.BAT), _show_node, _hide_node)
	_sfx.name = "Sfx"
	add_child(_sfx, true)
	_panel.visible = false
	_flash.modulate.a = 0.0


func _physics_process(delta: float) -> void:
	var flap := Input.is_action_just_pressed("flap")
	match state:
		State.READY:
			_scroll(delta)
			_bird.hover(delta)
			if flap:
				_start()
		State.PLAYING:
			_scroll(delta)
			if flap:
				_bird.flap()
				_sfx.play("flap")
			_bird.step(delta)
			_move_pipes(delta)
			_move_haunts(delta)
			if _spawn_timer.tick(delta):
				_spawn_pipe()
			if _haunt_timer.tick(delta):
				_spawn_haunt()
			_check_collisions()
		State.DEAD:
			_dead_time += delta
			if not _bird_landed():
				_bird.step(delta)
				_land_if_ground()
			if flap and _dead_time > RETRY_DELAY:
				get_tree().reload_current_scene()


func _scroll(delta: float) -> void:
	_background.scroll += SCROLL_SPEED * delta
	_ground.scroll += SCROLL_SPEED * delta


func _start() -> void:
	state = State.PLAYING
	_hint.visible = false
	_bird.flap()
	_sfx.play("flap")
	_spawn_pipe()


func _spawn_pipe() -> void:
	var gap_y: float
	if _pipes_spawned < OPENING_GAPS.size():
		gap_y = OPENING_GAPS[_pipes_spawned]
	else:
		gap_y = clampf(_last_gap_y + _rng.randf_range(-GAP_STEP, GAP_STEP), GAP_MIN, GAP_MAX)
	_pipes_spawned += 1
	_last_gap_y = gap_y
	var pipe: Node2D = _pipe_factory.acquire(&"pipe")
	pipe.reset(gap_y, PIPE_START_X)
	_pipes.append(pipe)


func _spawn_haunt() -> void:
	var plan: Array
	if _haunts_spawned < OPENING_HAUNTS.size():
		plan = OPENING_HAUNTS[_haunts_spawned]
	else:
		var kind: int = _rng.pick([HauntScript.Kind.GHOST, HauntScript.Kind.BAT])
		plan = [kind, _rng.randf_range(HAUNT_Y_MIN, HAUNT_Y_MAX), _rng.pick([-1.0, 1.0])]
		_haunt_timer.interval = _rng.randf_range(HAUNT_SECONDS_MIN, HAUNT_SECONDS_MAX)
	_haunts_spawned += 1
	var key := &"ghost" if plan[0] == HauntScript.Kind.GHOST else &"bat"
	var haunt: Node2D = _haunt_factory.acquire(key)
	haunt.launch(plan[0], Vector2(HAUNT_START_X, plan[1]), plan[2])
	_haunts.append(haunt)


func _move_pipes(delta: float) -> void:
	for pipe in _pipes.duplicate():
		pipe.position.x -= SCROLL_SPEED * delta
		if not pipe.scored and pipe.position.x < _bird.position.x:
			pipe.scored = true
			_set_score(score + 1)
			_sfx.play("score")
		if pipe.position.x < OFFSCREEN_X:
			_pipes.erase(pipe)
			_pipe_factory.release(pipe)


func _move_haunts(delta: float) -> void:
	for haunt in _haunts.duplicate():
		haunt.step(delta)
		if haunt.position.x < OFFSCREEN_X:
			_haunts.erase(haunt)
			_haunt_factory.release(haunt)


func _check_collisions() -> void:
	var y := _bird.position.y
	if y + BIRD_RADIUS >= GROUND_Y:
		_land_if_ground()
		_die()
		return
	for pipe in _pipes:
		if pipe.hits(_bird.position, BIRD_HALF_SIZE):
			_shatter(pipe)
			_die()
			return
	for haunt in _haunts:
		if haunt.position.distance_to(_bird.position) < haunt.radius + BIRD_RADIUS:
			_die()
			return


func _shatter(pipe: Node2D) -> void:
	var pieces := Node2D.new()
	pieces.set_script(PiecesScript)
	pieces.name = "PipePieces"
	$Obstacles.add_child(pieces, true)
	pieces.burst(pipe, _bird.position, _rng)
	_pipes.erase(pipe)
	_pipe_factory.release(pipe)


func _bird_landed() -> bool:
	return _bird.position.y + BIRD_RADIUS >= GROUND_Y


func _land_if_ground() -> void:
	if _bird_landed():
		_bird.land(GROUND_Y)


func _die() -> void:
	state = State.DEAD
	_bird.alive = false
	_sfx.play("hit")
	if score > best:
		best = score
		LFFile.save_json(BEST_PATH, {"best": best})
	_panel.text = "GAME OVER\n\nSCORE %d\nBEST %d\n\nPRESS SPACE" % [score, best]
	_panel.visible = true
	_flash.modulate.a = 0.8
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.25)


func _set_score(value: int) -> void:
	score = value
	_score_label.text = str(score)


func _make_pipe() -> Node:
	var pipe := Node2D.new()
	pipe.set_script(PipeScript)
	pipe.name = "Pipe"
	return pipe


func _make_haunt(kind: int) -> Node:
	var haunt := Node2D.new()
	haunt.set_script(HauntScript)
	haunt.name = "%s%d" % ["Ghost" if kind == HauntScript.Kind.GHOST else "Bat", _haunts_spawned]
	return haunt


func _show_node(node: Node2D) -> void:
	node.show()


func _hide_node(node: Node2D) -> void:
	node.hide()
