extends Control

const CardVisuals = preload("res://card_visuals.gd")
signal exit_to_menu

const SUITS := ["♣", "♦", "♥", "♠"]
const RANKS := ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]

var player_count := 2
var hands: Array[Array] = []
var active: Array[bool] = []
var pile: Array[String] = []
var last_batch: Array[String] = []
var last_player := -1
var turn := 0
var claimed_rank := ""
var selected: Array[int] = []
var finish_order: Array[int] = []
var message := ""
var running := false
var revision := 0
var pending_challenge: Dictionary = {}
var content: VBoxContainer

func _ready() -> void:
	show_setup()

func screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(CardVisuals.make_background())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)

func heading(text: String, sub := "") -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.07, 0.06, 0.9)
	style.border_color = Color("9c7a35")
	style.border_width_bottom = 3
	style.set_corner_radius_all(22)
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)
	var column := VBoxContainer.new(); panel.add_child(column)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 58)
	column.add_child(label)
	if sub:
		var note := Label.new()
		note.text = sub
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.modulate = Color("bcd6ca")
		column.add_child(note)

func button(text: String, call: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 82
	result.pressed.connect(call)
	content.add_child(result)
	return result

func small_button(text: String, call: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.custom_minimum_size.y = 78
	result.pressed.connect(call)
	return result

func spacer() -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(space)

func show_setup() -> void:
	revision += 1
	running = false
	screen(); heading("Обмани соседа", "36 карт • вся колода раздаётся игрокам")
	spacer()
	for count in range(2, 5): button("%d игрока • %d бот(а)" % [count, count - 1], start_game.bind(count))
	button("Правила", show_rules)
	spacer(); button("← К выбору игр", func(): exit_to_menu.emit())

func show_rules() -> void:
	screen(); heading("Правила игры", "Обмани соседа")
	var rules := Label.new()
	rules.text = """• Все 36 карт раздаются между 2–4 игроками.

• Начинающий кладёт рубашкой вверх любое количество карт и объявляет их достоинство. Говорить правду необязательно, но объявлять тузов нельзя.

• Следующий игрок либо добавляет любое количество карт, называя то же достоинство, либо проверяет одну карту из последней выложенной стопки.

• Если проверенная карта совпала с объявленным достоинством, проверявший забирает весь стол. Если не совпала — стол забирает игрок, который положил последнюю стопку.

• После взятия стола начинается новый круг, и достоинство можно объявить заново.

• Четыре карты одного достоинства обязательно сбрасываются из руки. Четыре туза не сбрасываются.

• Игроки, избавившиеся от карт, выходят из партии. Проигрывает последний игрок, у которого остались карты."""
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 36)
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.add_child(rules); content.add_child(scroll)
	button("Понятно", show_setup)

func start_game(count: int) -> void:
	revision += 1
	player_count = count
	hands.clear(); active.clear(); pile.clear(); last_batch.clear(); finish_order.clear(); selected.clear(); pending_challenge.clear()
	for player in player_count:
		hands.append([])
		active.append(true)
	var deck: Array[String] = []
	for suit in SUITS:
		for rank in RANKS: deck.append(rank + suit)
	deck.shuffle()
	var dealer := 0
	while not deck.is_empty():
		hands[dealer].append(deck.pop_back())
		dealer = (dealer + 1) % player_count
	for player in player_count: discard_quartets(player)
	turn = randi_range(0, player_count - 1)
	claimed_rank = ""
	last_player = -1
	running = true
	message = "%s начинает новый круг" % player_name(turn)
	draw_game(); schedule_bot()

func draw_game() -> void:
	screen(); var pile_count := Label.new(); pile_count.text = "На столе %d карт" % pile.size(); pile_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; pile_count.add_theme_font_size_override("font_size", 28); pile_count.modulate = Color("f4dfaa"); content.add_child(pile_count)
	add_claim_banner()
	var status := Label.new(); status.text = message; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 58; status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.modulate = Color("f2cf72"); content.add_child(status)
	add_table()
	var hand_title := Label.new(); hand_title.text = "ВАША РУКА • выбрано %d" % selected.size()
	hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hand_title.modulate = Color("bcd6ca"); content.add_child(hand_title)
	add_hand()
	var actions := HBoxContainer.new(); actions.alignment = BoxContainer.ALIGNMENT_CENTER; actions.custom_minimum_size.y = 90; content.add_child(actions)
	if turn == 0 and running:
		if not last_batch.is_empty(): actions.add_child(small_button("Проверить карту", show_challenge_choices))
		if not selected.is_empty():
			if claimed_rank == "": actions.add_child(small_button("Объявить ранг", show_rank_choices))
			else: actions.add_child(small_button("Положить", play_selected.bind(claimed_rank)))
	if actions.get_child_count() == 0:
		var waiting := Label.new(); waiting.text = "Ожидание хода соперника" if turn != 0 else "Выберите карты из руки"
		waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; waiting.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		waiting.size_flags_horizontal = Control.SIZE_EXPAND_FILL; waiting.modulate = Color("9bbbad"); actions.add_child(waiting)
	var nav := HBoxContainer.new(); nav.alignment = BoxContainer.ALIGNMENT_CENTER; nav.custom_minimum_size.y = 90; content.add_child(nav)
	nav.add_child(small_button("Правила", show_rules))
	nav.add_child(small_button("Меню", show_setup))

func add_claim_banner() -> void:
	var panel := PanelContainer.new(); panel.custom_minimum_size.y = 104
	var style := StyleBoxFlat.new(); style.bg_color = Color("3f2b18") if claimed_rank else Color("173b32")
	style.border_color = Color("f2cf72"); style.set_border_width_all(3); style.set_corner_radius_all(22)
	panel.add_theme_stylebox_override("panel", style); content.add_child(panel)
	var label := Label.new(); label.text = ("ЗАЯВЛЕНЫ: %s" % claimed_rank) if claimed_rank else "НОВЫЙ КРУГ — ОБЪЯВИТЕ РАНГ"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 50); label.add_theme_color_override("font_color", Color("fff0b0")); panel.add_child(label)

func opponent_panel(player: int) -> PanelContainer:
	var panel := PanelContainer.new(); panel.custom_minimum_size.x = 300 if player_count == 2 else 235
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.02, 0.10, 0.08, 0.92)
	style.border_color = Color("f2cf72") if player == turn else Color("315c4d")
	style.set_border_width_all(3 if player == turn else 2); style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "%s\n%s" % [player_name(player), "вышел" if not active[player] else "%d карт" % hands[player].size()]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.custom_minimum_size.y = 82
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; panel.add_child(label)
	return panel

func add_table() -> void:
	var felt := Panel.new(); felt.custom_minimum_size.y = 410; felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new(); style.bg_color = Color("0b4f5f"); style.border_color = Color("e0ad4f")
	style.set_border_width_all(11); style.set_corner_radius_all(70); style.shadow_size = 12
	felt.add_theme_stylebox_override("panel", style); content.add_child(felt)
	var pile_note := Label.new(); pile_note.text = "СТОЛ • %d" % pile.size(); pile_note.position = Vector2(42, 28)
	pile_note.modulate = Color("bcd6ca"); felt.add_child(pile_note)
	var shown := mini(pile.size(), 12)
	for index in shown:
		var back := card_back(); back.position = Vector2(220 + index * 35, 112 + (index % 3) * 8)
		back.rotation_degrees = -8 + index * 1.4; back.z_index = index; felt.add_child(back)
	if pile.is_empty():
		var empty := Label.new(); empty.text = "Новый круг — выберите карты и объявите ранг"
		empty.position = Vector2(160, 175); empty.size = Vector2(680, 60)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; empty.modulate = Color(1, 1, 1, 0.45); felt.add_child(empty)
	elif not last_batch.is_empty():
		var note := Label.new(); note.text = "Последняя стопка: %d • положил %s" % [last_batch.size(), player_name(last_player)]
		note.position = Vector2(170, 315); note.size = Vector2(660, 45); note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note.modulate = Color("f2cf72"); felt.add_child(note)
	CardVisuals.add_table_seats(felt, player_names(), hand_counts(), turn, Vector2(996, 410))

func card_back() -> Label:
	var back := Label.new(); back.text = "✦  ✦\n  ✦\n✦  ✦"; back.size = Vector2(128, 176)
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_theme_font_size_override("font_size", 26); back.add_theme_color_override("font_color", Color("b9d8ff"))
	back.add_theme_stylebox_override("normal", CardVisuals.back_style()); return back

func add_hand() -> void:
	var area := Control.new(); area.custom_minimum_size.y = 280; area.clip_contents = false; content.add_child(area)
	if hands[0].is_empty(): return
	var size := Vector2(154, 208)
	var step: float = 0.0 if hands[0].size() == 1 else minf(105.0, (996.0 - size.x) / (hands[0].size() - 1))
	var width := size.x + step * (hands[0].size() - 1); var start := (996.0 - width) / 2.0
	for index in hands[0].size():
		var card: String = hands[0][index]
		var control := Button.new(); CardVisuals.decorate_button(control, card, size, true)
		var chosen := index in selected
		control.position = Vector2(start + index * step, 4 if chosen else 48)
		control.z_index = 500 if chosen else index
		control.pressed.connect(toggle_card.bind(index))
		area.add_child(control)

func toggle_card(index: int) -> void:
	if turn != 0: return
	if index in selected: selected.erase(index)
	else: selected.append(index)
	draw_game()

func show_rank_choices() -> void:
	if turn != 0 or selected.is_empty(): return
	screen(); heading("Что объявить?", "Выбрано карт: %d • можно блефовать" % selected.size()); spacer()
	var grid := GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12); content.add_child(grid)
	for rank in RANKS:
		if rank == "Т": continue
		var choice := Button.new(); choice.text = rank; choice.custom_minimum_size = Vector2(315, 95)
		choice.pressed.connect(play_selected.bind(rank)); grid.add_child(choice)
	spacer(); button("← Назад", draw_game)

func play_selected(rank: String) -> void:
	if turn != 0 or selected.is_empty(): return
	var cards: Array[String] = []
	selected.sort(); selected.reverse()
	for index in selected: cards.append(hands[0].pop_at(index))
	selected.clear()
	play_cards(0, cards, rank)

func play_cards(player: int, cards: Array[String], rank: String) -> void:
	if cards.is_empty(): return
	confirm_previous_exit()
	if check_game_over(): return
	if claimed_rank == "": claimed_rank = rank
	last_batch = cards.duplicate(); last_player = player
	for card in cards: pile.append(card)
	message = "%s кладёт %d карт(ы) и говорит: «%s»" % [player_name(player), cards.size(), claimed_rank]
	turn = next_active(player)
	draw_game(); schedule_bot()

func show_challenge_choices() -> void:
	if turn != 0 or last_batch.is_empty(): return
	screen(); heading("Выберите карту для проверки", "Последняя стопка • заявлено: %s" % claimed_rank); spacer()
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 18); content.add_child(row)
	for index in last_batch.size():
		var choice := Button.new(); choice.custom_minimum_size = Vector2(145, 198)
		choice.add_theme_stylebox_override("normal", CardVisuals.back_style()); choice.text = "✦\n%d" % (index + 1)
		choice.pressed.connect(challenge.bind(0, index)); row.add_child(choice)
	spacer(); button("← Не проверять", draw_game)

func challenge(checker: int, index: int) -> void:
	if index < 0 or index >= last_batch.size(): return
	var checked: String = last_batch[index]
	var truthful: bool = rank_of(checked) == claimed_rank
	var challenged_player := last_player
	var taker: int = checker if truthful else challenged_player
	var amount := pile.size()
	pending_challenge = {"checker": checker, "checked": checked, "truthful": truthful, "taker": taker, "amount": amount}
	show_challenge_result(checked, truthful, taker, amount)

func finish_challenge() -> void:
	if pending_challenge.is_empty() or not running: return
	var checker: int = pending_challenge.checker
	var checked: String = pending_challenge.checked
	var truthful: bool = pending_challenge.truthful
	var taker: int = pending_challenge.taker
	var amount: int = pending_challenge.amount
	pending_challenge.clear()
	for card in pile: hands[taker].append(card)
	pile.clear(); last_batch.clear(); claimed_rank = ""; last_player = -1
	var discarded := discard_quartets(taker)
	message = "%s — %s. %s забирает %d карт%s" % [checked, "правда" if truthful else "обман", player_name(taker), amount, "; каре сброшено" if discarded else ""]
	finish_empty_players()
	if check_game_over(): return
	# Если проверявший забрал стол, ход переходит дальше. Если пойман
	# предыдущий игрок, проверявший начинает новый круг.
	turn = next_active(checker) if truthful else checker
	if not active[turn]: turn = next_active(turn)
	draw_game(); schedule_bot()

func show_challenge_result(checked: String, truthful: bool, taker: int, amount: int) -> void:
	screen(); heading("Проверка карты", "Заявлено: %s" % claimed_rank)
	var result := Label.new()
	result.text = "%s — %s\n%s забирает весь стол" % [checked, "ПРАВДА" if truthful else "ОБМАН", player_name(taker)]
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 40)
	result.modulate = Color("8fe0ac") if truthful else Color("ff9b87")
	content.add_child(result)
	var felt := Panel.new(); felt.custom_minimum_size.y = 720
	var style := StyleBoxFlat.new(); style.bg_color = Color("0b4f5f"); style.border_color = Color("e0ad4f")
	style.set_border_width_all(11); style.set_corner_radius_all(72); style.shadow_size = 12
	felt.add_theme_stylebox_override("panel", style); content.add_child(felt)
	var origin := Vector2(434, 245)
	var destination := Vector2(434, 650)
	if taker != 0:
		var spacing := 720.0 / maxf(1.0, player_count - 1.0)
		destination = Vector2(95 + (taker - 0.5) * spacing, -120)
	var revealed := Label.new(); CardVisuals.decorate_label(revealed, checked, Vector2(154, 208))
	revealed.position = origin + Vector2(-175, 0); revealed.z_index = 100; felt.add_child(revealed)
	for card_index in mini(amount, 12):
		var visual: Control
		if card_index == 0:
			var face := Label.new(); CardVisuals.decorate_label(face, checked, Vector2(154, 208)); visual = face
		else:
			visual = card_back(); visual.scale = Vector2(1.2, 1.2)
		visual.position = origin + Vector2(card_index * 10, card_index * 4)
		visual.rotation_degrees = -5 + card_index * 1.2
		visual.z_index = card_index
		felt.add_child(visual)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(visual, "position", destination, 1.25).set_delay(0.9 + card_index * 0.04)
		tween.tween_property(visual, "rotation_degrees", 0.0, 1.25).set_delay(0.9 + card_index * 0.04)
		tween.tween_property(visual, "scale", Vector2(0.55, 0.55), 1.25).set_delay(0.9 + card_index * 0.04)
		tween.tween_property(visual, "modulate:a", 0.15, 0.55).set_delay(1.55 + card_index * 0.04)
	var ok := button("Понятно", finish_challenge); ok.disabled = true
	enable_challenge_ok(ok, revision)

func enable_challenge_ok(ok: Button, stamp: int) -> void:
	await get_tree().create_timer(2.25).timeout
	if stamp == revision and is_instance_valid(ok): ok.disabled = false

func confirm_previous_exit() -> void:
	if last_player >= 0 and active[last_player] and hands[last_player].is_empty():
		active[last_player] = false
		finish_order.append(last_player)
		message = "%s избавился от карт" % player_name(last_player)

func finish_empty_players() -> void:
	for player in player_count:
		if active[player] and hands[player].is_empty() and player != last_player:
			active[player] = false
			finish_order.append(player)

func check_game_over() -> bool:
	var left: Array[int] = []
	for player in player_count:
		if active[player]: left.append(player)
	if left.size() > 1: return false
	running = false; revision += 1; screen()
	var loser := left[0] if not left.is_empty() else -1
	if loser == 0: heading("Вы проиграли", "У вас остались карты")
	else: heading("Поздравляем с победой!", "%s проиграл" % player_name(loser))
	spacer(); button("Сыграть ещё", start_game.bind(player_count)); button("Главное меню", func(): exit_to_menu.emit()); spacer()
	return true

func schedule_bot() -> void:
	if not running or turn == 0: return
	bot_turn(revision)

func bot_turn(stamp: int) -> void:
	await get_tree().create_timer(1.15).timeout
	if stamp != revision or not running or turn == 0: return
	var player := turn
	if not last_batch.is_empty():
		var owned := 0
		for card in hands[player]:
			if rank_of(card) == claimed_rank: owned += 1
		var certain_lie := owned + last_batch.size() > 4
		if certain_lie or randf() < 0.24:
			challenge(player, randi_range(0, last_batch.size() - 1)); return
	var rank := claimed_rank
	if rank == "": rank = best_rank(player)
	var matching: Array[String] = []
	for card in hands[player]:
		if rank_of(card) == rank: matching.append(card)
	var cards: Array[String] = []
	if not matching.is_empty() and randf() < 0.72:
		var amount := randi_range(1, matching.size())
		for i in amount: cards.append(matching[i])
	else:
		var amount := randi_range(1, mini(3, hands[player].size()))
		var copy := hands[player].duplicate(); copy.shuffle()
		for i in amount: cards.append(copy[i])
	for card in cards: hands[player].erase(card)
	play_cards(player, cards, rank)

func best_rank(player: int) -> String:
	var best := RANKS[0]; var best_count := -1
	for rank in RANKS:
		if rank == "Т": continue
		var amount := 0
		for card in hands[player]:
			if rank_of(card) == rank: amount += 1
		if amount > best_count: best_count = amount; best = rank
	return best

func discard_quartets(player: int) -> bool:
	var discarded := false
	for rank in RANKS:
		if rank == "Т": continue
		var cards: Array[String] = []
		for card in hands[player]:
			if rank_of(card) == rank: cards.append(card)
		if cards.size() == 4:
			for card in cards: hands[player].erase(card)
			discarded = true
	return discarded

func next_active(player: int) -> int:
	for offset in range(1, player_count + 1):
		var candidate := (player + offset) % player_count
		if active[candidate]: return candidate
	return player

func player_names() -> Array[String]:
	var names: Array[String] = ["Вы", "Шурик", "Черва", "Козырь"]
	return names.slice(0, player_count)
func hand_counts() -> Array[int]:
	var result: Array[int] = []
	for hand in hands: result.append(hand.size())
	return result
func player_name(player: int) -> String: return player_names()[player]
func rank_of(card: String) -> String: return card.left(card.length() - 1)
