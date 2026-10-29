extends GutTest

const PipeScript := preload("res://pipe.gd")
const PiecesScript := preload("res://pipe_pieces.gd")
const HauntScript := preload("res://haunt.gd")


func _pipe(gap_y := 100.0) -> Node2D:
	var pipe := Node2D.new()
	pipe.set_script(PipeScript)
	add_child_autofree(pipe)
	pipe.reset(gap_y, 80.0)
	return pipe


func _haunt(kind: int, y: float) -> Node2D:
	var haunt := Node2D.new()
	haunt.set_script(HauntScript)
	add_child_autofree(haunt)
	haunt.launch(kind, Vector2(100.0, y), 1.0)
	return haunt


func test_pipe_is_built_of_small_pieces() -> void:
	var pipe := _pipe()
	assert_gt(pipe.cell_pos.size(), 200)
	assert_eq(pipe.cell_pos.size(), pipe.cell_src.size())


func test_pipe_pieces_leave_the_gap_free() -> void:
	var pipe := _pipe(100.0)
	for p in pipe.cell_pos:
		var inside_gap: bool = p.y + PipeScript.PIECE > pipe.gap_top() and p.y < pipe.gap_bottom()
		assert_false(inside_gap, "piece at %s is inside the gap" % p)


func test_breaking_a_pipe_creates_one_piece_per_cell() -> void:
	var pipe := _pipe()
	var pieces := Node2D.new()
	pieces.set_script(PiecesScript)
	add_child_autofree(pieces)
	pieces.burst(pipe, Vector2(40.0, 100.0), LFRandom.new(1))
	assert_eq(pieces.piece_count(), pipe.cell_pos.size())


func test_ghost_drifts_slowly_along_y() -> void:
	var ghost := _haunt(HauntScript.Kind.GHOST, 100.0)
	ghost.step(1.0)
	assert_almost_eq(ghost.position.x, 100.0 - HauntScript.GHOST_SPEED, 0.01)
	assert_almost_eq(ghost.position.y, 100.0 + HauntScript.GHOST_DRIFT, 0.01)


func test_bat_is_faster_than_ghost_and_waves_slightly() -> void:
	var bat := _haunt(HauntScript.Kind.BAT, 100.0)
	var low := 100.0
	var high := 100.0
	for i in 60:
		bat.step(1.0 / 60.0)
		low = minf(low, bat.position.y)
		high = maxf(high, bat.position.y)
	assert_gt(HauntScript.BAT_SPEED, HauntScript.GHOST_SPEED)
	assert_lte(high - low, HauntScript.BAT_WAVE * 2.0 + 0.01)
	assert_gt(high - low, 1.0)
