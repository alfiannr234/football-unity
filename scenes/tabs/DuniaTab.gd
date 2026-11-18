extends Control

var _subtab: String = "KOMP."
var _comp_nat_idx: int = 0
var _comp_div: int = 3
var _rank_tab: String = "PEMAIN"
var _rank_page: int = 0
var _news_channel: String = "KLUB"
var _sched_filter: String = "LIGA"
var _body: VBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 4)
	outer.add_child(thb)
	for st in ["KOMP.", "BUKA", "TRANSFER", "JADWAL", "RANKING", "BERITA"]:
		var b := Button.new()
		b.text = st
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 38)
		UITheme.style_btn(b, Color("#0E2036"), UITheme.BORDER_STEEL, 10)
		b.pressed.connect(func():
			AudioSynth.play_click()
			_subtab = st
			refresh()
		)
		thb.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	CareerState.career_updated.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	for c in _body.get_children():
		c.queue_free()

	match _subtab:
		"KOMP.": _render_comp()
		"BUKA": _render_buka()
		"TRANSFER": _render_transfer_feed()
		"JADWAL": _render_jadwal()
		"RANKING": _render_ranking()
		"BERITA": _render_berita()

func _render_comp() -> void:
	var user_club := CareerState.get_current_club()
	var nhb := HBoxContainer.new()
	_body.add_child(nhb)
	var nl := Button.new()
	nl.text = "<"
	nl.pressed.connect(func(): AudioSynth.play_click(); _comp_nat_idx = posmod(_comp_nat_idx - 1, GameData.nations.size()); refresh())
	var nlbl := Label.new()
	nlbl.text = "LIGA %s • %s" % [GameData.nations[_comp_nat_idx]["name"].to_upper(), ["PERTAMA", "KEDUA", "KETIGA"][_comp_div - 1]]
	nlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nr := Button.new()
	nr.text = ">"
	nr.pressed.connect(func(): AudioSynth.play_click(); _comp_nat_idx = posmod(_comp_nat_idx + 1, GameData.nations.size()); refresh())
	nhb.add_child(nl)
	nhb.add_child(nlbl)
	nhb.add_child(nr)

	var dhb := HBoxContainer.new()
	dhb.add_theme_constant_override("separation", 4)
	_body.add_child(dhb)
	for d in [1, 2, 3]:
		var db := Button.new()
		db.text = ["DIV 1", "DIV 2", "DIV 3"][d - 1]
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(db, Color("#173B66") if _comp_div == d else Color("#0B1626"), UITheme.BORDER_CYAN)
		db.pressed.connect(func(): AudioSynth.play_click(); _comp_div = d; refresh())
		dhb.add_child(db)

	_body.add_child(UITheme.make_section_header("KLASEMEN"))
	var rows: Array[Dictionary] = []
	if _comp_nat_idx == int(user_club["nation_id"]) and _comp_div == int(user_club["division"]):
		rows = CareerState.get_sorted_league_table()
	else:
		for cl in GameData.get_clubs_in_division(_comp_nat_idx, _comp_div):
			rows.append({"club_id": cl["id"], "name": cl["name"], "p": 0, "w": 0, "d": 0, "l": 0, "pts": 0})

	var hdr := Label.new()
	hdr.text = "#   TIM                          MN  M  S  K  PTS"
	hdr.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	hdr.add_theme_font_size_override("font_size", 11)
	_body.add_child(hdr)

	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		var is_mine := int(r["club_id"]) == int(user_club["id"])
		var card := PanelContainer.new()
		var promo_col := UITheme.ACCENT_GOLD if i < 3 else UITheme.BORDER_STEEL
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#123452") if is_mine else Color("#0A1526"), UITheme.ACCENT_CYAN if is_mine else promo_col, 1, 2))
		_body.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		var nm := Label.new()
		nm.text = "%2d. %s%s" % [i + 1, str(r["name"]).left(22), " (KAMU)" if is_mine else ""]
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if is_mine else UITheme.TEXT_WHITE)
		nm.add_theme_font_size_override("font_size", 12)
		var st_l := Label.new()
		st_l.text = "%2d %2d %2d %2d  %2d" % [int(r["p"]), int(r["w"]), int(r["d"]), int(r["l"]), int(r["pts"])]
		st_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		st_l.add_theme_font_size_override("font_size", 12)
		hb.add_child(nm)
		hb.add_child(st_l)

func _render_buka() -> void:
	var tw := int(CareerState.career["careerMeta"].get("transferWindowWeeksLeft", 0))
	var p: Dictionary = CareerState.career["playerProfile"]
	var st_panel := PanelContainer.new()
	st_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122B20") if tw > 0 else Color("#241822"), UITheme.ACCENT_GREEN if tw > 0 else UITheme.ACCENT_RED))
	_body.add_child(st_panel)
	var sl := Label.new()
	sl.text = ("BURSA BUKA (%d PEKAN LAGI)\nNILAIMU: %s" % [tw, UITheme.format_short_cash(int(p["marketValue"]))]) if tw > 0 else ("BURSA TUTUP\nNILAIMU: %s" % UITheme.format_short_cash(int(p["marketValue"])))
	sl.add_theme_font_override("font", UITheme.get_display_font())
	sl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if tw > 0 else UITheme.ACCENT_RED)
	st_panel.add_child(sl)

	_body.add_child(UITheme.make_section_header("AGENMU • CARI KLUB BARU"))
	for opt in [
		["TAWARKAN KE SEMUA KLUB", 2404],
		["SATU LIGA DI LIGA LAIN", 4207],
		["SATU KLUB (KETUK PINTUNYA)", 7212],
	]:
		var btn := Button.new()
		btn.text = "%s  —  %s" % [opt[0], UITheme.format_cash(int(opt[1]))]
		UITheme.style_btn(btn, Color("#34244C"), Color("#8F64D4"))
		btn.pressed.connect(func():
			AudioSynth.play_click()
			if int(p["cash"]) >= int(opt[1]):
				p["cash"] = int(p["cash"]) - int(opt[1])
				CareerState._refresh_transfer_offers()
				CareerState.save_active_career()
				refresh()
		)
		_body.add_child(btn)

	_body.add_child(UITheme.make_section_header("TAWARAN MASUK"))
	var offers: Array = CareerState.career.get("transferOffers", [])
	if offers.is_empty():
		var empty := Label.new()
		empty.text = "Belum ada tawaran masuk. Tampil bagus atau minta agen mencarikan klub!"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(empty)
	else:
		for off in offers:
			var card := PanelContainer.new()
			_body.add_child(card)
			var hb := HBoxContainer.new()
			card.add_child(hb)
			var vb := VBoxContainer.new()
			vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(vb)
			var l1 := Label.new()
			l1.text = "%s (%s • DIV %d)" % [off["club_name"], off["nation"], int(off["division"])]
			var l2 := Label.new()
			l2.text = "OVR %d  •  Gaji %s/laga  •  %d THN" % [int(off["ovr"]), UITheme.format_cash(int(off["salary"])), int(off["years"])]
			l2.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
			vb.add_child(l1)
			vb.add_child(l2)
			var acc := Button.new()
			acc.text = "TEKEN"
			UITheme.style_btn(acc, Color("#1D5C9E"), UITheme.ACCENT_GOLD)
			acc.pressed.connect(func():
				AudioSynth.play_click()
				CareerState.accept_transfer(off, int(p["appearance"].get("shirt_num", 9)))
			)
			hb.add_child(acc)

func _render_transfer_feed() -> void:
	_body.add_child(UITheme.make_section_header("TRANSFER & BOSMAN"))
	var my_club := CareerState.get_current_club()
	for i in range(6):
		var p_idx := (i * 137 + 12) % CareerState.TOTAL_WORLD_PLAYERS
		var card := PanelContainer.new()
		_body.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		hb.add_child(UITheme.make_ovr_badge(int(CareerState.wp_ovr[p_idx]), "default", Vector2(36, 36)))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var l1 := Label.new()
		l1.text = "∅ BOSMAN • %s" % CareerState.wp_name[p_idx]
		var l2 := Label.new()
		l2.text = "%s  ←  TANPA KLUB (%s)" % [my_club["name"], GameData.POSITIONS[int(CareerState.wp_pos[p_idx])]]
		l2.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		vb.add_child(l1)
		vb.add_child(l2)

func _render_jadwal() -> void:
	var st: Dictionary = CareerState.career["stats"]
	var m := maxf(1.0, float(st["matches"]))
	var sum := Label.new()
	sum.text = "M %.0f%%   •   S %.0f%%   •   K %.0f%%   |   ★ %.1f   G:%d   A:%d" % [
		float(st["wins"]) / m * 100.0, float(st["draws"]) / m * 100.0, float(st["losses"]) / m * 100.0,
		float(st["totalRating"]) / m if int(st["matches"]) > 0 else 6.0,
		int(st["goals"]), int(st["assists"])
	]
	sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(sum)

	var fhb := HBoxContainer.new()
	fhb.add_theme_constant_override("separation", 6)
	_body.add_child(fhb)
	for flt in ["LIGA", "PIALA", "TIMNAS"]:
		var b := Button.new()
		b.text = flt
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(b, Color("#173B66") if _sched_filter == flt else Color("#0B1626"), UITheme.BORDER_CYAN)
		b.pressed.connect(func(): AudioSynth.play_click(); _sched_filter = flt; refresh())
		fhb.add_child(b)

	var week := int(CareerState.career["careerMeta"]["week"])
	var months := ["AGUSTUS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DESEMBER", "JANUARI", "FEBRUARI", "MARET", "APRIL", "MEI"]
	var sched: Array = CareerState.career["schedule"]
	for fx in sched:
		if _sched_filter != "SEMUA" and fx["comp"] != _sched_filter:
			continue
		var fw := int(fx["week"])
		var card := PanelContainer.new()
		var is_next := (fw == week)
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122D48") if is_next else UITheme.BG_CARD, UITheme.ACCENT_GOLD if is_next else UITheme.BORDER_STEEL))
		_body.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		var m_name: String = months[clampi(int((fw - 1) / 4.5), 0, months.size() - 1)]
		var l1 := Label.new()
		l1.text = "M%02d (%s) • %s vs %s" % [fw, m_name.left(3), fx["comp"], fx["opp_name"]]
		l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l2 := Label.new()
		if fx["played"]:
			l2.text = "%d - %d" % [int(fx["score_us"]), int(fx["score_them"])]
			l2.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if int(fx["score_us"]) > int(fx["score_them"]) else UITheme.TEXT_WHITE)
		else:
			l2.text = "KANDANG" if fx["is_home"] else "TANDANG"
			l2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		hb.add_child(l1)
		hb.add_child(l2)

func _render_ranking() -> void:
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 6)
	_body.add_child(thb)
	for rt in ["PEMAIN", "PELATIH", "NEGARA"]:
		var b := Button.new()
		b.text = rt
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(b, Color("#173B66") if _rank_tab == rt else Color("#0B1626"), UITheme.BORDER_CYAN if _rank_tab == rt else UITheme.BORDER_STEEL)
		b.pressed.connect(func(): AudioSynth.play_click(); _rank_tab = rt; _rank_page = 0; refresh())
		thb.add_child(b)

	if _rank_tab == "PEMAIN":
		var my_ovr := int(CareerState.career["playerProfile"]["ovr"])
		var my_rank := CareerState.get_player_global_rank(my_ovr)
		var me_panel := PanelContainer.new()
		me_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0F243C"), UITheme.BORDER_CYAN))
		_body.add_child(me_panel)
		var ml := Label.new()
		ml.text = "PERINGKATMU: %d / %d (OVR %d)" % [my_rank, CareerState.TOTAL_WORLD_PLAYERS, my_ovr]
		ml.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		me_panel.add_child(ml)

		_add_pager(CareerState.TOTAL_WORLD_PLAYERS, 25)
		var start := _rank_page * 25
		for r in range(start, mini(start + 25, CareerState.TOTAL_WORLD_PLAYERS)):
			var idx := CareerState.wp_rank_order[r]
			var row := PanelContainer.new()
			_body.add_child(row)
			var hb := HBoxContainer.new()
			row.add_child(hb)
			var rl := Label.new()
			rl.text = "%d." % (r + 1)
			rl.custom_minimum_size = Vector2(54, 0)
			hb.add_child(rl)
			hb.add_child(UITheme.make_flag_rect(int(CareerState.wp_nat[idx]), Vector2(20, 14)))
			var vb := VBoxContainer.new()
			vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(vb)
			var nl := Label.new()
			nl.text = " %s" % CareerState.wp_name[idx]
			var cl := Label.new()
			cl.text = " %s • %s • %d THN" % [GameData.POSITIONS[int(CareerState.wp_pos[idx])], GameData.clubs[int(CareerState.wp_club[idx])]["name"], int(CareerState.wp_age[idx])]
			cl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			cl.add_theme_font_size_override("font_size", 11)
			vb.add_child(nl)
			vb.add_child(cl)
			hb.add_child(UITheme.make_ovr_badge(int(CareerState.wp_ovr[idx]), "diamond" if int(CareerState.wp_ovr[idx]) >= 85 else "default", Vector2(34, 32)))

	elif _rank_tab == "PELATIH":
		var tot_c := GameData.coaches.size()
		_add_pager(tot_c, 25)
		var start := _rank_page * 25
		for r in range(start, mini(start + 25, tot_c)):
			var ch: Dictionary = GameData.coaches[r]
			var row := PanelContainer.new()
			_body.add_child(row)
			var hb := HBoxContainer.new()
			row.add_child(hb)
			var rl := Label.new()
			rl.text = "%d. %s (%s) — %s" % [r + 1, ch["name"], "★".repeat(int(ch["stars"])), GameData.clubs[int(ch["club_id"])]["name"]]
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(rl)

	else:
		for nat in GameData.nations:
			var row := PanelContainer.new()
			_body.add_child(row)
			var hb := HBoxContainer.new()
			row.add_child(hb)
			var rl := Label.new()
			rl.text = "%2d." % int(nat["world_rank"])
			rl.custom_minimum_size = Vector2(36, 0)
			hb.add_child(rl)
			hb.add_child(UITheme.make_flag_rect(int(nat["id"]), Vector2(22, 15)))
			var nl := Label.new()
			nl.text = "  %s" % nat["name"].to_upper()
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(nl)
			var cl := Label.new()
			cl.text = "%.3f" % float(nat["total_coeff"])
			cl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
			hb.add_child(cl)

func _add_pager(total_items: int, page_size: int) -> void:
	var hb := HBoxContainer.new()
	_body.add_child(hb)
	var prev := Button.new()
	prev.text = "SEBELUM"
	prev.disabled = (_rank_page <= 0)
	prev.pressed.connect(func(): AudioSynth.play_click(); _rank_page = maxi(0, _rank_page - 1); refresh())
	var lbl := Label.new()
	lbl.text = "%d-%d / %d" % [_rank_page * page_size + 1, mini((_rank_page + 1) * page_size, total_items), total_items]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nxt := Button.new()
	nxt.text = "LANJUT"
	nxt.disabled = ((_rank_page + 1) * page_size >= total_items)
	nxt.pressed.connect(func(): AudioSynth.play_click(); _rank_page += 1; refresh())
	hb.add_child(prev)
	hb.add_child(lbl)
	hb.add_child(nxt)

func _render_berita() -> void:
	var ch_hb := HBoxContainer.new()
	ch_hb.add_theme_constant_override("separation", 4)
	_body.add_child(ch_hb)
	for ch in ["KLUB", "LIGA", "DUNIA", "SOSMED", "PESAN"]:
		var b := Button.new()
		b.text = ch
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(b, Color("#173B66") if _news_channel == ch else Color("#0B1626"), UITheme.BORDER_CYAN if _news_channel == ch else UITheme.BORDER_STEEL, 10)
		b.pressed.connect(func(): AudioSynth.play_click(); _news_channel = ch; refresh())
		ch_hb.add_child(b)

	var fol := Label.new()
	fol.text = "▸ MEDSOS • PENGIKUT: %s" % UITheme.format_cash(int(CareerState.career["stats"]["followers"])).replace("$ ", "")
	fol.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_body.add_child(fol)

	for item in CareerState.career.get("news", []):
		if _news_channel != "PESAN" and item["channel"] != _news_channel and _news_channel != "DUNIA":
			continue
		var card := PanelContainer.new()
		_body.add_child(card)
		var l := Label.new()
		l.text = "[MUSIM %d • %s] %s" % [int(item["season"]), item["channel"], item["text"]]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(l)
