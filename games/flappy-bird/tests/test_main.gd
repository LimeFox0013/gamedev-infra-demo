extends GutTest

const MainScene := preload("res://main.tscn")


func _playing_main() -> Node2D:
	var main: Node2D = MainScene.instantiate()
	add_child_autofree(main)
	main.state = main.State.PLAYING
	return main


func _pipe_over_bird(main: Node2D) -> Node2D:
	main._spawn_pipe()
	var pipe: Node2D = main._pipes[0]
	pipe.reset(200.0, main._bird.position.x)
	return pipe


func test_hitting_a_pipe_breaks_it_but_the_game_goes_on() -> void:
	var main := _playing_main()
	_pipe_over_bird(main)
	main._check_collisions()
	assert_eq(main.state, main.State.PLAYING)
	assert_true(main.get_node("Obstacles").has_node("PipePieces"))
	assert_eq(main._pipes.size(), 0)


func test_a_broken_pipe_does_not_hit_again() -> void:
	var main := _playing_main()
	_pipe_over_bird(main)
	main._check_collisions()
	main._check_collisions()
	assert_eq(main.get_node("Obstacles").get_children().filter(func(n): return n.name.begins_with("PipePieces")).size(), 1)


func test_a_ghost_still_ends_the_game() -> void:
	var main := _playing_main()
	main._haunt_timer.interval = 0.0
	main._spawn_haunt()
	var haunt: Node2D = main._haunts[0]
	haunt.position = main._bird.position
	main._check_collisions()
	assert_eq(main.state, main.State.DEAD)


func test_the_ground_still_ends_the_game() -> void:
	var main := _playing_main()
	main._bird.position.y = main.GROUND_Y
	main._check_collisions()
	assert_eq(main.state, main.State.DEAD)
