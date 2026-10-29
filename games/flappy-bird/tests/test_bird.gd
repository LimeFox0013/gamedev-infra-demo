extends GutTest

const BirdScript := preload("res://bird.gd")
const PipeScript := preload("res://pipe.gd")


func _bird() -> Node2D:
	var bird := Node2D.new()
	bird.set_script(BirdScript)
	add_child_autofree(bird)
	return bird


func test_flap_sets_upward_speed() -> void:
	var bird := _bird()
	bird.flap()
	assert_eq(bird.velocity, BirdScript.FLAP_SPEED)


func test_gravity_pulls_bird_down() -> void:
	var bird := _bird()
	var y := bird.position.y
	bird.step(0.1)
	assert_gt(bird.position.y, y)


func test_fall_speed_is_capped() -> void:
	var bird := _bird()
	for i in 200:
		bird.step(0.05)
	assert_eq(bird.velocity, BirdScript.MAX_FALL)


func test_pipe_gap_edges() -> void:
	var pipe := Node2D.new()
	pipe.set_script(PipeScript)
	add_child_autofree(pipe)
	pipe.reset(100.0, 50.0)
	assert_eq(pipe.gap_bottom() - pipe.gap_top(), PipeScript.GAP)
	assert_eq(pipe.position.x, 50.0)
