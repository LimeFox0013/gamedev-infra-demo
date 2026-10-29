extends GutTest

const PipeScript := preload("res://pipe.gd")
const PiecesScript := preload("res://pipe_pieces.gd")
const HauntScript := preload("res://haunt.gd")
const BirdScript := preload("res://bird.gd")


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


func test_pipe_hits_bird_outside_the_gap_only() -> void:
	var pipe := _pipe(100.0)
	var half := Vector2(7.0, 4.5)
	assert_false(pipe.hits(Vector2(80.0, 100.0), half), "centre of gap is free")
	assert_true(pipe.hits(Vector2(80.0, 60.0), half), "above the gap hits the top pipe")
	assert_true(pipe.hits(Vector2(80.0, 140.0), half), "below the gap hits the bottom pipe")
	assert_true(pipe.hits(Vector2(80.0, -500.0), half), "far above the screen still hits")
	assert_false(pipe.hits(Vector2(20.0, 60.0), half), "a bird far to the left is safe")


func test_pipe_edge_touch_matches_the_drawing() -> void:
	var pipe := _pipe(100.0)
	var half := Vector2(7.0, 4.5)
	assert_true(pipe.hits(Vector2(80.0 - 11.0 - 6.0, 70.0), half), "beak over the cap edge hits")
	assert_false(pipe.hits(Vector2(80.0 - 11.0 - 8.0, 70.0), half), "just clear of the cap")


func test_bird_cannot_leave_through_the_top() -> void:
	var bird := _bird()
	for i in 600:
		bird.flap()
		bird.step(1.0 / 60.0)
	assert_gte(bird.position.y, BirdScript.CEILING)


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


func _bird() -> Node2D:
	var bird := Node2D.new()
	bird.set_script(BirdScript)
	add_child_autofree(bird)
	return bird
