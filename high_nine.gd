extends Control

const CardVisuals = preload("res://card_visuals.gd")

signal exit_to_menu

const SUITS := ["♣", "♦", "♥", "♠"]
const RANKS := ["9", "10", "В", "Д", "К", "Т"]
const RED := ["♦", "♥"]
var player_count := 2
var hands: Array[Array] = []
var pile: Array[String] = []
var turn := 0
var finish_order: Array[int] = []
var fast_mode := false
var fast_turns := 0
var running := false
var message := ""
var revision := 0
var action_animation: Dictionary = {}
var content: VBoxContainer

func _ready() -> void: show_setup()

func screen() -> void:
	theme = CardVisuals.make_theme()
	for child in get_children():
		remove_child(child); child.queue_free()
	var bg := CardVisuals.make_background(); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42); margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 24); margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	content = VBoxContainer.new(); content.add_theme_constant_override("separation", 18); content.alignment = BoxContainer.ALIGNMENT_CENTER; margin.add_child(content)

func heading(text: String, sub := "") -> void:
	var header := PanelContainer.new(); var header_style := StyleBoxFlat.new(); header_style.bg_color = Color("314658")
	header_style.border_color = Color("9c7a35"); header_style.border_width_bottom = 3; header_style.set_corner_radius_all(22)
	header_style.content_margin_top = 14; header_style.content_margin_bottom = 14; header.add_theme_stylebox_override("panel", header_style); content.add_child(header)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 4); header.add_child(column)
	var h := Label.new(); h.text = text; h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 58); column.add_child(h)
	if sub:
		var s := Label.new(); s.text = sub; s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; s.modulate = Color("bcd6ca"); column.add_child(s)

func spacer() -> void:
	var s := Control.new(); s.size_flags_vertical = Control.SIZE_EXPAND_FILL; content.add_child(s)

func button(text: String, call: Callable, disabled := false) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 84; b.disabled = disabled
	b.pressed.connect(call); content.add_child(b); return b

func show_setup() -> void:
	revision += 1; running = false; screen()
	heading("Девятка вверх", "24 карты от девятки до туза • вся колода раздаётся игрокам")
	spacer()
	for n in range(2, 5): button("%d игрока • %d бот(а)" % [n, n - 1], start_game.bind(n))
	button("Как играть", show_rules)
	spacer(); button("← К выбору игр", func(): exit_to_menu.emit())

func show_rules() -> void:
	screen(); heading("Правила игры", "Девятка вверх")
	var rules := Label.new()
	rules.text = """• Играют от 2 до 4 участников колодой из 24 карт — от девятки до туза.

• Все карты раздаются случайным образом. Первый ход делает владелец 9♥ и обязан начать именно с неё.

• Далее по часовой стрелке кладут карту того же или более высокого ранга. Карту ниже верхней класть нельзя.

• Вместо хода можно забрать до трёх верхних карт. Стартовая 9♥ всегда остаётся на столе.

• Если в руке собраны четыре карты одного ранга, можно положить одну карту или всё каре сразу.

• Игрок, избавившийся от карт, выходит из партии. Игра продолжается до последнего участника, а результаты показывают полный порядок выхода."""
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 36)
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.add_child(rules); content.add_child(scroll)
	button("Понятно", show_setup)

func start_game(count: int) -> void:
	revision += 1; player_count = count; finish_order.clear(); pile.clear(); hands.clear()
	fast_mode = false; fast_turns = 0; running = true
	var cards: Array[String] = []
	for suit in SUITS:
		for rank in RANKS: cards.append(rank + suit)
	cards.shuffle()
	for p in player_count: hands.append([])
	var dealer := 0
	while not cards.is_empty():
		hands[dealer].append(cards.pop_back()); dealer = (dealer + 1) % player_count
	turn = owner_of("9♥")
	message = "%s начинает с 9♥" % player_name(turn)
	draw_game(); schedule_bot()

func owner_of(card: String) -> int:
	for p in player_count:
		if card in hands[p]: return p
	return 0

func draw_game() -> void:
	screen(); var game_note := Label.new(); game_note.text = "Девятка вверх"; game_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; game_note.add_theme_font_size_override("font_size", 28); game_note.modulate = Color("f4dfaa"); content.add_child(game_note)
	var status := Label.new(); status.text = message; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.custom_minimum_size.y = 58; status.modulate = Color("f4cf74")
	var status_style := StyleBoxFlat.new(); status_style.bg_color = Color("314658")
	status_style.border_color = Color("9c7a35"); status_style.set_border_width_all(2); status_style.set_corner_radius_all(18)
	status.add_theme_stylebox_override("normal", status_style); content.add_child(status)
	add_pile_view()
	var hand_title := Label.new(); hand_title.text = "ВАШИ КАРТЫ • %d" % hands[0].size()
	hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hand_title.modulate = Color("bcd6ca")
	content.add_child(hand_title); add_hand()
	var actions := HBoxContainer.new(); actions.alignment = BoxContainer.ALIGNMENT_CENTER; actions.custom_minimum_size.y = 90; content.add_child(actions)
	if turn == 0 and running:
		var take := small_button("Забрать 3 сверху", take_three.bind(0))
		take.disabled = pile.size() <= 1; actions.add_child(take)
	actions.add_child(small_button("Меню", show_setup))
	if fast_mode and 0 in finish_order: add_fast_finish_notice()
	action_animation.clear()

func add_fast_finish_notice() -> void:
	var shade := ColorRect.new(); shade.color = Color(0.04, 0.02, 0.10, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.z_index = 400; add_child(shade)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); center.z_index = 401; add_child(center)
	var panel := PanelContainer.new(); panel.custom_minimum_size = Vector2(760, 390); center.add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color("102a23"); style.border_color = Color("d8b85c")
	style.set_border_width_all(4); style.set_corner_radius_all(28); panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; column.add_theme_constant_override("separation", 24); panel.add_child(column)
	var done := Label.new(); done.text = "Вы вышли %d-м!" % (finish_order.find(0) + 1); done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.add_theme_font_size_override("font_size", 48); done.modulate = Color("f4cf74"); column.add_child(done)
	var waiting := Label.new(); waiting.text = "Компьютеры доигрывают"; waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting.add_theme_font_size_override("font_size", 34); column.add_child(waiting)
	var order := Label.new(); order.text = "Уже вышли: " + finished_names(); order.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; order.modulate = Color("bcd6ca"); column.add_child(order)
	animate_waiting(waiting, revision)

func finished_names() -> String:
	var names: Array[String] = []
	for p in finish_order: names.append(player_name(p))
	return ", ".join(names)

func animate_waiting(label: Label, stamp: int) -> void:
	var frames := ["♣", "♦", "♥", "♠"]
	var frame := 0
	while is_instance_valid(label) and running and fast_mode and stamp == revision:
		label.text = "Компьютеры доигрывают  %s" % frames[frame % frames.size()]
		frame += 1
		await get_tree().create_timer(0.34).timeout

func opponent_view(p: int) -> PanelContainer:
	var seat := PanelContainer.new(); seat.custom_minimum_size.x = 280 if player_count == 2 else 220
	var seat_style := StyleBoxFlat.new(); seat_style.bg_color = Color(0.02,0.10,0.08,0.92)
	seat_style.border_color = Color("f2cf72") if p == turn else Color("315c4d")
	seat_style.set_border_width_all(3 if p == turn else 2); seat_style.set_corner_radius_all(18)
	seat_style.content_margin_left = 8; seat_style.content_margin_right = 8; seat.add_theme_stylebox_override("panel", seat_style)
	var view := VBoxContainer.new(); seat.add_child(view)
	var identity := HBoxContainer.new(); identity.alignment = BoxContainer.ALIGNMENT_CENTER; identity.add_theme_constant_override("separation", 10); view.add_child(identity)
	var avatar := Label.new(); avatar.text = player_name(p).left(1); avatar.custom_minimum_size = Vector2(56,56)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; avatar.add_theme_font_size_override("font_size", 22)
	var avatar_style := StyleBoxFlat.new(); avatar_style.bg_color = Color("d8b85c") if p == turn else Color("244b40")
	avatar_style.set_corner_radius_all(28); avatar_style.border_color = Color("fff0b0"); avatar_style.set_border_width_all(2)
	avatar.add_theme_stylebox_override("normal", avatar_style); identity.add_child(avatar)
	var name := Label.new(); name.text = "%s%s\n%d карт" % [player_name(p), "  • ход" if p == turn else "", hands[p].size()]
	name.add_theme_font_size_override("font_size", 24); identity.add_child(name)
	var fan := Control.new(); fan.custom_minimum_size.y = 88; view.add_child(fan)
	var visible := mini(7, hands[p].size())
	for i in visible:
		var back := card_back(Vector2(54, 74)); back.position = Vector2(45 + i * 23, 5 + abs(i - (visible - 1) / 2.0) * 2)
		back.rotation_degrees = (i - (visible - 1) / 2.0) * 2.0; back.z_index = i; fan.add_child(back)
		if action_animation.get("kind", "") == "take" and action_animation.get("player", -1) == p and i >= visible - action_animation.get("count", 0):
			var home := back.position
			back.position = Vector2(seat.custom_minimum_size.x / 2.0, 360)
			back.scale = Vector2(1.7, 1.7); back.modulate.a = 0.2
			animate_move(back, home, back.rotation_degrees, 1.5, i * 0.14)
	return seat

func add_pile_view() -> void:
	var felt := Panel.new(); felt.custom_minimum_size.y = 420; felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new(); style.bg_color = Color("0b4f5f"); style.border_color = Color("e0ad4f")
	style.set_border_width_all(11); style.set_corner_radius_all(74); style.shadow_color = Color(0,0,0,0.42); style.shadow_size = 16
	felt.add_theme_stylebox_override("panel", style); content.add_child(felt)
	var inner := Panel.new(); inner.position = Vector2(17,17); inner.size = Vector2(962,386); inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_style := StyleBoxFlat.new(); inner_style.bg_color = Color.TRANSPARENT; inner_style.border_color = Color(0.85,0.70,0.33,0.34)
	inner_style.set_border_width_all(3); inner_style.set_corner_radius_all(60); inner.add_theme_stylebox_override("panel", inner_style); felt.add_child(inner)
	var mark := Label.new(); mark.text = "♣   ♦   ♥   ♠"; mark.position = Vector2(270,165); mark.size = Vector2(480,80)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; mark.add_theme_font_size_override("font_size", 52); mark.modulate = Color(1,1,1,0.07)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE; felt.add_child(mark)
	var rules := Label.new(); rules.text = "ВЕРХНЯЯ КАРТА"; rules.position = Vector2(30, 25); rules.modulate = Color("bcd6ca"); felt.add_child(rules)
	if pile.is_empty():
		var start := Label.new(); start.text = "Первый ход только с 9♥"; start.position = Vector2(250, 160)
		start.size = Vector2(500, 60); start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; start.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; felt.add_child(start)
	else:
		var shown_from := maxi(0, pile.size() - 5)
		for i in range(shown_from, pile.size()):
			var card := face_card(pile[i], Vector2(158, 220)); var offset := i - shown_from
			var home := Vector2(400 + offset * 9, 90 + offset * 5)
			card.position = home; card.rotation_degrees = -4 + offset * 2
			card.z_index = offset; felt.add_child(card)
			var animated_cards: Array = action_animation.get("cards", [])
			if action_animation.get("kind", "") == "play" and pile[i] in animated_cards:
				var source := Vector2(480, 520) if action_animation.get("player", 0) == 0 else Vector2(480, -190)
				card.position = source; card.scale = Vector2(0.62, 0.62); card.modulate.a = 0.25
				animate_move(card, home, -4 + offset * 2, 1.0, animated_cards.find(pile[i]) * 0.08)
		var amount := Label.new(); amount.text = "%d карт в стопке" % pile.size(); amount.position = Vector2(380, 335)
		amount.size = Vector2(240, 40); amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; felt.add_child(amount)
	CardVisuals.add_table_seats(felt, player_names(), hand_counts(), turn, Vector2(996, 420))

func add_hand() -> void:
	hands[0].sort_custom(CardVisuals.card_less)
	var area := Control.new(); area.custom_minimum_size.y = 290; area.clip_contents = false; content.add_child(area)
	var total := hands[0].size()
	if total == 0: return
	var card_size := CardVisuals.fitted_hand_card_size(total, Vector2(150, 208)); var available := 996.0
	var step: float = CardVisuals.hand_step(total, card_size)
	var start_x: float = (available - (card_size.x + step * (total - 1))) / 2.0
	for i in total:
		var card: String = hands[0][i]; var distance := i - (total - 1) / 2.0
		var home := Vector2(start_x + i * step, 45)
		var face := face_card(card, card_size); face.position = home; face.rotation_degrees = 0.0; face.z_index = i
		face.mouse_entered.connect(lift_hand_card.bind(face, home, 0.0))
		face.mouse_exited.connect(lower_hand_card.bind(face, home, 0.0, i))
		face.pressed.connect(attempt_player_card.bind(card, face))
		area.add_child(face)
		var received: Array = action_animation.get("cards", [])
		if action_animation.get("kind", "") == "take" and action_animation.get("player", -1) == 0 and card in received:
			face.position = Vector2(470, -500); face.scale = Vector2(0.55, 0.55); face.modulate.a = 0.2
			animate_move(face, home, 0.0, 1.0, received.find(card) * 0.08)

func lift_hand_card(card: Control, home: Vector2, angle: float) -> void:
	card.z_index = 1000
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", home + Vector2(0, -30), 0.28)
	tween.tween_property(card, "rotation_degrees", angle * 0.1, 0.28)
	tween.tween_property(card, "scale", Vector2(1.04, 1.04), 0.28)

func lower_hand_card(card: Control, home: Vector2, angle: float, layer: int) -> void:
	card.z_index = layer
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", home, 0.28)
	tween.tween_property(card, "rotation_degrees", angle, 0.28)
	tween.tween_property(card, "scale", Vector2.ONE, 0.28)

func animate_move(node: Control, destination: Vector2, angle: float, duration: float, delay: float) -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", destination, duration).set_delay(delay)
	tween.tween_property(node, "rotation_degrees", angle, duration).set_delay(delay)
	tween.tween_property(node, "scale", Vector2.ONE, duration).set_delay(delay)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.65).set_delay(delay)

func attempt_player_card(card: String, card_view: Control) -> void:
	var quartet := rank_count(0, rank_of(card)) == 4 and not pile.is_empty()
	if turn != 0 or (not legal(card) and not quartet):
		reject_card(card_view)
		return
	if quartet:
		show_quartet_choice(card, legal(card))
	else:
		play_card(0, card, false)

func show_quartet_choice(card: String, single_allowed: bool) -> void:
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.z_index = 500; add_child(shade)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); center.z_index = 501; add_child(center)
	var panel := PanelContainer.new(); panel.custom_minimum_size = Vector2(680, 440); center.add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color("102a23"); style.border_color = Color("d8b85c")
	style.set_border_width_all(4); style.set_corner_radius_all(26); panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 20); panel.add_child(column)
	var label := Label.new(); label.text = "У вас четыре карты ранга %s" % rank_of(card)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 34); column.add_child(label)
	var one := Button.new(); one.text = "Положить одну карту"; one.disabled = not single_allowed
	one.pressed.connect(choose_quartet.bind(card, false, shade, center)); column.add_child(one)
	var all := Button.new(); all.text = "Положить все четыре"
	all.pressed.connect(choose_quartet.bind(card, true, shade, center)); column.add_child(all)
	var cancel := Button.new(); cancel.text = "Отмена"
	cancel.pressed.connect(close_choice.bind(shade, center)); column.add_child(cancel)

func close_choice(shade: Control, center: Control) -> void:
	shade.queue_free(); center.queue_free()

func choose_quartet(card: String, play_all: bool, shade: Control, center: Control) -> void:
	close_choice(shade, center)
	play_card(0, card, play_all)

func reject_card(card: Control) -> void:
	CardVisuals.shake_card(card)

func face_card(card: String, size: Vector2) -> Button:
	var b := Button.new(); CardVisuals.decorate_button(b, card, size)
	return b

func card_back(size: Vector2) -> Label:
	var l := Label.new(); l.text = "✦"; l.size = size; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var s := CardVisuals.back_style(Color("315f87")); s.set_border_width_all(4); s.set_corner_radius_all(8)
	l.add_theme_stylebox_override("normal", s); return l

func small_button(text: String, call: Callable) -> Button:
	var b := Button.new(); b.text = text; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.custom_minimum_size.y = 78; b.pressed.connect(call); return b

func legal(card: String) -> bool:
	if pile.is_empty(): return card == "9♥"
	return value(card) >= value(pile[-1])

func play_card(player: int, card: String, play_all := true) -> void:
	var has_four := rank_count(player, rank_of(card)) == 4 and not pile.is_empty()
	if player != turn or (not legal(card) and not (has_four and play_all)): return
	var same_rank: Array[String] = []
	for held in hands[player]:
		if rank_of(held) == rank_of(card): same_rank.append(held)
	var played: Array[String] = []
	if play_all and same_rank.size() == 4 and not pile.is_empty():
		played.assign(same_rank)
	else:
		played.append(card)
	for item in played: hands[player].erase(item); pile.append(item)
	action_animation = {"kind": "play", "player": player, "cards": played.duplicate(), "count": played.size()}
	message = "%s кладёт %s" % [player_name(player), "каре %s" % rank_of(card) if played.size() == 4 else card]
	after_turn(player)

func take_three(player: int) -> void:
	if player != turn or pile.size() <= 1: return
	var taken: Array[String] = []
	while taken.size() < 3 and pile.size() > 1:
		var card: String = pile.pop_back()
		if card == "9♥": pile.push_front(card); break
		taken.append(card); hands[player].append(card)
	action_animation = {"kind": "take", "player": player, "cards": taken.duplicate(), "count": taken.size()}
	message = "%s забирает %d карт" % [player_name(player), taken.size()]
	after_turn(player)

func after_turn(player: int) -> void:
	if hands[player].is_empty() and player not in finish_order:
		finish_order.append(player)
		message = "%s выходит %d-м" % [player_name(player), finish_order.size()]
		if player == 0:
			fast_mode = true
			fast_turns = 0
	var active := active_players()
	if active.size() == 1:
		finish_order.append(active[0])
		turn = -1
		draw_game()
		var stamp := revision
		await get_tree().create_timer(0.9).timeout
		if stamp == revision: finish_game()
		return
	turn = next_active(player)
	if fast_mode:
		fast_turns += 1
		if fast_turns >= 160:
			resolve_fast_stalemate()
			return
		if player == 0:
			message = "Вы вышли %d-м. Компьютеры быстро доигрывают…" % finish_order.size()
			draw_game()
		schedule_bot()
	else:
		draw_game(); schedule_bot()

func active_players() -> Array[int]:
	var result: Array[int] = []
	for p in player_count:
		if p not in finish_order: result.append(p)
	return result

func next_active(from: int) -> int:
	for offset in range(1, player_count + 1):
		var p := (from + offset) % player_count
		if p not in finish_order: return p
	return from

func schedule_bot() -> void:
	if not running or turn == 0: return
	bot_move(revision)

func bot_move(stamp: int) -> void:
	await get_tree().create_timer(0.06 if fast_mode else 1.2).timeout
	if stamp != revision or not running or turn == 0: return
	var choice := choose_bot_card(turn)
	if choice == "": take_three(turn)
	else: play_card(turn, choice)

func choose_bot_card(player: int) -> String:
	var choices: Array[String] = []
	for card in hands[player]:
		if legal(card) or (not pile.is_empty() and rank_count(player, rank_of(card)) == 4): choices.append(card)
	if choices.is_empty(): return ""
	# Иногда выгоднее снять верх стопки, чтобы открыть более низкий ранг
	# и не зациклить партию между двумя последними игроками.
	if pile.size() > 3 and randf() < 0.16: return ""
	choices.sort_custom(func(a: String, b: String):
		var a_count := rank_count(player, rank_of(a))
		var b_count := rank_count(player, rank_of(b))
		if a_count != b_count: return a_count > b_count
		return value(a) > value(b)
	)
	return choices[0]

func rank_count(player: int, rank: String) -> int:
	var amount := 0
	for card in hands[player]:
		if rank_of(card) == rank: amount += 1
	return amount

func resolve_fast_stalemate() -> void:
	var remaining := active_players()
	remaining.sort_custom(func(a: int, b: int): return hands[a].size() < hands[b].size())
	for player in remaining: finish_order.append(player)
	finish_game()

func finish_game() -> void:
	running = false; revision += 1; screen(); heading("Игра окончена", "Итоговый порядок")
	spacer()
	for i in finish_order.size():
		var row := Label.new(); row.text = "%d место — %s" % [i + 1, player_name(finish_order[i])]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; row.add_theme_font_size_override("font_size", 36)
		if finish_order[i] == 0: row.modulate = Color("f4cf74")
		content.add_child(row)
	spacer(); button("Сыграть ещё", start_game.bind(player_count)); button("К выбору игр", func(): exit_to_menu.emit())

func player_names() -> Array[String]:
	var names: Array[String] = ["Вы", "Шурик", "Черва", "Козырь"]
	return names.slice(0, player_count)
func hand_counts() -> Array[int]:
	var result: Array[int] = []
	for hand in hands: result.append(hand.size())
	return result
func player_name(p: int) -> String: return player_names()[p]
func rank_of(card: String) -> String: return card.left(card.length() - 1)
func suit_of(card: String) -> String: return card.right(1)
func value(card: String) -> int: return RANKS.find(rank_of(card))

func apply_game_layout() -> void:
	if is_instance_valid(content):
		CardVisuals.clean_layout(content)
