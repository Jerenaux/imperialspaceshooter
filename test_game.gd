extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.credits = 40
	game.enemies = [{"pos": Vector2(360, 300), "hp": 1}]
	game.destroy_enemy(0)
	assert(game.credits == 50, "Kills must award credits")
	game.phase = game.Phase.SHOP
	assert(game.buy_upgrade("speed"), "Credits must buy a speed upgrade")
	assert(game.credits == 20 and game.speed_level == 1, "Upgrade must apply and charge once")
	game.round_number = 2
	game.phase = game.Phase.PLAYING
	game.invincible_timer = 0.0
	game.damage_player()
	game.invincible_timer = 0.0
	game.damage_player()
	game.invincible_timer = 0.0
	game.damage_player()
	assert(game.round_number == 2 and game.lives == 3, "Three hits must restart the current round")
	assert(game.credits == 20 and game.speed_level == 1, "Round restart must preserve upgrades and credits")
	game.show_round_clear()
	assert(game.phase == game.Phase.SHOP, "Clearing a round must open the upgrade shop")
	game.advance_round()
	assert(game.round_number == 3 and game.lives == 3, "Continuing must start the next round")
	game.round_number = 5
	game.show_round_clear()
	assert(game.phase == game.Phase.WON, "Clearing round five must win the game")
	game.advance_round()
	assert(game.round_number == 1 and game.credits == 0 and game.speed_level == 0, "Play Again must start fresh")
	game.queue_free()
	print("Game checks passed")
	quit()
