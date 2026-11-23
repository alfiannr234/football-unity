extends RefCounted

const BG_DIM := Color(0.02, 0.04, 0.08, 0.80)
const BG_MODAL := Color("#122238")
const BORDER_MODAL := Color("#2B4468")
const GOLD_TXT := Color("#F5C430")

static func format_cash_dots(val: int) -> String:
	var neg: bool = val < 0
	var s: String = str(abs(val))
	var out: String = ""
	var cnt: int = 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "." + out
		out = s[i] + out
		cnt += 1
	return ("-$" if neg else "$") + out

static func make_sponsor_emblem(sponsor_id: String, sz: Vector2 = Vector2(44, 44)) -> Control:
	var c := SponsorEmblemControl.new()
	c.sponsor_id = sponsor_id
	c.custom_minimum_size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func make_icon(kind: String, col: Color = Color("#CBD5E1"), sz: Vector2 = Vector2(16, 16)) -> Control:
	var c := MarketIconControl.new()
	c.icon_kind = kind
	c.icon_color = col
	c.custom_minimum_size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func _style_btn(btn: Button, bg: Color, border: Color, font_sz: int = 12, text_col: Color = UITheme.TEXT_WHITE, bottom_bw: int = 1) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.border_color = border
	n.set_border_width_all(1)
	n.border_width_bottom = bottom_bw
	n.set_corner_radius_all(4)
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.content_margin_top = 6
	n.content_margin_bottom = 6
	var h := n.duplicate()
	h.bg_color = bg.lightened(0.14)
	h.border_color = UITheme.BORDER_CYAN
	var pr := n.duplicate()
	pr.bg_color = bg.darkened(0.10)
	pr.border_color = GOLD_TXT
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_override("font", UITheme.get_display_font())
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", UITheme.TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", GOLD_TXT)

static func _create_modal_layer(parent: Node, box_sz: Vector2) -> Dictionary:
	var layer := EscCanvasLayer.new()
	layer.layer = 20
	parent.add_child(layer)

	var root := Control.new()
	root.theme = UITheme.build_theme()
	root.clip_contents = true
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = BG_DIM
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := PanelContainer.new()
	box.custom_minimum_size = box_sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_MODAL
	sb.border_color = BORDER_MODAL
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	box.add_theme_stylebox_override("panel", sb)
	center.add_child(box)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	box.add_child(vb)
	return {"layer": layer, "root": root, "box": box, "vb": vb}

# ==============================================================================
# 1. SPONSOR DETAIL POP-UP (Gambar 4)
# ==============================================================================
static func open_sponsor_popup(parent: Node, sp_item: Dictionary, is_active: bool, on_changed: Callable = Callable()) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(510, 326))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	# Top Title: [Tag Icon] TOKO ROTI LOKAL
	var hdr_hb := HBoxContainer.new()
	hdr_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hdr_hb.add_theme_constant_override("separation", 8)
	vb.add_child(hdr_hb)
	var tw := CenterContainer.new()
	tw.add_child(make_icon("tag", Color("#D97706"), Vector2(14, 14)))
	hdr_hb.add_child(tw)
	var t_lbl := Label.new()
	t_lbl.text = str(sp_item.get("name", "SPONSOR")).to_upper()
	t_lbl.add_theme_font_override("font", UITheme.get_display_font())
	t_lbl.add_theme_font_size_override("font_size", 16)
	t_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	hdr_hb.add_child(t_lbl)

	var div1 := ColorRect.new()
	div1.custom_minimum_size = Vector2(0, 1)
	div1.color = Color("#243A59")
	vb.add_child(div1)

	# Upper Row: Circular Brand Emblem + "$1.442 / LAGA" & "+$1.442 PER GOL"
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 14)
	vb.add_child(top_hb)
	var ew := CenterContainer.new()
	ew.add_child(make_sponsor_emblem(str(sp_item.get("id", "roti_lokal")), Vector2(46, 46)))
	top_hb.add_child(ew)

	var pay_vb := VBoxContainer.new()
	pay_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	pay_vb.add_theme_constant_override("separation", 2)
	top_hb.add_child(pay_vb)
	var p1 := Label.new()
	p1.text = "%s / LAGA" % format_cash_dots(int(sp_item.get("per_match", 1400)))
	p1.add_theme_font_override("font", UITheme.get_display_font())
	p1.add_theme_font_size_override("font_size", 16)
	p1.add_theme_color_override("font_color", GOLD_TXT)
	var p2 := Label.new()
	p2.text = "+%s PER GOL" % format_cash_dots(int(sp_item.get("per_goal", 1400)))
	p2.add_theme_font_override("font", UITheme.get_display_font())
	p2.add_theme_font_size_override("font_size", 11)
	p2.add_theme_color_override("font_color", Color("#E6C05C"))
	pay_vb.add_child(p1)
	pay_vb.add_child(p2)

	# BONUS & TARGET
	var bonus_l := Label.new()
	bonus_l.text = "BONUS %s" % format_cash_dots(int(sp_item.get("season_bonus", 30000)))
	bonus_l.add_theme_font_override("font", UITheme.get_display_font())
	bonus_l.add_theme_font_size_override("font_size", 14)
	bonus_l.add_theme_color_override("font_color", GOLD_TXT)
	vb.add_child(bonus_l)

	var tg_vb := VBoxContainer.new()
	tg_vb.add_theme_constant_override("separation", 2)
	vb.add_child(tg_vb)
	var tg_cap := Label.new()
	tg_cap.text = "TARGET"
	tg_cap.add_theme_font_size_override("font_size", 9)
	tg_cap.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	tg_vb.add_child(tg_cap)
	var tg_hb := HBoxContainer.new()
	tg_hb.add_theme_constant_override("separation", 6)
	var tgw := CenterContainer.new()
	tgw.add_child(make_icon("target", UITheme.TEXT_WHITE, Vector2(13, 13)))
	tg_hb.add_child(tgw)
	var tg_val := Label.new()
	tg_val.text = "%d GOL" % int(sp_item.get("target_goals", 3))
	tg_val.add_theme_font_override("font", UITheme.get_display_font())
	tg_val.add_theme_font_size_override("font_size", 12)
	tg_val.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	tg_hb.add_child(tg_val)
	tg_vb.add_child(tg_hb)

	# Flavor description paragraph (Gambar 4!)
	var desc_l := Label.new()
	desc_l.text = CareerState.get_sponsor_flavor_text(str(sp_item.get("id", "roti_lokal")))
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_l.add_theme_font_size_override("font_size", 11)
	desc_l.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(desc_l)

	# Bottom 2-button bar: TEKEN (or PUTUS) | TUTUP
	var bhb := HBoxContainer.new()
	bhb.add_theme_constant_override("separation", 10)
	vb.add_child(bhb)

	var act_b := Button.new()
	act_b.text = "PUTUS KONTRAK" if is_active else "TEKEN"
	act_b.custom_minimum_size = Vector2(0, 40)
	act_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_active:
		_style_btn(act_b, Color("#4E1A22"), Color("#EF4444"), 12, Color("#FCA5A5"), 2)
	else:
		_style_btn(act_b, Color("#0A1322"), Color("#E2E8F0"), 12, UITheme.TEXT_WHITE, 3)
	var sp_id: String = str(sp_item.get("id", ""))
	act_b.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.sign_or_break_sponsor(sp_id, not is_active)
		layer.queue_free()
		if on_changed.is_valid():
			on_changed.call()
	)
	bhb.add_child(act_b)

	var cls_b := Button.new()
	cls_b.text = "TUTUP"
	cls_b.custom_minimum_size = Vector2(0, 40)
	cls_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_btn(cls_b, Color("#0A1322"), Color("#263A57"), 12, Color("#CBD5E1"), 1)
	cls_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	bhb.add_child(cls_b)
	return layer

# ==============================================================================
# 2. DIPANTAU FULL POP-UP (Gambar 7 — triggered by LAIN • N on BUKA)
# ==============================================================================
static func open_watched_list_popup(parent: Node, watched_clubs: Array, on_pick_club: Callable) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(710, 294))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	# Header: [Flag] [Bag] DIPANTAU ... count
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 7)
	vb.add_child(hdr)
	var iw1 := CenterContainer.new()
	iw1.add_child(make_icon("tag", GOLD_TXT, Vector2(13, 13)))
	hdr.add_child(iw1)
	var iw2 := CenterContainer.new()
	iw2.add_child(make_icon("bag", Color("#CBD5E1"), Vector2(13, 13)))
	hdr.add_child(iw2)
	var hl := Label.new()
	hl.text = "DIPANTAU"
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 12)
	hl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	hdr.add_child(hl)
	var cnt_l := Label.new()
	cnt_l.text = str(watched_clubs.size())
	cnt_l.add_theme_font_size_override("font_size", 11)
	cnt_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	hdr.add_child(cnt_l)

	var div1 := ColorRect.new()
	div1.custom_minimum_size = Vector2(0, 1)
	div1.color = Color("#243A59")
	vb.add_child(div1)

	# 4-Column Scrollable Club Cards (Gambar 7!)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)

	for entry in watched_clubs:
		var card_b := Button.new()
		card_b.custom_minimum_size = Vector2(0, 166)
		card_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color("#070D17")
		csb.border_color = Color("#1F314D")
		csb.set_border_width_all(1)
		csb.set_corner_radius_all(4)
		var csbh := csb.duplicate()
		csbh.bg_color = Color("#101D33")
		csbh.border_color = UITheme.ACCENT_CYAN
		card_b.add_theme_stylebox_override("normal", csb)
		card_b.add_theme_stylebox_override("hover", csbh)
		card_b.add_theme_stylebox_override("pressed", csbh)
		card_b.add_theme_stylebox_override("focus", csbh)

		var cvb := VBoxContainer.new()
		cvb.set_anchors_preset(Control.PRESET_FULL_RECT)
		cvb.offset_left = 8
		cvb.offset_right = -8
		cvb.offset_top = 12
		cvb.offset_bottom = -10
		cvb.alignment = BoxContainer.ALIGNMENT_CENTER
		cvb.add_theme_constant_override("separation", 5)
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_b.add_child(cvb)

		var cr_c := CenterContainer.new()
		cr_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(56, 56)
		cr.set_club(int(entry["club_id"]))
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr_c.add_child(cr)
		cvb.add_child(cr_c)

		var nm := Label.new()
		nm.text = str(entry["code"]) if str(entry["name"]).length() > 16 else str(entry["name"]).to_upper()
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.add_theme_font_override("font", UITheme.get_display_font())
		nm.add_theme_font_size_override("font_size", 11)
		nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(nm)

		var rk := Label.new()
		rk.text = "KE-%d • ke-%d/%d" % [int(entry["division"]), int(entry["rank"]), int(entry["total_teams"])]
		rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rk.add_theme_font_size_override("font_size", 10)
		rk.add_theme_color_override("font_color", Color("#94A7BD"))
		rk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(rk)

		var st_s: String = str(entry.get("status", "DEKAT"))
		var st_l := Label.new()
		st_l.text = st_s
		st_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_l.add_theme_font_override("font", UITheme.get_display_font())
		st_l.add_theme_font_size_override("font_size", 13)
		st_l.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if st_s == "LAMPU HIJAU" else (Color("#64748B") if st_s == "DITOLAK" else UITheme.TEXT_WHITE))
		st_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(st_l)

		var entry_copy: Dictionary = entry
		card_b.pressed.connect(func():
			AudioSynth.play_click()
			layer.queue_free()
			if on_pick_club.is_valid():
				on_pick_club.call(entry_copy)
		)
		grid.add_child(card_b)

	# Bottom TUTUP bar
	var cls_b := Button.new()
	cls_b.text = "TUTUP"
	cls_b.custom_minimum_size = Vector2(0, 38)
	cls_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_btn(cls_b, Color("#1C314E"), Color("#2E486E"), 12, UITheme.TEXT_WHITE, 1)
	cls_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	vb.add_child(cls_b)
	return layer

# ==============================================================================
# 3. ! GOSIP POP-UP (Gambar 8 — triggered by CEK button on BUKA or clicking a card in Gambar 7!)
# ==============================================================================
static func open_gossip_popup(parent: Node, club_entry: Dictionary, on_decided: Callable = Callable(), on_sign_offer: Callable = Callable()) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(490, 306))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	# Header: [Flag] ! GOSIP
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	vb.add_child(hdr)
	var iw := CenterContainer.new()
	iw.add_child(make_icon("tag", Color("#8B74E8"), Vector2(13, 13)))
	hdr.add_child(iw)
	var hl := Label.new()
	hl.text = "! GOSIP"
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 11)
	hl.add_theme_color_override("font_color", Color("#94A3B8"))
	hdr.add_child(hl)

	var div1 := ColorRect.new()
	div1.custom_minimum_size = Vector2(0, 1)
	div1.color = Color("#243A59")
	vb.add_child(div1)

	# Upper Club Crest + Name + DIVISI / POS split (Gambar 8!)
	var info_hb := HBoxContainer.new()
	info_hb.add_theme_constant_override("separation", 14)
	vb.add_child(info_hb)

	var cr_c := CenterContainer.new()
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(68, 68)
	cr.set_club(int(club_entry["club_id"]))
	cr_c.add_child(cr)
	info_hb.add_child(cr_c)

	var r_vb := VBoxContainer.new()
	r_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_vb.add_theme_constant_override("separation", 6)
	info_hb.add_child(r_vb)

	var cnm := Label.new()
	cnm.text = str(club_entry["name"]).to_upper()
	cnm.clip_text = true
	cnm.add_theme_font_override("font", UITheme.get_display_font())
	cnm.add_theme_font_size_override("font_size", 14)
	cnm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	r_vb.add_child(cnm)

	var div2 := ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = Color("#243A59")
	r_vb.add_child(div2)

	var stats_hb := HBoxContainer.new()
	stats_hb.add_theme_constant_override("separation", 12)
	r_vb.add_child(stats_hb)

	var d_col := VBoxContainer.new()
	d_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var d_cap := Label.new()
	d_cap.text = "DIVISI"
	d_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_cap.add_theme_font_size_override("font_size", 9)
	d_cap.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	var d_val := Label.new()
	d_val.text = "KE-%d" % int(club_entry["division"])
	d_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_val.add_theme_font_override("font", UITheme.get_display_font())
	d_val.add_theme_font_size_override("font_size", 18)
	d_val.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	d_col.add_child(d_cap)
	d_col.add_child(d_val)
	stats_hb.add_child(d_col)

	var vsep := ColorRect.new()
	vsep.custom_minimum_size = Vector2(1, 36)
	vsep.color = Color("#243A59")
	stats_hb.add_child(vsep)

	var p_col := VBoxContainer.new()
	p_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p_cap := Label.new()
	p_cap.text = "POS"
	p_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_cap.add_theme_font_size_override("font_size", 9)
	p_cap.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	var p_val := Label.new()
	p_val.text = "ke-%d/%d" % [int(club_entry["rank"]), int(club_entry["total_teams"])]
	p_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_val.add_theme_font_override("font", UITheme.get_display_font())
	p_val.add_theme_font_size_override("font_size", 17)
	p_val.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	p_col.add_child(p_cap)
	p_col.add_child(p_val)
	stats_hb.add_child(p_col)

	# Relation impact preview row (aligned right over LAMPU HIJAU, matching Gambar 8!)
	var imp_hb := HBoxContainer.new()
	imp_hb.alignment = BoxContainer.ALIGNMENT_END
	imp_hb.add_theme_constant_override("separation", 14)
	vb.add_child(imp_hb)
	for imp in [
		["whistle", str(int(club_entry.get("pen_pelatih", -6)))],
		["shirt", str(int(club_entry.get("pen_ruang", -4)))],
		["crowd", str(int(club_entry.get("pen_fans", -5)))],
	]:
		var ihb := HBoxContainer.new()
		ihb.add_theme_constant_override("separation", 4)
		var ic_w := CenterContainer.new()
		ic_w.add_child(make_icon(str(imp[0]), Color("#E2E8F0"), Vector2(13, 13)))
		ihb.add_child(ic_w)
		var il := Label.new()
		il.text = str(imp[1])
		il.add_theme_font_override("font", UITheme.get_display_font())
		il.add_theme_font_size_override("font_size", 13)
		il.add_theme_color_override("font_color", Color("#F87171"))
		ihb.add_child(il)
		imp_hb.add_child(ihb)

	# 2 Main Action Buttons: TAK TERTARIK (coral red) | LAMPU HIJAU (dark + red border)
	var act_hb := HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 10)
	vb.add_child(act_hb)

	var cid: int = int(club_entry["club_id"])
	var dec: String = str(club_entry.get("decision", ""))
	var tw_open: bool = bool(CareerState.get_transfer_window_status().get("is_open", false))

	var rej_b := Button.new()
	rej_b.text = "DITOLAK" if dec == "DECLINED" else "TAK TERTARIK"
	rej_b.custom_minimum_size = Vector2(0, 44)
	rej_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rej_b.disabled = (dec == "DECLINED")
	_style_btn(rej_b, Color("#D65550"), Color("#F2847F"), 12, UITheme.TEXT_WHITE, 3)
	rej_b.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.decide_watched_club_gossip(cid, false)
		layer.queue_free()
		if on_decided.is_valid():
			on_decided.call()
	)
	act_hb.add_child(rej_b)

	var grn_b := Button.new()
	var can_sign_now: bool = (tw_open and dec == "GREEN")
	grn_b.text = "TEKEN KONTRAK" if can_sign_now else ("✓ LAMPU HIJAU" if dec == "GREEN" else "LAMPU HIJAU")
	grn_b.custom_minimum_size = Vector2(0, 44)
	grn_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if can_sign_now:
		_style_btn(grn_b, Color("#155E3D"), UITheme.ACCENT_GREEN, 12, UITheme.TEXT_WHITE, 3)
	else:
		_style_btn(grn_b, Color("#080E18"), Color("#C82834"), 12, UITheme.ACCENT_GREEN if dec == "GREEN" else UITheme.TEXT_WHITE, 3)
	grn_b.pressed.connect(func():
		AudioSynth.play_click()
		if can_sign_now:
			var offer := _build_direct_offer(club_entry)
			layer.queue_free()
			if on_sign_offer.is_valid():
				on_sign_offer.call(offer)
		else:
			CareerState.decide_watched_club_gossip(cid, true)
			layer.queue_free()
			if on_decided.is_valid():
				on_decided.call()
	)
	act_hb.add_child(grn_b)

	# Bottom TUTUP bar
	var cls_b := Button.new()
	cls_b.text = "TUTUP"
	cls_b.custom_minimum_size = Vector2(0, 38)
	cls_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_btn(cls_b, Color("#1C314E"), Color("#2E486E"), 12, UITheme.TEXT_WHITE, 1)
	cls_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	vb.add_child(cls_b)
	return layer

static func _build_direct_offer(club_entry: Dictionary) -> Dictionary:
	var cid: int = int(club_entry["club_id"])
	var c: Dictionary = GameData.clubs[clampi(cid, 0, GameData.clubs.size() - 1)]
	var mv: int = int(CareerState.career["playerProfile"].get("marketValue", 1000000))
	return {
		"club_id": cid,
		"club_name": str(c["name"]),
		"nation": str(club_entry.get("nation_name", "LIGA")),
		"division": int(c["division"]),
		"ovr": int(c["ovr"]),
		"salary": maxi(1200, int(mv * 0.0022)),
		"years": 3,
		"tags": ["LAMPU HIJAU", "TARGET UTAMA"],
	}

# ==============================================================================
# 4. STATUSMU POP-UP (Gambar 6 Teal Button) & TAWARAN MASUK POP-UP
# ==============================================================================
static func open_status_popup(parent: Node) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(460, 270))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var p: Dictionary = CareerState.career["playerProfile"]
	var con: Dictionary = CareerState.career["contract"]
	var st: Dictionary = CareerState.career["stats"]
	var club: Dictionary = CareerState.get_current_club()

	var hl := Label.new()
	hl.text = "STATUSMU DI BURSA TRANSFER"
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 14)
	hl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	vb.add_child(hl)

	var rows := [
		["KLUB SAAT INI", "%s (KE-%d)" % [str(club["name"]), int(club["division"])], UITheme.TEXT_WHITE],
		["NILAI PASAR", UITheme.format_short_cash(int(p["marketValue"])), GOLD_TXT],
		["SISA KONTRAK", "PEMAIN BEBAS" if bool(con.get("isFreeAgent", false)) else "%d MUSIM" % int(con.get("yearsLeft", 1)), UITheme.ACCENT_GREEN if bool(con.get("isFreeAgent", false)) else UITheme.TEXT_WHITE],
		["KLAUSUL PRIBADI", str(con.get("clause", "NONE")), UITheme.ACCENT_CYAN],
		["PINDAH KLUB (PERGI)", "%d KALI" % int(st.get("transfers", 0)), UITheme.TEXT_WHITE],
		["PERCAYA AGEN", "%d / 100" % int(p["relations"].get("agen", 50)), GOLD_TXT],
	]
	for r in rows:
		var hb := HBoxContainer.new()
		var k_l := Label.new()
		k_l.text = str(r[0])
		k_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k_l.add_theme_font_size_override("font_size", 11)
		k_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		var v_l := Label.new()
		v_l.text = str(r[1])
		v_l.add_theme_font_override("font", UITheme.get_display_font())
		v_l.add_theme_font_size_override("font_size", 11)
		v_l.add_theme_color_override("font_color", r[2])
		hb.add_child(k_l)
		hb.add_child(v_l)
		vb.add_child(hb)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var cls_b := Button.new()
	cls_b.text = "TUTUP"
	cls_b.custom_minimum_size = Vector2(0, 38)
	_style_btn(cls_b, Color("#1C314E"), Color("#2E486E"), 12)
	cls_b.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls_b)
	return layer

static func open_offers_popup(parent: Node, on_sign_offer: Callable) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(600, 360))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	CareerState._refresh_transfer_offers()
	var offers: Array = CareerState.career.get("transferOffers", [])

	var hl := Label.new()
	hl.text = "TAWARAN KONTRAK MASUK (%d)" % offers.size()
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 14)
	hl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	vb.add_child(hl)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 6)
	sc.add_child(lvb)

	if offers.is_empty():
		var el := Label.new()
		el.text = "Belum ada tawaran masuk. Gunakan AGENMU untuk menawarkan dirimu!"
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lvb.add_child(el)
	else:
		for off in offers:
			var cp := PanelContainer.new()
			cp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1322"), Color("#1F334F"), 1, 6))
			lvb.add_child(cp)
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 10)
			cp.add_child(hb)
			var cr := ClubCrest.new()
			cr.custom_minimum_size = Vector2(36, 36)
			cr.set_club(int(off["club_id"]))
			hb.add_child(cr)
			var ivb := VBoxContainer.new()
			ivb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var t1 := Label.new()
			t1.text = "%s (%s • KE-%d)" % [str(off["club_name"]).to_upper(), str(off["nation"]), int(off["division"])]
			t1.add_theme_font_override("font", UITheme.get_display_font())
			t1.add_theme_font_size_override("font_size", 12)
			var t2 := Label.new()
			t2.text = "OVR %d • Gaji %s/laga • %d THN" % [int(off["ovr"]), format_cash_dots(int(off["salary"])), int(off["years"])]
			t2.add_theme_font_size_override("font_size", 10)
			t2.add_theme_color_override("font_color", GOLD_TXT)
			ivb.add_child(t1)
			ivb.add_child(t2)
			hb.add_child(ivb)
			var sb := Button.new()
			sb.text = "TEKEN"
			sb.custom_minimum_size = Vector2(82, 34)
			_style_btn(sb, Color("#155E3D"), UITheme.ACCENT_GREEN, 11, UITheme.TEXT_WHITE, 2)
			var off_copy: Dictionary = off
			sb.pressed.connect(func():
				AudioSynth.play_click()
				layer.queue_free()
				if on_sign_offer.is_valid():
					on_sign_offer.call(off_copy)
			)
			hb.add_child(sb)

	var cls_b := Button.new()
	cls_b.text = "TUTUP"
	cls_b.custom_minimum_size = Vector2(0, 38)
	_style_btn(cls_b, Color("#1C314E"), Color("#2E486E"), 12)
	cls_b.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls_b)
	return layer

# ==============================================================================
# INNER CLASSES: ESC LAYER, SPONSOR BRAND EMBLEM, BURSA PIXEL ICONS
# ==============================================================================
class EscCanvasLayer extends CanvasLayer:
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				AudioSynth.play_click()
				get_viewport().set_input_as_handled()
				queue_free()

class SponsorEmblemControl extends Control:
	var sponsor_id: String = "roti_lokal"

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		var r: float = minf(size.x, size.y) * 0.46
		match sponsor_id:
			"roti_lokal":
				draw_circle(Vector2(cx, cy), r, Color("#24180D"))
				draw_arc(Vector2(cx, cy), r, 0.0, TAU, 24, Color("#D98C36"), 2.0)
				draw_rect(Rect2(cx - r * 0.52, cy - r * 0.24, r * 1.04, r * 0.52), Color("#C97B2C"))
				for sl in [-0.26, 0.0, 0.26]:
					draw_line(Vector2(cx + r * sl - 2.0, cy - r * 0.16), Vector2(cx + r * sl + 2.0, cy + r * 0.18), Color("#4A250B"), 2.0)
			"kopi_kota":
				draw_circle(Vector2(cx, cy), r, Color("#1D1410"))
				draw_arc(Vector2(cx, cy), r, 0.0, TAU, 24, Color("#B47B48"), 2.0)
				draw_rect(Rect2(cx - r * 0.36, cy - r * 0.18, r * 0.62, r * 0.54), Color("#D4A373"))
				draw_arc(Vector2(cx + r * 0.28, cy + r * 0.06), r * 0.18, -PI * 0.5, PI * 0.5, 8, Color("#D4A373"), 2.0)
			"apparel_nord":
				draw_circle(Vector2(cx, cy), r, Color("#0E1F38"))
				draw_arc(Vector2(cx, cy), r, 0.0, TAU, 24, Color("#38BDF8"), 2.0)
				var pts := PackedVector2Array([Vector2(cx - r * 0.45, cy + r * 0.2), Vector2(cx + r * 0.45, cy - r * 0.25), Vector2(cx + r * 0.15, cy + r * 0.25)])
				draw_colored_polygon(pts, Color("#38BDF8"))
			"energy_volt":
				draw_circle(Vector2(cx, cy), r, Color("#1B240E"))
				draw_arc(Vector2(cx, cy), r, 0.0, TAU, 24, Color("#A3E635"), 2.0)
				var bolt := PackedVector2Array([Vector2(cx + 2, cy - r * 0.52), Vector2(cx - r * 0.32, cy + 2), Vector2(cx + 2, cy + 2), Vector2(cx - 4, cy + r * 0.52), Vector2(cx + r * 0.34, cy - 3), Vector2(cx, cy - 3)])
				draw_colored_polygon(bolt, Color("#FACC15"))
			_:
				draw_circle(Vector2(cx, cy), r, Color("#1E1233"))
				draw_arc(Vector2(cx, cy), r, 0.0, TAU, 24, Color("#A855F7"), 2.0)
				var dia := PackedVector2Array([Vector2(cx, cy - r * 0.48), Vector2(cx + r * 0.42, cy), Vector2(cx, cy + r * 0.48), Vector2(cx - r * 0.42, cy)])
				draw_colored_polygon(dia, Color("#C084FC"))

class MarketIconControl extends Control:
	var icon_kind: String = "lock"
	var icon_color: Color = Color("#CBD5E1")

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		var cy: float = h * 0.5
		var c: Color = icon_color
		match icon_kind:
			"lock":
				draw_rect(Rect2(w * 0.20, h * 0.44, w * 0.60, h * 0.46), c)
				draw_arc(Vector2(cx, h * 0.44), w * 0.20, PI, TAU, 10, c, 2.0)
			"unlock":
				draw_rect(Rect2(w * 0.20, h * 0.46, w * 0.60, h * 0.44), c)
				draw_arc(Vector2(cx + w * 0.08, h * 0.36), w * 0.20, PI, TAU * 0.88, 10, c, 2.0)
			"target":
				draw_line(Vector2(w * 0.14, h * 0.14), Vector2(w * 0.36, h * 0.14), c, 1.8)
				draw_line(Vector2(w * 0.14, h * 0.14), Vector2(w * 0.14, h * 0.36), c, 1.8)
				draw_line(Vector2(w * 0.86, h * 0.14), Vector2(w * 0.64, h * 0.14), c, 1.8)
				draw_line(Vector2(w * 0.86, h * 0.14), Vector2(w * 0.86, h * 0.36), c, 1.8)
				draw_line(Vector2(w * 0.14, h * 0.86), Vector2(w * 0.36, h * 0.86), c, 1.8)
				draw_line(Vector2(w * 0.14, h * 0.86), Vector2(w * 0.14, h * 0.64), c, 1.8)
				draw_line(Vector2(w * 0.86, h * 0.86), Vector2(w * 0.64, h * 0.86), c, 1.8)
				draw_line(Vector2(w * 0.86, h * 0.86), Vector2(w * 0.86, h * 0.64), c, 1.8)
			"globe":
				draw_arc(Vector2(cx, cy), minf(w, h) * 0.40, 0.0, TAU, 18, c, 1.6)
				draw_line(Vector2(w * 0.12, cy), Vector2(w * 0.88, cy), c, 1.2)
				draw_line(Vector2(cx, h * 0.12), Vector2(cx, h * 0.88), c, 1.2)
			"door":
				draw_rect(Rect2(w * 0.24, h * 0.12, w * 0.52, h * 0.76), c, false, 1.8)
				draw_circle(Vector2(w * 0.62, cy), 1.6, c)
			"bag":
				draw_rect(Rect2(w * 0.16, h * 0.34, w * 0.68, h * 0.52), c, false, 1.6)
				draw_rect(Rect2(w * 0.36, h * 0.16, w * 0.28, h * 0.18), c, false, 1.5)
			"headset":
				draw_arc(Vector2(cx, cy + 1.0), minf(w, h) * 0.36, PI, TAU, 12, c, 2.0)
				draw_rect(Rect2(w * 0.12, cy, w * 0.18, h * 0.32), c)
				draw_rect(Rect2(w * 0.70, cy, w * 0.18, h * 0.32), c)
			"doc":
				draw_rect(Rect2(w * 0.20, h * 0.12, w * 0.60, h * 0.76), c, false, 1.5)
				draw_line(Vector2(w * 0.32, h * 0.34), Vector2(w * 0.68, h * 0.34), c, 1.3)
				draw_line(Vector2(w * 0.32, h * 0.54), Vector2(w * 0.68, h * 0.54), c, 1.3)
				draw_line(Vector2(w * 0.32, h * 0.72), Vector2(w * 0.56, h * 0.72), c, 1.3)
			"tag":
				var pts := PackedVector2Array([Vector2(w * 0.14, h * 0.22), Vector2(w * 0.68, h * 0.22), Vector2(w * 0.88, cy), Vector2(w * 0.68, h * 0.78), Vector2(w * 0.14, h * 0.78)])
				draw_colored_polygon(pts, c)
			"whistle":
				draw_circle(Vector2(w * 0.38, h * 0.58), minf(w, h) * 0.26, c)
				draw_rect(Rect2(w * 0.44, h * 0.36, w * 0.42, h * 0.18), c)
			"shirt":
				var pts := PackedVector2Array([Vector2(w * 0.28, h * 0.16), Vector2(w * 0.72, h * 0.16), Vector2(w * 0.90, h * 0.38), Vector2(w * 0.74, h * 0.48), Vector2(w * 0.72, h * 0.86), Vector2(w * 0.28, h * 0.86), Vector2(w * 0.26, h * 0.48), Vector2(w * 0.10, h * 0.38)])
				draw_colored_polygon(pts, c)
			"crowd":
				draw_circle(Vector2(cx, h * 0.30), minf(w, h) * 0.16, c)
				draw_circle(Vector2(w * 0.24, h * 0.42), minf(w, h) * 0.13, c)
				draw_circle(Vector2(w * 0.76, h * 0.42), minf(w, h) * 0.13, c)
				draw_rect(Rect2(w * 0.32, h * 0.52, w * 0.36, h * 0.34), c)
				draw_rect(Rect2(w * 0.10, h * 0.60, w * 0.22, h * 0.26), c)
				draw_rect(Rect2(w * 0.68, h * 0.60, w * 0.22, h * 0.26), c)
			"calendar":
				draw_rect(Rect2(w * 0.14, h * 0.22, w * 0.72, h * 0.66), c, false, 1.5)
				draw_rect(Rect2(w * 0.14, h * 0.22, w * 0.72, h * 0.22), c)
			_:
				draw_circle(Vector2(cx, cy), minf(w, h) * 0.32, c)
