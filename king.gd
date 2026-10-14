extends Control
const CardVisuals = preload("res://card_visuals.gd")
signal exit_to_menu
const SUITS := ["♣", "♦", "♥", "♠"]
const RANKS := ["7", "8", "9", "10", "В", "Д", "К", "Т"]
const CONTRACTS := ["tricks", "hearts", "boys", "queens", "king", "last", "all"]
var king_mode := "short"
var hands: Array[Array] = []; var scores := [0,0,0,0]; var table: Array[Dictionary] = []
var used: Array[Array] = []; var round_index := 0; var leader := 0; var turn := 0; var trick_index := 0
var contract := ""; var positive := false; var message := ""; var revision := 0; var running := false
var round_start_scores := [0,0,0,0]
var content: VBoxContainer

func _ready() -> void: show_setup()
func mode_name() -> String: return "Короткий Кинг" if king_mode == "short" else "Длинный Кинг"
func screen() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	add_child(CardVisuals.make_background()); var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,42)
	margin.add_theme_constant_override("margin_top",18); margin.add_theme_constant_override("margin_bottom",18); add_child(margin)
	content=VBoxContainer.new(); content.add_theme_constant_override("separation",14); content.alignment=BoxContainer.ALIGNMENT_CENTER; margin.add_child(content)
func heading(text:String, sub:="") -> void:
	var p:=PanelContainer.new(); var s:=StyleBoxFlat.new(); s.bg_color=Color(0.025,0.07,0.06,0.9); s.border_color=Color("9c7a35"); s.border_width_bottom=3; s.set_corner_radius_all(22); p.add_theme_stylebox_override("panel",s); content.add_child(p)
	var v:=VBoxContainer.new(); p.add_child(v); var l:=Label.new(); l.text=text; l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",56); v.add_child(l)
	if sub: var n:=Label.new(); n.text=sub; n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; n.modulate=Color("bcd6ca"); v.add_child(n)
func button(text:String, call:Callable) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=82; b.pressed.connect(call); content.add_child(b); return b
func small(text:String, call:Callable) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=76; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.pressed.connect(call); return b
func spacer() -> void: var c:=Control.new(); c.size_flags_vertical=Control.SIZE_EXPAND_FILL; content.add_child(c)

func show_setup() -> void:
	revision+=1; running=false; screen(); heading(mode_name(),"4 игрока • 32 карты • игра на взятки"); spacer(); button("Начать партию",start_game); button("Правила",show_rules); spacer(); button("← К выбору игр",func():exit_to_menu.emit())
func show_rules() -> void:
	screen(); heading("Правила игры",mode_name()); var l:=Label.new()
	l.text="""Играют вчетвером 32 картами от семёрки до туза. Каждому раздаётся по 8 карт, козырей нет. Нужно ходить в масть; если нужной масти нет, разрешена любая карта. Взятку получает старшая карта масти первого хода.

Контракты: без взяток (2 очка за взятку), без червей (2 за карту), без мальчиков — валетов и королей (2), без дам (4), без Кинга червей (16), без двух последних взяток (8 за каждую) и общий контракт со всеми условиями. В положительном круге те же очки начисляются со знаком плюс.

В контрактах с червями нельзя начинать с червей, пока есть другая масть. В штрафном контракте Кинга его необходимо положить при первой возможности, если масти хода в руке нет.

В коротком Кинге контракты идут по фиксированному списку: сначала семь штрафных, затем семь положительных. В длинном Кинге право выбора переходит по кругу, и каждый игрок выбирает каждый тип контракта только один раз. Побеждает игрок с наибольшим итоговым счётом."""
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",36); l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var sc:=ScrollContainer.new(); sc.size_flags_vertical=Control.SIZE_EXPAND_FILL; sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.add_child(l); content.add_child(sc); button("Понятно",show_setup)

func start_game() -> void:
	revision+=1; scores=[0,0,0,0]; used.clear(); for p in 4: used.append([])
	round_index=0; leader=randi_range(0,3); running=true; start_round()
func start_round() -> void:
	if (king_mode=="short" and round_index>=14) or (king_mode=="long" and round_index>=56): finish_game(); return
	if king_mode=="short": contract=CONTRACTS[round_index%7]; positive=round_index>=7; deal_round()
	else:
		var chooser:=round_index%4
		if chooser==0: show_contract_choice(); return
		var options:=remaining_contracts(chooser); choose_contract(chooser,options.pick_random())
func show_contract_choice() -> void:
	screen(); heading("Выберите контракт","Ваш выбор • каждый вариант доступен один раз"); spacer()
	for key in remaining_contracts(0): button(contract_name(key),choose_contract.bind(0,key))
	spacer()
func remaining_contracts(player:int) -> Array[String]:
	var result:Array[String]=[]
	for sign in ["-","+"]:
		for base in CONTRACTS:
			var key:String=sign+base
			if key not in used[player]: result.append(key)
	return result
func choose_contract(player:int,key:String) -> void:
	used[player].append(key); positive=key.left(1)=="+"; contract=key.substr(1); deal_round()
func deal_round() -> void:
	hands.clear(); table.clear(); for p in 4:hands.append([])
	var deck:Array[String]=[]; for suit in SUITS: for rank in RANKS: deck.append(rank+suit)
	deck.shuffle(); for i in 8: for p in 4:hands[p].append(deck.pop_back())
	for p in 4: hands[p].sort_custom(card_less)
	round_start_scores=scores.duplicate(); leader=round_index%4; turn=leader; trick_index=0; message="%s начинает раздачу"%player_name(turn); draw_game(); schedule_bot()

func draw_game() -> void:
	screen()
	var round_note:=Label.new(); round_note.text="Раздача %d/%d"%[round_index+1,14 if king_mode=="short" else 56]; round_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; round_note.add_theme_font_size_override("font_size",28); round_note.modulate=Color("f4dfaa"); content.add_child(round_note)
	add_contract_banner()
	var st:=Label.new(); st.text=message; st.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; st.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; st.custom_minimum_size.y=55; st.modulate=Color("f2cf72"); content.add_child(st)
	var felt:=Panel.new(); felt.custom_minimum_size.y=700; felt.size_flags_vertical=Control.SIZE_EXPAND_FILL; var fs:=StyleBoxFlat.new(); fs.bg_color=Color("0b4f5f"); fs.border_color=Color("e0ad4f"); fs.set_border_width_all(11); fs.set_corner_radius_all(70); felt.add_theme_stylebox_override("panel",fs); content.add_child(felt)
	for i in table.size(): var card:=Label.new(); CardVisuals.decorate_label(card,table[i].card,Vector2(145,198)); card.position=Vector2(170+i*190,250); card.rotation_degrees=-5+i*3; felt.add_child(card)
	CardVisuals.add_table_seats(felt, player_names(), hand_counts(), turn, Vector2(996,700))
	var score:=Label.new(); score.text="Ваш счёт: %d"%scores[0]; score.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; content.add_child(score)
	add_hand(); var nav:=HBoxContainer.new(); nav.custom_minimum_size.y=84; content.add_child(nav)
	if table.size()==4: nav.add_child(small("Продолжить",resolve_trick))
	elif turn==0: nav.add_child(small("Очки",show_scores))
	nav.add_child(small("Правила",show_rules)); nav.add_child(small("Меню",show_setup))
func add_contract_banner() -> void:
	var panel:=PanelContainer.new(); panel.custom_minimum_size.y=102
	var style:=StyleBoxFlat.new(); style.bg_color=Color("442431") if not positive else Color("164f3b"); style.border_color=Color("f2cf72"); style.set_border_width_all(3); style.set_corner_radius_all(22); panel.add_theme_stylebox_override("panel",style); content.add_child(panel)
	var label:=Label.new(); label.text=contract_name(("+" if positive else "-")+contract).to_upper(); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size",48); label.add_theme_color_override("font_color",Color("fff0b0")); panel.add_child(label)
func add_hand() -> void:
	var area:=Control.new(); area.custom_minimum_size.y=300; content.add_child(area); var total:=hands[0].size(); if total==0:return
	var step:float=110.0; var start:float=(996-(154+step*(total-1)))/2
	for i in total:
		var card:String=hands[0][i]; var b:=Button.new(); CardVisuals.decorate_button(b,card,Vector2(154,208),true); b.position=Vector2(start+i*step,30+minf(abs(i-(total-1)/2.0)*5,45)); b.pressed.connect(play.bind(0,card)); area.add_child(b)
func legal(player:int,card:String) -> bool:
	if player!=turn or table.size()>=4:return false
	if table.is_empty():
		if suit_of(card)=="♥" and contract in ["hearts","king","all"]:
			for c in hands[player]: if suit_of(c)!="♥":return false
		return true
	var led:String=suit_of(table[0].card); if suit_of(card)==led:return true
	for c in hands[player]: if suit_of(c)==led:return false
	if not positive and contract in ["king","all"] and "К♥" in hands[player]: return card=="К♥"
	return true
func play(player:int,card:String) -> void:
	if not legal(player,card):return
	hands[player].erase(card); table.append({"player":player,"card":card}); message="%s кладёт %s"%[player_name(player),card]
	if table.size()==4:
		var winner:=trick_winner()
		message="Все карты открыты • взятку забирает %s"%player_name(winner)
		draw_game(); return
	turn=(turn+1)%4; draw_game(); schedule_bot()
func resolve_trick() -> void:
	if table.size()!=4:return
	var winner:=trick_winner()
	var points:=trick_points(); scores[winner]+=points if positive else -points; trick_index+=1; leader=winner; turn=winner
	message="%s берёт взятку (%s%d)"%[player_name(winner),"+" if positive else "-",points]
	if trick_index==8 or contract_finished_early(): show_round_result(); return
	table.clear(); draw_game(); schedule_bot()

func trick_winner() -> int:
	var led:String=suit_of(table[0].card); var winner:int=table[0].player; var best:int=value(table[0].card)
	for item in table:
		if suit_of(item.card)==led and value(item.card)>best:best=value(item.card);winner=item.player
	return winner

func contract_finished_early() -> bool:
	if contract not in ["hearts","boys","queens","king"]: return false
	var distributed:=0
	for p in 4: distributed+=absi(scores[p]-round_start_scores[p])
	return distributed>=16

func show_scores() -> void:
	show_score_screen(false)

func show_round_result() -> void:
	show_score_screen(true)

func show_score_screen(round_finished: bool) -> void:
	screen(); heading("Счёт",contract_name(("+" if positive else "-")+contract) if round_finished else "Текущая партия")
	spacer()
	for p in 4:
		var change:int=scores[p]-round_start_scores[p]
		var row:=Label.new(); row.text="%s     %s%d     всего %d"%[player_name(p),"+" if change>=0 else "",change,scores[p]]
		row.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; row.add_theme_font_size_override("font_size",42); row.custom_minimum_size.y=76
		row.modulate=Color("f2cf72") if p==0 else Color("f3eee0"); content.add_child(row)
	spacer()
	if round_finished: button("Продолжить",continue_after_round)
	else: button("Вернуться к столу",resume_from_scores)

func continue_after_round() -> void:
	round_index+=1; start_round()

func resume_from_scores() -> void:
	draw_game(); schedule_bot()
func trick_points() -> int:
	var points:=0
	if contract in ["tricks","all"]:points+=2
	if contract in ["hearts","all"]: for item in table: if suit_of(item.card)=="♥":points+=2
	if contract in ["boys","all"]: for item in table: if rank_of(item.card) in ["В","К"]:points+=2
	if contract in ["queens","all"]: for item in table: if rank_of(item.card)=="Д":points+=4
	if contract in ["king","all"]: for item in table: if item.card=="К♥":points+=16
	if contract in ["last","all"] and trick_index>=6:points+=8
	return points
func schedule_bot() -> void: if running and turn!=0:bot_turn(revision)
func bot_turn(stamp:int) -> void:
	await get_tree().create_timer(0.85).timeout; if stamp!=revision or turn==0:return
	var choices:Array[String]=[]; for c in hands[turn]: if legal(turn,c):choices.append(c)
	choices.sort_custom(func(a:String,b:String):return value(a)<value(b)); play(turn,choices[-1] if positive else choices[0])
func finish_game() -> void:
	running=false; revision+=1; var best:int=scores.max(); var winners:Array[int]=[]; for p in 4:if scores[p]==best:winners.append(p)
	screen(); heading("Партия завершена","Победитель: %s • %d очков"%[player_name(winners[0]) if winners.size()==1 else "ничья",best]); spacer(); for p in 4: var l:=Label.new();l.text="%s — %d"%[player_name(p),scores[p]];l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(l)
	spacer();button("Сыграть ещё",start_game);button("Главное меню",func():exit_to_menu.emit())
func contract_name(key:String) -> String:
	var plus:=key.left(1)=="+"; var base:=key.substr(1) if key.left(1) in ["+","-"] else key
	var names={"tricks":"взятки","hearts":"червы","boys":"мальчики","queens":"дамы","king":"Кинг ♥","last":"две последние","all":"всё сразу"}
	return ("Брать " if plus else "Не брать ")+names[base]
func player_names()->Array[String]:return ["Вы","Шурик","Черва","Козырь"]
func hand_counts()->Array[int]:
	var result:Array[int]=[]
	for hand in hands:result.append(hand.size())
	return result
func player_name(p:int)->String:return player_names()[p]
func rank_of(c:String)->String:return c.left(c.length()-1)
func suit_of(c:String)->String:return c.right(1)
func value(c:String)->int:return RANKS.find(rank_of(c))
func card_less(a:String,b:String)->bool:
	var suit_a:=SUITS.find(suit_of(a)); var suit_b:=SUITS.find(suit_of(b))
	if suit_a!=suit_b:return suit_a<suit_b
	return value(a)<value(b)
