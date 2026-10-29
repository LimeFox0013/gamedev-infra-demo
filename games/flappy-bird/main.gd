extends Node2D

enum State { READY, PLAYING, DEAD }

const PipeScript := preload("res://pipe.gd")
const Sfx := preload("res://sfx.gd")
const GROUND_Y := 216.0
const BIRD_X := 40.0
const BIRD_RADIUS := 4.0
const SCROLL_SPEED := 50.0
const PIPE_START_X := 160.0
const PIPE_REMOVE_X := -20.0
const SPAWN_SECONDS := 1.5
const GAP_MIN := 62.0
const GAP_MAX := 158.0
const GAP_STEP := 45.0
const FIRST_GAP_Y := 94.0
const RETRY_DELAY := 0.6
const BEST_PATH := "user://best.json"

var state := State.READY
var score := 0
var best := 0
var _dead_time := 0.0
var _last_gap_y := 0.0
var _rng := LFRandom.new()
var _spawn_timer := LFIntervalTimer.new(SPAWN_SECONDS)
var _factory := LFFactory.new()
var _pipes: Array[Node2D] = []
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
	_factory.set_container($Obstacles)
	_factory.register(&"pipe", _make_pipe, _show_pipe, _hide_pipe)
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
			if _spawn_timer.tick(delta):
				_spawn_pipe()
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
	var gap_y := FIRST_GAP_Y
	if not _pipes.is_empty():
		gap_y = clampf(
			_last_gap_y + _rng.randf_range(-GAP_STEP, GAP_STEP), GAP_MIN, GAP_MAX)
	_last_gap_y = gap_y
	var pipe: Node2D = _factory.acquire(&"pipe")
	pipe.reset(gap_y, PIPE_START_X)
	_pipes.append(pipe)


func _move_pipes(delta: float) -> void:
	for pipe in _pipes.duplicate():
		pipe.position.x -= SCROLL_SPEED * delta
		if not pipe.scored and pipe.position.x < _bird.position.x:
			pipe.scored = true
			_set_score(score + 1)
			_sfx.play("score")
		if pipe.position.x < PIPE_REMOVE_X:
			_pipes.erase(pipe)
			_factory.release(pipe)


func _check_collisions() -> void:
	var y := _bird.position.y
	if y + BIRD_RADIUS >= GROUND_Y:
		_land_if_ground()
		_die()
		return
	for pipe in _pipes:
		var dx := absf(pipe.position.x - _bird.position.x)
		if dx > PipeScript.CAP_WIDTH / 2.0 + BIRD_RADIUS:
			continue
		if y - BIRD_RADIUS < pipe.gap_top() or y + BIRD_RADIUS > pipe.gap_bottom():
			_die()
			return


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


func _show_pipe(pipe: Node2D) -> void:
	pipe.show()


func _hide_pipe(pipe: Node2D) -> void:
	pipe.hide()
