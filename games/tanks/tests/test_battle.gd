extends GutTest

var battle: Node2D

func before_each() -> void:
    battle = load("res://main.tscn").instantiate()
    add_child_autofree(battle)
    battle.set_process(false)

func test_initial_defense() -> void:
    assert_eq(battle.lives, 3)
    assert_eq(battle.enemies.size(), 2)
    assert_not_null(battle.get_node("EagleBase"))
    assert_true(battle.can_move(battle.player.position, battle.player))
    assert_false(battle.can_move(Vector2.ZERO, battle.player))

func test_shell_destroys_enemy_and_scores() -> void:
    var target: Node2D = battle.enemies[0]
    battle.player.position = target.position + Vector2(0, 50)
    battle.fire(battle.player)
    for i in 10:
        battle.step_bullets(1.0 / 60)
    assert_eq(battle.score, 100)
    assert_eq(battle.kills, 1)
    assert_eq(battle.enemies.size(), 1)

func test_brick_breaks_but_steel_survives() -> void:
    var brick := Vector2i(5, 5)
    battle.walls[brick] = 1
    battle.player.position = battle.FIELD.position + Vector2(brick) * 20 + Vector2(10, 40)
    battle.fire(battle.player)
    battle.step_bullets(0.04)
    assert_false(battle.walls.has(brick))
    battle.walls[brick] = 2
    battle.fire(battle.player)
    battle.step_bullets(0.04)
    assert_eq(battle.walls[brick], 2)
