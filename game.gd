extends Node2D

const PLAYER = preload("res://assets/player-spaceship.png")
const ENEMY = preload("res://assets/enemy-spaceship.png")
const WIDTH = 720.0
const HEIGHT = 960.0
const TOTAL_ROUNDS = 5
enum Phase {PLAYING, SHOP, WON}

var phase = Phase.PLAYING
var round_number = 1
var lives = 3
var credits = 0
var fire_level = 0
var speed_level = 0
var player_pos = Vector2(360, 820)
var enemies: Array = []
var bullets: Array = []
var bursts: Array = []
var stars: Array = []
var spawn_remaining = 0
var spawn_timer = 0.0
var shot_timer = 0.0
var invincible_timer = 0.0
var banner_timer = 0.0
var world_time = 0.0
var rng = RandomNumberGenerator.new()
var hud: Label
var hint: Label
var panel: PanelContainer
var title: Label
var detail: Label
var fire_button: Button
var speed_button: Button
var continue_button: Button

func _ready() -> void:
	rng.randomize()
	for i in 100:
		stars.append({"pos": Vector2(rng.randf_range(0, WIDTH), rng.randf_range(0, HEIGHT)), "size": rng.randf_range(0.8, 2.3), "speed": rng.randf_range(16, 55)})
	build_ui()
	start_round()

func build_ui() -> void:
	var layer: CanvasLayer = $UI
	hud = Label.new()
	hud.position = Vector2(22, 18)
	hud.add_theme_font_size_override("font_size", 25)
	hud.add_theme_color_override("font_color", Color("e7f7ff"))
	layer.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(22, 923)
	hint.text = "WASD / ARROWS  MOVE     SPACE  FIRE"
	hint.add_theme_font_size_override("font_size", 19)
	hint.add_theme_color_override("font_color", Color("92a8bd"))
	layer.add_child(hint)
	panel = PanelContainer.new()
	panel.position = Vector2(95, 238)
	panel.custom_minimum_size = Vector2(530, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("111c31")
	style.border_color = Color("32d8ed")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(25)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("f6f8ff"))
	column.add_child(title)
	detail = Label.new()
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 20)
	detail.add_theme_color_override("font_color", Color("b9cadc"))
	column.add_child(detail)
	fire_button = make_button(column)
	fire_button.pressed.connect(func(): buy_upgrade("fire"))
	speed_button = make_button(column)
	speed_button.pressed.connect(func(): buy_upgrade("speed"))
	continue_button = make_button(column)
	continue_button.pressed.connect(advance_round)
	panel.hide()

func make_button(parent: VBoxContainer) -> Button:
	var button = Button.new()
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", 21)
	parent.add_child(button)
	return button

func start_round() -> void:
	phase = Phase.PLAYING
	lives = 3
	player_pos = Vector2(360, 820)
	enemies.clear()
	bullets.clear()
	bursts.clear()
	spawn_remaining = 4 + round_number * 2
	spawn_timer = 0.5
	shot_timer = 0.0
	invincible_timer = 1.5
	panel.hide()
	refresh_hud()

func _process(delta: float) -> void:
	world_time += delta
	for star in stars:
		star.pos.y = fmod(star.pos.y + star.speed * delta, HEIGHT)
	if banner_timer > 0:
		banner_timer -= delta
	if phase == Phase.PLAYING:
		update_game(delta)
	queue_redraw()

func update_game(delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction += Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	player_pos += direction.normalized() * (330.0 + speed_level * 65.0) * delta
	player_pos.x = clampf(player_pos.x, 45, WIDTH - 45)
	player_pos.y = clampf(player_pos.y, 500, HEIGHT - 90)
	shot_timer -= delta
	invincible_timer = maxf(0, invincible_timer - delta)
	if Input.is_key_pressed(KEY_SPACE) and shot_timer <= 0:
		fire_player()
		shot_timer = 0.30 / (1.0 + fire_level * 0.32)
	spawn_timer -= delta
	if spawn_remaining > 0 and spawn_timer <= 0:
		spawn_enemy()
		spawn_remaining -= 1
		spawn_timer = maxf(0.42, 1.0 - round_number * 0.09)
	for enemy in enemies:
		enemy.age += delta
		enemy.pos.y = minf(enemy.pos.y + (90.0 + round_number * 8.0) * delta, enemy.hold_y)
		enemy.pos.x = enemy.base_x + sin(enemy.age * 1.45 + enemy.seed) * 35.0
		enemy.shot -= delta
		if enemy.pos.y > 0 and enemy.shot <= 0:
			bullets.append({"pos": enemy.pos + Vector2(0, 30), "velocity": Vector2(0, 270 + round_number * 25), "hostile": true})
			enemy.shot = maxf(0.85, 2.3 - round_number * 0.18) + rng.randf_range(0, 0.8)
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		bullet.pos += bullet.velocity * delta
		if bullet.pos.y < -20 or bullet.pos.y > HEIGHT + 20:
			bullets.remove_at(i)
			continue
		if bullet.hostile:
			if bullet.pos.distance_to(player_pos) < 30:
				bullets.remove_at(i)
				damage_player()
				if phase != Phase.PLAYING or invincible_timer > 1.4:
					return
		else:
			for j in range(enemies.size() - 1, -1, -1):
				if bullet.pos.distance_to(enemies[j].pos) < 34:
					bullets.remove_at(i)
					enemies[j].hp -= 1
					if enemies[j].hp <= 0:
						destroy_enemy(j)
					break
	for i in range(bursts.size() - 1, -1, -1):
		bursts[i].time -= delta
		if bursts[i].time <= 0:
			bursts.remove_at(i)
	if spawn_remaining == 0 and enemies.is_empty():
		show_round_clear()

func spawn_enemy() -> void:
	var x = rng.randf_range(80, WIDTH - 80)
	enemies.append({"pos": Vector2(x, -50), "base_x": x, "hold_y": rng.randf_range(155, 430), "age": 0.0, "seed": rng.randf_range(0, TAU), "shot": rng.randf_range(1.0, 2.2), "hp": 1 + int(round_number >= 4)})

func fire_player() -> void:
	bullets.append({"pos": player_pos + Vector2(0, -43), "velocity": Vector2(0, -760), "hostile": false})

func destroy_enemy(index: int) -> void:
	bursts.append({"pos": enemies[index].pos, "time": 0.35})
	enemies.remove_at(index)
	credits += 10
	refresh_hud()

func damage_player() -> void:
	if invincible_timer > 0 or phase != Phase.PLAYING:
		return
	lives -= 1
	if lives == 0:
		start_round()
		banner_timer = 2.5
	else:
		invincible_timer = 1.2
		refresh_hud()

func show_round_clear() -> void:
	phase = Phase.SHOP if round_number < TOTAL_ROUNDS else Phase.WON
	bullets.clear()
	panel.show()
	refresh_shop()

func upgrade_cost(kind: String) -> int:
	return (40 + fire_level * 35) if kind == "fire" else (30 + speed_level * 25)

func buy_upgrade(kind: String) -> bool:
	if phase != Phase.SHOP:
		return false
	var level = fire_level if kind == "fire" else speed_level
	var cost = upgrade_cost(kind)
	if level >= 3 or credits < cost:
		return false
	credits -= cost
	if kind == "fire":
		fire_level += 1
	else:
		speed_level += 1
	refresh_hud()
	refresh_shop()
	return true

func refresh_shop() -> void:
	if phase == Phase.WON:
		title.text = "SECTOR CLEARED"
		detail.text = "All five rounds complete!  Credits: %d" % credits
		fire_button.hide()
		speed_button.hide()
		continue_button.text = "PLAY AGAIN"
		return
	title.text = "ROUND %d CLEARED" % round_number
	detail.text = "Credits: %d   •   Choose an upgrade" % credits
	fire_button.show()
	speed_button.show()
	fire_button.text = "RAPID FIRE  Lv %d/3  —  %d credits" % [fire_level, upgrade_cost("fire")]
	speed_button.text = "THRUSTERS  Lv %d/3  —  %d credits" % [speed_level, upgrade_cost("speed")]
	fire_button.disabled = fire_level >= 3 or credits < upgrade_cost("fire")
	speed_button.disabled = speed_level >= 3 or credits < upgrade_cost("speed")
	continue_button.text = "START ROUND %d" % (round_number + 1)

func advance_round() -> void:
	if phase == Phase.WON:
		round_number = 1
		credits = 0
		fire_level = 0
		speed_level = 0
	elif phase == Phase.SHOP:
		round_number += 1
	else:
		return
	start_round()

func refresh_hud() -> void:
	hud.text = "ROUND %d/%d     LIVES %d     CREDITS %d" % [round_number, TOTAL_ROUNDS, lives, credits]

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, HEIGHT)), Color("07101f"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, 64)), Color("111c31"))
	for star in stars:
		draw_circle(star.pos, star.size, Color(0.48, 0.76, 1.0, 0.55))
	for enemy in enemies:
		draw_set_transform(enemy.pos, PI)
		draw_texture_rect(ENEMY, Rect2(Vector2(-43, -43), Vector2(86, 86)), false)
		draw_set_transform(Vector2.ZERO)
	for bullet in bullets:
		var color = Color("ff4bc9") if bullet.hostile else Color("43e8ff")
		draw_line(bullet.pos, bullet.pos + Vector2(0, -14 if bullet.hostile else 14), color, 6, true)
		draw_circle(bullet.pos, 4, Color.WHITE)
	for burst in bursts:
		draw_circle(burst.pos, (0.35 - burst.time) * 95, Color(1, 0.37, 0.15, burst.time * 1.8), false, 5)
	var player_alpha = 0.55 if invincible_timer > 0 and int(world_time * 10) % 2 == 1 else 1.0
	draw_texture_rect(PLAYER, Rect2(player_pos - Vector2(53, 53), Vector2(106, 106)), false, Color(1, 1, 1, player_alpha))
	if banner_timer > 0:
		draw_rect(Rect2(Vector2(0, 445), Vector2(WIDTH, 72)), Color(0, 0, 0, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(195, 491), "ROUND RESTARTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("ff8695"))
