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
	# Prevent the old bug: deck/trump must remain unscaled outside the
	# legacy table-centering control, and the deck must match hand-card size.
	game.deck.assign(["6♦", "7♦"])
	game.hands[0].assign(["6♣", "7♣", "8♠", "9♦", "Т♥", "К♠"])
	for pairs in [1,2,3,6]:
		game.table.clear()
		for i in pairs: game.table.append({"attack":"6♠", "defense":"7♠"})
		game.draw_table(); await process_frame; await process_frame
		var area = game.find_child("PlayedCards", true, false)
		assert(area != null and area.get_child_count() == pairs * 2)
		var deck_view: Control = game.find_child("DeckDisplay", true, false)
		assert(deck_view != null and deck_view.scale == Vector2.ONE)
		assert(deck_view.get_parent().name != "Control")
		assert(deck_view.get_child_count() == 6)
		var expected_size: Vector2 = visuals.fitted_hand_card_size(6, Vector2(174, 250))
		var trump_view: Control = deck_view.get_node("TrumpCard")
		var deck_back: Control = deck_view.get_node("DeckBack0")
		assert(deck_back.size.is_equal_approx(expected_size))
		assert(trump_view.size.is_equal_approx(expected_size))
		assert(is_equal_approx(trump_view.rotation_degrees, 90.0))
		assert(trump_view.z_index < deck_back.z_index)
		assert(is_equal_approx(trump_view.position.x, expected_size.x / 2.0))
		for height in [600,1000,1400]:
			area.get_parent().size = Vector2(836,height)
			assert(abs(area.position.y + area.size.y / 2 - height / 2.0) < 1)
	print("PASS: deck card size/half-trump/stack, adaptive hand, sorting, invalid move, table layout")
	quit()
