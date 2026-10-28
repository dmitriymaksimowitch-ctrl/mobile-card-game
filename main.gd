extends Control

const CardVisuals = preload("res://card_visuals.gd")

const SUITS := ["♣", "♦", "♥", "♠"]
const RANKS := ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
const RED := ["♦", "♥"]
var count := 2
var durak_variant := "podkidnoy"
var hand_target := 6
var deck: Array[String] = []
var hands: Array[Array] = []
var table: Array[Dictionary] = []
var trump := ""
var attacker := 0
var defender := 1
var actor := 0
var attackers: Array[int] = []
var attack_pos := 0
var limit := 6
var phase := "menu"
var message := ""
var revision := 0
var deal_animation_pending := false
var newly_drawn: Array[Array] = []
var table_animation: Dictionary = {}
var circle_cards: Array[String] = []
var circle_drawn := ""
var circle_turn := 0
var circle_running := false
var box: VBoxContainer

func _ready() -> void:
	make_theme()
	show_menu()

func make_theme() -> void:
	theme = CardVisuals.make_theme()

func screen() -> void:
	# Сначала отсоединяем старый экран, чтобы старые и новые карты не
	# отображались одновременно в течение одного кадра.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := CardVisuals.make_background()
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 42)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)

func title(main: String, sub := "") -> void:
	var header := PanelContainer.new()
	var header_style := StyleBoxFlat.new(); header_style.bg_color = Color("314658")
	header_style.border_color = Color("9c7a35"); header_style.border_width_bottom = 3; header_style.set_corner_radius_all(22)
	header_style.content_margin_top = 14; header_style.content_margin_bottom = 14
	header.add_theme_stylebox_override("panel", header_style); box.add_child(header)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 4); header.add_child(column)
	var label := Label.new()
	label.text = main
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 60)
	column.add_child(label)
	if sub:
		var note := Label.new()
		note.text = sub
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.modulate = Color("bcd6ca")
		column.add_child(note)

func spacer() -> void:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(c)

func action(text: String, call: Callable, disabled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 84
	b.disabled = disabled
	b.pressed.connect(call)
	box.add_child(b)
	return b

func game_menu_row(text: String, play_call: Callable, rules_call: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var play := Button.new()
	play.text = text
	play.custom_minimum_size.y = 104
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(play_call)
	row.add_child(play)
	var info := Button.new()
	info.text = "?"
	info.tooltip_text = "Правила"
	info.custom_minimum_size = Vector2(104, 104)
	info.add_theme_font_size_override("font_size", 46)
	info.pressed.connect(rules_call)
	row.add_child(info)

func show_menu() -> void:
	revision += 1
	phase = "menu"
	screen(); title("Карточный клуб", "Версия 1.0.2 • выберите игру")
	game_menu_row("Простой дурак", choose_durak_variant.bind("simple"), show_durak_rules.bind("simple"))
	game_menu_row("Подкидной дурак", choose_durak_variant.bind("podkidnoy"), show_durak_rules.bind("podkidnoy"))
	game_menu_row("Переводной дурак", choose_durak_variant.bind("perevodnoy"), show_durak_rules.bind("perevodnoy"))
	game_menu_row("Японский дурак", choose_durak_variant.bind("japanese"), show_durak_rules.bind("japanese"))
	game_menu_row("Круглый дурак", choose_durak_variant.bind("circle"), show_durak_rules.bind("circle"))
	game_menu_row("Девятка вверх", open_high_nine, open_high_nine.bind(true))
	game_menu_row("Обмани соседа", open_bluff_neighbor, open_bluff_neighbor.bind(true))
	game_menu_row("Сундучки", open_chests, open_chests.bind(true))
	game_menu_row("Короткий Кинг", open_king.bind("short"), open_king.bind("short", true))
	game_menu_row("Длинный Кинг", open_king.bind("long"), open_king.bind("long", true))
	spacer()

func open_high_nine(show_rules_first := false) -> void:
	revision += 1
	phase = "menu"
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var game = preload("res://high_nine.gd").new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_to_menu.connect(show_menu)
	add_child(game)
	if show_rules_first: game.show_rules()

func open_bluff_neighbor(show_rules_first := false) -> void:
	revision += 1
	phase = "menu"
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var game = preload("res://bluff_neighbor.gd").new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_to_menu.connect(show_menu)
	add_child(game)
	if show_rules_first: game.show_rules()

func open_chests(show_rules_first := false) -> void:
	revision += 1
	phase = "menu"
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var game = preload("res://chests.gd").new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_to_menu.connect(show_menu)
	add_child(game)
	if show_rules_first: game.show_rules()

func open_king(mode: String, show_rules_first := false) -> void:
	revision += 1; phase = "menu"
	for child in get_children(): remove_child(child); child.queue_free()
	var game = preload("res://king.gd").new()
	game.king_mode = mode; game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_to_menu.connect(show_menu); add_child(game)
	if show_rules_first: game.show_rules()

func choose_durak_variant(variant: String) -> void:
	durak_variant = variant
	hand_target = 6
	show_players()

func durak_name() -> String:
	match durak_variant:
		"simple": return "Простой дурак"
		"perevodnoy": return "Переводной дурак"
		"japanese": return "Японский дурак"
		"circle": return "Круглый дурак"
		_: return "Подкидной дурак"

func show_players() -> void:
	screen(); title(durak_name(), "36 карт • против компьютера"); spacer()
	for n in range(2, 5): action("%d игрока • %d бот(а)" % [n, n - 1], start.bind(n))
	action("Правила", show_durak_rules.bind(durak_variant, true))
	spacer(); action("← Назад", show_menu)

func show_durak_rules(variant: String, return_to_players := false) -> void:
	durak_variant = variant
	screen(); title("Правила игры", durak_name())
	var rules := Label.new()
	rules.text = durak_rules_text(variant)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 36)
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.modulate = Color("eef5e8")
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.add_child(rules); box.add_child(scroll)
	action("Понятно", show_players if return_to_players else show_menu)

func durak_rules_text(variant: String) -> String:
	var common := "Играют от 2 до 4 участников колодой из 36 карт. Карта бьётся старшей картой той же масти или козырем. За одну атаку нельзя положить больше шести карт и больше карт, чем было у защищающегося в начале хода. После отбоя или взятия игроки добирают карты до шести. Когда колода закончилась, побеждают игроки, избавившиеся от всех карт; последний с картами остаётся в дураках."
	match variant:
		"simple":
			return "ПРОСТОЙ ДУРАК\n\n%s\n\nПервый игрок заходит одной картой или сразу несколькими картами одного достоинства. Защищающийся отбивает весь первоначальный заход. После начала защиты новые карты подкидывать нельзя." % common
		"perevodnoy":
			return "ПЕРЕВОДНОЙ ДУРАК\n\n%s\n\nДо того как отбита первая карта, защищающийся может положить карту того же достоинства и перевести всю атаку следующему игроку. Перевод разрешён, только если у следующего игрока достаточно карт для защиты." % common
		"japanese":
			return "ЯПОНСКИЙ ДУРАК\n\n%s\n\nБубны всегда являются козырями. Пиковую карту можно побить только более старшей пиковой картой: бубновый козырь против пики не действует. В остальном используются правила подкидного дурака." % common
		"circle":
			return "КРУГЛЫЙ ДУРАК\n\nСначала девять карт кладутся открытыми вокруг колоды с козырем. Первый игрок выбирается случайно. Он открывает верхнюю карту и может забрать ею одну карту круга, которую она бьёт по обычным правилам. Тогда обе карты переходят ему, и он открывает следующую. Если побить нечего, открытая карта добавляется в круг, а ход переходит по часовой стрелке.\n\nОткрывший последнюю карту забирает её и весь остаток круга, затем первым атакует в обычной подкидной партии. За одну атаку разрешено не более шести карт."
		_:
			return "ПОДКИДНОЙ ДУРАК\n\n%s\n\nПосле каждой успешно отбитой карты атакующие могут подкидывать карты любого достоинства, которое уже лежит на столе. Защищающийся должен отбить все карты или забрать весь стол." % common

func start(players: int) -> void:
	revision += 1
	count = players
	deck.clear(); hands.clear(); table.clear()
	for suit in SUITS:
		for rank in RANKS: deck.append(rank + suit)
	deck.shuffle()
	trump = "♦" if durak_variant == "japanese" else suit_of(deck[0])
	for i in count: hands.append([])
	if durak_variant == "circle":
		start_circle_phase()
		return
	for i in hand_target:
		for p in count: hands[p].append(deck.pop_back())
	newly_drawn.clear()
	for p in count: newly_drawn.append(hands[p].duplicate())
	attacker = first_attacker()
	message = "%s ходит первым" % name_of(attacker)
	deal_animation_pending = true
	begin_round()

func start_circle_phase() -> void:
	circle_cards.clear()
	circle_drawn = ""
	circle_running = true
	phase = "circle"
	for i in 9:
		circle_cards.append(deck.pop_back())
	circle_turn = randi_range(0, count - 1)
	actor = circle_turn
	message = "%s начинает круг" % name_of(circle_turn)
	circle_draw_next()

func circle_draw_next() -> void:
	if not circle_running or deck.is_empty(): return
	circle_drawn = deck.pop_back()
	actor = circle_turn
	if deck.is_empty():
		message = "%s открывает последнюю карту и забирает весь круг" % name_of(circle_turn)
		draw_circle_table()
		var stamp := revision
		await get_tree().create_timer(1.35).timeout
		if stamp == revision and circle_running: finish_circle_phase()
		return
	var targets := circle_targets(circle_drawn)
	if targets.is_empty():
		message = "%s не может побить карты и кладёт %s в круг" % [name_of(circle_turn), circle_drawn]
		draw_circle_table()
		var stamp := revision
		await get_tree().create_timer(1.05).timeout
		if stamp != revision or not circle_running: return
		circle_cards.append(circle_drawn)
		circle_drawn = ""
		circle_turn = (circle_turn + 1) % count
		circle_draw_next()
		return
	message = "%s выбирает карту, которую побить картой %s" % [name_of(circle_turn), circle_drawn]
	draw_circle_table()
	if circle_turn != 0: circle_bot_choose(revision)

func circle_targets(card: String) -> Array[int]:
	var result: Array[int] = []
	for index in circle_cards.size():
		if beats(card, circle_cards[index]): result.append(index)
	return result

func capture_circle_card(index: int) -> void:
	if not circle_running or circle_turn != 0 or circle_drawn == "": return
	if index < 0 or index >= circle_cards.size() or not beats(circle_drawn, circle_cards[index]):
		message = "Эту карту нельзя побить картой %s" % circle_drawn
		draw_circle_table()
		return
	circle_capture(index)

func circle_capture(index: int) -> void:
	var captured := circle_cards[index]
	hands[circle_turn].append(captured)
	hands[circle_turn].append(circle_drawn)
	circle_cards.remove_at(index)
	message = "%s забирает %s и %s" % [name_of(circle_turn), captured, circle_drawn]
	circle_drawn = ""
	draw_circle_table()
	var stamp := revision
	await get_tree().create_timer(0.85).timeout
	if stamp == revision and circle_running: circle_draw_next()

func circle_bot_choose(stamp: int) -> void:
	await get_tree().create_timer(1.0).timeout
	if stamp != revision or not circle_running or circle_turn == 0: return
	var targets := circle_targets(circle_drawn)
	if targets.is_empty():
		circle_draw_next()
		return
	var best := targets[0]
	for index in targets:
		if strength(circle_cards[index]) > strength(circle_cards[best]): best = index
	circle_capture(best)

func finish_circle_phase() -> void:
	hands[circle_turn].append(circle_drawn)
	for card in circle_cards: hands[circle_turn].append(card)
	circle_cards.clear()
	circle_drawn = ""
	circle_running = false
	attacker = circle_turn
	message = "%s забрал остаток круга и атакует первым" % name_of(attacker)
	newly_drawn.clear()
	for p in count: newly_drawn.append(hands[p].duplicate())
	deal_animation_pending = true
	var players_with_cards: Array[int] = []
	for p in count:
		if not hands[p].is_empty(): players_with_cards.append(p)
	if players_with_cards.size() <= 1:
		game_over(players_with_cards)
		return
	begin_round()

func draw_circle_table() -> void:
	screen(); compact_game_info("Козырь %s  •  колода %d" % [trump, deck.size()])
	var status := Label.new()
	status.text = message
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 64
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.modulate = Color("f2cf72")
	box.add_child(status)
	var felt := Panel.new()
	felt.custom_minimum_size.y = 760
	felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var felt_style := StyleBoxFlat.new()
	felt_style.bg_color = Color("0b4f5f")
	felt_style.border_color = Color("e0ad4f")
	felt_style.set_border_width_all(11)
	felt_style.set_corner_radius_all(74)
	felt_style.shadow_color = Color(0, 0, 0, 0.35)
	felt_style.shadow_size = 14
	felt.add_theme_stylebox_override("panel", felt_style)
	box.add_child(felt)
	var center := Vector2(498, 378)
	if not deck.is_empty():
		CardVisuals.add_compact_deck(felt, center + Vector2(-110, -88), deck[0], Vector2(128, 176), deck.size())
	if circle_drawn != "":
		var drawn := card_label(circle_drawn)
		drawn.position = center + Vector2(105, -88)
		drawn.z_index = 8
		felt.add_child(drawn)
		var drawn_note := Label.new()
		drawn_note.text = "ОТКРЫТА"
		drawn_note.position = center + Vector2(105, 94)
		drawn_note.size = Vector2(128, 34)
		drawn_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		drawn_note.add_theme_font_size_override("font_size", 18)
		drawn_note.modulate = Color("f2cf72")
		felt.add_child(drawn_note)
	var total := circle_cards.size()
	for index in total:
		var angle := -PI / 2.0 + TAU * float(index) / maxf(1.0, total)
		var position := center + Vector2(cos(angle) * 365.0, sin(angle) * 250.0) - Vector2(55, 75)
		var button := Button.new()
		CardVisuals.decorate_button(button, circle_cards[index], Vector2(110, 150), true)
		button.position = position
		button.rotation = angle + PI / 2.0
		button.pivot_offset = Vector2(55, 75)
		button.z_index = index + 10
		button.pressed.connect(capture_circle_card.bind(index))
		felt.add_child(button)
	CardVisuals.add_table_seats(felt, player_names(), hand_counts(), actor, Vector2(996, 760))
	var controls := HBoxContainer.new(); controls.alignment = BoxContainer.ALIGNMENT_CENTER; controls.custom_minimum_size.y = 90; box.add_child(controls)
	# Menu is available in the top bar.

func first_attacker() -> int:
	var who := 0
	var low := 99
	for p in count:
		for card in hands[p]:
			if suit_of(card) == trump and value(card) < low:
				low = value(card); who = p
	return who

func begin_round() -> void:
	table.clear()
	defender = next_player(attacker)
	limit = min(6, hands[defender].size())
	attackers.clear()
	for offset in count:
		var p := (attacker + offset) % count
		if p != defender and (not hands[p].is_empty() or not deck.is_empty()): attackers.append(p)
	attack_pos = 0; actor = attackers[0]; phase = "attack"
	draw_table(); schedule_bot()

func draw_table() -> void:
	screen(); compact_game_info("%s  •  козырь %s  •  колода %d" % [durak_name(), trump, deck.size()])
	var status := Label.new()
	status.text = message
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 58
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.modulate = Color("f2cf72")
	var status_style := StyleBoxFlat.new(); status_style.bg_color = Color("314658")
	status_style.border_color = Color("9c7a35"); status_style.set_border_width_all(2); status_style.set_corner_radius_all(18)
	status.add_theme_stylebox_override("normal", status_style)
	box.add_child(status)
	add_playing_table()
	var hand_label := Label.new()
	hand_label.text = "ВАША РУКА%s" % (" • ЗАЩИТА" if defender == 0 else "")
	hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_label.add_theme_font_size_override("font_size", 29)
	hand_label.modulate = Color("a8c9bb")
	box.add_child(hand_label)
	add_hand_fan()
	var controls := HBoxContainer.new(); controls.alignment = BoxContainer.ALIGNMENT_CENTER; controls.custom_minimum_size.y = 90; box.add_child(controls)
	if actor == 0 and phase == "attack" and not table.is_empty(): controls.add_child(small_button("Пас", pass_attack))
	if actor == 0 and phase == "simple_add": controls.add_child(small_button("Начать защиту", begin_simple_defense))
	if actor == 0 and phase == "defense": controls.add_child(small_button("Взять", take))
	# Menu is available in the top bar.
	deal_animation_pending = false
	newly_drawn.clear()
	table_animation.clear()

func make_opponent_hand(player: int) -> PanelContainer:
	var seat := PanelContainer.new(); seat.custom_minimum_size.x = 300 if count == 2 else 240
	var seat_style := StyleBoxFlat.new(); seat_style.bg_color = Color(0.02,0.10,0.08,0.92)
	seat_style.border_color = Color("f2cf72") if player == actor else Color("315c4d")
	seat_style.set_border_width_all(3 if player == actor else 2); seat_style.set_corner_radius_all(18)
	seat_style.content_margin_left = 8; seat_style.content_margin_right = 8; seat.add_theme_stylebox_override("panel", seat_style)
	var opponent := VBoxContainer.new(); seat.add_child(opponent)
	var identity := HBoxContainer.new(); identity.alignment = BoxContainer.ALIGNMENT_CENTER; identity.add_theme_constant_override("separation", 10); opponent.add_child(identity)
	var avatar := Label.new(); avatar.text = name_of(player).left(1); avatar.custom_minimum_size = Vector2(58,58)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_theme_font_size_override("font_size", 26)
	var avatar_style := StyleBoxFlat.new(); avatar_style.bg_color = Color("d8b85c") if player == actor else Color("244b40")
	avatar_style.set_corner_radius_all(29); avatar_style.border_color = Color("fff0b0"); avatar_style.set_border_width_all(2)
	avatar.add_theme_stylebox_override("normal", avatar_style); identity.add_child(avatar)
	var label := Label.new(); label.text = "%s%s\n%d карт" % [name_of(player), "  • защита" if player == defender else "", hands[player].size()]
	label.add_theme_font_size_override("font_size", 24); label.modulate = Color("d4e8df"); identity.add_child(label)
	var fan := Control.new()
	fan.custom_minimum_size.y = 96
	opponent.add_child(fan)
	var visible_cards: int = mini(hands[player].size(), 8)
	var new_count := newly_drawn[player].size() if player < newly_drawn.size() else 0
	var spacing := 24.0
	var width := 60.0 + maxf(0, visible_cards - 1) * spacing
	var start_x := (opponent.custom_minimum_size.x - width) / 2.0
	for index in visible_cards:
		var back := make_small_card_back()
		var distance := index - (visible_cards - 1) / 2.0
		var home := Vector2(start_x + index * spacing, 8 + abs(distance) * 2)
		back.position = home
		back.rotation_degrees = distance * 2.2
		back.z_index = index
		fan.add_child(back)
		if deal_animation_pending and index >= visible_cards - new_count:
			back.position = Vector2(opponent.custom_minimum_size.x / 2.0, 260)
			back.scale = Vector2(0.65, 0.65)
			back.modulate.a = 0.0
			var tween := create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(back, "position", home, 1.05).set_delay(index * 0.14)
			tween.tween_property(back, "scale", Vector2.ONE, 1.05).set_delay(index * 0.14)
			tween.tween_property(back, "modulate:a", 1.0, 0.9).set_delay(index * 0.14)
	return seat

func make_small_card_back() -> Label:
	var back := Label.new()
	back.text = "✦"
	back.size = Vector2(60, 82)
	back.pivot_offset = back.size / 2.0
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_theme_font_size_override("font_size", 26)
	back.add_theme_color_override("font_color", Color("c8dcff"))
	var style := CardVisuals.back_style()
	style.set_border_width_all(4); style.set_corner_radius_all(8); style.shadow_size = 4
	back.add_theme_stylebox_override("normal", style)
	return back

func add_hand_fan() -> void:
	hands[0].sort_custom(func(a: String, b: String): return CardVisuals.card_less(a, b, trump))
	var area := Control.new()
	area.custom_minimum_size.y = 330
	area.clip_contents = false
	box.add_child(area)
	var card_count := hands[0].size()
	if card_count == 0: return
	var card_size := CardVisuals.fitted_hand_card_size(card_count, Vector2(174, 250))
	var available := 996.0
	var step: float = CardVisuals.hand_step(card_count, card_size)
	var total_width: float = card_size.x + step * (card_count - 1)
	var start_x: float = (available - total_width) / 2.0
	for index in card_count:
		var card: String = hands[0][index]
		var distance := index - (card_count - 1) / 2.0
		var home := Vector2(start_x + index * step, 45.0)
		var angle: float = 0.0
		var playable := true
		var b := make_hand_card(card, playable, card_size)
		b.position = home
		b.rotation_degrees = angle
		b.z_index = index
		b.mouse_entered.connect(lift_card.bind(b, home, angle))
		b.mouse_exited.connect(lower_card.bind(b, home, angle, index))
		b.pressed.connect(attempt_hand_card.bind(card, b))
		area.add_child(b)
		if deal_animation_pending and card in newly_drawn[0]:
			# Карта летит от видимой колоды к руке игрока.
			b.position = Vector2(100, -465)
			b.rotation_degrees = 90
			b.scale = Vector2(0.42, 0.42)
			b.modulate.a = 0.0
			var tween := create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(b, "position", home, 0.95).set_delay(index * 0.10)
			tween.tween_property(b, "rotation_degrees", angle, 0.95).set_delay(index * 0.10)
			tween.tween_property(b, "scale", Vector2.ONE, 0.95).set_delay(index * 0.10)
			tween.tween_property(b, "modulate:a", 1.0, 0.85).set_delay(index * 0.10)

func make_hand_card(card: String, playable: bool, card_size: Vector2 = Vector2(174, 250)) -> Button:
	var b := Button.new()
	CardVisuals.decorate_button(b, card, card_size, playable)
	b.modulate = Color.WHITE
	return b

func attempt_hand_card(value: String, view: Control) -> void:
	if not legal(0, value):
		CardVisuals.shake_card(view)
		return
	play(0, value)

func lift_card(card: Control, home: Vector2, angle: float) -> void:
	card.z_index = 1000
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", home + Vector2(0, -30), 0.18)
	tween.tween_property(card, "rotation_degrees", angle * 0.12, 0.18)
	tween.tween_property(card, "scale", Vector2(1.04, 1.04), 0.18)

func lower_card(card: Control, home: Vector2, angle: float, layer: int) -> void:
	card.z_index = layer
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", home, 0.18)
	tween.tween_property(card, "rotation_degrees", angle, 0.18)
	tween.tween_property(card, "scale", Vector2.ONE, 0.18)

func card_label(card: String) -> Label:
	var l := Label.new()
	if card == "…":
		l.text = "…"; l.size = Vector2(128,176); l.custom_minimum_size = l.size
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else: CardVisuals.decorate_label(l, card, Vector2(128,176))
	return l

func add_playing_table() -> void:
	var felt := Panel.new()
	felt.custom_minimum_size.y = 600
	felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var felt_style := StyleBoxFlat.new()
	felt_style.bg_color = Color("0b4f5f")
	felt_style.border_color = Color("e0ad4f")
	felt_style.set_border_width_all(11)
	felt_style.set_corner_radius_all(74)
	felt_style.shadow_color = Color(0, 0, 0, 0.35)
	felt_style.shadow_size = 14
	felt.add_theme_stylebox_override("panel", felt_style)
	box.add_child(felt)

	var deck_card_size := CardVisuals.fitted_hand_card_size(hands[0].size(), Vector2(174, 250))
	if not deck.is_empty():
		var trump_face := (RANKS[0] + "♦") if durak_variant == "japanese" else deck[0]
		# Matches the actual size of the player's hand cards; no parent scale.
		CardVisuals.add_compact_deck(felt, Vector2(-52, -247), trump_face, deck_card_size, deck.size())
	else:
		var empty_deck := Label.new()
		empty_deck.text = "КОЛОДА ПУСТА"
		empty_deck.position = Vector2(-52, -175)
		empty_deck.size = Vector2(300, 55)
		empty_deck.add_theme_font_size_override("font_size", 38)
		empty_deck.modulate = Color(1, 1, 1, 0.65)
		felt.add_child(empty_deck)

	var play_area := Control.new()
	play_area.name = "PlayedCards"
	play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	felt.add_child(play_area)
	play_area.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	play_area.offset_left = -310; play_area.offset_right = 310
	play_area.offset_top = -215; play_area.offset_bottom = 215

	if table.is_empty():
		var empty := Label.new()
		empty.text = "Положите карту на стол"
		empty.position = Vector2(0, 185)
		empty.size = Vector2(620, 60)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.modulate = Color(1, 1, 1, 0.38)
		play_area.add_child(empty)
	else:
		for index in table.size():
			var column := index % 3
			var row := index / 3
			var columns := mini(3, table.size())
			var rows := ceili(table.size() / 3.0)
			var base := Vector2((620 - (columns * 200 - 18)) / 2.0 + column * 200, (430 - (rows * 215 - 4)) / 2.0 + row * 215)
			var attack_card := card_label(table[index].attack)
			attack_card.position = base
			attack_card.rotation_degrees = -4 + column * 2
			attack_card.pivot_offset = attack_card.size / 2.0
			play_area.add_child(attack_card)
			if table_animation.get("pair", -1) == index and table_animation.get("kind", "") == "attack":
				animate_card_to_table(attack_card, base, -4 + column * 2, table_animation.get("player", 0))
			if table[index].defense:
				var defense_card := card_label(table[index].defense)
				defense_card.position = base + Vector2(54, 35)
				defense_card.rotation_degrees = 7
				defense_card.pivot_offset = defense_card.size / 2.0
				defense_card.z_index = 2
				play_area.add_child(defense_card)
				if table_animation.get("pair", -1) == index and table_animation.get("kind", "") == "defense":
					animate_card_to_table(defense_card, base + Vector2(54, 35), 7, table_animation.get("player", 0), 2)
	CardVisuals.add_table_seats(felt, player_names(), hand_counts(), actor, Vector2(996, 455))

func animate_card_to_table(card: Control, destination: Vector2, angle: float, player: int, final_layer := 0) -> void:
	var origin: Vector2
	if player == 0:
		origin = Vector2(500, 540)
	else:
		var opponent_width := 720.0 / maxf(1.0, count - 1.0)
		origin = Vector2(225 + (player - 0.5) * opponent_width, -115)
	card.position = origin
	card.rotation_degrees = 0
	card.scale = Vector2(0.62, 0.62)
	card.modulate.a = 0.35
	card.z_index = 100
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", destination, 1.05)
	tween.tween_property(card, "rotation_degrees", angle, 1.05)
	tween.tween_property(card, "scale", Vector2.ONE, 1.05)
	tween.tween_property(card, "modulate:a", 1.0, 0.95)
	tween.chain().tween_property(card, "z_index", final_layer, 0.0)

func make_card_back() -> Label:
	var back := Label.new()
	back.text = ""
	back.position = Vector2.ZERO
	back.size = Vector2(128, 176)
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_theme_font_size_override("font_size", 27)
	back.add_theme_color_override("font_color", Color("b9d8ff"))
	var style := CardVisuals.back_style()
	back.add_theme_stylebox_override("normal", style)
	return back

func small_button(text: String, call: Callable) -> Button:
	var b := Button.new(); b.text = text; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.custom_minimum_size.y = 78
	b.pressed.connect(call); return b

func compact_game_info(text: String) -> void:
	var label := Label.new(); label.text = text; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28); label.modulate = Color("f4dfaa"); box.add_child(label)

func legal(player: int, card: String) -> bool:
	if player != actor: return false
	if phase == "attack":
		if table.size() >= limit: return false
		if table.is_empty(): return player == attacker
		return rank_of(card) in table_ranks()
	if phase == "simple_add":
		return player == attacker and table.size() < limit and rank_of(card) == rank_of(table[0].attack)
	if phase == "defense" and player == defender:
		var target := uncovered_pair()
		return target >= 0 and (beats(card, table[target].attack) or can_transfer(card))
	return false

func play(player: int, card: String) -> void:
	if not legal(player, card): return
	hands[player].erase(card)
	var round_finished := false
	if phase == "attack":
		table.append({"attack": card, "defense": ""})
		table_animation = {"pair": table.size() - 1, "kind": "attack", "player": player}
		message = "%s атакует: %s" % [name_of(player), card]
		if durak_variant == "simple" and has_simple_addition(player):
			phase = "simple_add"; actor = attacker
		else:
			phase = "defense"; actor = defender
	elif phase == "simple_add":
		table.append({"attack": card, "defense": ""})
		table_animation = {"pair": table.size() - 1, "kind": "attack", "player": player}
		message = "%s добавляет: %s" % [name_of(player), card]
		if not has_simple_addition(player): begin_simple_defense(); return
	else:
		if can_transfer(card):
			transfer_attack(player, card)
			return
		var target := uncovered_pair()
		table[target].defense = card
		table_animation = {"pair": target, "kind": "defense", "player": player}
		phase = "attack"
		message = "%s покрывает: %s" % [name_of(player), card]
		if uncovered_pair() >= 0:
			phase = "defense"; actor = defender
		elif durak_variant == "simple":
			finish_defense(); return
		else:
			round_finished = advance_attacker()
	if round_finished: return
	draw_table(); schedule_bot()

func has_simple_addition(player: int) -> bool:
	if table.is_empty() or table.size() >= limit: return false
	for card in hands[player]:
		if rank_of(card) == rank_of(table[0].attack): return true
	return false

func begin_simple_defense() -> void:
	phase = "defense"; actor = defender
	message = "%s защищается от %d карт" % [name_of(defender), table.size()]
	draw_table(); schedule_bot()

func uncovered_pair() -> int:
	for index in table.size():
		if table[index].defense == "": return index
	return -1

func can_transfer(card: String) -> bool:
	if durak_variant != "perevodnoy" or phase != "defense": return false
	for pair in table:
		if pair.defense != "": return false
	if table.is_empty() or rank_of(card) != rank_of(table[0].attack): return false
	var next_defender := next_player(defender)
	return hands[next_defender].size() >= table.size() + 1

func transfer_attack(player: int, card: String) -> void:
	hands[player].erase(card)
	table.append({"attack": card, "defense": ""})
	table_animation = {"pair": table.size() - 1, "kind": "attack", "player": player}
	attacker = player; defender = next_player(player); actor = defender
	limit = min(6, hands[defender].size())
	attackers.clear()
	for offset in count:
		var candidate := (attacker + offset) % count
		if candidate != defender and (not hands[candidate].is_empty() or not deck.is_empty()): attackers.append(candidate)
	attack_pos = 0; phase = "defense"
	message = "%s переводит атаку на %s" % [name_of(player), name_of(defender)]
	draw_table(); schedule_bot()

func pass_attack() -> void:
	if table.is_empty(): return
	attack_pos += 1
	if attack_pos >= attackers.size(): finish_defense(); return
	actor = attackers[attack_pos]
	message = "%s решает, подкидывать ли" % name_of(actor)
	draw_table(); schedule_bot()

func advance_attacker() -> bool:
	attack_pos = (attack_pos + 1) % attackers.size()
	actor = attackers[attack_pos]
	if table.size() >= limit:
		finish_defense()
		return true
	return false

func take() -> void:
	finish_round(true)

func finish_defense() -> void:
	finish_round(false)

func finish_round(taking: bool) -> void:
	if phase == "resolving": return
	phase = "resolving"
	revision += 1
	var stamp := revision
	draw_table()
	await get_tree().create_timer(1.2).timeout
	if stamp != revision or phase != "resolving": return
	var next := defender
	if taking:
		for pair in table:
			hands[defender].append(pair.attack)
			if pair.defense: hands[defender].append(pair.defense)
		message = "%s берёт карты" % name_of(defender)
		next = next_player(defender)
	else:
		message = "%s отбился" % name_of(defender)
	refill(); attacker = next; continue_game()

func refill() -> void:
	var cards_drawn := false
	newly_drawn.clear()
	for p in count: newly_drawn.append([])
	for offset in count:
		var p := (attacker + offset) % count
		while hands[p].size() < hand_target and not deck.is_empty():
			var drawn_card: String = deck.pop_back()
			hands[p].append(drawn_card)
			newly_drawn[p].append(drawn_card)
			cards_drawn = true
	deal_animation_pending = cards_drawn

func continue_game() -> void:
	if deck.is_empty():
		var left: Array[int] = []
		for p in count:
			if not hands[p].is_empty(): left.append(p)
		if left.size() <= 1: game_over(left); return
	if hands[attacker].is_empty(): attacker = next_player(attacker)
	begin_round()

func game_over(left: Array[int]) -> void:
	revision += 1; phase = "over"; screen()
	if left.is_empty():
		title("Ничья", "Все игроки вышли одновременно")
	elif left[0] == 0:
		title("Вы проиграли", "В этот раз вы остались в дураках")
	else:
		title("Поздравляем с победой!", "%s остался в дураках" % name_of(left[0]))
	spacer(); action("Сыграть ещё", start.bind(count)); action("Главное меню", show_menu); spacer()

func schedule_bot() -> void:
	if actor == 0 or phase in ["menu", "over", "resolving"]: return
	bot_turn(revision)

func bot_turn(stamp: int) -> void:
	await get_tree().create_timer(1.1).timeout
	if stamp != revision or actor == 0 or phase in ["menu", "over", "resolving"]: return
	var choices: Array[String] = []
	for card in hands[actor]:
		if legal(actor, card): choices.append(card)
	choices.sort_custom(func(a: String, b: String): return strength(a) < strength(b))
	if not choices.is_empty(): play(actor, choices[0])
	elif phase == "defense": take()
	elif phase == "simple_add": begin_simple_defense()
	else: pass_attack()

func beats(cover: String, attack: String) -> bool:
	if durak_variant == "japanese" and suit_of(attack) == "♠":
		return suit_of(cover) == "♠" and value(cover) > value(attack)
	if suit_of(cover) == suit_of(attack): return value(cover) > value(attack)
	return suit_of(cover) == trump and suit_of(attack) != trump

func table_ranks() -> Array[String]:
	var result: Array[String] = []
	for pair in table:
		for card in [pair.attack, pair.defense]:
			if card and rank_of(card) not in result: result.append(rank_of(card))
	return result

func next_player(start_at: int) -> int:
	for offset in range(1, count + 1):
		var p := (start_at + offset) % count
		if not (deck.is_empty() and hands[p].is_empty()): return p
	return start_at

func player_names() -> Array[String]:
	var names: Array[String] = ["Вы", "Шурик", "Черва", "Козырь"]
	return names.slice(0, count)
func hand_counts() -> Array[int]:
	var result: Array[int] = []
	for hand in hands: result.append(hand.size())
	return result
func name_of(p: int) -> String: return player_names()[p]
func rank_of(card: String) -> String: return card.left(card.length() - 1)
func suit_of(card: String) -> String: return card.right(1)
func value(card: String) -> int: return RANKS.find(rank_of(card))
func strength(card: String) -> int: return value(card) + (20 if suit_of(card) == trump else 0)

func apply_game_layout() -> void:
	if is_instance_valid(box):
		CardVisuals.clean_layout(box)
