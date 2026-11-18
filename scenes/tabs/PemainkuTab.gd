extends Control

signal open_cosmetics_shop
signal open_friends_modal
signal open_practice_match
signal open_city_requested(landmark: String, inside_apt: bool)
signal open_cutscene_requested(mode_idx: int)
signal open_volley_requested

var _subtab: String = "SKILL"
var _gaya_sub: String = "JERSEY"
var _look_sub: String = "POTONGAN"
var _pending_skills: Dictionary = {}
var _stage_host: VBoxContainer
var _body: VBoxContainer
var _tab_btns: Dictionary = {}

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	# 6 Sub-tabs (SKILL | KONTRAK | RELASI | GAYA | TOKO | KOTA)
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 4)
	outer.add_child(thb)
	for st in ["SKILL", "KONTRAK", "RELASI", "GAYA", "TOKO", "KOTA"]:
		var b := Button.new()
		b.text = st
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		b.pressed.connect(func():
			AudioSynth.play_click()
			_subtab = st
			_refresh_tab_styles()
			refresh()
		)
		thb.add_child(b)
		_tab_btns[st] = b

	# Landscape Split: Optional Left Locker Showcase + Right Scrollable Body
	var content_hb := HBoxContainer.new()
	content_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_theme_constant_override("separation", 10)
	outer.add_child(content_hb)

	_stage_host = VBoxContainer.new()
	_stage_host.custom_minimum_size = Vector2(280, 0)
	_stage_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_child(_stage_host)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_child(scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	CareerState.career_updated.connect(refresh)
	_refresh_tab_styles()
	refresh()

func _refresh_tab_styles() -> void:
	for k in _tab_btns.keys():
		var b: Button = _tab_btns[k]
		var act: bool = (str(k) == _subtab)
		UITheme.style_btn(b, Color("#173B66") if act else Color("#0B1626"), UITheme.BORDER_CYAN if act else UITheme.BORDER_STEEL, 11)
		if k == "SKILL" and CareerState.has_active_career:
			var sp := int(CareerState.career["playerProfile"]["skillPoints"])
			b.text = "%d POIN" % sp if sp > 0 else "SKILL"

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	_refresh_tab_styles()
	for c in _stage_host.get_children():
		c.queue_free()
	for c in _body.get_children():
		c.queue_free()

	var show_locker := (_subtab in ["SKILL", "KONTRAK", "GAYA"])
	_stage_host.visible = show_locker
	if show_locker:
		_render_locker_stage()

	match _subtab:
		"SKILL":
			_render_skill_body()
		"KONTRAK":
			_render_contract_body()
		"RELASI":
			_render_relations_body()
		"GAYA":
			_render_gaya_body()
		"TOKO":
			_render_toko_body()
		"KOTA":
			_render_kota_body()

func _render_locker_stage() -> void:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage_host.add_child(panel)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/backgrounds/locker_room.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel.add_child(bg)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", -4)
	panel.add_child(hb)

	var club := CareerState.get_current_club()
	var sq: Array = CareerState.career["clubSquad"]["starters"]
	var left_p: Dictionary = sq[min(7, sq.size() - 1)]
	var right_p: Dictionary = CareerState.career["clubSquad"]["bench"][min(6, CareerState.career["clubSquad"]["bench"].size() - 1)]

	for item in [[left_p, false], [null, true], [right_p, false]]:
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_child(vb)
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		var av := PixelAvatar.new()
		if item[1]:
			var p: Dictionary = CareerState.career["playerProfile"]
			lbl.text = "#%d %s" % [int(p["appearance"].get("shirt_num", 9)), p["name"]]
			lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
			av.custom_minimum_size = Vector2(90, 134)
			av.configure_from_career()
			av.anim_mode = "IDLE"
			av.anim_phase = 0.0
		else:
			var tm: Dictionary = item[0]
			lbl.text = "#%d %s" % [int(tm["number"]), tm["name"]]
			av.custom_minimum_size = Vector2(62, 96)
			av.configure_from_seed(int(tm["seed"]), club, int(tm["number"]))
			av.anim_mode = "IDLE"
			av.anim_phase = 1.4 if item[0] == left_p else 2.7
		vb.add_child(lbl)
		vb.add_child(av)

func _render_skill_body() -> void:
	var p: Dictionary = CareerState.career["playerProfile"]
	var total_sp: int = int(p["skillPoints"])
	var pend_cost: int = 0
	for k in _pending_skills.keys():
		pend_cost += int(_pending_skills[k])
	if pend_cost > total_sp:
		_pending_skills.clear()
		pend_cost = 0
	var rem_sp: int = total_sp - pend_cost

	_body.add_child(UITheme.make_section_header("SKILL  •  %d POIN" % rem_sp))

	if pend_cost > 0:
		var commit_hb := HBoxContainer.new()
		commit_hb.add_theme_constant_override("separation", 6)
		_body.add_child(commit_hb)
		var info_l := Label.new()
		info_l.text = "%d TERTUNDA" % pend_cost
		info_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		commit_hb.add_child(info_l)
		var undo_b := Button.new()
		undo_b.text = "URUNGKAN"
		UITheme.style_btn(undo_b, Color("#4A2028"), UITheme.ACCENT_RED, 11)
		undo_b.pressed.connect(func(): AudioSynth.play_click(); _pending_skills.clear(); refresh())
		commit_hb.add_child(undo_b)
		var save_b := Button.new()
		save_b.text = "SIMPAN ✓"
		UITheme.style_btn(save_b, Color("#174A30"), UITheme.ACCENT_GREEN, 11)
		save_b.pressed.connect(func():
			AudioSynth.play_achievement()
			var ok: bool = CareerState.apply_batch_upgrades(_pending_skills)
			if ok:
				_pending_skills.clear()
		)
		commit_hb.add_child(save_b)

	var attrs: Dictionary = p["attributes"]
	for ak in GameData.ATTRIBUTE_KEYS:
		if ak == "penalti":
			_body.add_child(UITheme.make_section_header("BOLA MATI"))
		var hb := HBoxContainer.new()
		_body.add_child(hb)
		var lbl := Label.new()
		lbl.text = GameData.ATTRIBUTE_LABELS[ak]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lbl)

		var p_add: int = int(_pending_skills.get(ak, 0))
		var val: int = CareerState.get_effective_attribute(ak) + p_add
		var vl := Label.new()
		vl.text = ("%d (+%d)" % [val, p_add]) if p_add > 0 else str(val)
		vl.custom_minimum_size = Vector2(68, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if p_add > 0 else UITheme.ACCENT_AMBER)
		hb.add_child(vl)

		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(38, 30)
		plus.disabled = (rem_sp < 1 or int(attrs[ak]) + p_add >= 99)
		UITheme.style_btn(plus, Color("#133056"), UITheme.BORDER_CYAN)
		plus.pressed.connect(func():
			AudioSynth.play_click()
			_pending_skills[ak] = int(_pending_skills.get(ak, 0)) + 1
			refresh()
		)
		hb.add_child(plus)

	# POSISIMU
	_body.add_child(UITheme.make_section_header("POSISIMU"))
	var nat_pos := str(p["naturalPosition"])
	var fav_pos := str(p["favoritePosition"])
	var learned: Dictionary = p["learnedPositions"]

	var nat_hb := HBoxContainer.new()
	_body.add_child(nat_hb)
	var nat_l := Label.new()
	nat_l.text = "%s ASLI • PERFORMA 100%%" % nat_pos
	nat_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nat_hb.add_child(nat_l)
	var fav_b := Button.new()
	fav_b.text = "★ FAVORIT" if fav_pos == nat_pos else "JADIKAN FAVORIT"
	UITheme.style_btn(fav_b, Color("#18457A") if fav_pos == nat_pos else Color("#0F1E34"), UITheme.BORDER_CYAN)
	fav_b.pressed.connect(func(): AudioSynth.play_click(); CareerState.set_favorite_position(nat_pos))
	nat_hb.add_child(fav_b)

	for pos_c in GameData.LEARNABLE_POSITIONS:
		if pos_c == nat_pos:
			continue
		var phb := HBoxContainer.new()
		_body.add_child(phb)
		var is_l := learned.has(pos_c)
		var pl := Label.new()
		pl.text = "%s  •  %s" % [pos_c, ("KEMAHIRAN %d%%" % int(learned[pos_c])) if is_l else "BISA DIPELAJARI (6 POIN)"]
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if is_l else UITheme.TEXT_MUTED)
		phb.add_child(pl)

		if is_l:
			var fb := Button.new()
			fb.text = "★ FAVORIT" if fav_pos == pos_c else "PILIH"
			fb.pressed.connect(func(): AudioSynth.play_click(); CareerState.set_favorite_position(pos_c))
			phb.add_child(fb)
		else:
			var lb := Button.new()
			lb.text = "+"
			lb.custom_minimum_size = Vector2(38, 30)
			lb.disabled = (total_sp < 6)
			lb.pressed.connect(func(): AudioSynth.play_click(); CareerState.learn_position(pos_c))
			phb.add_child(lb)

func _render_contract_body() -> void:
	var p: Dictionary = CareerState.career["playerProfile"]
	var con: Dictionary = CareerState.career["contract"]

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)
	for box in [
		["GAJI", UITheme.format_cash(int(con["salaryPerMatch"]))],
		["MUSIM TERSISA", str(con["yearsLeft"])],
		["GAYA HIDUP", "%d ITEM" % CareerState.career["inventory"]["lifestyleOwned"].size()],
		["BERSIH PER LAGA", UITheme.format_cash(int(con["salaryPerMatch"]))],
	]:
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(pc)
		var vb := VBoxContainer.new()
		pc.add_child(vb)
		var l1 := Label.new()
		l1.text = box[0]
		l1.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		l1.add_theme_font_size_override("font_size", 11)
		var l2 := Label.new()
		l2.text = box[1]
		l2.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		vb.add_child(l1)
		vb.add_child(l2)

	_body.add_child(UITheme.make_section_header("HARTA"))
	var cash := int(p["cash"])
	var h_lbl := Label.new()
	h_lbl.text = "UANG: %s   •   NILAI PASAR: %s" % [UITheme.format_cash(cash), UITheme.format_cash(int(p["marketValue"]))]
	h_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_body.add_child(h_lbl)

	_body.add_child(UITheme.make_section_header("TUNTUTAN KLUB"))
	var pos := CareerState.get_user_league_position()
	var req_l := Label.new()
	req_l.text = "• Finis ke-14 atau lebih baik: %s (Kini #%d)\n• Lolos satu babak Piala: %s\n• Menyeimbangkan keuangan: KAS SEHAT" % [
		"TERCAPAI" if pos <= 14 else "BELUM", pos,
		"TERCAPAI" if int(CareerState.career["stats"]["wins"]) >= 2 else "0/1 BABAK"
	]
	_body.add_child(req_l)

	_body.add_child(UITheme.make_section_header("TARGET MUSIM"))
	var tg := int(con["goalTarget"])
	var gs := int(con["goalsScoredThisSeason"])
	var t_lbl := Label.new()
	t_lbl.text = "Kamu dinilai sebagai %s\nCetak %d gol (sudah %d)  •  Bonus +%s" % [
		CareerState.get_player_role_status(), tg, gs, UITheme.format_cash(int(con["targetBonus"]))
	]
	_body.add_child(t_lbl)

	var agree_b := Button.new()
	agree_b.text = "✓ TARGET DISEPAKATI" if con.get("targetAgreed", false) else "SEPAKATI TARGET"
	agree_b.disabled = bool(con.get("targetAgreed", false))
	UITheme.style_btn(agree_b, Color("#184560"), UITheme.BORDER_CYAN)
	agree_b.pressed.connect(func():
		AudioSynth.play_click()
		con["targetAgreed"] = true
		CareerState.save_active_career()
		refresh()
	)
	_body.add_child(agree_b)

	_body.add_child(UITheme.make_section_header("KLAUSUL PRIBADI"))
	var cl_btn := Button.new()
	cl_btn.text = "KLAUSUL: %s (PILIH / GANTI)" % str(con.get("clause", "NONE"))
	cl_btn.pressed.connect(func():
		AudioSynth.play_click()
		var clauses := ["NONE", "BEBAS TRANSFER", "BONUS CLEAN SHEET", "RILIS KLUB BESAR"]
		con["clause"] = clauses[(clauses.find(str(con.get("clause", "NONE"))) + 1) % clauses.size()]
		CareerState.save_active_career()
		refresh()
	)
	_body.add_child(cl_btn)

func _render_relations_body() -> void:
	# 5 Relation Characters Strip (matching Screenshot #8)
	var rel: Dictionary = CareerState.career["playerProfile"]["relations"]
	var strips := HBoxContainer.new()
	strips.add_theme_constant_override("separation", 4)
	strips.custom_minimum_size = Vector2(0, 170)
	_body.add_child(strips)

	var specs := [
		["PELATIH", "pelatih", 2],
		["RUANG GANTI", "ruangGanti", 5],
		["FANS", "fans", 1],
		["PERS", "pers", 0],
		["AGEN", "agen", 4],
	]
	for sp in specs:
		var val := int(rel[sp[1]])
		var tier := CareerState.get_relation_tier(val)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		strips.add_child(card)
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_END
		card.add_child(vb)

		var npc := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
		at.region = Rect2(int(sp[2]) * 24, 0, 24, 36)
		npc.texture = at
		npc.custom_minimum_size = Vector2(48, 72)
		npc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(npc)

		var l1 := Label.new()
		l1.text = sp[0]
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l1.add_theme_font_size_override("font_size", 10)
		var l2 := Label.new()
		l2.text = "%d\n%s" % [val, tier]
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if val >= 60 else (UITheme.ACCENT_RED if val < 40 else UITheme.TEXT_WHITE))
		l2.add_theme_font_size_override("font_size", 11)
		vb.add_child(l1)
		vb.add_child(l2)

	_body.add_child(UITheme.make_section_header("RELASI DETAIL"))
	var coach_name: String = GameData.coaches[int(CareerState.get_current_club()["coach_id"])]["name"]
	var details := [
		[coach_name, int(rel["pelatih"]), CareerState.get_player_role_status()],
		["Ruang ganti", int(rel["ruangGanti"]), "+%d umpan rekan" % int(int(rel["ruangGanti"]) / 10)],
		["Suporter", int(rel["fans"]), UITheme.format_cash(int(CareerState.career["playerProfile"]["marketValue"]))],
		["Pers", int(rel["pers"]), CareerState.get_relation_tier(int(rel["pers"]))],
		["Agen", int(rel["agen"]), "+%d%% GAJI" % maxi(5, int(int(rel["agen"]) / 6))],
	]
	for d in details:
		var hb := HBoxContainer.new()
		_body.add_child(hb)
		var l1 := Label.new()
		l1.text = "%s (%s)" % [d[0], d[2]]
		l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l2 := Label.new()
		l2.text = str(d[1])
		l2.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		hb.add_child(l1)
		hb.add_child(l2)

	# MEREKMU / Sponsor & Rituals
	_body.add_child(UITheme.make_section_header("MEREKMU • SPONSOR & EVENT SKUAD"))
	var ev_hb := HBoxContainer.new()
	ev_hb.add_theme_constant_override("separation", 6)
	_body.add_child(ev_hb)
	var sp_shoot := Button.new()
	sp_shoot.text = "IKLAN CLAPPER & SELFIE"
	sp_shoot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_btn(sp_shoot, Color("#4E2C66"), UITheme.ACCENT_GOLD, 11)
	sp_shoot.pressed.connect(func(): AudioSynth.play_click(); open_cutscene_requested.emit(4))
	ev_hb.add_child(sp_shoot)
	var ini_b := Button.new()
	ini_b.text = "MAKAN & NYANYI SKUAD"
	ini_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_btn(ini_b, Color("#173B66"), UITheme.ACCENT_CYAN, 11)
	ini_b.pressed.connect(func(): AudioSynth.play_click(); open_cutscene_requested.emit(3))
	ev_hb.add_child(ini_b)

	var active_sp := str(CareerState.career["sponsor"].get("activeId", ""))
	for sp_item in GameData.sponsors_catalog:
		var is_cur: bool = (str(sp_item["id"]) == active_sp)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A2E20") if is_cur else UITheme.BG_CARD, UITheme.ACCENT_GOLD if is_cur else UITheme.BORDER_STEEL))
		_body.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var t1 := Label.new()
		t1.text = sp_item["name"]
		t1.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		var t2 := Label.new()
		t2.text = "$%d/laga + $%d/gol • Target %d gol -> Bonus $%d" % [int(sp_item["per_match"]), int(sp_item["per_goal"]), int(sp_item["target_goals"]), int(sp_item["season_bonus"])]
		t2.add_theme_font_size_override("font_size", 11)
		vb.add_child(t1)
		vb.add_child(t2)

		var btn := Button.new()
		btn.text = "PUTUS" if is_cur else "TEKEN"
		UITheme.style_btn(btn, UITheme.ACCENT_RED if is_cur else Color("#1D5CA8"), UITheme.BORDER_CYAN)
		btn.pressed.connect(func():
			AudioSynth.play_click()
			if is_cur:
				CareerState.career["sponsor"]["activeId"] = ""
			else:
				CareerState.career["sponsor"]["activeId"] = sp_item["id"]
				CareerState.career["sponsor"]["goalsProgress"] = 0
				CareerState.career["stats"]["sponsorsSigned"] = int(CareerState.career["stats"].get("sponsorsSigned", 0)) + 1
			CareerState.evaluate_achievements()
			CareerState.save_active_career()
			refresh()
		)
		hb.add_child(btn)

func _make_club_base_app() -> Dictionary:
	var p: Dictionary = CareerState.career["playerProfile"]
	var app: Dictionary = p["appearance"].duplicate()
	var club := CareerState.get_current_club()
	app["primary_color"] = club.get("primary", Color("#1A90E0"))
	app["secondary_color"] = club.get("secondary", Color("#FFFFFF"))
	app["kit_pattern"] = str(club.get("pattern", "stripes"))
	var pc: Color = app["primary_color"]
	app["shorts_color"] = app["secondary_color"] if pc.get_luminance() < 0.7 else Color("#1A2232")
	return app

func _commit_gaya_edit() -> void:
	CareerState.career["stats"]["styleEdits"] = int(CareerState.career["stats"].get("styleEdits", 0)) + 1
	CareerState.evaluate_achievements()
	CareerState.save_active_career()
	refresh()

func _render_gaya_body() -> void:
	var p: Dictionary = CareerState.career["playerProfile"]
	var app: Dictionary = p["appearance"]
	var base_app := _make_club_base_app()

	var sub_hb := HBoxContainer.new()
	sub_hb.add_theme_constant_override("separation", 6)
	_body.add_child(sub_hb)
	for g in ["LOOK", "JERSEY", "KASUAL", "GALA"]:
		var g_id: String = g
		var gb := Button.new()
		gb.text = g_id
		gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(gb, Color("#173B66") if _gaya_sub == g_id else Color("#0B1626"), UITheme.BORDER_CYAN if _gaya_sub == g_id else UITheme.BORDER_STEEL, 12)
		gb.pressed.connect(func():
			AudioSynth.play_click()
			_gaya_sub = g_id
			if g_id == "KASUAL":
				app["casual_style"] = 1
			elif g_id == "GALA":
				app["casual_style"] = 2
			else:
				app["casual_style"] = 0
			CareerState.save_active_career()
			refresh()
		)
		sub_hb.add_child(gb)

	if _gaya_sub == "LOOK":
		var l_scroll := ScrollContainer.new()
		l_scroll.custom_minimum_size = Vector2(0, 38)
		l_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_body.add_child(l_scroll)
		var l_hb := HBoxContainer.new()
		l_hb.add_theme_constant_override("separation", 4)
		l_scroll.add_child(l_hb)
		for ls in ["POTONGAN", "WARNA", "WAJAH", "JENGGOT", "TATO"]:
			var ls_id: String = ls
			var lb := Button.new()
			lb.text = ls_id
			lb.custom_minimum_size = Vector2(78, 32)
			UITheme.style_btn(lb, Color("#1E4676") if _look_sub == ls_id else Color("#091322"), UITheme.ACCENT_GOLD if _look_sub == ls_id else UITheme.BORDER_STEEL, 10)
			lb.pressed.connect(func(): AudioSynth.play_click(); _look_sub = ls_id; refresh())
			l_hb.add_child(lb)

		if _look_sub == "POTONGAN":
			_body.add_child(UITheme.make_section_header("GAYA RAMBUT (%d DESAIN)" % CharacterStyleCatalog.HAIR_STYLES.size()))
			var grid := GridContainer.new()
			grid.columns = 5
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(grid)
			var cur_h := int(app.get("hair_style", 2))
			for i in range(CharacterStyleCatalog.HAIR_STYLES.size()):
				var idx: int = i
				grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.HAIR_STYLES[idx],
					base_app,
					{"hair_style": idx, "headwear": 0, "casual_style": 0},
					false,
					cur_h == idx,
					func():
						app["hair_style"] = idx
						app["headwear"] = 0
						_commit_gaya_edit(),
					88.0
				))

		elif _look_sub == "WARNA":
			_body.add_child(UITheme.make_section_header("WARNA RAMBUT"))
			var hc_grid := GridContainer.new()
			hc_grid.columns = 5
			hc_grid.add_theme_constant_override("h_separation", 6)
			hc_grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(hc_grid)
			var cur_hc := int(app.get("hair_color", 1))
			for i in range(CharacterStyleCatalog.HAIR_COLORS.size()):
				var idx: int = i
				var hc: Dictionary = CharacterStyleCatalog.HAIR_COLORS[idx]
				hc_grid.add_child(CharacterStyleCatalog.build_color_swatch_tile(
					str(hc["name"]),
					hc["col"],
					cur_hc == idx,
					func(): app["hair_color"] = idx; _commit_gaya_edit(),
					42.0,
					34.0
				))

			_body.add_child(UITheme.make_section_header("UJUNG RAMBUT"))
			var tip_grid := GridContainer.new()
			tip_grid.columns = 4
			tip_grid.add_theme_constant_override("h_separation", 6)
			_body.add_child(tip_grid)
			var cur_tip := int(app.get("tip_color", 0))
			for i in range(CharacterStyleCatalog.TIP_COLORS.size()):
				var idx: int = i
				var tc: Dictionary = CharacterStyleCatalog.TIP_COLORS[idx]
				tip_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					str(tc["name"]),
					base_app,
					{"tip_color": idx, "headwear": 0},
					false,
					cur_tip == idx,
					func(): app["tip_color"] = idx; _commit_gaya_edit(),
					84.0
				))

			_body.add_child(UITheme.make_section_header("WARNA KULIT"))
			var sk_grid := GridContainer.new()
			sk_grid.columns = 6
			sk_grid.add_theme_constant_override("h_separation", 6)
			_body.add_child(sk_grid)
			var cur_sk := int(app.get("skin", 1))
			for i in range(CharacterStyleCatalog.SKIN_TONES.size()):
				var idx: int = i
				var sk: Dictionary = CharacterStyleCatalog.SKIN_TONES[idx]
				sk_grid.add_child(CharacterStyleCatalog.build_color_swatch_tile(
					str(sk["name"]),
					sk["col"],
					cur_sk == idx,
					func(): app["skin"] = idx; _commit_gaya_edit(),
					38.0,
					36.0
				))

		elif _look_sub == "WAJAH":
			_body.add_child(UITheme.make_section_header("WARNA KULIT"))
			var sk_grid := GridContainer.new()
			sk_grid.columns = 3
			sk_grid.add_theme_constant_override("h_separation", 6)
			sk_grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(sk_grid)
			var cur_sk := int(app.get("skin", 1))
			for i in range(CharacterStyleCatalog.SKIN_TONES.size()):
				var idx: int = i
				var sk: Dictionary = CharacterStyleCatalog.SKIN_TONES[idx]
				sk_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					str(sk["name"]),
					base_app,
					{"skin": idx},
					false,
					cur_sk == idx,
					func(): app["skin"] = idx; _commit_gaya_edit(),
					82.0
				))

			_body.add_child(UITheme.make_section_header("TOPI / BANDANA"))
			var hw_grid := GridContainer.new()
			hw_grid.columns = 5
			hw_grid.add_theme_constant_override("h_separation", 6)
			hw_grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(hw_grid)
			var cur_hw := int(app.get("headwear", 0))
			for i in range(CharacterStyleCatalog.HEADWEAR_STYLES.size()):
				var idx: int = i
				hw_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.HEADWEAR_STYLES[idx],
					base_app,
					{"headwear": idx},
					false,
					cur_hw == idx,
					func(): app["headwear"] = idx; _commit_gaya_edit(),
					84.0
				))

			_body.add_child(UITheme.make_section_header("KACAMATA"))
			var ew_grid := GridContainer.new()
			ew_grid.columns = 4
			ew_grid.add_theme_constant_override("h_separation", 6)
			_body.add_child(ew_grid)
			var cur_ew := int(app.get("eyewear", 0))
			for i in range(CharacterStyleCatalog.EYEWEAR_STYLES.size()):
				var idx: int = i
				ew_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.EYEWEAR_STYLES[idx],
					base_app,
					{"eyewear": idx},
					false,
					cur_ew == idx,
					func(): app["eyewear"] = idx; _commit_gaya_edit(),
					82.0
				))

		elif _look_sub == "JENGGOT":
			_body.add_child(UITheme.make_section_header("JENGGOT & KUMIS (%d DESAIN)" % CharacterStyleCatalog.BEARD_STYLES.size()))
			var b_grid := GridContainer.new()
			b_grid.columns = 5
			b_grid.add_theme_constant_override("h_separation", 6)
			b_grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(b_grid)
			var cur_bd := int(app.get("beard_style", 1 if bool(app.get("beard", false)) else 0))
			for i in range(CharacterStyleCatalog.BEARD_STYLES.size()):
				var idx: int = i
				b_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.BEARD_STYLES[idx],
					base_app,
					{"beard_style": idx, "beard": idx > 0},
					false,
					cur_bd == idx,
					func():
						app["beard_style"] = idx
						app["beard"] = (idx > 0)
						_commit_gaya_edit(),
					88.0
				))

		elif _look_sub == "TATO":
			_body.add_child(UITheme.make_section_header("TATO WAJAH"))
			var tf_grid := GridContainer.new()
			tf_grid.columns = 3
			tf_grid.add_theme_constant_override("h_separation", 6)
			tf_grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(tf_grid)
			var cur_tf := int(app.get("tattoo_face", 0))
			for i in range(CharacterStyleCatalog.FACE_TATTOOS.size()):
				var idx: int = i
				tf_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.FACE_TATTOOS[idx],
					base_app,
					{"tattoo_face": idx},
					false,
					cur_tf == idx,
					func(): app["tattoo_face"] = idx; _commit_gaya_edit(),
					82.0
				))

			_body.add_child(UITheme.make_section_header("TATO LENGAN"))
			var ta_grid := GridContainer.new()
			ta_grid.columns = 3
			ta_grid.add_theme_constant_override("h_separation", 6)
			ta_grid.add_theme_constant_override("v_separation", 6)
			_body.add_child(ta_grid)
			var cur_ta := int(app.get("tattoo_arm", 0))
			for i in range(CharacterStyleCatalog.ARM_TATTOOS.size()):
				var idx: int = i
				ta_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.ARM_TATTOOS[idx],
					base_app,
					{"tattoo_arm": idx, "sleeve": "PENDEK", "casual_style": 0},
					true,
					cur_ta == idx,
					func():
						app["tattoo_arm"] = idx
						app["sleeve"] = "PENDEK"
						_commit_gaya_edit(),
					90.0
				))

			_body.add_child(UITheme.make_section_header("TATO KAKI"))
			var tl_grid := GridContainer.new()
			tl_grid.columns = 3
			tl_grid.add_theme_constant_override("h_separation", 6)
			_body.add_child(tl_grid)
			var cur_tl := int(app.get("tattoo_leg", 0))
			for i in range(CharacterStyleCatalog.LEG_TATTOOS.size()):
				var idx: int = i
				tl_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
					CharacterStyleCatalog.LEG_TATTOOS[idx],
					base_app,
					{"tattoo_leg": idx, "casual_style": 0},
					true,
					cur_tl == idx,
					func(): app["tattoo_leg"] = idx; _commit_gaya_edit(),
					90.0
				))

	elif _gaya_sub == "KASUAL":
		_body.add_child(UITheme.make_section_header("GAYA KASUAL (%d OUTFIT)" % CharacterStyleCatalog.CASUAL_STYLES.size()))
		var cas_grid := GridContainer.new()
		cas_grid.columns = 5
		cas_grid.add_theme_constant_override("h_separation", 6)
		cas_grid.add_theme_constant_override("v_separation", 6)
		_body.add_child(cas_grid)
		var cur_ov := int(app.get("outfit_variant", 0))
		for i in range(CharacterStyleCatalog.CASUAL_STYLES.size()):
			var idx: int = i
			var cs: Dictionary = CharacterStyleCatalog.CASUAL_STYLES[idx]
			cas_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				str(cs["name"]),
				base_app,
				{"casual_style": 1, "outfit_variant": idx},
				true,
				int(app.get("casual_style", 0)) == 1 and cur_ov == idx,
				func():
					app["casual_style"] = 1
					app["outfit_variant"] = idx
					_commit_gaya_edit(),
				96.0
			))

	elif _gaya_sub == "GALA":
		_body.add_child(UITheme.make_section_header("SETELAN GALA & AWARD (%d JAS)" % CharacterStyleCatalog.GALA_STYLES.size()))
		var gala_grid := GridContainer.new()
		gala_grid.columns = 5
		gala_grid.add_theme_constant_override("h_separation", 6)
		gala_grid.add_theme_constant_override("v_separation", 6)
		_body.add_child(gala_grid)
		var cur_ov := int(app.get("outfit_variant", 0))
		for i in range(CharacterStyleCatalog.GALA_STYLES.size()):
			var idx: int = i
			var gs: Dictionary = CharacterStyleCatalog.GALA_STYLES[idx]
			gala_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				str(gs["name"]),
				base_app,
				{"casual_style": 2, "outfit_variant": idx},
				true,
				int(app.get("casual_style", 0)) == 2 and cur_ov == idx,
				func():
					app["casual_style"] = 2
					app["outfit_variant"] = idx
					_commit_gaya_edit(),
				96.0
			))

	else:
		# JERSEY: Back name, number, visual sleeve length cards, wristband/glove color swatches & owned boots!
		var nhb := HBoxContainer.new()
		nhb.add_theme_constant_override("separation", 6)
		_body.add_child(nhb)
		var ne := LineEdit.new()
		ne.text = str(app.get("back_name", p["name"]))
		ne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nhb.add_child(ne)
		var nb := Button.new()
		nb.text = "GANTI"
		UITheme.style_btn(nb, UITheme.ACCENT_PURPLE, Color("#9F85E0"))
		nb.pressed.connect(func():
			AudioSynth.play_click()
			var clean := ne.text.strip_edges().to_upper()
			if not clean.is_empty():
				app["back_name"] = clean
				p["name"] = clean
				_commit_gaya_edit()
		)
		nhb.add_child(nb)

		var num_hb := HBoxContainer.new()
		num_hb.add_theme_constant_override("separation", 6)
		_body.add_child(num_hb)
		var num_l := Label.new()
		num_l.text = "NOMOR PUNGGUNG: #%d" % int(app.get("shirt_num", 9))
		num_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		num_hb.add_child(num_l)
		var b_m := Button.new()
		b_m.text = "-"
		b_m.custom_minimum_size = Vector2(36, 32)
		b_m.pressed.connect(func():
			AudioSynth.play_click()
			app["shirt_num"] = maxi(1, int(app.get("shirt_num", 9)) - 1)
			_commit_gaya_edit()
		)
		var b_p := Button.new()
		b_p.text = "+"
		b_p.custom_minimum_size = Vector2(36, 32)
		b_p.pressed.connect(func():
			AudioSynth.play_click()
			app["shirt_num"] = mini(99, int(app.get("shirt_num", 9)) + 1)
			_commit_gaya_edit()
		)
		num_hb.add_child(b_m)
		num_hb.add_child(b_p)

		_body.add_child(UITheme.make_section_header("LENGAN JERSEY"))
		var sl_grid := GridContainer.new()
		sl_grid.columns = 2
		sl_grid.add_theme_constant_override("h_separation", 8)
		_body.add_child(sl_grid)
		for sl_t in ["PENDEK", "PANJANG"]:
			var s_opt: String = sl_t
			sl_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				"LENGAN " + s_opt,
				base_app,
				{"sleeve": s_opt, "casual_style": 0},
				true,
				str(app.get("sleeve", "PENDEK")) == s_opt,
				func(): app["sleeve"] = s_opt; app["casual_style"] = 0; _commit_gaya_edit(),
				96.0
			))

		_body.add_child(UITheme.make_section_header("GELANG TANGAN"))
		var wr_hb := HBoxContainer.new()
		wr_hb.add_theme_constant_override("separation", 4)
		_body.add_child(wr_hb)
		for wr_t in ["TAK ADA", "LENGAN KIRI", "LENGAN KANAN", "KEDUANYA"]:
			var w_opt: String = wr_t
			var wb := Button.new()
			wb.text = w_opt
			wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UITheme.style_btn(wb, Color("#173B66") if app.get("wrist_side", "TAK ADA") == w_opt else Color("#0B1626"), UITheme.BORDER_CYAN if app.get("wrist_side", "TAK ADA") == w_opt else UITheme.BORDER_STEEL, 9)
			wb.pressed.connect(func(): AudioSynth.play_click(); app["wrist_side"] = w_opt; _commit_gaya_edit())
			wr_hb.add_child(wb)

		_body.add_child(UITheme.make_section_header("WARNA GELANG & SARUNG TANGAN"))
		var wc_hb := HBoxContainer.new()
		wc_hb.add_theme_constant_override("separation", 4)
		_body.add_child(wc_hb)
		var wc_cols := [Color("#94A3B8"), Color("#1E3A8A"), Color("#DC2626"), Color("#EAB308"), Color("#16A34A"), Color("#9333EA"), Color("#EA580C")]
		var cur_wc := int(app.get("wrist_color", 0))
		for wi in range(wc_cols.size()):
			var widx: int = wi
			wc_hb.add_child(CharacterStyleCatalog.build_color_swatch_tile(
				"Gelang %d" % (widx + 1),
				wc_cols[widx],
				cur_wc == widx,
				func(): app["wrist_color"] = widx; _commit_gaya_edit(),
				32.0,
				30.0
			))

		var gc_hb := HBoxContainer.new()
		gc_hb.add_theme_constant_override("separation", 4)
		_body.add_child(gc_hb)
		var gl_cols := [Color.TRANSPARENT, Color("#181C24"), Color("#F2F4F8"), Color("#C82832"), Color("#1E54B8"), Color("#F5C542"), Color("#EE7624")]
		var cur_gc := int(app.get("glove_color", -1))
		for gi in range(gl_cols.size()):
			var gval: int = gi - 1
			gc_hb.add_child(CharacterStyleCatalog.build_color_swatch_tile(
				"Tanpa Sarung" if gval < 0 else "Sarung %d" % gi,
				gl_cols[gi],
				cur_gc == gval,
				func(): app["glove_color"] = gval; _commit_gaya_edit(),
				32.0,
				30.0
			))

		_body.add_child(UITheme.make_section_header("BOOT DIMILIKI"))
		var owned_b: Array = CareerState.career["inventory"].get("bootsOwned", [0])
		var cur_b := int(app.get("boot_id", 0))
		var boot_sheet: Texture2D = load("res://assets/sprites/ui/boots_strip.png")
		var ob_grid := GridContainer.new()
		ob_grid.columns = 3
		ob_grid.add_theme_constant_override("h_separation", 6)
		ob_grid.add_theme_constant_override("v_separation", 6)
		_body.add_child(ob_grid)
		for bid_v in owned_b:
			var bid: int = int(bid_v)
			if bid < 0 or bid >= GameData.boots_catalog.size():
				continue
			var bt: Dictionary = GameData.boots_catalog[bid]
			var is_eq_b: bool = (cur_b == bid)
			var bb := Button.new()
			bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bb.custom_minimum_size = Vector2(0, 68)
			UITheme.style_btn(bb, Color("#15365E") if is_eq_b else Color("#0A1320"), UITheme.ACCENT_GOLD if is_eq_b else UITheme.BORDER_STEEL, 10)
			bb.pressed.connect(func(): AudioSynth.play_click(); app["boot_id"] = bid; _commit_gaya_edit())
			var bvb := VBoxContainer.new()
			bvb.set_anchors_preset(Control.PRESET_FULL_RECT)
			bvb.alignment = BoxContainer.ALIGNMENT_CENTER
			bvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bb.add_child(bvb)
			var btex := TextureRect.new()
			var bat := AtlasTexture.new()
			bat.atlas = boot_sheet
			bat.region = Rect2(bid * 32, 0, 32, 32)
			btex.texture = bat
			btex.custom_minimum_size = Vector2(32, 32)
			btex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			btex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			btex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bvb.add_child(btex)
			var bl := Label.new()
			bl.text = str(bt["name"])
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bl.clip_text = true
			bl.add_theme_font_size_override("font_size", 9)
			bl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_eq_b else Color("#CBD5E1"))
			bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bvb.add_child(bl)
			ob_grid.add_child(bb)

func _render_toko_body() -> void:
	# Daily Promo Card (ECLIPSE X -30% matching Screenshot #10!)
	var promo := PanelContainer.new()
	promo.add_theme_stylebox_override("panel", UITheme.make_box(Color("#4E320E"), UITheme.ACCENT_GOLD, 2, 4))
	_body.add_child(promo)
	var pvb := VBoxContainer.new()
	promo.add_child(pvb)
	var p_hdr := Label.new()
	p_hdr.text = "PROMO HARI INI  •  BOOT  (-30%)"
	p_hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	pvb.add_child(p_hdr)

	var phb := HBoxContainer.new()
	phb.add_theme_constant_override("separation", 12)
	pvb.add_child(phb)
	var boot_tex := TextureRect.new()
	var bat := AtlasTexture.new()
	bat.atlas = load("res://assets/sprites/ui/boots_strip.png")
	bat.region = Rect2(8 * 32, 0, 32, 32)
	boot_tex.texture = bat
	boot_tex.custom_minimum_size = Vector2(72, 72)
	boot_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	phb.add_child(boot_tex)

	var b_info := VBoxContainer.new()
	b_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phb.add_child(b_info)
	var bn := Label.new()
	bn.text = "ECLIPSE X\n$ 420.000  (Dulu $600.000)"
	bn.add_theme_font_override("font", UITheme.get_display_font())
	bn.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	b_info.add_child(bn)

	var buy_p := Button.new()
	buy_p.text = "BELI SEKARANG" if int(CareerState.career["playerProfile"]["cash"]) >= 420000 else "DAPAT UANG (MAIN LAGA)"
	buy_p.pressed.connect(func(): AudioSynth.play_click(); CareerState.buy_boot(8))
	pvb.add_child(buy_p)

	# Quick Energy Drink + Cosmetics & Perks Launcher
	var q_hb := HBoxContainer.new()
	q_hb.add_theme_constant_override("separation", 8)
	_body.add_child(q_hb)

	var drink_b := Button.new()
	drink_b.text = "⚡ MINUMAN PEKAN\n+35 ENERGI ($1.200)"
	drink_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drink_b.custom_minimum_size = Vector2(0, 62)
	UITheme.style_btn(drink_b, Color("#404E18"), UITheme.ACCENT_GREEN, 12)
	drink_b.pressed.connect(func(): AudioSynth.play_click(); CareerState.buy_energy_drink())
	q_hb.add_child(drink_b)

	var cos_b := Button.new()
	cos_b.text = "★ GAYA / PERK\nCINCIN • AIM • XP×2"
	cos_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cos_b.custom_minimum_size = Vector2(0, 62)
	UITheme.style_btn(cos_b, Color("#4A2C60"), Color("#C084FC"), 12)
	cos_b.pressed.connect(func(): AudioSynth.play_click(); open_cosmetics_shop.emit())
	q_hb.add_child(cos_b)

	# 11 Boots Grid
	_body.add_child(UITheme.make_section_header("BOOT (11 MODEL)"))
	var owned_b: Array = CareerState.career["inventory"]["bootsOwned"]
	var eq_b := int(CareerState.career["playerProfile"]["appearance"].get("boot_id", 0))
	for b_item in GameData.boots_catalog:
		var bid := int(b_item["id"])
		var row := PanelContainer.new()
		_body.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		row.add_child(hb)

		var bt := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/sprites/ui/boots_strip.png")
		at.region = Rect2(bid * 32, 0, 32, 32)
		bt.texture = at
		bt.custom_minimum_size = Vector2(36, 36)
		bt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(bt)

		var lbl := Label.new()
		lbl.text = "%s (+%d %s)" % [b_item["name"], int(b_item["bonus_val"]), GameData.ATTRIBUTE_LABELS[b_item["bonus_attr"]]]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lbl)

		var btn := Button.new()
		btn.text = "DIPAKAI" if eq_b == bid else ("PAKAI" if owned_b.has(bid) else UITheme.format_cash(int(b_item["price"])))
		btn.pressed.connect(func(): AudioSynth.play_click(); CareerState.buy_boot(bid))
		hb.add_child(btn)

	# 6 Staff Slots
	_body.add_child(UITheme.make_section_header("STAF (%d/6)" % CareerState.career["inventory"]["staffHired"].size()))
	var hired: Array = CareerState.career["inventory"]["staffHired"]
	for st in GameData.staff_catalog:
		var is_h := hired.has(st["id"])
		var card := PanelContainer.new()
		_body.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var l1 := Label.new()
		l1.text = st["name"]
		var l2 := Label.new()
		l2.text = st["desc"]
		l2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		l2.add_theme_font_size_override("font_size", 11)
		vb.add_child(l1)
		vb.add_child(l2)
		var hb_btn := Button.new()
		hb_btn.text = "DIREKRUT ✓" if is_h else UITheme.format_cash(int(st["price"]))
		hb_btn.disabled = is_h
		hb_btn.pressed.connect(func(): AudioSynth.play_click(); CareerState.hire_staff(st["id"]))
		hb.add_child(hb_btn)

	# Properties / Cars / Luxury
	_body.add_child(UITheme.make_section_header("KANDANG, MEBEL, MOBIL & MEWAH"))
	var owned_life: Array = CareerState.career["inventory"]["lifestyleOwned"]
	for item in GameData.lifestyle_catalog:
		var has_it := owned_life.has(item["id"])
		var card := PanelContainer.new()
		_body.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var l1 := Label.new()
		l1.text = "[%s] %s" % [item["cat"], item["name"]]
		var l2 := Label.new()
		l2.text = item["desc"]
		l2.add_theme_font_size_override("font_size", 11)
		l2.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		vb.add_child(l1)
		vb.add_child(l2)
		var b := Button.new()
		b.text = "MILIK ✓" if has_it else UITheme.format_cash(int(item["price"]))
		b.disabled = has_it
		b.pressed.connect(func(): AudioSynth.play_click(); CareerState.buy_lifestyle(item["id"]))
		hb.add_child(b)

func _render_kota_body() -> void:
	# Interactive City Map (matching PETA KOTA & Video 3)
	var map_panel := PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(0, 360)
	_body.add_child(map_panel)

	var map_tex := TextureRect.new()
	map_tex.texture = load("res://assets/sprites/backgrounds/city_map.png")
	map_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_panel.add_child(map_tex)

	var overlay := Control.new()
	map_panel.add_child(overlay)

	var pins := [
		["▸ STADION (3D)", Vector2(205, 56), Color("#38BDF8"), func(): open_city_requested.emit("STADION", false)],
		["● LATIHAN VOLI", Vector2(46, 68), Color("#3AD656"), func(): open_volley_requested.emit()],
		["★ SNEAKERS (3D)", Vector2(205, 200), Color("#EC4899"), func(): open_city_requested.emit("SNEAKERS", false)],
		["★ TEMAN", Vector2(315, 130), Color("#E86E9E"), func(): open_friends_modal.emit()],
		["○ APARTEMEN (3D)", Vector2(185, 290), Color("#F2C438"), func(): open_city_requested.emit("APARTEMEN", true)],
	]
	for pin in pins:
		var pb := Button.new()
		pb.text = pin[0]
		pb.position = pin[1]
		UITheme.style_btn(pb, Color("#0C1A30"), pin[2], 10)
		pb.pressed.connect(func(): AudioSynth.play_click(); pin[3].call())
		overlay.add_child(pb)

	var act_hb := HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 8)
	_body.add_child(act_hb)

	var ke_kota := Button.new()
	ke_kota.text = "▸ JALAN KE KOTA (3D)"
	ke_kota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ke_kota.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(ke_kota, Color("#174C6B"), UITheme.ACCENT_CYAN, 13)
	ke_kota.pressed.connect(func(): AudioSynth.play_click(); open_city_requested.emit("SNEAKERS", false))
	act_hb.add_child(ke_kota)

	var lat_v := Button.new()
	lat_v.text = "● LATIHAN VOLI"
	lat_v.custom_minimum_size = Vector2(150, 44)
	UITheme.style_btn(lat_v, Color("#4E2C66"), UITheme.ACCENT_GOLD, 12)
	lat_v.pressed.connect(func(): AudioSynth.play_click(); open_volley_requested.emit())
	act_hb.add_child(lat_v)
