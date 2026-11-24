extends Control

signal open_cosmetics_shop
signal open_friends_modal
signal open_practice_match
signal open_city_requested(landmark: String, inside_apt: bool)
signal open_cutscene_requested(mode_idx: int)
signal open_volley_requested

const MarketSponsorOverlaysScript := preload("res://scripts/ui/MarketSponsorOverlays.gd")

var _subtab: String = "SKILL"
var _gaya_sub: String = "JERSEY"
var _look_sub: String = "POTONGAN"
var _pending_skills: Dictionary = {}
var _tab_bar: HBoxContainer
var _content_hb: HBoxContainer
var _sponsor_root: HBoxContainer
var _stage_host: VBoxContainer
var _body: VBoxContainer
var _tab_btns: Dictionary = {}

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	# 6 Sub-tabs (SKILL | KONTRAK | SPONSOR | RELASI | GAYA | KOTA — TOKO removed because it has its own top nav!)
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	outer.add_child(_tab_bar)
	for st in ["SKILL", "KONTRAK", "SPONSOR", "RELASI", "GAYA", "KOTA"]:
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
		_tab_bar.add_child(b)
		_tab_btns[st] = b

	# Full-height 2-column dashboard exclusively for SPONSOR (Gambar 3!)
	_sponsor_root = HBoxContainer.new()
	_sponsor_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sponsor_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sponsor_root.add_theme_constant_override("separation", 12)
	_sponsor_root.visible = false
	outer.add_child(_sponsor_root)

	# Landscape Split: Optional Left Locker Showcase + Right Scrollable Body
	_content_hb = HBoxContainer.new()
	_content_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_hb.add_theme_constant_override("separation", 10)
	outer.add_child(_content_hb)

	_stage_host = VBoxContainer.new()
	_stage_host.custom_minimum_size = Vector2(280, 0)
	_stage_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_hb.add_child(_stage_host)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_hb.add_child(scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	CareerState.career_updated.connect(refresh)
	_refresh_tab_styles()
	refresh()

func set_subtab(st: String) -> void:
	_subtab = st
	_refresh_tab_styles()
	refresh()

func _refresh_tab_styles() -> void:
	if _tab_bar != null:
		_tab_bar.visible = (_subtab != "TOKO")
	for k in _tab_btns.keys():
		var b: Button = _tab_btns[k]
		var act: bool = (str(k) == _subtab)
		if act and str(k) == "SPONSOR":
			UITheme.style_btn(b, Color("#F1F5F9"), Color("#FFFFFF"), 11)
			b.add_theme_color_override("font_color", Color("#0A1322"))
			b.add_theme_color_override("font_hover_color", Color("#0A1322"))
		else:
			UITheme.style_btn(b, Color("#173B66") if act else Color("#0B1626"), UITheme.BORDER_CYAN if act else UITheme.BORDER_STEEL, 11)
			b.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			b.add_theme_color_override("font_hover_color", UITheme.TEXT_WHITE)
		if k == "SKILL" and CareerState.has_active_career:
			var sp := int(CareerState.career["playerProfile"]["skillPoints"])
			b.text = "%d POIN" % sp if sp > 0 else "SKILL"

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	_refresh_tab_styles()
	for c in _sponsor_root.get_children():
		_sponsor_root.remove_child(c)
		c.queue_free()
	for c in _stage_host.get_children():
		_stage_host.remove_child(c)
		c.queue_free()
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()

	var is_sponsor: bool = (_subtab == "SPONSOR")
	_sponsor_root.visible = is_sponsor
	_content_hb.visible = not is_sponsor

	if is_sponsor:
		_render_sponsor_body()
		return

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
			av.custom_minimum_size = Vector2(112, 168)
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
	var attrs: Dictionary = p["attributes"]
	var total_sp: int = int(p["skillPoints"])
	var pend_cost: int = 0
	for k in _pending_skills.keys():
		var steps_k: int = int(_pending_skills[k])
		var cv: int = int(attrs.get(k, 60))
		for _s in range(steps_k):
			if cv >= 99:
				break
			pend_cost += CareerState.get_attribute_upgrade_cost(cv)
			cv += 1
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

	var attr_cols: Dictionary = {
		"kekuatan": Color("#F97316"), "akurasi": Color("#38BDF8"), "efek": Color("#A78BFA"),
		"visi": Color("#FACC15"), "fisik": Color("#F472B6"), "kecepatan": Color("#22D3EE"),
		"akselerasi": Color("#FB923C"), "dribel": Color("#60A5FA"), "penalti": Color("#EF4444"), "bolaMati": Color("#4ADE80"),
	}
	for ak in GameData.ATTRIBUTE_KEYS:
		if ak == "penalti":
			_body.add_child(UITheme.make_section_header("BOLA MATI"))
		var ak_copy: String = ak
		var p_add: int = int(_pending_skills.get(ak, 0))
		var base_cur: int = int(attrs[ak]) + p_add
		var next_cost: int = CareerState.get_attribute_upgrade_cost(base_cur)
		var val: int = CareerState.get_effective_attribute(ak) + p_add

		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0B1628"), Color("#1B3150"), 1, 3))
		_body.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		row.add_child(hb)

		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(6, 28)
		icon.color = attr_cols.get(ak, UITheme.ACCENT_CYAN)
		hb.add_child(icon)

		var name_vb := VBoxContainer.new()
		name_vb.custom_minimum_size = Vector2(112, 0)
		name_vb.add_theme_constant_override("separation", 0)
		hb.add_child(name_vb)
		var lbl := Button.new()
		lbl.text = str(GameData.ATTRIBUTE_LABELS[ak]).to_upper()
		lbl.alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.flat = true
		lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		lbl.pressed.connect(func(): AudioSynth.play_click(); _show_skill_tooltip(ak_copy))
		name_vb.add_child(lbl)
		if next_cost > 1 and base_cur < 99:
			var cost_tag := Label.new()
			cost_tag.text = "%d POIN" % next_cost
			cost_tag.add_theme_color_override("font_color", Color("#F59E0B"))
			cost_tag.add_theme_font_size_override("font_size", 9)
			name_vb.add_child(cost_tag)

		var bar_bg := ColorRect.new()
		bar_bg.color = Color("#13233B")
		bar_bg.custom_minimum_size = Vector2(70, 8)
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(bar_bg)
		var bar_fill := ColorRect.new()
		bar_fill.color = UITheme.get_stat_color(val)
		bar_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		bar_fill.anchor_right = clampf(float(val) / 99.0, 0.02, 1.0)
		bar_fill.offset_right = 0
		bar_bg.add_child(bar_fill)

		var vl := Label.new()
		vl.text = ("%d (+%d)" % [val, p_add]) if p_add > 0 else str(val)
		vl.custom_minimum_size = Vector2(60, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_color_override("font_color", UITheme.get_stat_color(val))
		hb.add_child(vl)

		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(40, 28)
		plus.disabled = (rem_sp < next_cost or base_cur >= 99)
		UITheme.style_btn(plus, Color("#243A1C") if next_cost > 1 else Color("#133056"), UITheme.ACCENT_GOLD if next_cost > 1 else UITheme.BORDER_CYAN)
		plus.pressed.connect(func():
			AudioSynth.play_click()
			_pending_skills[ak_copy] = int(_pending_skills.get(ak_copy, 0)) + 1
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

	var scout_cid: int = int(CareerState.career["careerMeta"].get("scoutedByClubId", -1))
	if scout_cid >= 0 and scout_cid < GameData.clubs.size():
		var sc_c: Dictionary = GameData.clubs[scout_cid]
		_body.add_child(UITheme.make_section_header("DIINCAR SCOUT KLUB"))
		var sc_card := PanelContainer.new()
		sc_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1A0E"), UITheme.ACCENT_GOLD, 2, 6))
		_body.add_child(sc_card)
		var sc_hb := HBoxContainer.new()
		sc_hb.add_theme_constant_override("separation", 10)
		sc_card.add_child(sc_hb)
		var sc_cr := ClubCrest.new()
		sc_cr.custom_minimum_size = Vector2(40, 40)
		sc_cr.set_club(scout_cid)
		sc_hb.add_child(sc_cr)
		var sc_l := Label.new()
		sc_l.text = "%s (OVR %d • DIV %d)\nMinat Pemantauan: %d%%" % [str(sc_c.get("name", "KLUB")).to_upper(), int(sc_c.get("ovr", 68)), int(sc_c.get("division", 2)), int(CareerState.career["careerMeta"].get("scoutInterest", 25))]
		sc_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		sc_l.add_theme_font_size_override("font_size", 11)
		sc_hb.add_child(sc_l)

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

	if bool(con.get("isFreeAgent", false)):
		var fa_card := PanelContainer.new()
		fa_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#132A1B"), UITheme.ACCENT_GREEN, 2, 6))
		_body.add_child(fa_card)
		var fa_lbl := Label.new()
		fa_lbl.text = "STATUS: PEMAIN BEBAS (BEBAS TRANSFER) • Klub peminat tidak perlu membayar biaya tebusan!"
		fa_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
		fa_lbl.add_theme_font_size_override("font_size", 11)
		fa_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fa_card.add_child(fa_lbl)

	_body.add_child(UITheme.make_section_header("KLAUSUL PRIBADI"))
	var active_clause: String = str(con.get("clause", "NONE"))
	var clause_desc_str := "Tanpa klausul. Satu syarat yang tegas, ditukar dengan melepas klausul lain."
	var clause_title_str := "PILIH KLAUSUL"
	for cd in GameData.CLAUSE_DEFS:
		if str(cd["id"]) == active_clause:
			clause_title_str = "%s (GANTI)" % str(cd["title"])
			clause_desc_str = "AKTIF SEMUSIM: %s" % str(cd["desc"])
			break
	var cl_desc := Label.new()
	cl_desc.text = clause_desc_str
	cl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cl_desc.add_theme_font_size_override("font_size", 11)
	cl_desc.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if active_clause != "NONE" else UITheme.TEXT_MUTED)
	_body.add_child(cl_desc)

	var cl_btn := Button.new()
	cl_btn.text = clause_title_str
	cl_btn.custom_minimum_size = Vector2(0, 40)
	UITheme.style_btn(cl_btn, Color("#123944") if active_clause != "NONE" else Color("#18273B"), UITheme.ACCENT_CYAN if active_clause != "NONE" else UITheme.BORDER_STEEL, 12)
	cl_btn.pressed.connect(func():
		AudioSynth.play_click()
		_open_clause_modal()
	)
	_body.add_child(cl_btn)

func _open_clause_modal() -> void:
	var con: Dictionary = CareerState.career["contract"]
	var cur_clause: String = str(con.get("clause", "NONE"))
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.04, 0.08, 0.84)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 140
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 0)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#162338"), UITheme.BORDER_CYAN, 2, 10))
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	var hdr := Label.new()
	hdr.text = "KLAUSUL PRIBADI"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	vb.add_child(hdr)

	var sub := Label.new()
	sub.text = "Hanya boleh satu. Disepakati di awal musim."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	vb.add_child(sub)

	for cd in GameData.CLAUSE_DEFS:
		var cid: String = str(cd["id"])
		var d_lbl := Label.new()
		d_lbl.text = str(cd["desc"])
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d_lbl.add_theme_font_size_override("font_size", 11)
		d_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		vb.add_child(d_lbl)

		var opt_btn := Button.new()
		var is_sel: bool = (cur_clause == cid)
		opt_btn.text = ("✓ " if is_sel else "") + str(cd["title"])
		opt_btn.custom_minimum_size = Vector2(0, 42)
		UITheme.style_btn(opt_btn, Color("#175966") if is_sel else Color("#123945"), UITheme.ACCENT_GOLD if is_sel else UITheme.ACCENT_CYAN, 13)
		opt_btn.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.set_contract_clause(cid)
			overlay.queue_free()
			refresh()
		)
		vb.add_child(opt_btn)

	var none_btn := Button.new()
	none_btn.text = "X  NOL KLAUSUL"
	none_btn.custom_minimum_size = Vector2(0, 40)
	UITheme.style_btn(none_btn, Color("#7A2B1D"), UITheme.ACCENT_RED, 13)
	none_btn.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.set_contract_clause("NONE")
		overlay.queue_free()
		refresh()
	)
	vb.add_child(none_btn)

	var back_btn := Button.new()
	back_btn.text = "KEMBALI"
	back_btn.custom_minimum_size = Vector2(0, 38)
	UITheme.style_btn(back_btn, Color("#1A263C"), UITheme.BORDER_STEEL, 12)
	back_btn.pressed.connect(func():
		AudioSynth.play_click()
		overlay.queue_free()
	)
	vb.add_child(back_btn)

func _render_relations_body() -> void:
	# 6 Relation Characters Strip (including KEKASIH)
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
		["KEKASIH", "kekasih", -1],
	]
	for sp in specs:
		var val := int(rel.get(sp[1], 0))
		var tier := "BELUM ADA" if (sp[1] == "kekasih" and val <= 0) else CareerState.get_relation_tier(val)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		strips.add_child(card)
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_END
		card.add_child(vb)

		var club_cur: Dictionary = CareerState.get_current_club()
		var npc_role: String = "PARTNER"
		match int(sp[2]):
			0: npc_role = "REPORTER"
			1: npc_role = "SUPPORTER"
			2: npc_role = "COACH"
			4: npc_role = "AGENT"
			5: npc_role = "TEAMMATE"
			_: npc_role = "PARTNER"
		var npc_av := NpcAvatar.new()
		npc_av.configure_role(npc_role, false, club_cur)
		npc_av.anim_mode = "IDLE" if (sp[1] != "kekasih" or val > 0) else "NONE"
		npc_av.anim_phase = float(specs.find(sp)) * 0.7
		npc_av.custom_minimum_size = Vector2(54, 82)
		if sp[1] == "kekasih" and val <= 0:
			npc_av.modulate = Color(0.32, 0.36, 0.44, 0.55)
		vb.add_child(npc_av)

		var l1 := Label.new()
		l1.text = sp[0]
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l1.add_theme_font_size_override("font_size", 10)
		var l2 := Label.new()
		l2.text = ("?" if (sp[1] == "kekasih" and val <= 0) else "%d\n%s" % [val, tier])
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.add_theme_color_override("font_color", UITheme.TEXT_MUTED if (sp[1] == "kekasih" and val <= 0) else (UITheme.ACCENT_GREEN if val >= 60 else (UITheme.ACCENT_RED if val < 40 else UITheme.TEXT_WHITE)))
		l2.add_theme_font_size_override("font_size", 11)
		vb.add_child(l1)
		vb.add_child(l2)

	_body.add_child(UITheme.make_section_header("RELASI DETAIL"))
	var coach_name: String = GameData.coaches[int(CareerState.get_current_club()["coach_id"])]["name"]
	var k_val := int(rel.get("kekasih", 0))
	var details := [
		[coach_name, int(rel["pelatih"]), CareerState.get_player_role_status()],
		["Ruang ganti", int(rel["ruangGanti"]), "+%d umpan rekan" % int(int(rel["ruangGanti"]) / 10)],
		["Suporter", int(rel["fans"]), UITheme.format_cash(int(CareerState.career["playerProfile"]["marketValue"]))],
		["Pers", int(rel["pers"]), CareerState.get_relation_tier(int(rel["pers"]))],
		["Agen", int(rel["agen"]), "+%d%% GAJI" % maxi(5, int(int(rel["agen"]) / 6))],
		["Kekasih (Wulan)", k_val, "BELUM KENALAN" if k_val <= 0 else CareerState.get_relation_tier(k_val)],
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

func open_sponsor_detail_modal(sp_item: Dictionary) -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	var active_id: String = str(CareerState.career["sponsor"].get("activeId", ""))
	var is_cur: bool = (str(sp_item.get("id", "")) == active_id)
	return MarketSponsorOverlaysScript.open_sponsor_popup(host, sp_item, is_cur, func(): refresh())

# ==============================================================================
# SPONSOR TAB (Gambar 3 -> Pop-Up Gambar 4)
# ==============================================================================
func _render_sponsor_body() -> void:
	var active_id: String = str(CareerState.career["sponsor"].get("activeId", ""))
	var prog: int = int(CareerState.career["sponsor"].get("goalsProgress", 0))
	var wk: int = int(CareerState.career["careerMeta"].get("week", 1))
	var active_item: Dictionary = {}
	for item in GameData.sponsors_catalog:
		if str(item["id"]) == active_id:
			active_item = item
			break

	# LEFT COLUMN: MEREKMU Card (Gambar 3!)
	var left_p := PanelContainer.new()
	left_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_p.size_flags_stretch_ratio = 0.88
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color("#0A1322")
	lsb.border_color = Color("#1B2D47")
	lsb.set_border_width_all(1)
	lsb.set_corner_radius_all(6)
	lsb.content_margin_left = 14
	lsb.content_margin_right = 14
	lsb.content_margin_top = 12
	lsb.content_margin_bottom = 12
	left_p.add_theme_stylebox_override("panel", lsb)
	_sponsor_root.add_child(left_p)

	var lvb := VBoxContainer.new()
	lvb.add_theme_constant_override("separation", 10)
	left_p.add_child(lvb)

	var m_hdr := Label.new()
	m_hdr.text = "MEREKMU"
	m_hdr.add_theme_font_override("font", UITheme.get_display_font())
	m_hdr.add_theme_font_size_override("font_size", 11)
	m_hdr.add_theme_color_override("font_color", Color("#8EA3BC"))
	lvb.add_child(m_hdr)

	var m_div := ColorRect.new()
	m_div.custom_minimum_size = Vector2(0, 1)
	m_div.color = Color("#1F334F")
	lvb.add_child(m_div)

	if active_item.is_empty():
		var empty_c := VBoxContainer.new()
		empty_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_c.alignment = BoxContainer.ALIGNMENT_CENTER
		var em_l := Label.new()
		em_l.text = "Belum ada. Muncul di pers dan mereka akan datang sendiri."
		em_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		em_l.add_theme_font_size_override("font_size", 12)
		em_l.add_theme_color_override("font_color", Color("#DCE6F2"))
		empty_c.add_child(em_l)
		lvb.add_child(empty_c)
	else:
		var act_card := Button.new()
		act_card.custom_minimum_size = Vector2(0, 126)
		act_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var acsb := StyleBoxFlat.new()
		acsb.bg_color = Color("#11231B")
		acsb.border_color = UITheme.ACCENT_GOLD
		acsb.set_border_width_all(1)
		acsb.set_corner_radius_all(6)
		var acsbh := acsb.duplicate()
		acsbh.bg_color = Color("#173024")
		act_card.add_theme_stylebox_override("normal", acsb)
		act_card.add_theme_stylebox_override("hover", acsbh)
		act_card.add_theme_stylebox_override("pressed", acsbh)
		act_card.add_theme_stylebox_override("focus", acsbh)
		lvb.add_child(act_card)

		var ac_vb := VBoxContainer.new()
		ac_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		ac_vb.offset_left = 12
		ac_vb.offset_right = -12
		ac_vb.offset_top = 10
		ac_vb.offset_bottom = -10
		ac_vb.add_theme_constant_override("separation", 6)
		ac_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		act_card.add_child(ac_vb)

		var a_top := HBoxContainer.new()
		a_top.add_theme_constant_override("separation", 10)
		a_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ac_vb.add_child(a_top)
		var a_em := CenterContainer.new()
		a_em.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a_em.add_child(MarketSponsorOverlaysScript.make_sponsor_emblem(str(active_item["id"]), Vector2(44, 44)))
		a_top.add_child(a_em)
		var a_txt := VBoxContainer.new()
		a_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		a_txt.add_theme_constant_override("separation", 2)
		a_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a_top.add_child(a_txt)
		var anm := Label.new()
		anm.text = str(active_item["name"]).to_upper()
		anm.add_theme_font_override("font", UITheme.get_display_font())
		anm.add_theme_font_size_override("font_size", 13)
		anm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		anm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var apay := Label.new()
		apay.text = "%s / LAGA  (+%s/GOL)" % [MarketSponsorOverlaysScript.format_cash_dots(int(active_item["per_match"])), MarketSponsorOverlaysScript.format_cash_dots(int(active_item["per_goal"]))]
		apay.add_theme_font_size_override("font_size", 11)
		apay.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		apay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a_txt.add_child(anm)
		a_txt.add_child(apay)

		var tg: int = maxi(1, int(active_item["target_goals"]))
		var prog_l := Label.new()
		prog_l.text = "TARGET: %d / %d GOL  •  BONUS %s" % [prog, tg, MarketSponsorOverlaysScript.format_cash_dots(int(active_item["season_bonus"]))]
		prog_l.add_theme_font_size_override("font_size", 11)
		prog_l.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if prog >= tg else Color("#CBD5E1"))
		prog_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ac_vb.add_child(prog_l)

		var pb := ProgressBar.new()
		pb.max_value = float(tg)
		pb.value = float(mini(prog, tg))
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 8)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ac_vb.add_child(pb)

		var act_copy: Dictionary = active_item
		act_card.pressed.connect(func():
			AudioSynth.play_click()
			open_sponsor_detail_modal(act_copy)
		)

	# RIGHT COLUMN: DIINCAR + PRAMUSIM badge + Sponsor Offer Cards (Gambar 3!)
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 1.12
	right_vb.add_theme_constant_override("separation", 8)
	_sponsor_root.add_child(right_vb)

	var rhdr := HBoxContainer.new()
	rhdr.add_theme_constant_override("separation", 8)
	right_vb.add_child(rhdr)
	var di_lbl := Label.new()
	di_lbl.text = "▸  DIINCAR"
	di_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	di_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	di_lbl.add_theme_font_override("font", UITheme.get_display_font())
	di_lbl.add_theme_font_size_override("font_size", 12)
	di_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	rhdr.add_child(di_lbl)

	var tag_p := PanelContainer.new()
	var tpsb := StyleBoxFlat.new()
	tpsb.bg_color = Color("#241F10")
	tpsb.border_color = Color("#B58B2B")
	tpsb.set_border_width_all(1)
	tpsb.set_corner_radius_all(3)
	tpsb.content_margin_left = 8
	tpsb.content_margin_right = 8
	tpsb.content_margin_top = 2
	tpsb.content_margin_bottom = 2
	tag_p.add_theme_stylebox_override("panel", tpsb)
	var tag_l := Label.new()
	tag_l.text = "PRAMUSIM" if wk <= 4 else "TAWARAN AKTIF"
	tag_l.add_theme_font_override("font", UITheme.get_display_font())
	tag_l.add_theme_font_size_override("font_size", 9)
	tag_l.add_theme_color_override("font_color", Color("#F5C430"))
	tag_p.add_child(tag_l)
	rhdr.add_child(tag_p)

	var r_sc := ScrollContainer.new()
	r_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vb.add_child(r_sc)

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 8)
	r_sc.add_child(list_vb)

	for sp_item in GameData.sponsors_catalog:
		var is_cur: bool = (str(sp_item["id"]) == active_id)
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 76)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color("#11211B") if is_cur else Color("#0A1424")
		csb.border_color = UITheme.ACCENT_GOLD if is_cur else Color("#1D304D")
		csb.set_border_width_all(1)
		csb.set_corner_radius_all(6)
		var csbh := csb.duplicate()
		csbh.bg_color = csb.bg_color.lightened(0.10)
		csbh.border_color = UITheme.ACCENT_CYAN
		card.add_theme_stylebox_override("normal", csb)
		card.add_theme_stylebox_override("hover", csbh)
		card.add_theme_stylebox_override("pressed", csbh)
		card.add_theme_stylebox_override("focus", csbh)
		list_vb.add_child(card)

		var hb := HBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 12
		hb.offset_right = -12
		hb.offset_top = 8
		hb.offset_bottom = -8
		hb.add_theme_constant_override("separation", 12)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(hb)

		var em_c := CenterContainer.new()
		em_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		em_c.add_child(MarketSponsorOverlaysScript.make_sponsor_emblem(str(sp_item["id"]), Vector2(44, 44)))
		hb.add_child(em_c)

		var ivb := VBoxContainer.new()
		ivb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ivb.alignment = BoxContainer.ALIGNMENT_CENTER
		ivb.add_theme_constant_override("separation", 2)
		ivb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(ivb)

		var n_l := Label.new()
		n_l.text = str(sp_item["name"]).to_upper()
		n_l.add_theme_font_override("font", UITheme.get_display_font())
		n_l.add_theme_font_size_override("font_size", 12)
		n_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		n_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ivb.add_child(n_l)

		var pay_l := Label.new()
		pay_l.text = "%s / LAGA" % MarketSponsorOverlaysScript.format_cash_dots(int(sp_item["per_match"]))
		pay_l.add_theme_font_override("font", UITheme.get_display_font())
		pay_l.add_theme_font_size_override("font_size", 11)
		pay_l.add_theme_color_override("font_color", Color("#F5C430"))
		pay_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ivb.add_child(pay_l)

		var meta_l := Label.new()
		meta_l.text = "%d GOL  •  BONUS %s" % [int(sp_item["target_goals"]), MarketSponsorOverlaysScript.format_cash_dots(int(sp_item["season_bonus"]))]
		meta_l.add_theme_font_size_override("font_size", 10)
		meta_l.add_theme_color_override("font_color", Color("#CBD5E1"))
		meta_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ivb.add_child(meta_l)

		# Right TEKEN / AKTIF pill visual
		var act_p := PanelContainer.new()
		act_p.custom_minimum_size = Vector2(92, 36)
		act_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var apsb := StyleBoxFlat.new()
		apsb.bg_color = Color("#133324") if is_cur else Color("#08101C")
		apsb.border_color = UITheme.ACCENT_GREEN if is_cur else Color("#E2E8F0")
		apsb.set_border_width_all(1)
		apsb.border_width_bottom = 3
		apsb.set_corner_radius_all(3)
		act_p.add_theme_stylebox_override("panel", apsb)
		var apl := Label.new()
		apl.text = "AKTIF" if is_cur else "TEKEN"
		apl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		apl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		apl.add_theme_font_override("font", UITheme.get_display_font())
		apl.add_theme_font_size_override("font_size", 11)
		apl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if is_cur else UITheme.TEXT_WHITE)
		apl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		act_p.add_child(apl)
		var ap_c := CenterContainer.new()
		ap_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ap_c.add_child(act_p)
		hb.add_child(ap_c)

		var sp_copy: Dictionary = sp_item
		card.pressed.connect(func():
			AudioSynth.play_click()
			open_sponsor_detail_modal(sp_copy)
		)

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

func _show_skill_tooltip(ak: String) -> void:
	var old := get_node_or_null("SkillTooltipOverlay")
	if old != null:
		old.queue_free()

	var raw_val := int(CareerState.career["playerProfile"]["attributes"].get(ak, 60))
	var pend := int(_pending_skills.get(ak, 0))
	var base_display := raw_val + pend
	var eff_val := CareerState.get_effective_attribute(ak) + pend
	var next_cost := CareerState.get_attribute_upgrade_cost(base_display)
	var attr_title := str(GameData.ATTRIBUTE_LABELS.get(ak, ak.to_upper())).to_upper()

	var desc_txt := ""
	var stat_txt := ""
	match ak:
		"kekuatan":
			desc_txt = "Mengatur seberapa keras tendanganmu meluncur ke gawang dan jangkauan umpan jauh dari luar kotak penalti."
			stat_txt = "TEMBAKAN: %d KM/H" % int(round(75.0 + float(eff_val) * 0.55))
		"akurasi":
			desc_txt = "Mengatur presisi bidikan ke pojok gawang, tendangan placing, maupun akurasi umpan terobosan ke rekan."
			stat_txt = "DEVIASI: ±%d CM @ 18M" % maxi(4, int(round(48.0 - float(eff_val) * 0.42)))
		"efek":
			desc_txt = "Mengatur seberapa tajam bola melengkung melewati pagar hidup lawan dan jangkauan tangan kiper."
			stat_txt = "EFEK MELENGKUNG: %.2f×" % (0.75 + float(eff_val) * 0.012)
		"visi":
			desc_txt = "Membaca pergerakan rekan dan celah pertahanan; di angka 85 memunculkan peringatan garis offside sebelum umpan."
			if eff_val >= 85:
				stat_txt = "GARIS OFFSIDE: AKTIF (@ 85)"
			else:
				stat_txt = "KURANG %d UNTUK GARIS OFFSIDE @ 85" % (85 - eff_val)
		"fisik":
			desc_txt = "Menjaga keseimbangan saat duel bahu dengan bek lawan, ketahanan stamina laga, serta tenaga sundulan udara."
			stat_txt = "SUNDULANMU: %d KM/H • STAMINA +%d%%" % [int(round(46.0 + float(eff_val) * 0.35)), int(round(float(eff_val) * 0.45))]
		"kecepatan":
			desc_txt = "Mengatur kecepatan lari puncakmu saat mengejar umpan terobosan maupun membangun serangan balik."
			stat_txt = "LARIMU: %.1f M/S" % (6.2 + float(eff_val) * 0.038)
		"akselerasi":
			desc_txt = "Mengatur seberapa cepat kamu mencapai kecepatan penuh sejak langkah pertama dan melepas kawalan bek."
			stat_txt = "AKSELERASI: %.2f S" % maxf(1.60, 3.60 - float(eff_val) * 0.018)
		"dribel":
			desc_txt = "Mengontrol kelengketan bola di kakimu saat menggiring cepat di ruang sempit maupun melewati hadangan."
			stat_txt = "DIREBUT DARI %d CM" % maxi(18, int(round(74.0 - float(eff_val) * 0.52)))
		"penalti":
			desc_txt = "Meningkatkan ketenangan eksekusi penalti serta peluang rekan menyetujui permintaanmu mengambil penalti."
			stat_txt = "CHANCE PENALTI: %d%%" % clampi(int(round(20.0 + float(eff_val) * 0.72)), 20, 95)
		"bolaMati":
			desc_txt = "Meningkatkan kualitas tendangan bebas & sepak pojok, serta peluang tim menyerahkan eksekusi bola mati padamu."
			stat_txt = "CHANCE BOLA MATI: %d%%" % clampi(int(round(20.0 + float(eff_val) * 0.72)), 20, 95)
		_:
			desc_txt = "Atribut dasar pemain."
			stat_txt = "NILAI: %d" % eff_val

	var scrim := PanelContainer.new()
	scrim.name = "SkillTooltipOverlay"
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim_sb := StyleBoxFlat.new()
	scrim_sb.bg_color = Color(0.02, 0.04, 0.09, 0.78)
	scrim.add_theme_stylebox_override("panel", scrim_sb)
	add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(410, 0)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A162C"), UITheme.BORDER_CYAN, 2, 10))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	card.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	m.add_child(vb)

	var top_hb := HBoxContainer.new()
	vb.add_child(top_hb)
	var title_lbl := Label.new()
	title_lbl.text = "%s (%d)" % [attr_title, base_display]
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	title_lbl.add_theme_font_size_override("font_size", 16)
	top_hb.add_child(title_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "UPGRADE: %d POIN" % next_cost
	cost_lbl.add_theme_color_override("font_color", Color("#F59E0B") if next_cost >= 2 else UITheme.ACCENT_CYAN)
	cost_lbl.add_theme_font_size_override("font_size", 11)
	top_hb.add_child(cost_lbl)

	var dlbl := Label.new()
	dlbl.text = desc_txt
	dlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	dlbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(dlbl)

	var stat_box := PanelContainer.new()
	stat_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0E2242"), UITheme.BORDER_STEEL, 1, 6))
	vb.add_child(stat_box)
	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 10)
	sm.add_theme_constant_override("margin_right", 10)
	sm.add_theme_constant_override("margin_top", 8)
	sm.add_theme_constant_override("margin_bottom", 8)
	stat_box.add_child(sm)
	var slbl := Label.new()
	slbl.text = stat_txt
	slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slbl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	slbl.add_theme_font_size_override("font_size", 13)
	sm.add_child(slbl)

	var ok_b := Button.new()
	ok_b.text = "PAHAM"
	ok_b.custom_minimum_size = Vector2(0, 38)
	UITheme.style_btn(ok_b, Color("#174C6B"), UITheme.ACCENT_CYAN, 13)
	ok_b.pressed.connect(func():
		AudioSynth.play_click()
		scrim.queue_free()
	)
	vb.add_child(ok_b)
