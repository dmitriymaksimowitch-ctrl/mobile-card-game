extends SceneTree
func _initialize(): call_deferred("run_checks")
func run_checks():
	var visuals = load("res://card_visuals.gd")
	var cards = ["Т♣", "8♠", "7♦", "6♣", "6♥", "6♦", "Т♥"]
	cards.sort_custom(func(a, b): return visuals.card_less(a, b, "♣"))
	assert(cards == ["6♦", "7♦", "6♥", "Т♥", "8♠", "6♣", "Т♣"])
	assert(ProjectSettings.get_setting("display/window/stretch/aspect") == "expand")
	for amount in [1, 2, 6, 12, 24, 36]:
		var fitted: Vector2 = visuals.fitted_hand_card_size(amount, Vector2(174, 250))
		var step: float = visuals.hand_step(amount, fitted)
		assert(fitted.x > 0.0 and fitted.y > 0.0)
		assert(fitted.x + step * (amount - 1) <= 996.1)
		if amount > 1: assert(step >= fitted.x)
	var game = load("res://main.gd").new(); root.add_child(game)
	game.count = 2; game.durak_variant = "simple"
	game.hands.append([]); game.hands.append(["7♠"])
	game.table.append({"attack":"6♠", "defense":""})
	game.actor = 1; game.defender = 1; game.attacker = 0; game.phase = "defense"
	game.play(1, "7♠")
	assert(game.phase == "resolving"); assert(game.table[0].defense == "7♠")
	await create_timer(0.45).timeout
	assert(game.phase == "resolving")
	await create_timer(0.9).timeout
	assert(game.phase == "over")
	game.show_menu(); game.phase = "attack"; game.finish_defense(); game.show_menu()
	await create_timer(1.0).timeout
	assert(game.phase == "menu")
	game.hands[0].assign(["6♣", "8♦"]); game.hands[1].assign(["9♣"])
	game.actor = 0; game.phase = "attack"; game.limit = 6
	game.table.clear(); game.table.append({"attack":"6♠", "defense":"7♠"})
	var view = game.make_hand_card("8♦", true); game.add_child(view)
	game.attempt_hand_card("8♦", view)
	assert(game.hands[0].size() == 2); assert(view.get_meta("shaking", false))
	await create_timer(0.4).timeout
	assert(not view.get_meta("shaking", false)); assert(abs(view.rotation_degrees) < 0.01)
	for pairs in [1,2,3,6]:
		game.table.clear()
		for i in pairs: game.table.append({"attack":"6♠", "defense":"7♠"})
		game.draw_table(); await process_frame; await process_frame
		var area = game.find_child("PlayedCards", true, false)
		assert(area != null and area.get_child_count() == pairs * 2)
		for height in [600,1000,1400]:
			area.get_parent().size = Vector2(836,height)
			assert(abs(area.position.y + area.size.y / 2 - height / 2.0) < 1)
	print("PASS: adaptive hand, sorting, invalid move, final move pause, cancelled result, centered 1/2/3/6 pairs, full screen")
	quit()
