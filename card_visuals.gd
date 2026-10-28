extends RefCounted

const RED_SUITS := ["♦", "♥"]
const INK := Color("082b3b")
const RED_INK := Color("c42b3d")
const PAPER := Color.WHITE
const GOLD := Color("f3b64c")
static var cached_theme: Theme
static var cached_background: GradientTexture2D

static func rank_of(card: String) -> String: return card.left(card.length() - 1)
static func suit_of(card: String) -> String: return card.right(1)
static func ink_for(card: String) -> Color: return RED_INK if suit_of(card) in RED_SUITS else INK

static func face_style(_playable := true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER; style.border_color = Color("15232c")
	style.set_border_width_all(5); style.set_corner_radius_all(18)
	return style

static func decorate_button(button: Button, card: String, card_size: Vector2, _playable := true) -> void:
	button.text = ""; button.size = card_size; button.custom_minimum_size = card_size
	button.pivot_offset = card_size / 2.0; button.focus_mode = Control.FOCUS_NONE; button.clip_contents = false
	for state in ["normal", "disabled", "hover", "pressed"]: button.add_theme_stylebox_override(state, face_style())
	add_card_marks(button, card, card_size)

# Fit the complete player hand into the available width without cards hiding one another.
static func fitted_hand_card_size(card_count: int, preferred: Vector2, available_width := 996.0) -> Vector2:
	var count := maxi(1, card_count)
	var gap := minf(6.0, available_width / float(count * 5))
	var width := minf(preferred.x, (available_width - gap * float(count - 1)) / float(count))
	return Vector2(width, preferred.y * width / preferred.x)

static func hand_step(card_count: int, card_size: Vector2, available_width := 996.0) -> float:
	if card_count <= 1: return 0.0
	var gap := minf(6.0, available_width / float(card_count * 5))
	return minf(card_size.x + gap, (available_width - card_size.x) / float(card_count - 1))

static func add_card_marks(parent: Control, card: String, card_size: Vector2) -> void:
	var ink := ink_for(card)
	var corner := Label.new(); corner.text = rank_of(card)
	corner.position = Vector2(maxf(3.0, card_size.x * 0.06), 2); corner.size = Vector2(card_size.x * 0.75, card_size.y * 0.28)
	corner.add_theme_font_size_override("font_size", int(card_size.x * (0.27 if rank_of(card) == "10" else 0.34))); corner.add_theme_color_override("font_color", ink)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(corner)
	var suit := Label.new(); suit.text = suit_of(card); suit.position = Vector2(maxf(3.0, card_size.x * 0.06), card_size.y * 0.23)
	suit.add_theme_font_size_override("font_size", int(card_size.x * 0.31)); suit.add_theme_color_override("font_color", ink)
	suit.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(suit)
	var center := Label.new(); center.text = suit_of(card); center.position = Vector2(card_size.x * 0.12, card_size.y * 0.40)
	center.size = Vector2(card_size.x * 0.85, card_size.y * 0.57)
	center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.add_theme_font_size_override("font_size", int(card_size.x * 0.70)); center.add_theme_color_override("font_color", ink)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(center)

static func decorate_label(label: Label, card: String, card_size: Vector2) -> void:
	label.text = ""; label.size = card_size; label.custom_minimum_size = card_size; label.clip_contents = false
	label.add_theme_stylebox_override("normal", face_style()); add_card_marks(label, card, card_size)

static func back_style(_accent := Color("274454")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("24384c"); style.border_color = Color("527183")
	style.set_border_width_all(6); style.set_corner_radius_all(18)
	style.shadow_color = Color("12202e"); style.shadow_size = 3
	return style

# Single, unscaled deck view. The rotated trump's bounding rectangle is
# [card_width - card_height / 2, card_width + card_height / 2] on X:
# exactly half its long side is beneath the card backs.
static func add_compact_deck(table: Control, at: Vector2, trump_face: String, card_size: Vector2, card_count: int) -> Control:
	var deck_display := Control.new()
	deck_display.name = "DeckDisplay"
	deck_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_display.clip_contents = false
	deck_display.position = at
	deck_display.size = Vector2(card_size.x + card_size.y / 2.0 + 12.0, card_size.y + 12.0)
	table.add_child(deck_display)

	var caption := Label.new()
	caption.name = "DeckCaption"
	caption.text = "КОЛОДА • %d" % card_count
	caption.position = Vector2(0, -53)
	caption.size = Vector2(300, 50)
	caption.add_theme_font_size_override("font_size", 38)
	caption.modulate = Color("d4e8df")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_display.add_child(caption)

	var trump_card := Label.new()
	trump_card.name = "TrumpCard"
	decorate_label(trump_card, trump_face, card_size)
	trump_card.pivot_offset = card_size / 2.0
	trump_card.position = Vector2(card_size.x / 2.0, 0)
	trump_card.rotation_degrees = 90
	trump_card.z_index = 1
	trump_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_display.add_child(trump_card)

	for layer in 4:
		var back := Label.new()
		back.name = "DeckBack%d" % layer
		back.text = ""
		back.size = card_size
		back.custom_minimum_size = card_size
		back.position = Vector2(float(layer) * 2.0, -float(layer) * 2.0)
		back.add_theme_stylebox_override("normal", back_style())
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.z_index = layer + 2
		deck_display.add_child(back)
	return deck_display

static func make_background() -> TextureRect:
	if cached_background == null:
		var gradient := Gradient.new(); gradient.colors = PackedColorArray([Color("314658"), Color("243747")])
		cached_background = GradientTexture2D.new(); cached_background.gradient = gradient
		cached_background.width = 16; cached_background.height = 256
		cached_background.fill_from = Vector2.ZERO; cached_background.fill_to = Vector2(0,1)
	var view := TextureRect.new(); view.texture = cached_background; view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE; view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return view

static func make_theme() -> Theme:
	if cached_theme != null: return cached_theme
	cached_theme = Theme.new(); cached_theme.default_font = preload("res://fonts/Club-Bold.ttf"); cached_theme.default_font_size = 40
	cached_theme.set_font_size("font_size", "Button", 39)
	cached_theme.set_color("font_color", "Label", Color("f7f3e8"))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]: cached_theme.set_color(state, "Button", Color("243747"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new(); style.bg_color = Color("f7f3e8") if state != "pressed" else GOLD
		if state == "disabled": style.bg_color = Color("83929d")
		style.set_corner_radius_all(38); style.content_margin_left = 24; style.content_margin_right = 24
		style.content_margin_top = 14; style.content_margin_bottom = 14
		cached_theme.set_stylebox(state, "Button", style)
	return cached_theme

static func table_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("175e70"); style.border_color = GOLD
	style.set_border_width_all(15); style.set_corner_radius_all(100)
	return style

static func add_table_seats(table: Control, names: Array[String], card_counts: Array[int], active_player: int, table_size: Vector2) -> void:
	table.add_theme_stylebox_override("panel", table_style())
	var parent := table.get_parent()
	var game := parent.get_parent().get_parent()
	var frame := MarginContainer.new(); frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_constant_override("margin_left", 80); frame.add_theme_constant_override("margin_right", 80)
	var index := table.get_index(); parent.add_child(frame); parent.move_child(frame, index); table.reparent(frame, false)
	var gap := Control.new(); gap.custom_minimum_size.y = 320 if game.has_method("durak_name") else 220
	parent.add_child(gap); parent.move_child(gap, frame.get_index())
	# Adapt older fixed-coordinate layouts to the actual center of the table.
	if table.get_node_or_null("PlayedCards") == null:
		var existing := table.get_children()
		var center := Control.new(); center.mouse_filter = Control.MOUSE_FILTER_IGNORE; table.add_child(center)
		center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		center.offset_left = -table_size.x / 2; center.offset_right = table_size.x / 2
		center.offset_top = -table_size.y / 2; center.offset_bottom = table_size.y / 2
		center.pivot_offset = table_size / 2.0; center.scale = Vector2(0.80,0.80)
		for child in existing:
			if child is Panel or (child is Label and child.text == "♣   ♦   ♥   ♠"):
				table.remove_child(child); child.queue_free()
			elif child.name != "DeckDisplay": child.reparent(center, false)
	var mark := Label.new(); mark.text = "♠"; mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_theme_font_size_override("font_size", 380); mark.add_theme_color_override("font_color", Color("15596a"))
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	table.add_child(mark); table.move_child(mark, 0); mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for player in names.size():
		var top := player == 1 if names.size() == 2 else player == 2
		var side := player != 0 and not top
		var seat := PanelContainer.new(); seat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new(); style.bg_color = GOLD if player == active_player else Color("f6d899")
		style.border_color = GOLD; style.set_border_width_all(6); style.set_corner_radius_all(46)
		style.content_margin_left = 14; style.content_margin_right = 14; seat.add_theme_stylebox_override("panel", style)
		var label := Label.new(); label.text = names[player].to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 36); label.add_theme_color_override("font_color", Color("344858")); seat.add_child(label)
		table.add_child(seat); seat.z_index = 80
		if side:
			seat.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT if player == 1 else Control.PRESET_CENTER_RIGHT)
			seat.offset_left = -100; seat.offset_right = 100; seat.offset_top = -40; seat.offset_bottom = 40
			seat.pivot_offset = Vector2(100,40); seat.rotation_degrees = 90 if player == 1 else -90
		else:
			seat.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP if top else Control.PRESET_CENTER_BOTTOM)
			seat.offset_left = -105; seat.offset_right = 105; seat.offset_top = -40; seat.offset_bottom = 40
		if player == 0: continue
		var shown := mini(card_counts[player], 8)
		for i in shown:
			var back := Label.new(); back.mouse_filter = Control.MOUSE_FILTER_IGNORE; back.add_theme_stylebox_override("normal", back_style())
			table.add_child(back); back.z_index = 50 + i
			if top:
				back.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
				back.offset_left = -65 + (i - (shown - 1) / 2.0) * 22; back.offset_right = back.offset_left + 130
				back.offset_top = -210; back.offset_bottom = -55
			else:
				back.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT if player == 1 else Control.PRESET_CENTER_RIGHT)
				back.offset_left = -175 if player == 1 else 55; back.offset_right = back.offset_left + 120
				back.offset_top = -80 + (i - (shown - 1) / 2.0) * 20; back.offset_bottom = back.offset_top + 160
	add_game_header(parent, game)
	# Runs after the caller has finished adding action buttons and hand labels.
	game.call_deferred("apply_game_layout")

static func add_game_header(container: VBoxContainer, game: Control) -> void:
	var main_game := game.has_method("durak_name")
	var back := Callable(game, "show_menu" if main_game else "show_setup")
	var help := Callable(game, "show_durak_rules").bind(game.get("durak_variant")) if main_game else Callable(game, "show_rules")
	var row := HBoxContainer.new(); row.name = "GameHeader"; row.custom_minimum_size.y = 112; row.add_theme_constant_override("separation", 24)
	container.add_child(row); container.move_child(row, 0)
	row.add_child(round_button("‹", back))
	var name := Label.new(); name.text = game.durak_name() if main_game else "КАРТОЧНЫЙ КЛУБ"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL; name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name.add_theme_font_size_override("font_size", 42); row.add_child(name)
	row.add_child(round_button("?", help))

static func round_button(text: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(108,108)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER; button.add_theme_font_size_override("font_size", 58 if text == "‹" else 44)
	for state in ["normal","hover","pressed"]:
		var style := StyleBoxFlat.new(); style.bg_color = PAPER; style.set_corner_radius_all(54); button.add_theme_stylebox_override(state,style)
	button.pressed.connect(callback); return button

static func clean_layout(container: VBoxContainer) -> void:
	for child in container.get_children():
		if child is Label:
			if child.text.begins_with("ВАША РУКА") or child.text.begins_with("ВАШИ КАРТЫ"):
				child.text = ""; child.custom_minimum_size.y = 44
			else: child.add_theme_font_size_override("font_size", 38)
		if child is HBoxContainer and child.name != "GameHeader":
			for button in child.get_children():
				if button is Button and button.text in ["Меню", "Правила"]:
					child.remove_child(button); button.queue_free()
			if child.get_child_count() == 0: child.custom_minimum_size.y = 0

static func shake_card(card: Control) -> void:
	if card.get_meta("shaking", false): return
	card.set_meta("shaking", true)
	var angle := card.rotation_degrees
	var tween := card.create_tween()
	for offset in [-5.0, 5.0, -4.0, 3.0, 0.0]: tween.tween_property(card, "rotation_degrees", angle + offset, 0.055)
	tween.tween_callback(func(): card.set_meta("shaking", false))

static func card_less(a: String, b: String, trump := "") -> bool:
	var suits := ["♣", "♦", "♥", "♠"]
	var ranks := ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
	var suit_a := 4 if suit_of(a) == trump else suits.find(suit_of(a))
	var suit_b := 4 if suit_of(b) == trump else suits.find(suit_of(b))
	if suit_a != suit_b: return suit_a < suit_b
	return ranks.find(rank_of(a)) < ranks.find(rank_of(b))
