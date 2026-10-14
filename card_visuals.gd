extends RefCounted

const RED_SUITS := ["♦", "♥"]
const INK := Color("18201d")
const RED_INK := Color("bd2636")
const PAPER := Color("fffaf0")
const GOLD := Color("d8b85c")

static func rank_of(card: String) -> String: return card.left(card.length() - 1)
static func suit_of(card: String) -> String: return card.right(1)
static func ink_for(card: String) -> Color: return RED_INK if suit_of(card) in RED_SUITS else INK

static func face_style(playable := true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER if playable else Color("eee9dc")
	style.border_color = GOLD if playable else Color("a79f8c")
	style.set_border_width_all(4); style.set_corner_radius_all(15)
	style.shadow_color = Color(0.01, 0.02, 0.02, 0.5); style.shadow_size = 11; style.shadow_offset = Vector2(0, 8)
	return style

static func decorate_button(button: Button, card: String, card_size: Vector2, playable := true) -> void:
	button.text = ""; button.size = card_size; button.custom_minimum_size = card_size
	button.pivot_offset = Vector2(card_size.x / 2.0, card_size.y * 0.92)
	var normal := face_style(playable); var hover := normal.duplicate(); hover.border_color = Color("f6dc82"); hover.shadow_size = 17
	var pressed := normal.duplicate(); pressed.bg_color = Color("f5edda")
	for state in ["normal", "disabled"]: button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed)
	add_card_marks(button, card, card_size)

static func add_card_marks(parent: Control, card: String, card_size: Vector2) -> void:
	var ink := ink_for(card)
	var corner := Label.new(); corner.text = "%s\n%s" % [rank_of(card), suit_of(card)]
	corner.position = Vector2(10, 7); corner.size = Vector2(52, 72); corner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corner.add_theme_font_size_override("font_size", int(card_size.x * 0.22)); corner.add_theme_color_override("font_color", ink)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(corner)
	var center := Label.new(); center.text = suit_of(card); center.position = Vector2(0, card_size.y * 0.23)
	center.size = Vector2(card_size.x, card_size.y * 0.52); center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; center.add_theme_font_size_override("font_size", int(card_size.x * 0.48))
	center.add_theme_color_override("font_color", ink); center.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(center)
	var lower := Label.new(); lower.text = "%s\n%s" % [rank_of(card), suit_of(card)]
	lower.position = Vector2(card_size.x - 61, card_size.y - 79); lower.size = Vector2(52, 72); lower.rotation_degrees = 180
	lower.pivot_offset = lower.size / 2.0; lower.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lower.add_theme_font_size_override("font_size", int(card_size.x * 0.22)); lower.add_theme_color_override("font_color", ink)
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(lower)

static func decorate_label(label: Label, card: String, card_size: Vector2) -> void:
	label.text = "%s\n%s" % [rank_of(card), suit_of(card)]; label.size = card_size; label.custom_minimum_size = card_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(card_size.x * 0.35)); label.add_theme_color_override("font_color", ink_for(card))
	label.add_theme_stylebox_override("normal", face_style())

static func back_style(accent := Color("295a91")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = accent; style.border_color = Color("f1db9b")
	style.set_border_width_all(6); style.set_corner_radius_all(13); style.shadow_color = Color(0,0,0,0.46)
	style.shadow_size = 9; style.shadow_offset = Vector2(0,6); return style

static func make_background() -> TextureRect:
	var gradient := Gradient.new(); gradient.colors = PackedColorArray([Color("2d2028"), Color("60383a"), Color("352532")])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.width = 1080; texture.height = 1920
	texture.fill_from = Vector2(0.05,0.0); texture.fill_to = Vector2(0.95,1.0)
	var background := TextureRect.new(); background.texture = texture; background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); return background

static func add_table_seats(table: Control, names: Array[String], card_counts: Array[int], active_player: int, table_size: Vector2) -> void:
	var opponents := names.size() - 1
	for player in range(1, names.size()):
		var seat := PanelContainer.new(); seat.custom_minimum_size = Vector2(190, 58); seat.size = seat.custom_minimum_size
		var style := StyleBoxFlat.new(); style.bg_color = Color("e6bb62") if player == active_player else Color("d3a956")
		style.border_color = Color("fff0a8") if player == active_player else Color("477666")
		style.set_border_width_all(3); style.set_corner_radius_all(25); style.shadow_size = 5
		seat.add_theme_stylebox_override("panel", style)
		var label := Label.new(); label.text = "%s%s" % [names[player], "  •" if player == active_player else ""]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 29); label.add_theme_color_override("font_color", Color("573524")); seat.add_child(label)
		if opponents == 1:
			seat.set_anchor(SIDE_LEFT,0.5); seat.set_anchor(SIDE_RIGHT,0.5); seat.offset_left=-95; seat.offset_right=95; seat.offset_top=-29; seat.offset_bottom=29
		elif opponents == 2:
			seat.set_anchor(SIDE_TOP,0.5); seat.set_anchor(SIDE_BOTTOM,0.5); seat.offset_top=-29; seat.offset_bottom=29
			if player==1: seat.offset_left=-66; seat.offset_right=124
			else: seat.set_anchor(SIDE_LEFT,1.0); seat.set_anchor(SIDE_RIGHT,1.0); seat.offset_left=-124; seat.offset_right=66
			seat.pivot_offset = seat.size / 2.0; seat.rotation_degrees = -90 if player == 1 else 90
		else:
			if player == 1:
				seat.set_anchor(SIDE_TOP,0.5); seat.set_anchor(SIDE_BOTTOM,0.5); seat.offset_left=-66; seat.offset_right=124; seat.offset_top=-29; seat.offset_bottom=29; seat.pivot_offset = seat.size / 2.0; seat.rotation_degrees = -90
			elif player == 2:
				seat.set_anchor(SIDE_LEFT,0.5); seat.set_anchor(SIDE_RIGHT,0.5); seat.offset_left=-95; seat.offset_right=95; seat.offset_top=-29; seat.offset_bottom=29
			else:
				seat.set_anchor(SIDE_LEFT,1.0); seat.set_anchor(SIDE_RIGHT,1.0); seat.set_anchor(SIDE_TOP,0.5); seat.set_anchor(SIDE_BOTTOM,0.5); seat.offset_left=-124; seat.offset_right=66; seat.offset_top=-29; seat.offset_bottom=29; seat.pivot_offset = seat.size / 2.0; seat.rotation_degrees = 90
		seat.z_index = 80; table.add_child(seat)
		var shown := mini(card_counts[player], 8)
		for card_index in shown:
			var back := Label.new(); back.text = "✦"; back.size = Vector2(62, 86)
			back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			back.add_theme_font_size_override("font_size", 20)
			var back_box := back_style(); back_box.set_border_width_all(3); back_box.set_corner_radius_all(8); back.add_theme_stylebox_override("normal", back_box)
			if opponents == 1 or (opponents == 3 and player == 2):
				back.set_anchor(SIDE_LEFT,0.5); back.set_anchor(SIDE_RIGHT,0.5); back.offset_left=-31+(card_index-(shown-1)/2.0)*19; back.offset_right=31+(card_index-(shown-1)/2.0)*19; back.offset_top=38; back.offset_bottom=124
			else:
				back.pivot_offset = back.size / 2.0; back.rotation_degrees = 90
				back.set_anchor(SIDE_TOP,0.5); back.set_anchor(SIDE_BOTTOM,0.5); back.offset_top=-43+(card_index-(shown-1)/2.0)*15; back.offset_bottom=43+(card_index-(shown-1)/2.0)*15
				if player == 1: back.offset_left=-34; back.offset_right=28
				else: back.set_anchor(SIDE_LEFT,1.0); back.set_anchor(SIDE_RIGHT,1.0); back.offset_left=-28; back.offset_right=34
			back.z_index = 70 + card_index; table.add_child(back)
	var you := PanelContainer.new(); you.custom_minimum_size = Vector2(150, 54); you.size = you.custom_minimum_size
	you.set_anchor(SIDE_LEFT,0.5); you.set_anchor(SIDE_RIGHT,0.5); you.set_anchor(SIDE_TOP,1.0); you.set_anchor(SIDE_BOTTOM,1.0)
	you.offset_left=-75; you.offset_right=75; you.offset_top=-27; you.offset_bottom=27; you.z_index = 82
	var you_style := StyleBoxFlat.new(); you_style.bg_color = Color("e6bb62") if active_player == 0 else Color("d3a956")
	you_style.border_color = Color("fff0a8"); you_style.set_border_width_all(3); you_style.set_corner_radius_all(24); you.add_theme_stylebox_override("panel", you_style)
	var you_label := Label.new(); you_label.text = "ВЫ%s" % ("  •" if active_player == 0 else "")
	you_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; you_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	you_label.add_theme_font_size_override("font_size", 24); you_label.add_theme_color_override("font_color", Color("573524")); you.add_child(you_label); table.add_child(you)
