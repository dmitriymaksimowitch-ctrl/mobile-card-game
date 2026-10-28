extends Control

const CardVisuals = preload("res://card_visuals.gd")
signal exit_to_menu

const SUITS := ["♣", "♦", "♥", "♠"]
const RANKS := ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
const STARTING_CARDS := 5

var player_count := 2
var deck: Array[String] = []
var hands: Array[Array] = []
var chests: Array[int] = []
var chest_ranks: Array[Array] = []
var turn := 0
var chosen_rank := ""
var message := ""
var running := false
var revision := 0
var content: VBoxContainer

func _ready() -> void:
	show_setup()

func screen() -> void:
	theme = CardVisuals.make_theme()
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
	style.bg_color = Color("314658")
	style.border_color = Color("9c7a35")
	style.border_width_bottom = 3
	style.set_corner_radius_all(22)
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)
	var column := VBoxContainer.new(); panel.add_child(column)
	var label := Label.new(); label.text = text; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 58); column.add_child(label)
	if sub:
		var note := Label.new(); note.text = sub; note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.modulate = Color("bcd6ca"); column.add_child(note)

func button(text: String, call: Callable) -> Button:
	var result := Button.new(); result.text = text; result.custom_minimum_size.y = 82
	result.pressed.connect(call); content.add_child(result); return result

func small_button(text: String, call: Callable) -> Button:
	var result := Button.new(); result.text = text; result.size_flags_horizontal = Control.SIZE_EXPAND_FILL; result.custom_minimum_size.y = 78
	result.pressed.connect(call); return result

func spacer() -> void:
	var space := Control.new(); space.size_flags_vertical = Control.SIZE_EXPAND_FILL; content.add_child(space)

func show_setup() -> void:
	revision += 1; running = false; screen()
	heading("Сундучки", "36 карт • по 5 карт каждому • игра против компьютера")
	spacer()
	for count in range(2, 5): button("%d игрока • %d бот(а)" % [count, count - 1], start_game.bind(count))
	button("Правила", show_rules)
	spacer(); button("← К выбору игр", func(): exit_to_menu.emit())

func show_rules() -> void:
	screen(); heading("Правила игры", "Сундучки • колода 36 карт")
	var rules := Label.new()
	rules.text = """• Играют от 2 до 4 участников. Каждому раздаётся по 5 карт, остальные карты образуют прикуп в центре стола.

• Цель — собрать больше всех сундучков. Сундучок состоит из четырёх карт одного достоинства.

• В свой ход игрок выбирает соперника и спрашивает у него карты достоинства, которое уже есть у спрашивающего в руке.

• Если такие карты есть, соперник обязан отдать их все. Угадавший игрок продолжает ход и может обратиться к любому сопернику.

• Если нужных карт нет, спрашивающий берёт одну карту из прикупа. Затем ход переходит к сопернику, которому был задан вопрос.

• Собранные четыре карты одного достоинства автоматически выкладываются перед игроком как готовый сундучок.

• Когда прикуп и руки опустели, побеждает игрок с наибольшим количеством сундучков. При равном результате победителей может быть несколько."""
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 36)
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.add_child(rules); content.add_child(scroll)
	button("Понятно", show_setup)

func start_game(count: int) -> void:
	revision += 1; player_count = count; deck.clear(); hands.clear(); chests.clear(); chest_ranks.clear()
	for suit in SUITS:
		for rank in RANKS: deck.append(rank + suit)
	deck.shuffle()
	for player in player_count:
		hands.append([]); chests.append(0); chest_ranks.append([])
	for i in STARTING_CARDS:
		for player in player_count: hands[player].append(deck.pop_back())
	for player in player_count: collect_chests(player)
	turn = randi_range(0, player_count - 1)
	chosen_rank = ""; running = true
	message = "%s начинает игру" % player_name(turn)
	prepare_turn()

func draw_game() -> void:
	screen(); var game_note := Label.new(); game_note.text = "Прикуп %d  •  ваши сундучки %d" % [deck.size(), chests[0]]; game_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; game_note.add_theme_font_size_override("font_size", 28); game_note.modulate = Color("f4dfaa"); content.add_child(game_note)
	var status := Label.new(); status.text = message; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.custom_minimum_size.y = 62
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.modulate = Color("f2cf72"); content.add_child(status)
	add_table()
	var hand_title := Label.new(); hand_title.text = "ВАША РУКА"
	hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hand_title.modulate = Color("bcd6ca"); content.add_child(hand_title)
	add_hand()
	var actions := HBoxContainer.new(); actions.alignment = BoxContainer.ALIGNMENT_CENTER; actions.custom_minimum_size.y = 90; content.add_child(actions)
	if running and turn == 0 and not hands[0].is_empty(): actions.add_child(small_button("Спросить карты", show_rank_choices))
	actions.add_child(small_button("Правила", show_rules)); actions.add_child(small_button("Меню", show_setup))

func opponent_panel(player: int) -> PanelContainer:
	var panel := PanelContainer.new(); panel.custom_minimum_size.x = 300 if player_count == 2 else 235
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.02, 0.10, 0.08, 0.92)
	style.border_color = Color("f2cf72") if player == turn else Color("315c4d")
	style.set_border_width_all(3 if player == turn else 2); style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new(); label.text = "%s\n%d карт • %d сунд." % [player_name(player), hands[player].size(), chests[player]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 88; panel.add_child(label); return panel

func add_table() -> void:
	var felt := Panel.new(); felt.custom_minimum_size.y = 430; felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new(); style.bg_color = Color("0b4f5f"); style.border_color = Color("e0ad4f")
	style.set_border_width_all(11); style.set_corner_radius_all(72); style.shadow_size = 12
	felt.add_theme_stylebox_override("panel", style); content.add_child(felt)
	var deck_note := Label.new(); deck_note.text = "ПРИКУП • %d" % deck.size(); deck_note.position = Vector2(42, 28)
	deck_note.modulate = Color("bcd6ca"); felt.add_child(deck_note)
	if not deck.is_empty():
		for layer in 3:
			var back := card_back(); back.position = Vector2(80 + layer * 5, 115 - layer * 5); back.z_index = layer
			felt.add_child(back)
	else:
		var empty := Label.new(); empty.text = "Прикуп\nпуст"; empty.position = Vector2(75, 130); empty.size = Vector2(140, 160)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.modulate = Color(1, 1, 1, 0.4); felt.add_child(empty)
	var chest_title := Label.new(); chest_title.text = "ВАШИ СУНДУЧКИ"; chest_title.position = Vector2(310, 44)
	chest_title.size = Vector2(600, 42); chest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; chest_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chest_title.modulate = Color("f2cf72"); felt.add_child(chest_title)
	if chest_ranks[0].is_empty():
		var none := Label.new(); none.text = "Соберите четыре карты одного достоинства"
		none.position = Vector2(300, 190); none.size = Vector2(620, 50); none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; none.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		none.modulate = Color(1, 1, 1, 0.4); felt.add_child(none)
	else:
		for index in chest_ranks[0].size():
			var card := Label.new(); CardVisuals.decorate_label(card, String(chest_ranks[0][index]) + "♥", Vector2(128, 176))
			card.position = Vector2(320 + index * 105, 120); card.rotation_degrees = -5 + index * 2; felt.add_child(card)
	CardVisuals.add_table_seats(felt, player_names(), hand_counts(), turn, Vector2(996, 430))

func card_back() -> Label:
	var back := Label.new(); back.text = ""; back.size = Vector2(128, 176)
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_theme_font_size_override("font_size", 26); back.add_theme_color_override("font_color", Color("b9d8ff"))
	back.add_theme_stylebox_override("normal", CardVisuals.back_style()); return back

func add_hand() -> void:
	hands[0].sort_custom(CardVisuals.card_less)
	var area := Control.new(); area.custom_minimum_size.y = 295; area.clip_contents = false; content.add_child(area)
	if hands[0].is_empty(): return
	var size := CardVisuals.fitted_hand_card_size(hands[0].size(), Vector2(154, 208))
	var step: float = CardVisuals.hand_step(hands[0].size(), size)
	var width := size.x + step * (hands[0].size() - 1); var start := (996.0 - width) / 2.0
	for index in hands[0].size():
		var card := Button.new(); CardVisuals.decorate_button(card, hands[0][index], size, true)
		var distance := index - (hands[0].size() - 1) / 2.0
		card.position = Vector2(start + index * step, 45); card.rotation_degrees = 0.0
		card.z_index = index; area.add_child(card)

func show_rank_choices() -> void:
	if turn != 0 or hands[0].is_empty(): return
	screen(); heading("Какое достоинство спросить?", "Можно спрашивать только карты, которые есть у вас")
	spacer(); var grid := GridContainer.new(); grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12); content.add_child(grid)
	for rank in ranks_in_hand(0):
		var choice := Button.new(); choice.text = rank; choice.custom_minimum_size = Vector2(315, 100)
		choice.pressed.connect(choose_rank.bind(rank)); grid.add_child(choice)
	spacer(); button("← Назад", draw_game)

func choose_rank(rank: String) -> void:
	chosen_rank = rank
	screen(); heading("У кого спросить %s?" % rank, "Выберите соперника")
	spacer()
	for player in player_count:
		if player != 0 and not hands[player].is_empty(): button("%s • %d карт" % [player_name(player), hands[player].size()], ask.bind(0, player, rank))
	spacer(); button("← Выбрать другой ранг", show_rank_choices)

func ask(asking: int, target: int, rank: String) -> void:
	if not running or asking != turn or asking == target or rank not in ranks_in_hand(asking): return
	var given: Array[String] = []
	for card in hands[target].duplicate():
		if rank_of(card) == rank:
			hands[target].erase(card); hands[asking].append(card); given.append(card)
	if not given.is_empty():
		var made := collect_chests(asking)
		message = "%s получает у %s %d карт(ы) %s%s" % [player_name(asking), player_name(target), given.size(), rank, " и собирает сундучок" if made else ""]
		turn = asking
	else:
		var drawn := ""
		if not deck.is_empty(): drawn = deck.pop_back(); hands[asking].append(drawn)
		var made := collect_chests(asking)
		message = "%s не нашёл у %s карты %s%s%s" % [player_name(asking), player_name(target), rank, " и берёт карту" if drawn else "", "; собран сундучок" if made else ""]
		turn = target
	chosen_rank = ""
	if check_game_over(): return
	prepare_turn()

func collect_chests(player: int) -> bool:
	var made := false
	for rank in RANKS:
		var cards: Array[String] = []
		for card in hands[player]:
			if rank_of(card) == rank: cards.append(card)
		if cards.size() == 4:
			for card in cards: hands[player].erase(card)
			chests[player] += 1; chest_ranks[player].append(rank); made = true
	return made

func prepare_turn() -> void:
	if check_game_over(): return
	var attempts := 0
	while hands[turn].is_empty() and attempts < player_count:
		if not deck.is_empty():
			var card: String = deck.pop_back(); hands[turn].append(card); collect_chests(turn)
			message = "%s берёт карту из прикупа, чтобы продолжить" % player_name(turn)
			break
		turn = next_player_with_cards(turn); attempts += 1
	draw_game(); schedule_bot()

func schedule_bot() -> void:
	if not running or turn == 0: return
	bot_turn(revision)

func bot_turn(stamp: int) -> void:
	await get_tree().create_timer(1.1).timeout
	if stamp != revision or not running or turn == 0: return
	if hands[turn].is_empty(): prepare_turn(); return
	var ranks := ranks_in_hand(turn)
	var rank: String = ranks.pick_random()
	var targets: Array[int] = []
	for player in player_count:
		if player != turn and not hands[player].is_empty(): targets.append(player)
	if targets.is_empty():
		prepare_turn(); return
	ask(turn, targets.pick_random(), rank)

func ranks_in_hand(player: int) -> Array[String]:
	var result: Array[String] = []
	for card in hands[player]:
		var rank := rank_of(card)
		if rank not in result: result.append(rank)
	return result

func next_player_with_cards(player: int) -> int:
	for offset in range(1, player_count + 1):
		var candidate := (player + offset) % player_count
		if not hands[candidate].is_empty(): return candidate
	return player

func check_game_over() -> bool:
	if not deck.is_empty(): return false
	for hand in hands:
		if not hand.is_empty(): return false
	running = false; revision += 1
	var best: int = chests.max(); var winners: Array[int] = []
	for player in player_count:
		if chests[player] == best: winners.append(player)
	screen()
	if winners.size() > 1:
		heading("Ничья", "По %d сундучка у %s" % [best, names_of(winners)])
	elif winners[0] == 0:
		heading("Поздравляем с победой!", "Вы собрали %d сундучка" % best)
	else:
		heading("Вы проиграли", "%s собрал больше всех: %d" % [player_name(winners[0]), best])
	spacer(); button("Сыграть ещё", start_game.bind(player_count)); button("Главное меню", func(): exit_to_menu.emit()); spacer()
	return true

func names_of(players: Array[int]) -> String:
	var names: Array[String] = []
	for player in players: names.append(player_name(player))
	return ", ".join(names)

func player_names() -> Array[String]:
	var names: Array[String] = ["Вы", "Шурик", "Черва", "Козырь"]
	return names.slice(0, player_count)
func hand_counts() -> Array[int]:
	var result: Array[int] = []
	for hand in hands: result.append(hand.size())
	return result
func player_name(player: int) -> String: return player_names()[player]
func rank_of(card: String) -> String: return card.left(card.length() - 1)

func apply_game_layout() -> void:
	if is_instance_valid(content):
		CardVisuals.clean_layout(content)
