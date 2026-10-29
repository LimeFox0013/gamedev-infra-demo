extends Node2D

const TANK := preload("res://tank.gd")
const FIELD := Rect2(36, 92, 520, 520)
const CELL := 20
var rng := LFRandom.new(1985)
var spawn_timer := LFIntervalTimer.new(3.8)
var walls: Dictionary = {}
var enemies: Array[Node2D] = []
var bullets: Array[Dictionary] = []
var blasts: Array[Dictionary] = []
var player: Node2D
var score := 0
var lives := 3
var remaining := 20
var kills := 0
var paused := false
var ended := false
var base_alive := true
var score_label: Label
var status_label: Label
var info_label: Label
var overlay: Label
var font := ThemeDB.fallback_font

func label_at(node_name: String, pos: Vector2, size: int, color: Color) -> Label:
    var result := Label.new()
    result.name = node_name
    result.position = pos
    result.add_theme_font_size_override("font_size", size)
    result.add_theme_color_override("font_color", color)
    add_child(result)
    return result

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color('#13191b'))
    label_at("Title", Vector2(36, 19), 28, Color('#e5b94e')).text = "BATTLE / TANKS"
    label_at("Subtitle", Vector2(338, 30), 12, Color('#80968e')).text = "8-BIT DEFENSE     /     1985"
    label_at("Stage", Vector2(589, 95), 15, Color('#e5b94e')).text = "STAGE 01"
    label_at("Mission", Vector2(589, 132), 13, Color('#80968e')).text = "HOLD THE LINE\nDEFEND THE EAGLE"
    score_label = label_at("Score", Vector2(589, 220), 21, Color('#f1ebd5'))
    status_label = label_at("Status", Vector2(589, 295), 17, Color('#e5b94e'))
    info_label = label_at("Remaining", Vector2(589, 361), 16, Color('#c7d8c7'))
    label_at("Controls", Vector2(589, 465), 14, Color('#80968e')).text = "ARROWS   MOVE\nSPACE    FIRE\nP        PAUSE\nENTER    RESTART"
    label_at("Footer", Vector2(36, 633), 13, Color('#80968e')).text = "BREAK BRICKS.  STOP THE INVASION.  PROTECT YOUR BASE."
    overlay = label_at("Overlay", Vector2(136, 300), 25, Color('#fff0af'))
    overlay.z_index = 10
    for y in range(2, 23):
        for x in range(1, 25):
            if x in [3, 4, 7, 8, 16, 17, 21, 22] and y % 8 < 6:
                walls[Vector2i(x, y)] = 1
    for x in range(10, 16):
        walls[Vector2i(x, 23)] = 1
    for y in [24, 25]:
        walls[Vector2i(10, y)] = 1
        walls[Vector2i(15, y)] = 1
    for cell in [Vector2i(11, 8), Vector2i(12, 8), Vector2i(13, 8), Vector2i(14, 8), Vector2i(1, 15), Vector2i(2, 15), Vector2i(23, 15), Vector2i(24, 15)]:
        walls[cell] = 2
    var eagle := Node2D.new()
    eagle.name = "EagleBase"
    eagle.position = Vector2(296, 592)
    add_child(eagle)
    player = TANK.new()
    player.name = "PlayerTank"
    player.position = Vector2(156, 582)
    add_child(player)
    spawn_enemy(Vector2(156, 114))
    spawn_enemy(Vector2(526, 114))
    refresh_hud()

func refresh_hud() -> void:
    score_label.text = "%06d\nSCORE" % score
    status_label.text = "LIVES   %02d" % lives
    info_label.text = "ENEMY   %02d\n\nKILLS   %02d / 20" % [remaining + enemies.size(), kills]

func spawn_enemy(pos: Vector2) -> void:
    var tank := TANK.new()
    tank.enemy = true
    tank.decision.interval = 2.5
    tank.direction = Vector2.DOWN
    tank.cooldown.interval = 1.9
    tank.name = "EnemyTank"
    tank.position = pos
    add_child(tank, true)
    enemies.append(tank)
    remaining -= 1

func can_move(pos: Vector2, tank: Node2D) -> bool:
    var box := Rect2(pos - Vector2(14, 14), Vector2(28, 28))
    if not FIELD.encloses(box):
        return false
    if box.intersects(Rect2(278, 574, 36, 38)):
        return false
    for cell: Vector2i in walls:
        if box.intersects(Rect2(FIELD.position + Vector2(cell) * CELL, Vector2(CELL, CELL))):
            return false
    for other in enemies + [player]:
        if other != tank and pos.distance_to(other.position) < 29:
            return false
    return true

func fire(tank: Node2D) -> void:
    var marker := Node2D.new()
    marker.name = "EnemyShell" if tank.enemy else "PlayerShell"
    marker.position = tank.position + tank.direction * 23
    add_child(marker, true)
    bullets.append({"node": marker, "dir": tank.direction, "enemy": tank.enemy})

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("restart"):
        get_tree().reload_current_scene()
        return
    if Input.is_action_just_pressed("pause") and not ended:
        paused = not paused
        overlay.text = "      PAUSED" if paused else ""
    if not paused and not ended:
        player.step(delta)
        for tank in enemies:
            tank.step(delta)
        if spawn_timer.tick(delta) and remaining > 0 and enemies.size() < 4:
            var pos := Vector2(float(rng.pick([66, 296, 526])), 114)
            if can_move(pos, null):
                spawn_enemy(pos)
        step_bullets(delta)
    for i in range(blasts.size() - 1, -1, -1):
        blasts[i]["life"] -= delta
        if blasts[i]["life"] <= 0:
            blasts.remove_at(i)
    refresh_hud()
    queue_redraw()

func step_bullets(delta: float) -> void:
    for i in range(bullets.size() - 1, -1, -1):
        var bullet: Dictionary = bullets[i]
        var node: Node2D = bullet.node
        var hit := false
        for substep in 3:
            node.position += bullet.dir * 285 * delta / 3
            if not FIELD.has_point(node.position):
                hit = true
            var cell := Vector2i((node.position - FIELD.position) / CELL)
            if walls.has(cell):
                if walls[cell] == 1:
                    walls.erase(cell)
                hit = true
            if node.position.distance_to(Vector2(296, 592)) < 19:
                base_alive = false
                finish(false)
                hit = true
            if not hit:
                if bullet.enemy:
                    if node.position.distance_to(player.position) < 16:
                        hit = true
                        if player.shield <= 0:
                            blasts.append({"pos": player.position, "life": 0.35})
                            lives -= 1
                            player.position = Vector2(156, 582)
                            player.shield = 2.5
                            if lives <= 0:
                                finish(false)
                else:
                    for tank in enemies:
                        if node.position.distance_to(tank.position) < 17:
                            enemies.erase(tank)
                            tank.queue_free()
                            score += 100
                            kills += 1
                            hit = true
                            if kills == 20:
                                finish(true)
                            break
            if hit:
                break
        if hit:
            blasts.append({"pos": node.position, "life": 0.25})
            node.queue_free()
            bullets.remove_at(i)

func finish(won: bool) -> void:
    ended = true
    overlay.text = "STAGE CLEAR!" if won else "BASE LOST" if not base_alive else "GAME OVER"
    overlay.text += "\nENTER TO RESTART"

func _draw() -> void:
    draw_rect(Rect2(31, 87, 530, 530), Color('#43544e'))
    draw_rect(FIELD, Color('#080e10'))
    for x in range(26):
        for y in range(26):
            draw_rect(Rect2(FIELD.position + Vector2(x * 20, y * 20), Vector2(1, 1)), Color('#172122'))
    for cell: Vector2i in walls:
        var pos := FIELD.position + Vector2(cell) * CELL
        if walls[cell] == 1:
            draw_rect(Rect2(pos, Vector2(19, 19)), Color('#974e35'))
            for row in 4:
                draw_line(pos + Vector2(0, row * 5), pos + Vector2(19, row * 5), Color('#d38454'))
                draw_line(pos + Vector2(5 if row % 2 else 12, row * 5), pos + Vector2(5 if row % 2 else 12, row * 5 + 5), Color('#291e1b'))
        else:
            draw_rect(Rect2(pos, Vector2(19, 19)), Color('#687b80'))
            draw_rect(Rect2(pos + Vector2(3, 3), Vector2(13, 13)), Color('#b1c1bf'), false, 2)
    var base_color := Color('#e5b94e') if base_alive else Color('#4d4844')
    draw_rect(Rect2(280, 575, 32, 35), Color('#25312d'))
    draw_colored_polygon(PackedVector2Array([Vector2(296, 584), Vector2(282, 579), Vector2(286, 595), Vector2(293, 599), Vector2(290, 605), Vector2(302, 605), Vector2(299, 599), Vector2(306, 595), Vector2(310, 579)]), base_color)
    draw_rect(Rect2(293, 581, 6, 15), base_color.lightened(0.25))
    for bullet in bullets:
        draw_rect(Rect2(bullet.node.position - Vector2(2, 3), Vector2(4, 6)), Color('#fff0af'))
    for blast in blasts:
        var radius: float = (0.4 - blast.life) * 65
        draw_circle(blast.pos, radius, Color('#edaa4d'), false, 3)
        draw_line(blast.pos - Vector2(radius, radius), blast.pos + Vector2(radius, radius), Color('#fff0af'), 2)
