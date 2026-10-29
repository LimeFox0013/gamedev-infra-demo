extends Node2D

var direction := Vector2.UP
var enemy := false
var cooldown := LFIntervalTimer.new(0.32)
var decision := LFIntervalTimer.new(1.1)
var shield := 2.0
var tread := 0.0

func _ready() -> void:
    cooldown.fire_next()

func _draw() -> void:
    var color := Color('#e5b94e') if not enemy else Color('#c7d8c7')
    draw_set_transform(Vector2.ZERO, direction.angle() + PI / 2)
    for x in [-13, 7]:
        draw_rect(Rect2(x, -14, 6, 28), Color('#46504b'))
        for y in range(-12, 14, 6):
            draw_rect(Rect2(x + 1, y + int(tread) % 3, 4, 2), color.darkened(0.3))
    draw_rect(Rect2(-7, -11, 14, 23), color.darkened(0.25))
    draw_rect(Rect2(-6, -10, 11, 19), color)
    draw_rect(Rect2(-5, -5, 10, 11), color.lightened(0.2))
    draw_rect(Rect2(-2, -21, 4, 17), color)
    draw_rect(Rect2(-2, -3, 4, 5), Color('#61664c'))
    if shield > 0 and not enemy:
        draw_rect(Rect2(-17, -17, 34, 34), Color('#7cd6c3'), false, 1)

func step(delta: float) -> void:
    shield = maxf(0, shield - delta)
    var world = get_parent()
    var moving := false
    if enemy:
        if decision.tick(delta):
            direction = world.rng.pick([Vector2.DOWN, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP])
        moving = true
    else:
        for pair in [["move_up", Vector2.UP], ["move_down", Vector2.DOWN], ["move_left", Vector2.LEFT], ["move_right", Vector2.RIGHT]]:
            if Input.is_action_pressed(pair[0]):
                direction = pair[1]
                moving = true
                break
    if moving:
        var next := position + direction * (49.0 if enemy else 100.0) * delta
        if world.can_move(next, self):
            position = next
            tread += delta * 24
        elif enemy:
            decision.fire_next()
    if cooldown.tick(delta):
        if enemy or Input.is_action_pressed("fire"):
            world.fire(self)
        else:
            cooldown.fire_next()
    queue_redraw()
