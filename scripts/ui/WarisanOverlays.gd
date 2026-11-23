extends RefCounted

const BG_DARK := Color("#060D1A")
const BG_MODAL := Color("#132540")
const BORDER_MODAL := Color("#36537C")
const GOLD_TXT := Color("#F5C430")
const AMBER_TXT := Color("#E59A38")

static func format_comma(val: float, decimals: int = 1) -> String:
	var fmt: String = "%." + str(decimals) + "f"
	return (fmt % val).replace(".", ",")

static func format_mv_short(val_dollars: int) -> String:
	if val_dollars >= 1000000:
		return "$%s M" % format_comma(float(val_dollars) / 1000000.0, 1)
	if val_dollars >= 1000:
		return "$%d K" % int(round(float(val_dollars) / 1000.0))
	return "$%d" % maxi(0, val_dollars)

static func make_icon(kind: String, col: Color = Color("#E2E8F0"), sz: Vector2 = Vector2(16, 16)) -> Control:
	var c := WarisanIconControl.new()
	c.icon_kind = kind
	c.icon_color = col
	c.custom_minimum_size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func make_club_mini_crest(entry: Dictionary, sz: Vector2 = Vector2(16, 16)) -> Control:
	var cid: int = int(entry.get("club_id", -1))
	if cid >= 0 and cid < GameData.clubs.size():
		var cr := ClubCrest.new()
		cr.custom_minimum_size = sz
		cr.set_club(cid)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return cr
	var mc := MiniWorldCrest.new()
	mc.pri_col = UITheme.parse_color(entry.get("pri", Color("#2563EB")), Color("#2563EB"))
	mc.sec_col = UITheme.parse_color(entry.get("sec", Color("#FFFFFF")), Color("#FFFFFF"))
	mc.pattern = str(entry.get("pat", "solid"))
	mc.custom_minimum_size = sz
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mc

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
	h.border_color = UITheme.ACCENT_CYAN
	var pr := n.duplicate()
	pr.bg_color = bg.darkened(0.08)
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

static func _create_modal_layer(parent: Node, box_sz: Vector2, bg_col: Color = BG_MODAL, layer_num: int = 20, pad_x: int = 18, pad_y: int = 14) -> Dictionary:
	var layer := EscCanvasLayer.new()
	layer.layer = layer_num
	parent.add_child(layer)

	var root := Control.new()
	root.theme = UITheme.build_theme()
	root.clip_contents = true
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.07, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := PanelContainer.new()
	box.custom_minimum_size = box_sz
	box.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = BORDER_MODAL
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	box.add_theme_stylebox_override("panel", sb)
	center.add_child(box)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	box.add_child(vb)
	return {"layer": layer, "root": root, "box": box, "vb": vb}

# ==============================================================================
# 1. CLUB CATEGORY POPUP: LIGA (Gambar 14), PIALA (Gambar 15), KONTINENTAL
# ==============================================================================
static func open_club_category_popup(parent: Node, category_key: String, ranking_data: Dictionary) -> CanvasLayer:
	var title_map := {"liga": "LIGA", "piala": "PIALA", "kont": "KONTINENTAL"}
	var icon_map := {"liga": "liga", "piala": "piala", "kont": "kont"}
	var icon_col_map := {"liga": Color("#CBD5E1"), "piala": Color("#F5C430"), "kont": Color("#60A5FA")}
	var title_txt: String = str(title_map.get(category_key, "LIGA"))
	var leaders: Dictionary = ranking_data.get("leaders", {})
	var cat_data: Dictionary = leaders.get(category_key, {})
	var rows: Array = cat_data.get("list", [])
	var my_entry: Dictionary = ranking_data.get("my_entry", {})
	var my_rank: int = int(cat_data.get("my_rank", 50))
	var my_val: int = int(cat_data.get("my_val", 0))

	var built: Dictionary = _create_modal_layer(parent, Vector2(416, 376))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	# Title + Right Icon Header
	var ttl := Label.new()
	ttl.text = title_txt
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 16)
	ttl.add_theme_color_override("font_color", AMBER_TXT)
	vb.add_child(ttl)

	var ic_row := HBoxContainer.new()
	vb.add_child(ic_row)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic_row.add_child(sp)
	ic_row.add_child(make_icon(str(icon_map.get(category_key, "liga")), icon_col_map.get(category_key, GOLD_TXT), Vector2(14, 14)))

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 3)
	vb.add_child(list_vb)

	var user_shown_in_top10: bool = false
	var show_n: int = mini(10, rows.size())
	var prev_val: int = -1
	var disp_rk: int = 1
	for i in range(show_n):
		var r: Dictionary = rows[i]
		var v: int = int(r.get(category_key, 0))
		if i > 0 and v != prev_val:
			disp_rk = i + 1
		prev_val = v
		var is_me: bool = bool(r.get("is_user_club", false))
		if is_me:
			user_shown_in_top10 = true
		list_vb.add_child(_make_cat_popup_row(disp_rk, r, v, is_me))

	if not user_shown_in_top10 and not my_entry.is_empty():
		var dots := Label.new()
		dots.text = "    . . ."
		dots.add_theme_font_size_override("font_size", 10)
		dots.add_theme_color_override("font_color", Color("#64748B"))
		list_vb.add_child(dots)
		list_vb.add_child(_make_cat_popup_row(my_rank, my_entry, my_val, true))

	var close_b := Button.new()
	close_b.text = "X  TUTUP"
	close_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	close_b.custom_minimum_size = Vector2(0, 38)
	_style_btn(close_b, Color("#404F63"), Color("#6A7D94"), 11, UITheme.TEXT_WHITE, 2)
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	vb.add_child(close_b)
	return layer

static func _make_cat_popup_row(rank_num: int, entry: Dictionary, val: int, highlight: bool) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#344357") if highlight else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	pc.add_child(hb)

	var rl := Label.new()
	rl.text = str(rank_num)
	rl.custom_minimum_size = Vector2(28, 0)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rl.add_theme_font_override("font", UITheme.get_display_font())
	rl.add_theme_font_size_override("font_size", 11)
	rl.add_theme_color_override("font_color", Color("#CBD5E1") if highlight else Color("#94A3B8"))
	hb.add_child(rl)

	var cc := CenterContainer.new()
	cc.add_child(make_club_mini_crest(entry, Vector2(15, 15)))
	hb.add_child(cc)

	var nl := Label.new()
	nl.text = str(entry.get("name", "Klub"))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	nl.add_theme_font_override("font", UITheme.get_display_font())
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	hb.add_child(nl)

	var vl := Label.new()
	vl.text = str(val)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_override("font", UITheme.get_display_font())
	vl.add_theme_font_size_override("font_size", 12)
	vl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	hb.add_child(vl)
	return pc

# ==============================================================================
# 2. LEGENDA FULLSCREEN HALL OF FAME TOP 30 (Gambar 7)
# ==============================================================================
static func open_legends_overlay(parent: Node) -> CanvasLayer:
	var layer := EscCanvasLayer.new()
	layer.layer = 20
	parent.add_child(layer)

	var root := Control.new()
	root.theme = UITheme.build_theme()
	root.clip_contents = true
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color("#060D1A")
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var sp_l := Control.new()
	sp_l.custom_minimum_size = Vector2(96, 0)
	hdr.add_child(sp_l)

	var ttl := Label.new()
	ttl.text = "LEGENDA"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 18)
	ttl.add_theme_color_override("font_color", AMBER_TXT)
	hdr.add_child(ttl)

	var back_b := Button.new()
	back_b.text = "KEMBALI"
	back_b.custom_minimum_size = Vector2(96, 34)
	_style_btn(back_b, Color("#122036"), Color("#2A4166"), 11, UITheme.TEXT_WHITE, 1)
	back_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	hdr.add_child(back_b)

	build_legends_table_into(vb)
	return layer

static func build_legends_table_into(parent_vb: VBoxContainer) -> void:
	# Centered column (max ~380px wide) matching Gambar 7 cleanly!
	var center_hb := HBoxContainer.new()
	center_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	parent_vb.add_child(center_hb)

	var col_vb := VBoxContainer.new()
	col_vb.custom_minimum_size = Vector2(390, 0)
	col_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_vb.add_theme_constant_override("separation", 3)
	center_hb.add_child(col_vb)

	var cap_hb := HBoxContainer.new()
	col_vb.add_child(cap_hb)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_hb.add_child(sp)
	var gl_cap := Label.new()
	gl_cap.text = "GELAR"
	gl_cap.add_theme_font_size_override("font_size", 9)
	gl_cap.add_theme_color_override("font_color", Color("#7C90AB"))
	cap_hb.add_child(gl_cap)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col_vb.add_child(sc)

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 2)
	sc.add_child(list_vb)

	var sorted_leg: Array[Dictionary] = []
	for lg in GameData.world_legends:
		sorted_leg.append(lg)
	sorted_leg.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ta: int = int(a.get("indiv", 0)) + int(a.get("team", 0))
		var tb: int = int(b.get("indiv", 0)) + int(b.get("team", 0))
		if ta != tb:
			return ta > tb
		return int(a.get("goals", 0)) > int(b.get("goals", 0))
	)

	var show_n: int = mini(30, sorted_leg.size())
	for i in range(show_n):
		var lg: Dictionary = sorted_leg[i]
		var tot_t: int = int(lg.get("indiv", 0)) + int(lg.get("team", 0))
		list_vb.add_child(_make_legend_row(str(i + 1), int(lg.get("nat", 0)), str(lg.get("name", "Legenda")).to_upper(), tot_t, false))

	# Sticky highlighted bottom row for User Player (Gambar 7!)
	if CareerState.has_active_career:
		var p: Dictionary = CareerState.career["playerProfile"]
		var u_trophies: int = int(CareerState.career["stats"].get("trophies", 0))
		var u_rk_str: String = "-"
		for i in range(show_n):
			var tot_t: int = int(sorted_leg[i].get("indiv", 0)) + int(sorted_leg[i].get("team", 0))
			if u_trophies >= tot_t and u_trophies > 0:
				u_rk_str = str(i + 1)
				break
		col_vb.add_child(_make_legend_row(u_rk_str, int(p.get("nationId", 16)), str(p.get("name", "PEMAIN")).to_upper(), u_trophies, true))

static func _make_legend_row(rk_str: String, nat_id: int, nm_up: String, titles: int, is_user: bool) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#3F301F") if is_user else Color(0, 0, 0, 0)
	sb.border_color = Color("#8A6533") if is_user else Color.TRANSPARENT
	sb.set_border_width_all(1 if is_user else 0)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	pc.add_child(hb)

	var rl := Label.new()
	rl.text = rk_str
	rl.custom_minimum_size = Vector2(22, 0)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rl.add_theme_font_override("font", UITheme.get_display_font())
	rl.add_theme_font_size_override("font_size", 10)
	rl.add_theme_color_override("font_color", AMBER_TXT if is_user else Color("#7C90AB"))
	hb.add_child(rl)

	var fc := CenterContainer.new()
	fc.add_child(UITheme.make_flag_rect(nat_id, Vector2(18, 12)))
	hb.add_child(fc)

	var nl := Label.new()
	nl.text = nm_up
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	nl.add_theme_font_override("font", UITheme.get_display_font())
	nl.add_theme_font_size_override("font_size", 10)
	nl.add_theme_color_override("font_color", Color("#F8FAFC"))
	hb.add_child(nl)

	var vl := Label.new()
	vl.text = str(titles)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_override("font", UITheme.get_display_font())
	vl.add_theme_font_size_override("font_size", 11)
	vl.add_theme_color_override("font_color", GOLD_TXT if is_user else Color("#E2E8F0"))
	hb.add_child(vl)
	return pc

# ==============================================================================
# 3. BUKU REKOR POPUP (Gambar 12), PERJALANAN LAIN, KEMITRAAN, BOLA GALA & JUARA
# ==============================================================================
static func open_record_book_popup(parent: Node, summary: Dictionary) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(540, 340))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var ttl := Label.new()
	ttl.text = "BUKU REKOR  •  LIGA • KLUB • DUNIA"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 14)
	ttl.add_theme_color_override("font_color", GOLD_TXT)
	vb.add_child(ttl)

	var st: Dictionary = CareerState.career.get("stats", {}) if CareerState.has_active_career else {}
	var rows := [
		["GOL TERBANYAK 1 LAGA", "%d GOL" % int(st.get("bestMatchGoals", 0)), "KLUB"],
		["RATING TERTINGGI", format_comma(float(summary.get("best_rating", 0.0)), 1), "LIGA"],
		["GOL TERJAUH", "%s m" % format_comma(float(summary.get("longest_goal_m", 0.0)), 1), "KLUB"],
		["UMPAN TERJAUH", "%s m" % format_comma(float(summary.get("longest_pass_m", 0.0)), 1), "KLUB"],
		["TOTAL GOL KARIER", "%d GOL" % int(summary.get("goals", 0)), "DUNIA"],
		["TOTAL ASSIST KARIER", "%d AST" % int(summary.get("assists", 0)), "DUNIA"],
		["BINTANG LAGA (MOTM)", "%d KALI" % int(st.get("motm", 0)), "LIGA"],
		["PENALTI SUKSES", "%d GOL" % int(st.get("penaltiesScored", 0)), "KLUB"],
	]
	for rd in rows:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1628"), Color("#1E3352"), 1, 4))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		pc.add_child(hb)
		var tag := Label.new()
		tag.text = str(rd[2])
		tag.custom_minimum_size = Vector2(54, 0)
		tag.add_theme_font_override("font", UITheme.get_display_font())
		tag.add_theme_font_size_override("font_size", 9)
		tag.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		var nm := Label.new()
		nm.text = str(rd[0])
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.add_theme_font_size_override("font_size", 11)
		var vl := Label.new()
		vl.text = str(rd[1])
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 12)
		vl.add_theme_color_override("font_color", GOLD_TXT)
		hb.add_child(tag)
		hb.add_child(nm)
		hb.add_child(vl)
		vb.add_child(pc)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 38)
	_style_btn(cls, Color("#0E1A2D"), Color("#2E466B"), 12)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)
	return layer

static func open_journey_popup(parent: Node, summary: Dictionary) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(520, 310))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var ttl := Label.new()
	ttl.text = "PERJALANANMU  •  RIWAYAT KLUB"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 14)
	ttl.add_theme_color_override("font_color", GOLD_TXT)
	vb.add_child(ttl)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 6)
	sc.add_child(lvb)

	for jc in summary.get("journey_clubs", []):
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1628"), Color("#21385A"), 1, 5))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		pc.add_child(hb)
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(24, 24)
		cr.set_club(int(jc.get("club_id", 0)))
		hb.add_child(cr)
		var nl := Label.new()
		nl.text = "%s  (%s)" % [str(jc.get("name", "Klub")), str(jc.get("season_span", "M1"))]
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.add_theme_font_override("font", UITheme.get_display_font())
		nl.add_theme_font_size_override("font_size", 11)
		hb.add_child(nl)
		var sl := Label.new()
		sl.text = "MN %d  •  G %d  •  A %d" % [int(jc.get("matches", 0)), int(jc.get("goals", 0)), int(jc.get("assists", 0))]
		sl.add_theme_font_size_override("font_size", 11)
		sl.add_theme_color_override("font_color", GOLD_TXT)
		hb.add_child(sl)
		lvb.add_child(pc)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 38)
	_style_btn(cls, Color("#0E1A2D"), Color("#2E466B"), 12)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)
	return layer

static func open_kemitraan_popup(parent: Node) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(540, 330))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var ttl := Label.new()
	ttl.text = "KEMITRAAN  •  DUO REKAN SETIM"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 14)
	ttl.add_theme_color_override("font_color", AMBER_TXT)
	vb.add_child(ttl)

	var starters: Array = CareerState.career.get("clubSquad", {}).get("starters", []) if CareerState.has_active_career else []
	var rg_val: int = int(CareerState.career.get("playerProfile", {}).get("relations", {}).get("ruangGanti", 60)) if CareerState.has_active_career else 60
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 5)
	sc.add_child(lvb)

	var cnt: int = 0
	for pl in starters:
		if bool(pl.get("is_user", false)) or str(pl.get("pos", "")) == "GK":
			continue
		cnt += 1
		var chem: int = clampi(rg_val + ((cnt * 7) % 18) - 6, 35, 100)
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1628"), Color("#203657"), 1, 5))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		pc.add_child(hb)
		var pos_l := Label.new()
		pos_l.text = str(pl.get("pos", "CM"))
		pos_l.custom_minimum_size = Vector2(36, 0)
		pos_l.add_theme_font_override("font", UITheme.get_display_font())
		pos_l.add_theme_font_size_override("font_size", 10)
		pos_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		var nm := Label.new()
		nm.text = str(pl.get("name", "Rekan"))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.add_theme_font_override("font", UITheme.get_display_font())
		nm.add_theme_font_size_override("font_size", 11)
		var st_l := Label.new()
		st_l.text = "SINERGI %d%%  •  OVR %d" % [chem, int(pl.get("ovr", 62))]
		st_l.add_theme_font_size_override("font_size", 10)
		st_l.add_theme_color_override("font_color", Color("#4ADE80") if chem >= 75 else GOLD_TXT)
		hb.add_child(pos_l)
		hb.add_child(nm)
		hb.add_child(st_l)
		lvb.add_child(pc)
		if cnt >= 6:
			break

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 38)
	_style_btn(cls, Color("#0E1A2D"), Color("#2E466B"), 12)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)
	return layer

static func open_bola_gala_popup(parent: Node) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(600, 356))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var gala_d: Dictionary = CareerState.get_ballon_gala_preview_data() if CareerState.has_active_career else {}
	var cal_yr: int = int(gala_d.get("year", 2026))
	var bd_list: Array = gala_d.get("ballon_top10", [])
	var y_list: Array = gala_d.get("youth_top10", [])

	var ttl := Label.new()
	ttl.text = "BALLON D'OR %d  •  GALA OKTOBER MINGGU TERAKHIR" % cal_yr
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 14)
	ttl.add_theme_color_override("font_color", GOLD_TXT)
	vb.add_child(ttl)

	var pod := HBoxContainer.new()
	pod.alignment = BoxContainer.ALIGNMENT_CENTER
	pod.add_theme_constant_override("separation", 10)
	vb.add_child(pod)

	var pod_order: Array[int] = [1, 0, 2]
	var pod_styles: Array = [
		[Color("#253348"), Color("#94A3B8")],
		[Color("#4B3A12"), GOLD_TXT],
		[Color("#3E2718"), Color("#D97706")],
	]
	for pi in range(3):
		var ridx: int = pod_order[pi]
		var st_arr: Array = pod_styles[pi]
		var nm_s: String = "#%d ---" % (ridx + 1)
		var pts_s: String = "0 PTS"
		var cl_s: String = "Kandidat Dunia"
		if ridx < bd_list.size() and bd_list[ridx] is Dictionary:
			var ent: Dictionary = bd_list[ridx]
			nm_s = "#%d %s" % [ridx + 1, str(ent.get("name", "---"))]
			pts_s = "%d PTS" % int(ent.get("points", 0))
			cl_s = "%s (%dG/%dA)" % [str(ent.get("club_name", "Klub")), int(ent.get("goals", 0)), int(ent.get("assists", 0))]

		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pc.custom_minimum_size = Vector2(0, 108)
		pc.add_theme_stylebox_override("panel", UITheme.make_box(st_arr[0], st_arr[1], 2, 6))
		var ivb := VBoxContainer.new()
		ivb.alignment = BoxContainer.ALIGNMENT_CENTER
		ivb.add_theme_constant_override("separation", 3)
		pc.add_child(ivb)
		var l1 := Label.new()
		l1.text = nm_s
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l1.clip_text = true
		l1.add_theme_font_override("font", UITheme.get_display_font())
		l1.add_theme_font_size_override("font_size", 11)
		var l_cl := Label.new()
		l_cl.text = cl_s
		l_cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_cl.clip_text = true
		l_cl.add_theme_font_size_override("font_size", 10)
		l_cl.add_theme_color_override("font_color", Color("#CBD5E1"))
		var l2 := Label.new()
		l2.text = pts_s
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.add_theme_font_override("font", UITheme.get_display_font())
		l2.add_theme_font_size_override("font_size", 14)
		l2.add_theme_color_override("font_color", st_arr[1])
		ivb.add_child(l1)
		ivb.add_child(l_cl)
		ivb.add_child(l2)
		pod.add_child(pc)

	var sub := Label.new()
	sub.text = "▸ PEMAIN MUDA TERBAIK (U-21)"
	sub.add_theme_font_override("font", UITheme.get_display_font())
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	vb.add_child(sub)

	var y_parts: PackedStringArray = []
	for yi in range(mini(3, y_list.size())):
		if y_list[yi] is Dictionary:
			var ye: Dictionary = y_list[yi]
			y_parts.append("%d. %s (%dth, %d PTS)" % [yi + 1, str(ye.get("name", "---")), int(ye.get("age", 19)), int(ye.get("points", 0))])
	var y_line: String = "  •  ".join(y_parts) if not y_parts.is_empty() else "Belum ada nominasi U-21 tercatat."

	var note := Label.new()
	note.text = "%s\nMalam Gala digelar otomatis setiap Oktober minggu terakhir: Ballon d'Or terlebih dahulu, disusul Pemain Muda Terbaik (U-21)." % y_line
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(note)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 10)
	vb.add_child(btn_hb)

	var play_btn := Button.new()
	play_btn.text = "TONTON ANIMASI GALA"
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_btn.custom_minimum_size = Vector2(0, 40)
	_style_btn(play_btn, Color("#523C10"), GOLD_TXT, 12, Color("#FEF08A"), 3)
	play_btn.pressed.connect(func():
		AudioSynth.play_click()
		var host_parent: Node = layer.get_parent()
		layer.queue_free()
		if host_parent != null:
			open_ballon_gala_ceremony(host_parent, gala_d)
	)
	btn_hb.add_child(play_btn)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(128, 40)
	_style_btn(cls, Color("#0E1A2D"), Color("#2E466B"), 12)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	btn_hb.add_child(cls)
	return layer

static func open_ballon_gala_ceremony(parent: Node, gala_data: Dictionary = {}) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 22
	parent.add_child(layer)
	var scr: GDScript = load("res://scenes/modals/BallonGalaModal.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		layer.queue_free()
		return null
	var gm: Control = scr.new()
	var payload: Dictionary = gala_data if not gala_data.is_empty() else (CareerState.get_ballon_gala_preview_data() if CareerState.has_active_career else {})
	gm.call("configure", payload)
	gm.set_anchors_preset(Control.PRESET_FULL_RECT)
	gm.connect("finished", func():
		if is_instance_valid(layer):
			layer.queue_free()
	)
	layer.add_child(gm)
	return layer

static func open_champions_popup(parent: Node) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(500, 320))
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var ttl := Label.new()
	ttl.text = "JUARA  •  KLUB PALING DOMINAN"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 14)
	ttl.add_theme_color_override("font_color", AMBER_TXT)
	vb.add_child(ttl)

	var items := [
		["LIGA SPANYOL", "Madrid Blanco", "37 GELAR"],
		["LIGA INGGRIS", "Liverpool Reds", "20 GELAR"],
		["LIGA JERMAN", "Munchen Rote", "35 GELAR"],
		["LIGA ITALIA", "Torino Bianconeri", "36 GELAR"],
		["PIALA ELITE", "Madrid Blanco", "15 GELAR"],
		["DUNIA", "Glasgow Hoops", "99 TOTAL"],
	]
	for it in items:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1628"), Color("#1E3352"), 1, 4))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		pc.add_child(hb)
		var l1 := Label.new()
		l1.text = str(it[0])
		l1.custom_minimum_size = Vector2(126, 0)
		l1.add_theme_font_size_override("font_size", 10)
		l1.add_theme_color_override("font_color", Color("#94A3B8"))
		var l2 := Label.new()
		l2.text = str(it[1])
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.add_theme_font_override("font", UITheme.get_display_font())
		l2.add_theme_font_size_override("font_size", 11)
		var l3 := Label.new()
		l3.text = str(it[2])
		l3.add_theme_font_override("font", UITheme.get_display_font())
		l3.add_theme_font_size_override("font_size", 11)
		l3.add_theme_color_override("font_color", GOLD_TXT)
		hb.add_child(l1)
		hb.add_child(l2)
		hb.add_child(l3)
		vb.add_child(pc)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 38)
	_style_btn(cls, Color("#0E1A2D"), Color("#2E466B"), 12)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)
	return layer

# ==============================================================================
# CUSTOM VISUAL CONTROLS: ICONS, PERSPECTIVE SHOT/PASS MAP, DRIBBLE HEATMAP
# ==============================================================================
class EscCanvasLayer extends CanvasLayer:
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				AudioSynth.play_click()
				get_viewport().set_input_as_handled()
				queue_free()

class MiniWorldCrest extends Control:
	var pri_col: Color = Color("#2563EB")
	var sec_col: Color = Color("#FFFFFF")
	var pattern: String = "solid"
	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.45
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		draw_circle(c, r + 0.8, Color("#CBD5E1"))
		draw_circle(c, r, pri_col)
		if pattern == "stripes":
			draw_rect(Rect2(c.x - r * 0.25, c.y - r * 0.75, r * 0.50, r * 1.50), sec_col, true)
		elif pattern == "hoops":
			draw_rect(Rect2(c.x - r * 0.78, c.y - r * 0.24, r * 1.56, r * 0.48), sec_col, true)
		elif pattern == "sash":
			draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), sec_col, 2.2)
		else:
			draw_circle(c, r * 0.36, sec_col)

class PitchTelemetryCanvas extends Control:
	signal point_selected(pt: Dictionary)
	var mode: String = "SHOT"  # SHOT or UMPAN
	var points: Array = []
	var selected_idx: int = -1

	func configure(p_mode: String, pts: Array) -> void:
		mode = p_mode
		points = pts
		selected_idx = -1
		queue_redraw()

	func _pitch_to_screen(px: float, py: float) -> Vector2:
		# Perspective trapezoid matching Gambar 9 (narrower at goal line top, wider near bottom!)
		var top_y: float = size.y * 0.22
		var bot_y: float = size.y * 0.96
		var t_depth: float = clampf(1.0 - clampf(py, 0.05, 0.98), 0.0, 1.0)
		var y: float = lerpf(top_y, bot_y, t_depth)
		var half_w: float = lerpf(size.x * 0.36, size.x * 0.50, t_depth)
		var x: float = size.x * 0.5 + (clampf(px, 0.02, 0.98) - 0.5) * 2.0 * half_w
		return Vector2(x, y)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var best_i: int = -1
			var best_d: float = 16.0
			for i in range(points.size()):
				var pc: Dictionary = points[i].get("pitchCoord", {"x": 0.5, "y": 0.7})
				var sp: Vector2 = _pitch_to_screen(float(pc.get("x", 0.5)), float(pc.get("y", 0.7)))
				var d: float = sp.distance_to(event.position)
				if d < best_d:
					best_d = d
					best_i = i
			if best_i >= 0:
				selected_idx = best_i
				queue_redraw()
				point_selected.emit(points[best_i])

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 10.0 or h <= 10.0:
			return
		# Stadium stands banner at top (Gambar 9 look!)
		draw_rect(Rect2(0, 0, w, h * 0.22), Color("#353944"), true)
		for si in range(0, int(w), 12):
			draw_rect(Rect2(float(si) + 2.0, 4.0, 6.0, 4.0), Color("#64748B") if (si % 24 == 0) else Color("#94A3B8"), true)
			draw_rect(Rect2(float(si) + 4.0, 12.0, 5.0, 4.0), Color("#475569"), true)
		draw_rect(Rect2(0, h * 0.17, w, h * 0.05), Color("#1E293B"), true)

		# Green striped perspective pitch
		draw_rect(Rect2(0, h * 0.22, w, h * 0.78), Color("#266B36"), true)
		for st_i in range(6):
			var frac0: float = float(st_i) / 6.0
			var frac1: float = float(st_i + 1) / 6.0
			if st_i % 2 == 0:
				var p0: Vector2 = _pitch_to_screen(frac0, 0.98)
				var p1: Vector2 = _pitch_to_screen(frac1, 0.98)
				var p2: Vector2 = _pitch_to_screen(frac1, 0.02)
				var p3: Vector2 = _pitch_to_screen(frac0, 0.02)
				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color("#2F7B40"))

		# White pitch lines (touchlines, goal line, penalty box, 6-yard box, penalty arc, goal posts)
		var lc := Color(0.92, 0.96, 0.94, 0.80)
		var tl: Vector2 = _pitch_to_screen(0.02, 0.98)
		var tr: Vector2 = _pitch_to_screen(0.98, 0.98)
		var bl: Vector2 = _pitch_to_screen(0.02, 0.04)
		var br: Vector2 = _pitch_to_screen(0.98, 0.04)
		draw_polyline(PackedVector2Array([bl, tl, tr, br]), lc, 1.5)

		# Penalty box
		var ptl: Vector2 = _pitch_to_screen(0.22, 0.98)
		var ptr: Vector2 = _pitch_to_screen(0.78, 0.98)
		var pbl: Vector2 = _pitch_to_screen(0.22, 0.62)
		var pbr: Vector2 = _pitch_to_screen(0.78, 0.62)
		draw_polyline(PackedVector2Array([ptl, pbl, pbr, ptr]), lc, 1.5)

		# 6-yard box
		var stl: Vector2 = _pitch_to_screen(0.36, 0.98)
		var str_: Vector2 = _pitch_to_screen(0.64, 0.98)
		var sbl: Vector2 = _pitch_to_screen(0.36, 0.84)
		var sbr: Vector2 = _pitch_to_screen(0.64, 0.84)
		draw_polyline(PackedVector2Array([stl, sbl, sbr, str_]), lc, 1.3)

		# Penalty spot & arc
		var pspot: Vector2 = _pitch_to_screen(0.50, 0.74)
		draw_circle(pspot, 2.0, lc)
		draw_arc(Vector2(w * 0.5, pbl.y - 2.0), w * 0.10, 0.15, PI - 0.15, 16, lc, 1.4)

		# Goal frame at top center
		var g_l: Vector2 = _pitch_to_screen(0.41, 0.98)
		var g_r: Vector2 = _pitch_to_screen(0.59, 0.98)
		var g_h: float = 13.0
		draw_rect(Rect2(g_l.x, g_l.y - g_h, g_r.x - g_l.x, g_h), Color(0.95, 0.98, 1.0, 0.18), true)
		draw_polyline(PackedVector2Array([
			g_l, Vector2(g_l.x, g_l.y - g_h), Vector2(g_r.x, g_r.y - g_h), g_r
		]), Color.WHITE, 2.0)

		# Draw pass lines (UMPAN) and dots (SHOT / UMPAN)
		for i in range(points.size()):
			var pt: Dictionary = points[i]
			var pc: Dictionary = pt.get("pitchCoord", {"x": 0.5, "y": 0.72})
			var to_p: Vector2 = _pitch_to_screen(float(pc.get("x", 0.5)), float(pc.get("y", 0.72)))
			var out_s: String = str(pt.get("outcome", "ON_TARGET"))
			var is_sel: bool = (i == selected_idx)

			if mode == "UMPAN":
				var fc: Dictionary = pt.get("fromCoord", {"x": 0.35, "y": 0.48})
				var from_p: Vector2 = _pitch_to_screen(float(fc.get("x", 0.35)), float(fc.get("y", 0.48)))
				var line_c: Color = Color(0.96, 0.77, 0.19, 0.48 if not is_sel else 0.95) if out_s == "ASSIST" else Color(0.92, 0.95, 0.98, 0.24 if not is_sel else 0.80)
				draw_line(from_p, to_p, line_c, 2.0 if is_sel else 1.1, true)
				if out_s == "ASSIST":
					draw_circle(to_p, 5.2 if is_sel else 4.2, Color("#0A1220"))
					draw_circle(to_p, 4.0 if is_sel else 3.2, Color("#F5C430"))
				else:
					draw_arc(to_p, 4.0 if is_sel else 3.0, 0.0, TAU, 12, Color("#E2E8F0"), 1.4)
			else:
				var col: Color = Color("#F5C430") if out_s == "GOAL" else (Color("#E2E8F0") if out_s == "ON_TARGET" else Color("#EF4444"))
				var rad: float = 5.5 if is_sel else 4.2
				draw_circle(to_p, rad + 1.3, Color("#09111E"))
				draw_circle(to_p, rad, col)
			if is_sel:
				draw_arc(to_p, 8.5, 0.0, TAU, 16, Color("#38BDF8"), 2.0)

		draw_rect(Rect2(0.5, 0.5, w - 1.0, h - 1.0), Color("#385A45"), false, 1.0)

class DribbleHeatmapCanvas extends Control:
	var heat: Array = []
	var grid_w: int = 16
	var grid_h: int = 10
	var lost_pts: Array = []

	func configure(h_grid: Array, gw: int, gh: int, lost: Array) -> void:
		heat = h_grid
		grid_w = maxi(1, gw)
		grid_h = maxi(1, gh)
		lost_pts = lost
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 10.0 or h <= 10.0:
			return
		# Striped horizontal full pitch (Gambar 10 & 11!)
		var stripes: int = 10
		var sw: float = w / float(stripes)
		for i in range(stripes):
			var c: Color = Color("#1F5A2E") if i % 2 == 0 else Color("#266736")
			draw_rect(Rect2(float(i) * sw, 0, sw + 0.5, h), c, true)

		# Cyan-teal translucent dribble heatmap tiles
		var max_h: float = 1.0
		for row in heat:
			for v in row:
				max_h = maxf(max_h, float(v))
		var cw: float = w / float(grid_w)
		var ch: float = h / float(grid_h)
		for gy in range(mini(grid_h, heat.size())):
			var row: Array = heat[gy]
			for gx in range(mini(grid_w, row.size())):
				var val: float = float(row[gx])
				if val <= 0.01:
					continue
				var inten: float = clampf(val / max_h, 0.15, 1.0)
				var col: Color = Color("#2AA3B8").lerp(Color("#4DD4EC"), inten)
				col.a = lerpf(0.16, 0.62, inten)
				draw_rect(Rect2(float(gx) * cw, float(gy) * ch, cw + 0.5, ch + 0.5), col, true)

		# Crisp white pitch markings
		var lc := Color(0.88, 0.95, 0.90, 0.62)
		var pad: float = 4.0
		draw_rect(Rect2(pad, pad, w - pad * 2.0, h - pad * 2.0), lc, false, 1.4)
		draw_line(Vector2(w * 0.5, pad), Vector2(w * 0.5, h - pad), lc, 1.3)
		draw_arc(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.15, 0.0, TAU, 24, lc, 1.3)
		draw_circle(Vector2(w * 0.5, h * 0.5), 2.0, lc)
		# Left & Right penalty boxes
		var pb_w: float = w * 0.16
		var pb_h: float = h * 0.52
		draw_rect(Rect2(pad, (h - pb_h) * 0.5, pb_w, pb_h), lc, false, 1.3)
		draw_rect(Rect2(w - pad - pb_w, (h - pb_h) * 0.5, pb_w, pb_h), lc, false, 1.3)
		var sb_w: float = w * 0.06
		var sb_h: float = h * 0.26
		draw_rect(Rect2(pad, (h - sb_h) * 0.5, sb_w, sb_h), lc, false, 1.1)
		draw_rect(Rect2(w - pad - sb_w, (h - sb_h) * 0.5, sb_w, sb_h), lc, false, 1.1)

		# Red 'x' dispossession markers (from Gambar 11, shown inline!)
		for lp in lost_pts:
			var pv: Vector2 = lp
			var x: float = pad + pv.x * (w - pad * 2.0)
			var y: float = pad + pv.y * (h - pad * 2.0)
			var d: float = 3.2
			draw_line(Vector2(x - d, y - d), Vector2(x + d, y + d), Color("#EF4444"), 1.8)
			draw_line(Vector2(x + d, y - d), Vector2(x - d, y + d), Color("#EF4444"), 1.8)

class WarisanIconControl extends Control:
	var icon_kind: String = "trophy"
	var icon_color: Color = Color("#E2E8F0")
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var c := Vector2(w * 0.5, h * 0.5)
		match icon_kind:
			"goal":
				draw_rect(Rect2(w * 0.14, h * 0.22, w * 0.72, h * 0.50), icon_color, false, 1.5)
				draw_circle(Vector2(w * 0.50, h * 0.56), minf(w, h) * 0.15, icon_color)
			"assist":
				draw_circle(Vector2(w * 0.28, h * 0.52), minf(w, h) * 0.15, icon_color)
				draw_line(Vector2(w * 0.44, h * 0.52), Vector2(w * 0.84, h * 0.52), icon_color, 1.6)
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.88, h * 0.52), Vector2(w * 0.66, h * 0.30), Vector2(w * 0.66, h * 0.74),
				]), icon_color)
			"match":
				draw_rect(Rect2(w * 0.14, h * 0.20, w * 0.72, h * 0.60), icon_color, false, 1.4)
				draw_line(Vector2(w * 0.50, h * 0.20), Vector2(w * 0.50, h * 0.80), icon_color, 1.1)
				draw_arc(c, minf(w, h) * 0.14, 0, TAU, 12, icon_color, 1.1)
			"star":
				var pts := PackedVector2Array()
				for i in range(10):
					var ang: float = -PI * 0.5 + float(i) * PI / 5.0
					var rad: float = (minf(w, h) * 0.44) if (i % 2 == 0) else (minf(w, h) * 0.20)
					pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
				draw_colored_polygon(pts, icon_color)
			"bars":
				draw_rect(Rect2(w * 0.16, h * 0.54, w * 0.18, h * 0.32), icon_color, true)
				draw_rect(Rect2(w * 0.42, h * 0.34, w * 0.18, h * 0.52), icon_color, true)
				draw_rect(Rect2(w * 0.68, h * 0.18, w * 0.18, h * 0.68), icon_color, true)
			"medal":
				draw_line(Vector2(w * 0.36, h * 0.12), Vector2(w * 0.44, h * 0.40), icon_color, 1.8)
				draw_line(Vector2(w * 0.64, h * 0.12), Vector2(w * 0.56, h * 0.40), icon_color, 1.8)
				draw_circle(Vector2(w * 0.50, h * 0.64), minf(w, h) * 0.24, icon_color)
			"mic":
				draw_rect(Rect2(w * 0.36, h * 0.16, w * 0.28, h * 0.42), icon_color, true)
				draw_line(Vector2(w * 0.50, h * 0.58), Vector2(w * 0.50, h * 0.84), icon_color, 1.8)
				draw_line(Vector2(w * 0.32, h * 0.84), Vector2(w * 0.68, h * 0.84), icon_color, 1.6)
			"ball":
				var r: float = minf(w, h) * 0.38
				draw_circle(c, r, icon_color)
				draw_circle(c, r * 0.32, Color("#241506"))
			"crown":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.14, h * 0.78), Vector2(w * 0.14, h * 0.30),
					Vector2(w * 0.34, h * 0.52), Vector2(w * 0.50, h * 0.22),
					Vector2(w * 0.66, h * 0.52), Vector2(w * 0.86, h * 0.30),
					Vector2(w * 0.86, h * 0.78),
				]), icon_color)
			"bag":
				draw_arc(Vector2(w * 0.50, h * 0.30), w * 0.18, PI, TAU, 8, icon_color, 1.4)
				draw_rect(Rect2(w * 0.20, h * 0.32, w * 0.60, h * 0.52), icon_color, true)
			"globe":
				var r: float = minf(w, h) * 0.38
				draw_arc(c, r, 0.0, TAU, 16, icon_color, 1.4)
				draw_line(Vector2(c.x - r, c.y), Vector2(c.x + r, c.y), icon_color, 1.1)
				draw_line(Vector2(c.x, c.y - r), Vector2(c.x, c.y + r), icon_color, 1.1)
			"shield":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.18, h * 0.16), Vector2(w * 0.82, h * 0.16),
					Vector2(w * 0.78, h * 0.60), Vector2(w * 0.50, h * 0.88),
					Vector2(w * 0.22, h * 0.60),
				]), icon_color)
			"boot":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.20, h * 0.26), Vector2(w * 0.48, h * 0.26),
					Vector2(w * 0.56, h * 0.54), Vector2(w * 0.86, h * 0.62),
					Vector2(w * 0.86, h * 0.78), Vector2(w * 0.18, h * 0.78),
				]), icon_color)
			"cal_star":
				draw_rect(Rect2(w * 0.16, h * 0.18, w * 0.68, h * 0.68), icon_color, true)
				draw_rect(Rect2(w * 0.16, h * 0.18, w * 0.68, h * 0.18), Color("#D97706"), true)
				draw_circle(Vector2(w * 0.50, h * 0.58), minf(w, h) * 0.15, Color("#D97706"))
			"piala":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.50, h * 0.12), Vector2(w * 0.76, h * 0.44),
					Vector2(w * 0.62, h * 0.66), Vector2(w * 0.38, h * 0.66),
					Vector2(w * 0.24, h * 0.44),
				]), icon_color)
				draw_rect(Rect2(w * 0.34, h * 0.72, w * 0.32, h * 0.14), icon_color, true)
			"kont":
				draw_arc(Vector2(w * 0.24, h * 0.36), w * 0.16, PI * 0.5, PI * 1.5, 8, icon_color, 1.3)
				draw_arc(Vector2(w * 0.76, h * 0.36), w * 0.16, -PI * 0.5, PI * 0.5, 8, icon_color, 1.3)
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.28, h * 0.18), Vector2(w * 0.72, h * 0.18),
					Vector2(w * 0.62, h * 0.62), Vector2(w * 0.38, h * 0.62),
				]), icon_color)
				draw_rect(Rect2(w * 0.30, h * 0.72, w * 0.40, h * 0.14), icon_color, true)
			"dunia":
				var r: float = minf(w, h) * 0.34
				draw_arc(Vector2(w * 0.5, h * 0.42), r, 0, TAU, 16, icon_color, 1.4)
				draw_circle(Vector2(w * 0.5, h * 0.42), r * 0.40, icon_color)
				draw_rect(Rect2(w * 0.32, h * 0.78, w * 0.36, h * 0.12), icon_color, true)
			"flag":
				draw_line(Vector2(w * 0.24, h * 0.14), Vector2(w * 0.24, h * 0.88), icon_color, 1.6)
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.28, h * 0.16), Vector2(w * 0.86, h * 0.36), Vector2(w * 0.28, h * 0.58),
				]), icon_color)
			"ballon":
				var r: float = minf(w, h) * 0.36
				draw_circle(c, r, icon_color)
				draw_arc(c, r * 0.55, 0.0, TAU, 12, Color("#78350F"), 1.2)
			"shirt":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.28, h * 0.18), Vector2(w * 0.72, h * 0.18),
					Vector2(w * 0.90, h * 0.40), Vector2(w * 0.76, h * 0.52),
					Vector2(w * 0.72, h * 0.44), Vector2(w * 0.72, h * 0.84),
					Vector2(w * 0.28, h * 0.84), Vector2(w * 0.28, h * 0.44),
					Vector2(w * 0.24, h * 0.52), Vector2(w * 0.10, h * 0.40),
				]), icon_color)
			"brand_d":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.28, h * 0.18), Vector2(w * 0.58, h * 0.18),
					Vector2(w * 0.80, h * 0.38), Vector2(w * 0.80, h * 0.62),
					Vector2(w * 0.58, h * 0.82), Vector2(w * 0.28, h * 0.82),
				]), icon_color)
				draw_rect(Rect2(w * 0.42, h * 0.34, w * 0.18, h * 0.32), Color("#241506"), true)
			"red_card":
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.34, h * 0.16), Vector2(w * 0.74, h * 0.22),
					Vector2(w * 0.66, h * 0.84), Vector2(w * 0.26, h * 0.78),
				]), icon_color)
			"pitch":
				draw_rect(Rect2(w * 0.12, h * 0.22, w * 0.76, h * 0.56), icon_color, false, 1.5)
				draw_line(Vector2(w * 0.50, h * 0.22), Vector2(w * 0.50, h * 0.78), icon_color, 1.2)
				draw_arc(c, minf(w, h) * 0.15, 0.0, TAU, 12, icon_color, 1.2)
				draw_rect(Rect2(w * 0.12, h * 0.36, w * 0.16, h * 0.28), icon_color, false, 1.1)
				draw_rect(Rect2(w * 0.72, h * 0.36, w * 0.16, h * 0.28), icon_color, false, 1.1)
			"person":
				draw_circle(Vector2(w * 0.50, h * 0.32), minf(w, h) * 0.18, icon_color)
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.22, h * 0.84), Vector2(w * 0.28, h * 0.56),
					Vector2(w * 0.72, h * 0.56), Vector2(w * 0.78, h * 0.84),
				]), icon_color)
			_:
				# Default / "trophy" / "liga"
				draw_colored_polygon(PackedVector2Array([
					Vector2(w * 0.22, h * 0.16), Vector2(w * 0.78, h * 0.16),
					Vector2(w * 0.66, h * 0.58), Vector2(w * 0.34, h * 0.58),
				]), icon_color)
				draw_rect(Rect2(w * 0.42, h * 0.58, w * 0.16, h * 0.18), icon_color, true)
				draw_rect(Rect2(w * 0.28, h * 0.76, w * 0.44, h * 0.14), icon_color, true)

class CircleIconBadge extends Control:
	var bg_col: Color = Color("#FFFFFF")
	var icon_kind: String = "mic"
	var fg_col: Color = Color("#D64D8B")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cc)
		var ic := WarisanIconControl.new()
		ic.icon_kind = icon_kind
		ic.icon_color = fg_col
		ic.custom_minimum_size = Vector2(maxf(12.0, custom_minimum_size.x * 0.56), maxf(12.0, custom_minimum_size.y * 0.56))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(ic)

	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.48
		draw_circle(size * 0.5, r, bg_col)

class SunburstHeaderBg extends Control:
	var ray_center_ratio: Vector2 = Vector2(0.16, 0.56)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 4.0 or h <= 4.0:
			return
		# Smooth magenta-pink to deep plum vertical gradient
		var bands: int = 16
		var c_top := Color("#E25294")
		var c_mid := Color("#9A2E66")
		var c_bot := Color("#162540")
		for i in range(bands):
			var t0: float = float(i) / float(bands)
			var y0: float = t0 * h
			var bh: float = h / float(bands) + 1.0
			var col: Color = c_top.lerp(c_mid, t0 * 1.4) if t0 < 0.68 else c_mid.lerp(c_bot, (t0 - 0.68) / 0.32)
			draw_rect(Rect2(0, y0, w, bh), col, true)

		# Soft radial sunburst beams
		var origin := Vector2(w * ray_center_ratio.x, h * ray_center_ratio.y)
		var ray_len: float = maxf(w, h) * 0.65
		var ray_count: int = 14
		for r_i in range(ray_count):
			var a0: float = float(r_i) * (TAU / float(ray_count))
			var a1: float = a0 + (TAU / float(ray_count)) * 0.42
			var p1: Vector2 = origin + Vector2(cos(a0), sin(a0)) * ray_len
			var p2: Vector2 = origin + Vector2(cos(a1), sin(a1)) * ray_len
			draw_colored_polygon(PackedVector2Array([origin, p1, p2]), Color(1.0, 0.85, 0.94, 0.11))

		# Crisp pixel 4-point sparkles
		var sparkles: Array = [
			Vector2(w * 0.05, h * 0.16),
			Vector2(w * 0.29, h * 0.18),
			Vector2(w * 0.72, h * 0.24),
			Vector2(w * 0.86, h * 0.18),
		]
		for sp_item in sparkles:
			var pt: Vector2 = sp_item
			draw_line(pt + Vector2(-4, 0), pt + Vector2(4, 0), Color(1.0, 0.95, 1.0, 0.85), 1.4)
			draw_line(pt + Vector2(0, -4), pt + Vector2(0, 4), Color(1.0, 0.95, 1.0, 0.85), 1.4)

# ==============================================================================
# SHARED LEGEND HUB HELPERS
# ==============================================================================
static func make_circle_icon_badge(kind: String, bg_col: Color, fg_col: Color, diameter: float = 28.0) -> Control:
	var b := CircleIconBadge.new()
	b.icon_kind = kind
	b.bg_col = bg_col
	b.fg_col = fg_col
	b.custom_minimum_size = Vector2(diameter, diameter)
	return b

static func make_flag_section_header(title_txt: String, font_sz: int = 12) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	vb.add_child(hb)
	var ic_c := CenterContainer.new()
	ic_c.add_child(make_icon("flag", Color("#DC2E44"), Vector2(12, 12)))
	hb.add_child(ic_c)
	var lbl := Label.new()
	lbl.text = title_txt
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UITheme.get_display_font())
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(lbl)
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color("#243A5E")
	vb.add_child(sep)
	return vb

static func make_micro_trophies_strip(lg: Dictionary) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var defs := [
		["ballon", int(lg.get("ballon", 0)), Color("#F5C430")],
		["boot", int(lg.get("boot", 0)), Color("#EAB308")],
		["liga", int(lg.get("liga", 0)), Color("#CBD5E1")],
		["piala", int(lg.get("piala", 0)), Color("#E59A38")],
		["kont", int(lg.get("kont", 0)), Color("#93C5FD")],
		["dunia", int(lg.get("wc", 0)), Color("#FACC15")],
	]
	for d in defs:
		var ihb := HBoxContainer.new()
		ihb.add_theme_constant_override("separation", 2)
		hb.add_child(ihb)
		var val: int = int(d[1])
		var col: Color = d[2] if val > 0 else Color("#475B75")
		var ic_c := CenterContainer.new()
		ic_c.add_child(make_icon(str(d[0]), col, Vector2(9, 9)))
		ihb.add_child(ic_c)
		var vl := Label.new()
		vl.text = str(val)
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 8)
		vl.add_theme_color_override("font_color", Color("#E2E8F0") if val > 0 else Color("#526682"))
		ihb.add_child(vl)

	var is_ret: bool = bool(lg.get("retired", true))
	var st_lbl := Label.new()
	st_lbl.text = "PENSIUN" if is_ret else "AKTIF"
	st_lbl.add_theme_font_size_override("font_size", 7)
	st_lbl.add_theme_color_override("font_color", Color("#647896") if is_ret else Color("#E2E8F0"))
	hb.add_child(st_lbl)
	return hb

static func _make_stacked_stat(col_hdr: String, val_txt: String, col_w: float, val_col: Color = Color.WHITE, val_sz: int = 12) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(col_w, 0)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	var h_l := Label.new()
	h_l.text = col_hdr
	h_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h_l.add_theme_font_size_override("font_size", 6)
	h_l.add_theme_color_override("font_color", Color("#7C90AB"))
	var v_l := Label.new()
	v_l.text = val_txt
	v_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_l.add_theme_font_override("font", UITheme.get_display_font())
	v_l.add_theme_font_size_override("font_size", val_sz)
	v_l.add_theme_color_override("font_color", val_col)
	vb.add_child(h_l)
	vb.add_child(v_l)
	return vb

static func _make_crimson_nav_btn(sym: String) -> Button:
	var b := Button.new()
	b.text = sym
	b.custom_minimum_size = Vector2(28, 28)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_btn(b, Color("#4A2535"), Color("#9E3852"), 12, Color("#FB7185"), 2)
	return b

static func _make_legend_entry_block(rank_num: int, lg: Dictionary, show_goals: bool = false) -> VBoxContainer:
	var is_u: bool = bool(lg.get("is_user", false))
	var row_vb := VBoxContainer.new()
	row_vb.add_theme_constant_override("separation", 1)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 5)
	row_vb.add_child(top_hb)

	if rank_num > 0:
		var rk := Label.new()
		rk.text = str(rank_num)
		rk.custom_minimum_size = Vector2(22, 0)
		rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rk.add_theme_font_override("font", UITheme.get_display_font())
		rk.add_theme_font_size_override("font_size", 10)
		rk.add_theme_color_override("font_color", Color("#CBD5E1"))
		top_hb.add_child(rk)

	var fl_c := CenterContainer.new()
	fl_c.add_child(UITheme.make_flag_rect(int(lg.get("nat", 1)), Vector2(15, 10)))
	top_hb.add_child(fl_c)

	var nm := Label.new()
	nm.text = str(lg.get("name", "Legenda"))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", Color("#F87171") if is_u else Color.WHITE)
	top_hb.add_child(nm)

	top_hb.add_child(_make_stacked_stat("INDIV.", str(int(lg.get("indiv", 0))), 32, Color.WHITE, 12))
	top_hb.add_child(_make_stacked_stat("TIM", str(int(lg.get("team", 0))), 26, Color.WHITE, 12))
	if show_goals:
		var gv: int = int(lg.get("disp_goals", lg.get("goals", 0)))
		top_hb.add_child(_make_stacked_stat("GOL", str(gv), 34, Color.WHITE, 12))

	var micro_wrap := HBoxContainer.new()
	if rank_num > 0:
		var ind := Control.new()
		ind.custom_minimum_size = Vector2(22, 0)
		micro_wrap.add_child(ind)
	micro_wrap.add_child(make_micro_trophies_strip(lg))
	row_vb.add_child(micro_wrap)
	return row_vb

# ==============================================================================
# 7. LEGENDA DUNIA POPUP (Gambar 4: INDIV. | TIM | TOTAL, 2-Column Top 10 + User)
# ==============================================================================
static func open_world_legends_popup(parent: Node) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(736, 444), BG_MODAL, 20, 16, 12)
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var state: Dictionary = {"mode": "INDIV"}
	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 18)
	vb.add_child(cols)

	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(342, 0)
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 6)
	cols.add_child(left_vb)

	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(332, 0)
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 7)
	cols.add_child(right_vb)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 32)
	_style_btn(cls, Color("#243959"), Color("#4B6791"), 11)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	left_vb.add_child(cls)

	left_vb.add_child(make_flag_section_header("LEGENDA DUNIA", 13))

	var intro := Label.new()
	intro.text = "Palmaresmu hanya menghitung yang diraih di kasta tertinggi dan Kejuaraan Dunia: itulah patokan untuk mengukur para legenda."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 9)
	intro.add_theme_color_override("font_color", Color("#A7BCD4"))
	left_vb.add_child(intro)

	var tab_hb := HBoxContainer.new()
	tab_hb.add_theme_constant_override("separation", 6)
	left_vb.add_child(tab_hb)

	var mode_desc := Label.new()
	mode_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_desc.add_theme_font_size_override("font_size", 9)
	mode_desc.add_theme_color_override("font_color", Color("#94ADC8"))
	left_vb.add_child(mode_desc)

	var left_rows := VBoxContainer.new()
	left_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_rows.add_theme_constant_override("separation", 6)
	left_vb.add_child(left_rows)

	var tab_btns: Dictionary = {}
	var desc_map: Dictionary = {
		"INDIV": "Penghargaan yang dimenangkan sendirian: pemain terbaik tahun ini dan sepatu emas top skor.",
		"TIM": "Gelar kolektif kasta tertinggi: liga, piala domestik, kontinental, dan Kejuaraan Dunia.",
		"TOTAL": "Gabungan seluruh gelar individu dan gelar tim elite sepanjang karier.",
	}

	var rebuild_fn: Callable = func() -> void:
		var m_key: String = str(state["mode"])
		for tk in ["INDIV", "TIM", "TOTAL"]:
			var tb: Button = tab_btns[tk]
			var active: bool = (tk == m_key)
			var tsb := StyleBoxFlat.new()
			tsb.bg_color = Color("#08101C")
			tsb.border_color = Color("#DC2E44") if active else Color("#223856")
			tsb.set_border_width_all(1)
			tsb.border_width_bottom = 3 if active else 1
			tsb.set_corner_radius_all(3)
			tsb.content_margin_top = 6
			tsb.content_margin_bottom = 6
			tb.add_theme_stylebox_override("normal", tsb)
			tb.add_theme_stylebox_override("hover", tsb)
			tb.add_theme_stylebox_override("pressed", tsb)
			tb.add_theme_color_override("font_color", Color.WHITE if active else Color("#8DA4C0"))

		mode_desc.text = str(desc_map.get(m_key, ""))

		for c in left_rows.get_children():
			left_rows.remove_child(c)
			c.queue_free()
		for c in right_vb.get_children():
			right_vb.remove_child(c)
			c.queue_free()

		var data: Dictionary = CareerState.get_world_legends_list(m_key)
		var top10: Array = data.get("top10", [])
		for i in range(mini(4, top10.size())):
			var row_d: Dictionary = top10[i]
			left_rows.add_child(_make_legend_entry_block(i + 1, row_d, false))
		for i in range(4, mini(10, top10.size())):
			var row_d: Dictionary = top10[i]
			right_vb.add_child(_make_legend_entry_block(i + 1, row_d, false))

		if not bool(data.get("user_in_top10", false)):
			var below_l := Label.new()
			below_l.text = "Kamu finis lebih bawah:"
			below_l.add_theme_font_size_override("font_size", 9)
			below_l.add_theme_color_override("font_color", Color("#94ADC8"))
			right_vb.add_child(below_l)
			var u_row: Dictionary = data.get("user_row", {})
			right_vb.add_child(_make_legend_entry_block(int(data.get("user_rank", 975)), u_row, false))

	for tdef in [["INDIV", "INDIV."], ["TIM", "TIM"], ["TOTAL", "TOTAL"]]:
		var tk: String = str(tdef[0])
		var tb := Button.new()
		tb.text = str(tdef[1])
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 32)
		tb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tb.add_theme_font_override("font", UITheme.get_display_font())
		tb.add_theme_font_size_override("font_size", 11)
		tb.pressed.connect(func():
			AudioSynth.play_click()
			state["mode"] = tk
			rebuild_fn.call()
		)
		tab_btns[tk] = tb
		tab_hb.add_child(tb)

	rebuild_fn.call()
	return layer

# ==============================================================================
# 8. GOL + ASSIST ALL-TIME LEGENDS POPUP (Gambar 5)
# ==============================================================================
static func open_goals_assists_legends_popup(parent: Node) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(510, 444), BG_MODAL, 20, 16, 12)
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 32)
	_style_btn(cls, Color("#243959"), Color("#4B6791"), 11)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)

	vb.add_child(make_flag_section_header("GOL + ASSIST", 13))

	var intro := Label.new()
	intro.text = "Pemain paling produktif sepanjang sejarah (G+A). Hanya hasil di kasta tertinggi atau timnasmu yang dihitung: itulah ukuran pemain hebat."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 9)
	intro.add_theme_color_override("font_color", Color("#A7BCD4"))
	vb.add_child(intro)

	var data: Dictionary = CareerState.get_world_legends_list("GA")
	var top10: Array = data.get("top10", [])

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 4)
	vb.add_child(list_vb)

	for i in range(top10.size()):
		var row_d: Dictionary = top10[i]
		list_vb.add_child(_make_ga_row(i + 1, row_d))

	if not bool(data.get("user_in_top10", false)):
		var u_row: Dictionary = data.get("user_row", {})
		list_vb.add_child(_make_ga_row(int(data.get("user_rank", 11)), u_row))

	return layer

static func _make_ga_row(rank_num: int, row_d: Dictionary) -> HBoxContainer:
	var is_u: bool = bool(row_d.get("is_user", false))
	var is_ret: bool = bool(row_d.get("retired", true))
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(0, 24)
	hb.add_theme_constant_override("separation", 6)

	var rk := Label.new()
	rk.text = str(rank_num)
	rk.custom_minimum_size = Vector2(22, 0)
	rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rk.add_theme_font_override("font", UITheme.get_display_font())
	rk.add_theme_font_size_override("font_size", 10)
	rk.add_theme_color_override("font_color", Color("#E2E8F0"))
	hb.add_child(rk)

	var fl_c := CenterContainer.new()
	fl_c.add_child(UITheme.make_flag_rect(int(row_d.get("nat", 1)), Vector2(15, 10)))
	hb.add_child(fl_c)

	var nm := Label.new()
	nm.text = str(row_d.get("name", "Legenda"))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", Color("#F87171") if is_u else Color.WHITE)
	hb.add_child(nm)

	var st_l := Label.new()
	st_l.text = "PENSIUN" if is_ret else "AKTIF"
	st_l.custom_minimum_size = Vector2(48, 0)
	st_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	st_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	st_l.add_theme_font_size_override("font_size", 8)
	st_l.add_theme_color_override("font_color", Color("#647896") if is_ret else Color("#E2E8F0"))
	hb.add_child(st_l)

	hb.add_child(_make_stacked_stat("G", str(int(row_d.get("goals", 0))), 38, Color("#CBD5E1"), 11))
	hb.add_child(_make_stacked_stat("A", str(int(row_d.get("assists", 0))), 32, Color("#CBD5E1"), 11))
	hb.add_child(_make_stacked_stat("G+A", str(int(row_d.get("ga", 0))), 42, Color.WHITE, 12))
	return hb

# ==============================================================================
# 9. LEGENDA PER KLUB POPUP (Gambar 3: Nation < > + Club < > + Top 5)
# ==============================================================================
static func open_club_legends_popup(parent: Node, init_nat_id: int = -1, init_club_id: int = -1) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(512, 460), BG_MODAL, 20, 16, 10)
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var my_club: Dictionary = CareerState.get_current_club()
	var start_nat: int = init_nat_id if init_nat_id >= 0 else int(my_club.get("nation_id", 1))
	start_nat = clampi(start_nat, 0, GameData.nations.size() - 1)
	var start_club: int = init_club_id if init_club_id >= 0 else int(my_club.get("id", 0))

	# Gather ordered nation IDs that have clubs
	var nat_ids: Array[int] = []
	for ni in range(GameData.nations.size()):
		if not GameData.get_clubs_in_nation(ni).is_empty():
			nat_ids.append(ni)
	if nat_ids.is_empty():
		nat_ids.append(0)
	var start_nat_pos: int = nat_ids.find(start_nat)
	if start_nat_pos < 0:
		start_nat_pos = 0

	var state: Dictionary = {"nat_pos": start_nat_pos, "club_pos": 0, "clubs": [], "mode": "GELAR"}

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 30)
	_style_btn(cls, Color("#243959"), Color("#4B6791"), 11)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)

	vb.add_child(make_flag_section_header("LEGENDA PER KLUB", 13))

	# Nation Selector Row
	var nat_bar := PanelContainer.new()
	nat_bar.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1C33"), Color("#243C60"), 1, 4))
	vb.add_child(nat_bar)
	var nat_hb := HBoxContainer.new()
	nat_hb.add_theme_constant_override("separation", 8)
	nat_bar.add_child(nat_hb)
	var nat_prev := _make_crimson_nav_btn("<")
	var nat_flag_host := CenterContainer.new()
	var nat_lbl := Label.new()
	nat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nat_lbl.add_theme_font_override("font", UITheme.get_display_font())
	nat_lbl.add_theme_font_size_override("font_size", 11)
	nat_lbl.add_theme_color_override("font_color", Color.WHITE)
	var nat_next := _make_crimson_nav_btn(">")
	nat_hb.add_child(nat_prev)
	nat_hb.add_child(nat_flag_host)
	nat_hb.add_child(nat_lbl)
	nat_hb.add_child(nat_next)

	# Club Selector Row
	var clb_bar := PanelContainer.new()
	clb_bar.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1C33"), Color("#243C60"), 1, 4))
	vb.add_child(clb_bar)
	var clb_hb := HBoxContainer.new()
	clb_hb.add_theme_constant_override("separation", 8)
	clb_bar.add_child(clb_hb)
	var clb_prev := _make_crimson_nav_btn("<")
	var clb_crest_host := CenterContainer.new()
	var clb_lbl := Label.new()
	clb_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clb_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clb_lbl.clip_text = true
	clb_lbl.add_theme_font_override("font", UITheme.get_display_font())
	clb_lbl.add_theme_font_size_override("font_size", 12)
	clb_lbl.add_theme_color_override("font_color", Color.WHITE)
	var clb_next := _make_crimson_nav_btn(">")
	clb_hb.add_child(clb_prev)
	clb_hb.add_child(clb_crest_host)
	clb_hb.add_child(clb_lbl)
	clb_hb.add_child(clb_next)

	# 2 Switchable Filter Tabs: GELAR TERBANYAK (default) | GOL & ASSIST
	var filter_hb := HBoxContainer.new()
	filter_hb.add_theme_constant_override("separation", 8)
	vb.add_child(filter_hb)
	var filter_btns: Dictionary = {}

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 6)
	vb.add_child(list_vb)

	var sync_clubs_fn: Callable = func(prefer_cid: int) -> void:
		var nid: int = nat_ids[int(state["nat_pos"])]
		var clist: Array[Dictionary] = GameData.get_clubs_in_nation(nid)
		clist.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.get("division", 3)) != int(b.get("division", 3)):
				return int(a.get("division", 3)) < int(b.get("division", 3))
			return int(a.get("ovr", 60)) > int(b.get("ovr", 60))
		)
		state["clubs"] = clist
		var found_pos: int = 0
		if prefer_cid >= 0:
			for i in range(clist.size()):
				if int(clist[i]["id"]) == prefer_cid:
					found_pos = i
					break
		state["club_pos"] = found_pos

	var render_fn: Callable = func() -> void:
		var m_key: String = str(state["mode"])
		for tk in ["GELAR", "GA"]:
			var tb: Button = filter_btns[tk]
			var active: bool = (tk == m_key)
			var tsb := StyleBoxFlat.new()
			tsb.bg_color = Color("#3A1524") if active else Color("#08101C")
			tsb.border_color = Color("#DC2E44") if active else Color("#223856")
			tsb.set_border_width_all(1)
			tsb.border_width_bottom = 3 if active else 1
			tsb.set_corner_radius_all(3)
			tsb.content_margin_top = 4
			tsb.content_margin_bottom = 4
			tb.add_theme_stylebox_override("normal", tsb)
			tb.add_theme_stylebox_override("hover", tsb)
			tb.add_theme_stylebox_override("pressed", tsb)
			tb.add_theme_color_override("font_color", Color.WHITE if active else Color("#8DA4C0"))

		var nid: int = nat_ids[int(state["nat_pos"])]
		var nd: Dictionary = GameData.nations[nid]
		nat_lbl.text = str(nd.get("name", "Spanyol")).to_upper()
		for c in nat_flag_host.get_children():
			nat_flag_host.remove_child(c)
			c.queue_free()
		nat_flag_host.add_child(UITheme.make_flag_rect(nid, Vector2(18, 12)))

		var clist: Array = state["clubs"]
		for c in clb_crest_host.get_children():
			clb_crest_host.remove_child(c)
			c.queue_free()
		for c in list_vb.get_children():
			list_vb.remove_child(c)
			c.queue_free()

		if clist.is_empty():
			clb_lbl.text = "---"
			return
		var cpos: int = clampi(int(state["club_pos"]), 0, clist.size() - 1)
		var sel_club: Dictionary = clist[cpos]
		var cid: int = int(sel_club["id"])
		clb_lbl.text = str(sel_club.get("name", "Klub")).to_upper()
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(20, 20)
		cr.set_club(cid)
		clb_crest_host.add_child(cr)

		var cdata: Dictionary = CareerState.get_legends_by_club(cid, m_key)
		var rows_arr: Array = cdata.get("legends", [])
		for i in range(rows_arr.size()):
			var lg: Dictionary = rows_arr[i]
			if m_key == "GA":
				list_vb.add_child(_make_ga_row(i + 1, lg))
			else:
				list_vb.add_child(_make_legend_entry_block(0, lg, false))

		if bool(cdata.get("user_played_here", false)) and not bool(cdata.get("user_in_top5", false)):
			var u_row: Dictionary = cdata.get("user_row", {})
			if not u_row.is_empty():
				var sep_u := ColorRect.new()
				sep_u.custom_minimum_size = Vector2(0, 1)
				sep_u.color = Color("#2C456B")
				list_vb.add_child(sep_u)
				if m_key == "GA":
					list_vb.add_child(_make_ga_row(int(cdata.get("user_rank", 6)), u_row))
				else:
					list_vb.add_child(_make_legend_entry_block(0, u_row, false))

	for fdef in [["GELAR", "GELAR TERBANYAK"], ["GA", "GOL & ASSIST"]]:
		var fk: String = str(fdef[0])
		var fb := Button.new()
		fb.text = str(fdef[1])
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb.custom_minimum_size = Vector2(0, 28)
		fb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		fb.add_theme_font_override("font", UITheme.get_display_font())
		fb.add_theme_font_size_override("font_size", 10)
		fb.pressed.connect(func():
			AudioSynth.play_click()
			state["mode"] = fk
			render_fn.call()
		)
		filter_btns[fk] = fb
		filter_hb.add_child(fb)

	nat_prev.pressed.connect(func():
		AudioSynth.play_click()
		state["nat_pos"] = (int(state["nat_pos"]) - 1 + nat_ids.size()) % nat_ids.size()
		sync_clubs_fn.call(-1)
		render_fn.call()
	)
	nat_next.pressed.connect(func():
		AudioSynth.play_click()
		state["nat_pos"] = (int(state["nat_pos"]) + 1) % nat_ids.size()
		sync_clubs_fn.call(-1)
		render_fn.call()
	)
	clb_prev.pressed.connect(func():
		AudioSynth.play_click()
		var clist: Array = state["clubs"]
		if not clist.is_empty():
			state["club_pos"] = (int(state["club_pos"]) - 1 + clist.size()) % clist.size()
			render_fn.call()
	)
	clb_next.pressed.connect(func():
		AudioSynth.play_click()
		var clist: Array = state["clubs"]
		if not clist.is_empty():
			state["club_pos"] = (int(state["club_pos"]) + 1) % clist.size()
			render_fn.call()
	)

	sync_clubs_fn.call(start_club)
	render_fn.call()
	return layer

# ==============================================================================
# 10. LEGENDA TIMNAS POPUP (User Request: 2 Tabs -> PIALA default | GOL & ASSIST)
# ==============================================================================
static func open_timnas_legends_popup(parent: Node, init_nat_id: int = -1) -> CanvasLayer:
	var built: Dictionary = _create_modal_layer(parent, Vector2(616, 456), BG_MODAL, 20, 16, 12)
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]

	var u_nat: int = int(CareerState.career.get("playerProfile", {}).get("nationality", 16))
	var start_nat: int = init_nat_id if init_nat_id >= 0 else u_nat
	start_nat = clampi(start_nat, 0, GameData.nations.size() - 1)
	var state: Dictionary = {"nat_id": start_nat, "tab": "PIALA"}

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 30)
	_style_btn(cls, Color("#243959"), Color("#4B6791"), 11)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	vb.add_child(cls)

	vb.add_child(make_flag_section_header("LEGENDA TIMNAS", 13))

	# Nation selector bar
	var nav_bar := PanelContainer.new()
	nav_bar.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1C33"), Color("#243C60"), 1, 4))
	vb.add_child(nav_bar)
	var nav_hb := HBoxContainer.new()
	nav_hb.add_theme_constant_override("separation", 8)
	nav_bar.add_child(nav_hb)
	var prev_b := _make_crimson_nav_btn("<")
	var flag_host := CenterContainer.new()
	var nat_lbl := Label.new()
	nat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nat_lbl.add_theme_font_override("font", UITheme.get_display_font())
	nat_lbl.add_theme_font_size_override("font_size", 12)
	nat_lbl.add_theme_color_override("font_color", Color.WHITE)
	var next_b := _make_crimson_nav_btn(">")
	nav_hb.add_child(prev_b)
	nav_hb.add_child(flag_host)
	nav_hb.add_child(nat_lbl)
	nav_hb.add_child(next_b)

	# 2 Switchable Tabs: PIALA (default) | GOL & ASSIST
	var tab_hb := HBoxContainer.new()
	tab_hb.add_theme_constant_override("separation", 8)
	vb.add_child(tab_hb)
	var tab_btns: Dictionary = {}

	var sub_lbl := Label.new()
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.add_theme_color_override("font_color", Color("#94ADC8"))
	vb.add_child(sub_lbl)

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 3)
	vb.add_child(list_vb)

	var render_fn: Callable = func() -> void:
		var nid: int = int(state["nat_id"])
		var m_key: String = str(state["tab"])
		for tk in ["PIALA", "GA"]:
			var tb: Button = tab_btns[tk]
			var active: bool = (tk == m_key)
			var tsb := StyleBoxFlat.new()
			tsb.bg_color = Color("#08101C") if not active else Color("#3A1524")
			tsb.border_color = Color("#DC2E44") if active else Color("#223856")
			tsb.set_border_width_all(1)
			tsb.border_width_bottom = 3 if active else 1
			tsb.set_corner_radius_all(3)
			tsb.content_margin_top = 5
			tsb.content_margin_bottom = 5
			tb.add_theme_stylebox_override("normal", tsb)
			tb.add_theme_stylebox_override("hover", tsb)
			tb.add_theme_stylebox_override("pressed", tsb)
			tb.add_theme_color_override("font_color", Color.WHITE if active else Color("#8DA4C0"))

		var tdata: Dictionary = CareerState.get_timnas_legends(nid, m_key)
		var conf: String = str(tdata.get("conf", "AFC"))
		var cont_lbl: String = str(tdata.get("cont_cup_label", "PIALA BENUA"))
		nat_lbl.text = "%s  •  %s" % [str(tdata.get("nat_name", "INDONESIA")).to_upper(), conf]
		for c in flag_host.get_children():
			flag_host.remove_child(c)
			c.queue_free()
		flag_host.add_child(UITheme.make_flag_rect(nid, Vector2(18, 12)))

		if m_key == "PIALA":
			sub_lbl.text = "Peringkat legenda timnas berdasarkan koleksi Piala Dunia dan %s." % cont_lbl
		else:
			sub_lbl.text = "Peringkat legenda timnas paling produktif berdasarkan total Gol + Assist laga internasional."

		for c in list_vb.get_children():
			list_vb.remove_child(c)
			c.queue_free()

		var top10: Array = tdata.get("top10", [])
		for i in range(top10.size()):
			var row_d: Dictionary = top10[i]
			list_vb.add_child(_make_timnas_legend_row(i + 1, row_d, m_key, cont_lbl))

		if bool(tdata.get("user_matches_nat", false)) and not bool(tdata.get("user_in_top10", false)):
			var sep := ColorRect.new()
			sep.custom_minimum_size = Vector2(0, 1)
			sep.color = Color("#2C456B")
			list_vb.add_child(sep)
			var u_row: Dictionary = tdata.get("user_row", {})
			list_vb.add_child(_make_timnas_legend_row(int(tdata.get("user_rank", 11)), u_row, m_key, cont_lbl))

	for tdef in [["PIALA", "BERDASARKAN PIALA"], ["GA", "GOL & ASSIST"]]:
		var tk: String = str(tdef[0])
		var tb := Button.new()
		tb.text = str(tdef[1])
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 30)
		tb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tb.add_theme_font_override("font", UITheme.get_display_font())
		tb.add_theme_font_size_override("font_size", 10)
		tb.pressed.connect(func():
			AudioSynth.play_click()
			state["tab"] = tk
			render_fn.call()
		)
		tab_btns[tk] = tb
		tab_hb.add_child(tb)

	prev_b.pressed.connect(func():
		AudioSynth.play_click()
		state["nat_id"] = (int(state["nat_id"]) - 1 + GameData.nations.size()) % GameData.nations.size()
		render_fn.call()
	)
	next_b.pressed.connect(func():
		AudioSynth.play_click()
		state["nat_id"] = (int(state["nat_id"]) + 1) % GameData.nations.size()
		render_fn.call()
	)

	render_fn.call()
	return layer

static func _make_timnas_legend_row(rank_num: int, row_d: Dictionary, mode_key: String, cont_lbl: String) -> HBoxContainer:
	var is_u: bool = bool(row_d.get("is_user", false))
	var is_ret: bool = bool(row_d.get("retired", true))
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(0, 23)
	hb.add_theme_constant_override("separation", 6)

	var rk := Label.new()
	rk.text = str(rank_num)
	rk.custom_minimum_size = Vector2(22, 0)
	rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rk.add_theme_font_override("font", UITheme.get_display_font())
	rk.add_theme_font_size_override("font_size", 10)
	rk.add_theme_color_override("font_color", GOLD_TXT if rank_num <= 3 else Color("#CBD5E1"))
	hb.add_child(rk)

	var fl_c := CenterContainer.new()
	fl_c.add_child(UITheme.make_flag_rect(int(row_d.get("nat", 16)), Vector2(15, 10)))
	hb.add_child(fl_c)

	var nm := Label.new()
	nm.text = str(row_d.get("name", "Legenda"))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", Color("#F87171") if is_u else Color.WHITE)
	hb.add_child(nm)

	var st_l := Label.new()
	st_l.text = "PENSIUN" if is_ret else "AKTIF"
	st_l.custom_minimum_size = Vector2(46, 0)
	st_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	st_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	st_l.add_theme_font_size_override("font_size", 7)
	st_l.add_theme_color_override("font_color", Color("#647896") if is_ret else Color("#E2E8F0"))
	hb.add_child(st_l)

	if mode_key == "PIALA":
		var short_c: String = "BENUA"
		if cont_lbl.contains("ASIA"):
			short_c = "ASIA"
		elif cont_lbl.contains("EURO"):
			short_c = "EURO"
		elif cont_lbl.contains("COPA"):
			short_c = "COPA"
		elif cont_lbl.contains("AFRIKA"):
			short_c = "AFCON"
		elif cont_lbl.contains("GOLD"):
			short_c = "GOLD"
		elif cont_lbl.contains("OFC"):
			short_c = "OFC"
		hb.add_child(_make_stacked_stat("CAPS", str(int(row_d.get("caps", 0))), 34, Color("#94ADC8"), 10))
		hb.add_child(_make_stacked_stat("DUNIA", str(int(row_d.get("wc", 0))), 34, GOLD_TXT if int(row_d.get("wc", 0)) > 0 else Color("#526682"), 11))
		hb.add_child(_make_stacked_stat(short_c, str(int(row_d.get("cont", 0))), 34, Color("#60A5FA") if int(row_d.get("cont", 0)) > 0 else Color("#526682"), 11))
		hb.add_child(_make_stacked_stat("PIALA", str(int(row_d.get("tot_cups", 0))), 34, Color.WHITE, 12))
	else:
		hb.add_child(_make_stacked_stat("CAPS", str(int(row_d.get("caps", 0))), 34, Color("#94ADC8"), 10))
		hb.add_child(_make_stacked_stat("G", str(int(row_d.get("goals", 0))), 34, Color("#CBD5E1"), 11))
		hb.add_child(_make_stacked_stat("A", str(int(row_d.get("assists", 0))), 30, Color("#CBD5E1"), 11))
		hb.add_child(_make_stacked_stat("G+A", str(int(row_d.get("ga", 0))), 38, Color.WHITE, 12))
	return hb

# ==============================================================================
# 11. KETENARAN (FAME) POPUP (Gambar 8) + CARANYA? HELP POPUP (Gambar 9)
# ==============================================================================
static func open_fame_popup(parent: Node) -> CanvasLayer:
	var ov: Dictionary = CareerState.get_fame_overview()
	var built: Dictionary = _create_modal_layer(parent, Vector2(616, 422), Color("#11223A"), 20, 0, 0)
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]
	vb.add_theme_constant_override("separation", 0)

	# --- TOP PINK-MAGENTA SUNBURST BANNER ---
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(0, 106)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.clip_contents = true
	vb.add_child(banner)

	var sb_bg := SunburstHeaderBg.new()
	sb_bg.ray_center_ratio = Vector2(0.14, 0.56)
	sb_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sb_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(sb_bg)

	var ban_m := MarginContainer.new()
	ban_m.set_anchors_preset(Control.PRESET_FULL_RECT)
	ban_m.add_theme_constant_override("margin_left", 16)
	ban_m.add_theme_constant_override("margin_right", 16)
	ban_m.add_theme_constant_override("margin_top", 10)
	ban_m.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(ban_m)

	var ban_vb := VBoxContainer.new()
	ban_vb.add_theme_constant_override("separation", 4)
	ban_m.add_child(ban_vb)

	# Banner Top Row: spacer | KETENARAN title | circular [?] button
	var top_r := HBoxContainer.new()
	ban_vb.add_child(top_r)
	var sp_l := Control.new()
	sp_l.custom_minimum_size = Vector2(28, 28)
	top_r.add_child(sp_l)
	var ttl := Label.new()
	ttl.text = "KETENARAN"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", Color.WHITE)
	top_r.add_child(ttl)

	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.custom_minimum_size = Vector2(28, 28)
	help_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color("#FCEBF4")
	hsb.border_color = Color("#FFFFFF")
	hsb.set_border_width_all(1)
	hsb.set_corner_radius_all(14)
	var hsbh := hsb.duplicate()
	hsbh.bg_color = Color("#FFFFFF")
	hsbh.border_color = GOLD_TXT
	help_btn.add_theme_stylebox_override("normal", hsb)
	help_btn.add_theme_stylebox_override("hover", hsbh)
	help_btn.add_theme_stylebox_override("pressed", hsbh)
	help_btn.add_theme_font_override("font", UITheme.get_display_font())
	help_btn.add_theme_font_size_override("font_size", 14)
	help_btn.add_theme_color_override("font_color", Color("#5B1E45"))
	help_btn.add_theme_color_override("font_hover_color", Color("#2B0E21"))
	help_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_fame_help_popup(parent)
	)
	top_r.add_child(help_btn)

	# Banner Bottom Row: [Mic Circle] 64 [★★★★☆ / TERKENAL]   ...   [KLUB ●●●●○ ×1,05]
	var score_r := HBoxContainer.new()
	score_r.add_theme_constant_override("separation", 10)
	ban_vb.add_child(score_r)

	var mic_cc := CenterContainer.new()
	mic_cc.add_child(make_circle_icon_badge("mic", Color("#FCEBF4"), Color("#B93274"), 38.0))
	score_r.add_child(mic_cc)

	var big_sc := Label.new()
	big_sc.text = str(int(ov["score"]))
	big_sc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big_sc.add_theme_font_override("font", UITheme.get_display_font())
	big_sc.add_theme_font_size_override("font_size", 32)
	big_sc.add_theme_color_override("font_color", Color.WHITE)
	score_r.add_child(big_sc)

	var star_vb := VBoxContainer.new()
	star_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	star_vb.add_theme_constant_override("separation", 2)
	score_r.add_child(star_vb)
	var st_hb := HBoxContainer.new()
	st_hb.add_theme_constant_override("separation", 3)
	star_vb.add_child(st_hb)
	var s_cnt: int = int(ov["stars"])
	for si in range(5):
		var st_col: Color = Color("#FFFFFF") if si < s_cnt else Color("#4C203C")
		st_hb.add_child(make_icon("star", st_col, Vector2(12, 12)))
	var tier_l := Label.new()
	tier_l.text = str(ov["tier_label"])
	tier_l.add_theme_font_override("font", UITheme.get_display_font())
	tier_l.add_theme_font_size_override("font_size", 11)
	tier_l.add_theme_color_override("font_color", Color("#FDE7F3"))
	star_vb.add_child(tier_l)

	var sp_mid := Control.new()
	sp_mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_r.add_child(sp_mid)

	# Club Prestige Pill
	var club_pill := PanelContainer.new()
	club_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cpsb := StyleBoxFlat.new()
	cpsb.bg_color = Color(0.16, 0.06, 0.14, 0.72)
	cpsb.border_color = Color("#B85086")
	cpsb.set_border_width_all(1)
	cpsb.set_corner_radius_all(14)
	cpsb.content_margin_left = 10
	cpsb.content_margin_right = 10
	cpsb.content_margin_top = 4
	cpsb.content_margin_bottom = 4
	club_pill.add_theme_stylebox_override("panel", cpsb)
	score_r.add_child(club_pill)
	var cphb := HBoxContainer.new()
	cphb.add_theme_constant_override("separation", 5)
	club_pill.add_child(cphb)
	var bag_cc := CenterContainer.new()
	bag_cc.add_child(make_icon("bag", Color("#FCEBF4"), Vector2(11, 11)))
	cphb.add_child(bag_cc)
	var kl_t := Label.new()
	kl_t.text = "KLUB"
	kl_t.add_theme_font_override("font", UITheme.get_display_font())
	kl_t.add_theme_font_size_override("font_size", 9)
	kl_t.add_theme_color_override("font_color", Color("#FCEBF4"))
	cphb.add_child(kl_t)
	var cdots: int = int(ov["club_dots"])
	for di in range(5):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color("#FCEBF4") if di < cdots else Color("#532443")
		dsb.border_color = Color("#E87EB3")
		dsb.set_border_width_all(1)
		dsb.set_corner_radius_all(4)
		dot.add_theme_stylebox_override("panel", dsb)
		cphb.add_child(dot)
	var cm_t := Label.new()
	cm_t.text = "x%s" % format_comma(float(ov["club_mult"]), 2)
	cm_t.add_theme_font_override("font", UITheme.get_display_font())
	cm_t.add_theme_font_size_override("font_size", 11)
	cm_t.add_theme_color_override("font_color", Color.WHITE)
	cphb.add_child(cm_t)

	# --- MAIN 2-COLUMN BODY ---
	var body_m := MarginContainer.new()
	body_m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_m.add_theme_constant_override("margin_left", 14)
	body_m.add_theme_constant_override("margin_right", 14)
	body_m.add_theme_constant_override("margin_top", 10)
	body_m.add_theme_constant_override("margin_bottom", 12)
	vb.add_child(body_m)

	var body_vb := VBoxContainer.new()
	body_vb.add_theme_constant_override("separation", 10)
	body_m.add_child(body_vb)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	body_vb.add_child(cols)

	# LEFT: 5-Tier Stepped Pyramid Ladder
	var lad_vb := VBoxContainer.new()
	lad_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lad_vb.custom_minimum_size = Vector2(310, 0)
	lad_vb.add_theme_constant_override("separation", 5)
	cols.add_child(lad_vb)

	var tiers: Array = ov["tiers"]
	var cur_ti: int = int(ov["tier_idx"])
	var tier_prog: float = float(ov["tier_prog"])
	var step_indents: Array[int] = [108, 72, 48, 24, 0]

	for ti in range(tiers.size()):
		var td: Dictionary = tiers[ti]
		var is_cur: bool = (ti == cur_ti)
		var row_hb := HBoxContainer.new()
		row_hb.add_theme_constant_override("separation", 6)
		lad_vb.add_child(row_hb)

		var indent_w: int = step_indents[ti]
		if is_cur:
			var kau_box := HBoxContainer.new()
			kau_box.custom_minimum_size = Vector2(maxi(64, indent_w), 0)
			kau_box.alignment = BoxContainer.ALIGNMENT_END
			kau_box.add_theme_constant_override("separation", 4)
			row_hb.add_child(kau_box)
			var k_ic := CenterContainer.new()
			k_ic.add_child(make_circle_icon_badge("mic", Color("#FCEBF4"), Color("#B93274"), 18.0))
			kau_box.add_child(k_ic)
			var k_lbl := Label.new()
			k_lbl.text = "KAU"
			k_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			k_lbl.add_theme_font_override("font", UITheme.get_display_font())
			k_lbl.add_theme_font_size_override("font_size", 10)
			k_lbl.add_theme_color_override("font_color", Color.WHITE)
			kau_box.add_child(k_lbl)
		elif indent_w > 0:
			var sp_i := Control.new()
			sp_i.custom_minimum_size = Vector2(indent_w, 0)
			row_hb.add_child(sp_i)

		var bar := PanelContainer.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 42 if is_cur else 29)
		var base_c: Color = td["color"]
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = base_c if is_cur else base_c.darkened(0.08)
		bsb.border_color = Color("#FFFFFF") if is_cur else base_c.lightened(0.18)
		bsb.set_border_width_all(2 if is_cur else 1)
		bsb.set_corner_radius_all(4)
		bsb.content_margin_left = 8
		bsb.content_margin_right = 8
		bsb.content_margin_top = 4
		bsb.content_margin_bottom = 4
		bar.add_theme_stylebox_override("panel", bsb)
		row_hb.add_child(bar)

		var bvb := VBoxContainer.new()
		bvb.alignment = BoxContainer.ALIGNMENT_CENTER
		bvb.add_theme_constant_override("separation", 3)
		bar.add_child(bvb)

		var bhb := HBoxContainer.new()
		bhb.add_theme_constant_override("separation", 6)
		bvb.add_child(bhb)
		var txt_col: Color = td["text_col"]
		var ic_cc := CenterContainer.new()
		ic_cc.add_child(make_icon(str(td["icon"]), txt_col, Vector2(12, 12)))
		bhb.add_child(ic_cc)
		var tl := Label.new()
		tl.text = str(td["label"])
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.add_theme_font_override("font", UITheme.get_display_font())
		tl.add_theme_font_size_override("font_size", 11)
		tl.add_theme_color_override("font_color", txt_col)
		bhb.add_child(tl)
		var mn := Label.new()
		mn.text = str(int(td["min"]))
		mn.add_theme_font_override("font", UITheme.get_display_font())
		mn.add_theme_font_size_override("font_size", 11)
		mn.add_theme_color_override("font_color", txt_col)
		bhb.add_child(mn)

		if is_cur:
			var pg_bg := PanelContainer.new()
			pg_bg.custom_minimum_size = Vector2(0, 5)
			var pbg_sb := StyleBoxFlat.new()
			pbg_sb.bg_color = Color(0.12, 0.04, 0.09, 0.45)
			pbg_sb.set_corner_radius_all(2)
			pg_bg.add_theme_stylebox_override("panel", pbg_sb)
			bvb.add_child(pg_bg)
			var pg_bar := ProgressBar.new()
			pg_bar.show_percentage = false
			pg_bar.max_value = 100.0
			pg_bar.value = clampf(tier_prog * 100.0, 4.0, 100.0)
			pg_bar.custom_minimum_size = Vector2(0, 5)
			var p_fill := StyleBoxFlat.new()
			p_fill.bg_color = Color("#FFFFFF")
			p_fill.set_corner_radius_all(2)
			var p_emp := StyleBoxFlat.new()
			p_emp.bg_color = Color(0.15, 0.05, 0.12, 0.35)
			p_emp.set_corner_radius_all(2)
			pg_bar.add_theme_stylebox_override("fill", p_fill)
			pg_bar.add_theme_stylebox_override("background", p_emp)
			pg_bg.add_child(pg_bar)

	var next_lbl := Label.new()
	var n_txt: String = str(ov["next_label"])
	if n_txt.is_empty():
		next_lbl.text = "TINGKAT TERTINGGI TERCAPAI!"
		next_lbl.add_theme_color_override("font_color", GOLD_TXT)
	else:
		next_lbl.text = "%d LAGI KE %s" % [int(ov["pts_to_next"]), n_txt]
		next_lbl.add_theme_color_override("font_color", Color("#CBD5E1"))
	next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next_lbl.add_theme_font_override("font", UITheme.get_display_font())
	next_lbl.add_theme_font_size_override("font_size", 9)
	lad_vb.add_child(next_lbl)

	# RIGHT: BONUS (NILAI / MEREK / JERSEY) + NAIK (WAWANCARA / GOL / GELAR) + DROP (SKANDAL)
	var r_vb := VBoxContainer.new()
	r_vb.custom_minimum_size = Vector2(252, 0)
	r_vb.add_theme_constant_override("separation", 7)
	cols.add_child(r_vb)

	# Gold BONUS pill header
	r_vb.add_child(_make_fame_pill("• BONUS", Color("#E8AF2A"), Color("#291A04")))

	var bonus_hb := HBoxContainer.new()
	bonus_hb.add_theme_constant_override("separation", 6)
	r_vb.add_child(bonus_hb)
	for bdef in [
		["NILAI", "bag", bool(ov["bonus_nilai"])],
		["MEREK", "brand_d", bool(ov["bonus_merek"])],
		["JERSEY", "shirt", bool(ov["bonus_jersey"])],
	]:
		var unlocked: bool = bool(bdef[2])
		var bc := PanelContainer.new()
		bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bc.custom_minimum_size = Vector2(0, 62)
		var bcsb := StyleBoxFlat.new()
		bcsb.bg_color = Color("#2C2618") if unlocked else Color("#151F30")
		bcsb.border_color = Color("#A8842E") if unlocked else Color("#243652")
		bcsb.set_border_width_all(1)
		bcsb.set_corner_radius_all(5)
		bcsb.content_margin_top = 6
		bcsb.content_margin_bottom = 5
		bc.add_theme_stylebox_override("panel", bcsb)
		var bcvb := VBoxContainer.new()
		bcvb.alignment = BoxContainer.ALIGNMENT_CENTER
		bcvb.add_theme_constant_override("separation", 4)
		bc.add_child(bcvb)
		var ic_cc := CenterContainer.new()
		ic_cc.add_child(make_circle_icon_badge(str(bdef[1]), Color("#F2C438") if unlocked else Color("#3E4C63"), Color("#231704") if unlocked else Color("#94A3B8"), 26.0))
		bcvb.add_child(ic_cc)
		var bl := Label.new()
		bl.text = str(bdef[0])
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.add_theme_font_override("font", UITheme.get_display_font())
		bl.add_theme_font_size_override("font_size", 9)
		bl.add_theme_color_override("font_color", Color.WHITE if unlocked else Color("#6B7D96"))
		bcvb.add_child(bl)
		bonus_hb.add_child(bc)

	# Bottom Right Split: NAIK (left 65%) | DROP (right 35%)
	var nd_hb := HBoxContainer.new()
	nd_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nd_hb.add_theme_constant_override("separation", 8)
	r_vb.add_child(nd_hb)

	var naik_vb := VBoxContainer.new()
	naik_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	naik_vb.size_flags_stretch_ratio = 1.65
	naik_vb.add_theme_constant_override("separation", 5)
	nd_hb.add_child(naik_vb)
	naik_vb.add_child(_make_fame_pill("NAIK", Color("#E0649E"), Color("#290B1A")))
	for ndef in [
		["WAWANCARA", "mic"],
		["GOL", "goal"],
		["GELAR", "trophy"],
	]:
		var nc := PanelContainer.new()
		nc.custom_minimum_size = Vector2(0, 30)
		nc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A233A"), Color("#3B2B4B"), 1, 4))
		var nhb := HBoxContainer.new()
		nhb.add_theme_constant_override("separation", 8)
		nc.add_child(nhb)
		var nic := CenterContainer.new()
		nic.add_child(make_circle_icon_badge(str(ndef[1]), Color("#E0649E"), Color("#290B1A"), 20.0))
		nhb.add_child(nic)
		var nl := Label.new()
		nl.text = str(ndef[0])
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.add_theme_font_override("font", UITheme.get_display_font())
		nl.add_theme_font_size_override("font_size", 9)
		nl.add_theme_color_override("font_color", Color.WHITE)
		nhb.add_child(nl)
		naik_vb.add_child(nc)

	var drop_vb := VBoxContainer.new()
	drop_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_vb.size_flags_stretch_ratio = 1.0
	drop_vb.add_theme_constant_override("separation", 5)
	nd_hb.add_child(drop_vb)
	drop_vb.add_child(_make_fame_pill("DROP", Color("#EB5B49"), Color("#2B0B08")))

	var sk_card := PanelContainer.new()
	sk_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sksb := StyleBoxFlat.new()
	sksb.bg_color = Color("#2C1928")
	sksb.border_color = Color("#7A313D")
	sksb.set_border_width_all(1)
	sksb.set_corner_radius_all(5)
	sksb.content_margin_top = 8
	sksb.content_margin_bottom = 8
	sk_card.add_theme_stylebox_override("panel", sksb)
	var skvb := VBoxContainer.new()
	skvb.alignment = BoxContainer.ALIGNMENT_CENTER
	skvb.add_theme_constant_override("separation", 8)
	sk_card.add_child(skvb)
	var sk_ic := CenterContainer.new()
	sk_ic.add_child(make_circle_icon_badge("red_card", Color("#EB5B49"), Color("#220706"), 32.0))
	skvb.add_child(sk_ic)
	var sk_l := Label.new()
	sk_l.text = "SKANDAL"
	sk_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sk_l.add_theme_font_override("font", UITheme.get_display_font())
	sk_l.add_theme_font_size_override("font_size", 10)
	sk_l.add_theme_color_override("font_color", Color("#F87171"))
	skvb.add_child(sk_l)
	drop_vb.add_child(sk_card)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 34)
	_style_btn(cls, Color("#1C304E"), Color("#436089"), 11)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	body_vb.add_child(cls)
	return layer

static func _make_fame_pill(txt: String, bg: Color, fg: Color) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", UITheme.get_display_font())
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", fg)
	pc.add_child(l)
	hb.add_child(pc)
	return hb

# ==============================================================================
# 12. CARANYA? FAME HELP POPUP (Gambar 9, layer = 21 above KETENARAN!)
# ==============================================================================
static func open_fame_help_popup(parent: Node) -> CanvasLayer:
	var ov: Dictionary = CareerState.get_fame_overview()
	var built: Dictionary = _create_modal_layer(parent, Vector2(584, 354), Color("#11223A"), 21, 0, 0)
	var layer: CanvasLayer = built["layer"]
	var vb: VBoxContainer = built["vb"]
	vb.add_theme_constant_override("separation", 0)

	# Pink Sunburst Header
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(0, 56)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.clip_contents = true
	vb.add_child(banner)

	var sb_bg := SunburstHeaderBg.new()
	sb_bg.ray_center_ratio = Vector2(0.50, 0.92)
	sb_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sb_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(sb_bg)

	var ttl := Label.new()
	ttl.text = "CARANYA?"
	ttl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 21)
	ttl.add_theme_color_override("font_color", Color.WHITE)
	banner.add_child(ttl)

	var body_m := MarginContainer.new()
	body_m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_m.add_theme_constant_override("margin_left", 14)
	body_m.add_theme_constant_override("margin_right", 14)
	body_m.add_theme_constant_override("margin_top", 12)
	body_m.add_theme_constant_override("margin_bottom", 12)
	vb.add_child(body_m)

	var body_vb := VBoxContainer.new()
	body_vb.add_theme_constant_override("separation", 12)
	body_m.add_child(body_vb)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body_vb.add_child(grid)

	var cards: Array = [
		{
			"title": "MAIN",
			"body": "Bermain bagus dan mencetak gol membuatmu terkenal. Di klub besar, lebih lagi.",
			"icon": "pitch",
			"accent": Color("#E0649E"),
			"bg": Color("#1D223B"),
			"show_club": true,
		},
		{
			"title": "CAKAP",
			"body": "Setiap wawancara menaikkannya.",
			"icon": "mic",
			"accent": Color("#E0649E"),
			"bg": Color("#1D223B"),
			"show_club": false,
		},
		{
			"title": "RAIH",
			"body": "Setiap gelar membawamu ke halaman depan.",
			"icon": "trophy",
			"accent": Color("#E0649E"),
			"bg": Color("#1D223B"),
			"show_club": false,
		},
		{
			"title": "AWAS",
			"body": "Kontroversi menurunkannya, dan tiap pertandingan orang lupa sedikit.",
			"icon": "red_card",
			"accent": Color("#EB5B49"),
			"bg": Color("#281D31"),
			"show_club": false,
		},
	]

	for c_item in cards:
		var cd: Dictionary = c_item
		var acc: Color = cd["accent"]
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var pcsb := StyleBoxFlat.new()
		pcsb.bg_color = cd["bg"]
		pcsb.border_color = Color("#2C3D5C")
		pcsb.set_border_width_all(1)
		pcsb.set_corner_radius_all(6)
		pcsb.content_margin_left = 12
		pcsb.content_margin_right = 12
		pcsb.content_margin_top = 10
		pcsb.content_margin_bottom = 10
		pc.add_theme_stylebox_override("panel", pcsb)
		grid.add_child(pc)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		pc.add_child(hb)

		var ic_cc := CenterContainer.new()
		ic_cc.add_child(make_circle_icon_badge(str(cd["icon"]), acc, Color("#240A18"), 38.0))
		hb.add_child(ic_cc)

		var cvb := VBoxContainer.new()
		cvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cvb.alignment = BoxContainer.ALIGNMENT_CENTER
		cvb.add_theme_constant_override("separation", 4)
		hb.add_child(cvb)

		var ct := Label.new()
		ct.text = str(cd["title"])
		ct.add_theme_font_override("font", UITheme.get_display_font())
		ct.add_theme_font_size_override("font_size", 11)
		ct.add_theme_color_override("font_color", acc)
		cvb.add_child(ct)

		var cb := Label.new()
		cb.text = str(cd["body"])
		cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cb.add_theme_font_size_override("font_size", 10)
		cb.add_theme_color_override("font_color", Color("#F1F5F9"))
		cvb.add_child(cb)

		if bool(cd["show_club"]):
			var m_hb := HBoxContainer.new()
			m_hb.add_theme_constant_override("separation", 4)
			cvb.add_child(m_hb)
			var mb_cc := CenterContainer.new()
			mb_cc.add_child(make_icon("bag", Color("#E0649E"), Vector2(10, 10)))
			m_hb.add_child(mb_cc)
			var cdots: int = int(ov["club_dots"])
			for di in range(5):
				var dot := PanelContainer.new()
				dot.custom_minimum_size = Vector2(7, 7)
				dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				var dsb := StyleBoxFlat.new()
				dsb.bg_color = Color("#FCEBF4") if di < cdots else Color("#4C2441")
				dsb.set_corner_radius_all(4)
				dot.add_theme_stylebox_override("panel", dsb)
				m_hb.add_child(dot)
			var ml := Label.new()
			ml.text = "x%s" % format_comma(float(ov["club_mult"]), 2)
			ml.add_theme_font_override("font", UITheme.get_display_font())
			ml.add_theme_font_size_override("font_size", 10)
			ml.add_theme_color_override("font_color", Color("#CBD5E1"))
			m_hb.add_child(ml)

	var cls := Button.new()
	cls.text = "TUTUP"
	cls.custom_minimum_size = Vector2(0, 34)
	_style_btn(cls, Color("#1C304E"), Color("#436089"), 11)
	cls.pressed.connect(func(): AudioSynth.play_click(); layer.queue_free())
	body_vb.add_child(cls)
	return layer
