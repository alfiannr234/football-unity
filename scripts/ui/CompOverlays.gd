extends RefCounted

const ZONE_BLUE := Color("#2563EB")
const ZONE_ORANGE := Color("#F97316")
const ZONE_CYAN := Color("#14B8A6")
const ZONE_GREEN := Color("#22C55E")
const ZONE_RED := Color("#EF4444")
const GOLD_STAT := Color("#F5C430")
const BG_OVERLAY := Color("#070F1C")
const BG_CARD := Color("#0B1626")
const BG_BTN := Color("#111D30")
const BORDER_SUBTLE := Color("#1F334F")

static func get_zone_color(zone: String) -> Color:
	match zone:
		"ELITE": return ZONE_BLUE
		"EUROPA": return ZONE_ORANGE
		"CHALLENGE": return ZONE_CYAN
		"PROMO": return ZONE_GREEN
		"RELEG": return ZONE_RED
	return Color(0, 0, 0, 0)

static func format_rating_id(val: float) -> String:
	return ("%.1f" % val).replace(".", ",")

static func make_icon(kind: String, col: Color = Color("#CBD5E1"), sz: Vector2 = Vector2(14, 14)) -> Control:
	var ic := CompIconControl.new()
	ic.icon_kind = kind
	ic.icon_color = col
	ic.custom_minimum_size = sz
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic

static func _make_zone_bar(zone: String, bar_h: float = 20.0) -> Control:
	var cr := ColorRect.new()
	cr.custom_minimum_size = Vector2(3, bar_h)
	cr.color = get_zone_color(zone)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cr

static func _style_flat_btn(btn: Button, bg: Color, border: Color, font_sz: int = 12, text_col: Color = UITheme.TEXT_WHITE) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.border_color = border
	n.set_border_width_all(1)
	n.set_corner_radius_all(3)
	n.content_margin_left = 8
	n.content_margin_right = 8
	n.content_margin_top = 4
	n.content_margin_bottom = 4
	var h := n.duplicate()
	h.bg_color = bg.lightened(0.14)
	h.border_color = UITheme.BORDER_CYAN
	var p := n.duplicate()
	p.bg_color = bg.darkened(0.12)
	p.border_color = GOLD_STAT
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", UITheme.TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", GOLD_STAT)

static func _create_layer(parent: Node) -> Dictionary:
	var layer := OverlayCanvasLayer.new()
	layer.layer = 20
	parent.add_child(layer)

	var root := Control.new()
	root.theme = UITheme.build_theme()
	root.clip_contents = true
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = BG_OVERLAY
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return {"layer": layer, "root": root}

# ==============================================================================
# 1. NEGARA & DIVISI FILTER OVERLAY (Gambar 3)
# ==============================================================================
static func open_nation_filter(parent: Node, cur_nat_idx: int, cur_div: int, on_selected: Callable) -> CanvasLayer:
	var built: Dictionary = _create_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var state := {
		"nat_idx": clampi(cur_nat_idx, 0, GameData.nations.size() - 1),
		"div": clampi(cur_div, 1, 3),
		"letter": "",
	}
	var cur_name: String = str(GameData.nations[int(state["nat_idx"])].get("name", "S")).to_upper()
	state["letter"] = cur_name.left(1)

	# Collect distinct starting letters sorted A..Z
	var letter_map: Dictionary = {}
	for nat in GameData.nations:
		var nm: String = str(nat.get("name", "")).to_upper()
		if nm.length() > 0:
			letter_map[nm.left(1)] = true
	var letters: Array[String] = []
	for k in letter_map.keys():
		letters.append(str(k))
	letters.sort()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title := Label.new()
	title.text = "NEGARA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	outer.add_child(title)

	# Alphabet strip
	var alpha_hb := HBoxContainer.new()
	alpha_hb.add_theme_constant_override("separation", 4)
	alpha_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(alpha_hb)

	# Division strip
	var div_hb := HBoxContainer.new()
	div_hb.add_theme_constant_override("separation", 6)
	div_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(div_hb)

	# Country card scroll + 4-col grid
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)

	# Render helper using Dictionary callback trick for GDScript self-recursion
	var render_ref := {}
	render_ref["fn"] = func() -> void:
		for c in alpha_hb.get_children():
			alpha_hb.remove_child(c)
			c.queue_free()
		var all_letters: Array[String] = []
		for lt in letters:
			all_letters.append(lt)
		all_letters.append("SEMUA")
		for lt in all_letters:
			var ab := Button.new()
			ab.text = lt
			ab.custom_minimum_size = Vector2(52 if lt == "SEMUA" else 30, 28)
			var is_act: bool = (str(state["letter"]) == lt)
			_style_flat_btn(ab, Color("#242D4A") if is_act else Color("#0B1322"), UITheme.ACCENT_CYAN if is_act else Color("#1D2B42"), 11, UITheme.TEXT_WHITE if is_act else Color("#CBD5E1"))
			var lt_copy: String = lt
			ab.pressed.connect(func():
				AudioSynth.play_click()
				state["letter"] = lt_copy
				render_ref["fn"].call()
			)
			alpha_hb.add_child(ab)

		for c in div_hb.get_children():
			div_hb.remove_child(c)
			c.queue_free()
		var div_labels: Array[String] = ["KE-1 • PERTAMA", "KE-2 • KEDUA", "KE-3 • KETIGA"]
		for d_i in range(3):
			var d_val: int = d_i + 1
			var db := Button.new()
			db.text = div_labels[d_i]
			db.custom_minimum_size = Vector2(150, 28)
			var d_act: bool = (int(state["div"]) == d_val)
			_style_flat_btn(db, Color("#18355E") if d_act else Color("#0B1322"), GOLD_STAT if d_act else Color("#1D2B42"), 11, GOLD_STAT if d_act else UITheme.TEXT_MUTED)
			db.pressed.connect(func():
				AudioSynth.play_click()
				state["div"] = d_val
				on_selected.call(int(state["nat_idx"]), int(state["div"]))
				render_ref["fn"].call()
			)
			div_hb.add_child(db)

		if CareerState.has_active_career:
			var my_b := Button.new()
			my_b.text = "LIGA SAYA"
			my_b.custom_minimum_size = Vector2(100, 28)
			_style_flat_btn(my_b, Color("#153554"), UITheme.ACCENT_CYAN, 11, UITheme.ACCENT_CYAN)
			my_b.pressed.connect(func():
				AudioSynth.play_click()
				var uc: Dictionary = CareerState.get_current_club()
				var unid: int = clampi(int(uc.get("nation_id", 0)), 0, GameData.nations.size() - 1)
				var udiv: int = clampi(int(uc.get("division", 3)), 1, 3)
				on_selected.call(unid, udiv)
				layer.queue_free()
			)
			div_hb.add_child(my_b)

		for c in grid.get_children():
			grid.remove_child(c)
			c.queue_free()
		var active_l: String = str(state["letter"])
		var matched: Array[Dictionary] = []
		for nat in GameData.nations:
			var nm: String = str(nat.get("name", "")).to_upper()
			if active_l == "SEMUA" or nm.begins_with(active_l):
				matched.append(nat)
		matched.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("name", "")) < str(b.get("name", ""))
		)
		for nat in matched:
			var nid: int = int(nat["id"])
			var is_sel: bool = (nid == int(state["nat_idx"]))
			var card_btn := Button.new()
			card_btn.custom_minimum_size = Vector2(0, 48)
			card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_flat_btn(card_btn, Color("#242848") if is_sel else Color("#0B1424"), Color("#6366F1") if is_sel else Color("#1A2940"), 12)
			var inner_hb := HBoxContainer.new()
			inner_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
			inner_hb.offset_left = 10
			inner_hb.offset_right = -10
			inner_hb.add_theme_constant_override("separation", 10)
			inner_hb.alignment = BoxContainer.ALIGNMENT_BEGIN
			inner_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_btn.add_child(inner_hb)

			var flag_wrap := CenterContainer.new()
			flag_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flag_wrap.add_child(UITheme.make_flag_rect(nid, Vector2(26, 18)))
			inner_hb.add_child(flag_wrap)

			var nlbl := Label.new()
			nlbl.text = str(nat.get("name", "NEGARA")).to_upper()
			nlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nlbl.clip_text = true
			nlbl.add_theme_font_override("font", UITheme.get_display_font())
			nlbl.add_theme_font_size_override("font_size", 12)
			nlbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			nlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner_hb.add_child(nlbl)

			card_btn.pressed.connect(func():
				AudioSynth.play_click()
				on_selected.call(nid, int(state["div"]))
				layer.queue_free()
			)
			grid.add_child(card_btn)

	render_ref["fn"].call()

	# Bottom full-width TUTUP button (Gambar 3)
	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 38)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_flat_btn(close_b, Color("#111B2D"), Color("#24354F"), 13, Color("#CBD5E1"))
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	outer.add_child(close_b)
	return layer

# ==============================================================================
# 2. FULL LEAGUE STANDINGS OVERLAY (Gambar 4 Inggris, Gambar 5 Italia, Gambar 6 Jerman)
# ==============================================================================
static func open_full_standings(parent: Node, nat_id: int, div_num: int, on_div_changed: Callable = Callable()) -> CanvasLayer:
	var built: Dictionary = _create_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var state := {
		"nat_id": clampi(nat_id, 0, GameData.nations.size() - 1),
		"div": clampi(div_num, 1, 3),
	}

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	margin.add_child(outer)

	var render_ref := {}
	render_ref["fn"] = func() -> void:
		for c in outer.get_children():
			outer.remove_child(c)
			c.queue_free()

		var nid: int = int(state["nat_id"])
		var d_num: int = int(state["div"])
		var rows: Array[Dictionary] = CareerState.get_live_division_table(nid, d_num)
		var total_teams: int = rows.size()
		var rules: Dictionary = CareerState.get_league_zone_rules(nid, d_num, total_teams)
		var accent: Color = rules["accent_color"]
		var div_word: String = ["PERTAMA", "KEDUA", "KETIGA"][clampi(d_num - 1, 0, 2)]
		var nat_name: String = str(GameData.nations[nid].get("name", "LIGA")).to_upper()
		var my_cid: int = int(CareerState.get_current_club().get("id", -1)) if CareerState.has_active_career else -1

		# Top bar: Left nation + quick div pills | Center KLASEMEN • PERTAMA | Right TUTUP
		var top_hb := HBoxContainer.new()
		top_hb.add_theme_constant_override("separation", 8)
		outer.add_child(top_hb)

		var left_hb := HBoxContainer.new()
		left_hb.add_theme_constant_override("separation", 6)
		left_hb.custom_minimum_size = Vector2(230, 0)
		top_hb.add_child(left_hb)

		var fl_wrap := CenterContainer.new()
		fl_wrap.add_child(UITheme.make_flag_rect(nid, Vector2(20, 14)))
		left_hb.add_child(fl_wrap)

		var nat_lbl := Label.new()
		nat_lbl.text = nat_name
		nat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nat_lbl.add_theme_font_size_override("font_size", 11)
		nat_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		left_hb.add_child(nat_lbl)

		for d_i in [1, 2, 3]:
			var qdb := Button.new()
			qdb.text = "K%d" % d_i
			qdb.custom_minimum_size = Vector2(30, 24)
			var is_cur_d: bool = (d_num == d_i)
			_style_flat_btn(qdb, Color("#172C4C") if is_cur_d else Color("#0B1424"), accent if is_cur_d else Color("#1D2E48"), 10, accent if is_cur_d else UITheme.TEXT_MUTED)
			var dv: int = d_i
			qdb.pressed.connect(func():
				AudioSynth.play_click()
				state["div"] = dv
				if on_div_changed.is_valid():
					on_div_changed.call(dv)
				render_ref["fn"].call()
			)
			left_hb.add_child(qdb)

		var title := Label.new()
		title.text = "KLASEMEN  •  %s" % div_word
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_font_override("font", UITheme.get_display_font())
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", accent)
		top_hb.add_child(title)

		var right_box := HBoxContainer.new()
		right_box.custom_minimum_size = Vector2(230, 0)
		right_box.alignment = BoxContainer.ALIGNMENT_END
		top_hb.add_child(right_box)

		var close_b := Button.new()
		close_b.text = "TUTUP"
		close_b.custom_minimum_size = Vector2(92, 32)
		_style_flat_btn(close_b, Color("#121D2F"), Color("#273A56"), 12, Color("#E2E8F0"))
		close_b.pressed.connect(func():
			AudioSynth.play_click()
			layer.queue_free()
		)
		right_box.add_child(close_b)

		# Centered table container matching Gambar 4, 5, 6 proportions
		var center_wrap := CenterContainer.new()
		center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		outer.add_child(center_wrap)

		var tbl_vb := VBoxContainer.new()
		tbl_vb.custom_minimum_size = Vector2(610, 444)
		tbl_vb.add_theme_constant_override("separation", 2)
		center_wrap.add_child(tbl_vb)

		# Column header row (M  S  K  SG  PTS)
		var hdr := HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 6)
		tbl_vb.add_child(hdr)
		var sp_h := Control.new()
		sp_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hdr.add_child(sp_h)
		for col_def in [["M", 32], ["S", 32], ["K", 32], ["SG", 42], ["PTS", 44]]:
			var hl := Label.new()
			hl.text = str(col_def[0])
			hl.custom_minimum_size = Vector2(int(col_def[1]), 14)
			hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hl.add_theme_font_size_override("font_size", 10)
			hl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			hdr.add_child(hl)

		# Scrollable rows (20 teams fit cleanly without scrolling at 20px row height!)
		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tbl_vb.add_child(sc)

		var rows_vb := VBoxContainer.new()
		rows_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows_vb.add_theme_constant_override("separation", 1)
		sc.add_child(rows_vb)

		for i in range(total_teams):
			var r: Dictionary = rows[i]
			var rk: int = i + 1
			var cid: int = int(r["club_id"])
			var is_mine: bool = (cid == my_cid)
			var zone: String = CareerState.get_zone_for_rank(nid, d_num, rk, total_teams)

			var row_bg := PanelContainer.new()
			var rsb := StyleBoxFlat.new()
			rsb.bg_color = Color("#2C1524") if is_mine else Color(0, 0, 0, 0)
			rsb.set_border_width_all(0)
			rsb.set_corner_radius_all(2)
			rsb.content_margin_left = 0
			rsb.content_margin_right = 4
			rsb.content_margin_top = 0
			rsb.content_margin_bottom = 0
			row_bg.add_theme_stylebox_override("panel", rsb)
			row_bg.custom_minimum_size = Vector2(0, 20)
			rows_vb.add_child(row_bg)

			var rhb := HBoxContainer.new()
			rhb.add_theme_constant_override("separation", 6)
			row_bg.add_child(rhb)

			# Left vertical colored zone bar (3px)
			rhb.add_child(_make_zone_bar(zone, 18.0))

			# Rank number
			var rkl := Label.new()
			rkl.text = str(rk)
			rkl.custom_minimum_size = Vector2(22, 0)
			rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			rkl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			rkl.add_theme_font_size_override("font_size", 12)
			rkl.add_theme_color_override("font_color", UITheme.TEXT_WHITE if is_mine else Color("#CBD5E1"))
			rhb.add_child(rkl)

			# Mini ClubCrest
			var cr_wrap := CenterContainer.new()
			var crest := ClubCrest.new()
			crest.custom_minimum_size = Vector2(16, 16)
			crest.set_club(cid)
			cr_wrap.add_child(crest)
			rhb.add_child(cr_wrap)

			# Club Name
			var cnm := Label.new()
			cnm.text = "%s%s" % [str(r["name"]), " (KAMU)" if is_mine else ""]
			cnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cnm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cnm.clip_text = true
			cnm.add_theme_font_size_override("font_size", 12)
			cnm.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if is_mine else UITheme.TEXT_WHITE)
			rhb.add_child(cnm)

			var gd: int = int(r.get("gf", 0)) - int(r.get("ga", 0))
			var gd_str: String = ("+%d" % gd) if gd > 0 else str(gd)
			for st_def in [
				[str(int(r.get("w", 0))), 32, Color("#E2E8F0"), false],
				[str(int(r.get("d", 0))), 32, Color("#E2E8F0"), false],
				[str(int(r.get("l", 0))), 32, Color("#E2E8F0"), false],
				[gd_str, 42, Color("#E2E8F0"), false],
				[str(int(r.get("pts", 0))), 44, accent, true],
			]:
				var sl := Label.new()
				sl.text = str(st_def[0])
				sl.custom_minimum_size = Vector2(int(st_def[1]), 0)
				sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				if bool(st_def[3]):
					sl.add_theme_font_override("font", UITheme.get_display_font())
					sl.add_theme_font_size_override("font_size", 13)
				else:
					sl.add_theme_font_size_override("font_size", 12)
				sl.add_theme_color_override("font_color", st_def[2])
				rhb.add_child(sl)

		# Compact Zone Color Legend footer
		var leg_hb := HBoxContainer.new()
		leg_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		leg_hb.add_theme_constant_override("separation", 14)
		outer.add_child(leg_hb)

		var leg_items: Array = []
		if d_num == 1:
			var ee: int = int(rules["elite_end"])
			var es: int = int(rules["europa_start"])
			var eu_e: int = int(rules["europa_end"])
			var cs: int = int(rules["challenge_start"])
			var ce: int = int(rules["challenge_end"])
			var rs: int = int(rules["releg_start"])
			if ee > 0:
				leg_items.append([ZONE_BLUE, "1-%d ELITE" % ee])
			if es > 0:
				var eu_rng: String = ("%d-%d" % [es, eu_e]) if eu_e > es else str(es)
				leg_items.append([ZONE_ORANGE, "%s EUROPA" % eu_rng])
			if cs > 0:
				var ch_rng: String = ("%d-%d" % [cs, ce]) if ce > cs else str(cs)
				leg_items.append([ZONE_CYAN, "%s CHALLENGE" % ch_rng])
			if rs > 0:
				leg_items.append([ZONE_RED, "%d-%d DEGRADASI (DIV 2)" % [rs, total_teams]])
		elif d_num == 2:
			leg_items.append([ZONE_GREEN, "1-3 PROMOSI (DIV 1)"])
			var rs2: int = int(rules["releg_start"])
			if rs2 > 0:
				leg_items.append([ZONE_RED, "%d-%d DEGRADASI (DIV 3)" % [rs2, total_teams]])
		else:
			leg_items.append([ZONE_GREEN, "1-3 PROMOSI (DIV 2)"])

		for li in leg_items:
			var item_hb := HBoxContainer.new()
			item_hb.add_theme_constant_override("separation", 5)
			var sw := ColorRect.new()
			sw.custom_minimum_size = Vector2(8, 10)
			sw.color = li[0]
			var sw_c := CenterContainer.new()
			sw_c.add_child(sw)
			item_hb.add_child(sw_c)
			var ll := Label.new()
			ll.text = str(li[1])
			ll.add_theme_font_size_override("font_size", 10)
			ll.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			item_hb.add_child(ll)
			leg_hb.add_child(item_hb)

	render_ref["fn"].call()
	return layer

# ==============================================================================
# 3. TOP SKOR OVERLAY — TOP 10 GOL | ASSIST | RATING (Gambar 7)
# ==============================================================================
static func open_top_scorers(parent: Node, nat_id: int, div_num: int) -> CanvasLayer:
	var built: Dictionary = _create_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var nid: int = clampi(nat_id, 0, GameData.nations.size() - 1)
	var d_num: int = clampi(div_num, 1, 3)
	var stats: Dictionary = CareerState.get_division_top_stats(nid, d_num)
	var nat_name: String = str(GameData.nations[nid].get("name", "LIGA")).to_upper()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	# Compact league context strip
	var ctx_hb := HBoxContainer.new()
	ctx_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	ctx_hb.add_theme_constant_override("separation", 8)
	outer.add_child(ctx_hb)
	var fl_c := CenterContainer.new()
	fl_c.add_child(UITheme.make_flag_rect(nid, Vector2(20, 14)))
	ctx_hb.add_child(fl_c)
	var ctx_lbl := Label.new()
	ctx_lbl.text = "LIGA %s  •  KE-%d" % [nat_name, d_num]
	ctx_lbl.add_theme_font_size_override("font_size", 11)
	ctx_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	ctx_hb.add_child(ctx_lbl)

	# 3 Equal Columns side-by-side (GOL | ASSIST | RATING)
	var cols_hb := HBoxContainer.new()
	cols_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols_hb.add_theme_constant_override("separation", 14)
	outer.add_child(cols_hb)

	var col_specs := [
		{"title": "TOP 10  •  GOL", "key": "goals", "icon": "ball", "is_float": false},
		{"title": "TOP 10  •  ASSIST", "key": "assists", "icon": "assist", "is_float": false},
		{"title": "TOP 10  •  RATING", "key": "rating", "icon": "star", "is_float": true},
	]

	for spec in col_specs:
		var col_vb := VBoxContainer.new()
		col_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col_vb.add_theme_constant_override("separation", 4)
		cols_hb.add_child(col_vb)

		var c_title := Label.new()
		c_title.text = str(spec["title"])
		c_title.add_theme_font_override("font", UITheme.get_display_font())
		c_title.add_theme_font_size_override("font_size", 13)
		c_title.add_theme_color_override("font_color", GOLD_STAT)
		col_vb.add_child(c_title)

		# Column sub-header: PEMAIN | MN | Icon
		var sub_hb := HBoxContainer.new()
		sub_hb.add_theme_constant_override("separation", 6)
		col_vb.add_child(sub_hb)
		var sub_sp := Control.new()
		sub_sp.custom_minimum_size = Vector2(36, 0)
		sub_hb.add_child(sub_sp)
		var sub_p := Label.new()
		sub_p.text = "PEMAIN"
		sub_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_p.add_theme_font_size_override("font_size", 10)
		sub_p.add_theme_color_override("font_color", Color("#94A3B8"))
		sub_hb.add_child(sub_p)
		var sub_mn := Label.new()
		sub_mn.text = "MN"
		sub_mn.custom_minimum_size = Vector2(26, 0)
		sub_mn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sub_mn.add_theme_font_size_override("font_size", 10)
		sub_mn.add_theme_color_override("font_color", Color("#94A3B8"))
		sub_hb.add_child(sub_mn)
		var ic_wrap := CenterContainer.new()
		ic_wrap.custom_minimum_size = Vector2(36, 14)
		ic_wrap.add_child(make_icon(str(spec["icon"]), GOLD_STAT, Vector2(13, 13)))
		sub_hb.add_child(ic_wrap)

		# Top 10 rows
		var entries: Array = stats.get(str(spec["key"]), [])
		var is_flt: bool = bool(spec["is_float"])
		for idx in range(mini(10, entries.size())):
			var e: Dictionary = entries[idx]
			var is_u: bool = bool(e.get("is_user", false))

			var row_p := PanelContainer.new()
			var rsb := StyleBoxFlat.new()
			rsb.bg_color = Color("#16314E") if is_u else Color(0, 0, 0, 0)
			rsb.set_border_width_all(1 if is_u else 0)
			rsb.border_color = UITheme.ACCENT_CYAN if is_u else Color(0, 0, 0, 0)
			rsb.set_corner_radius_all(3)
			rsb.content_margin_left = 3
			rsb.content_margin_right = 4
			rsb.content_margin_top = 2
			rsb.content_margin_bottom = 2
			row_p.add_theme_stylebox_override("panel", rsb)
			row_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
			col_vb.add_child(row_p)

			var rhb := HBoxContainer.new()
			rhb.add_theme_constant_override("separation", 5)
			row_p.add_child(rhb)

			var rkl := Label.new()
			rkl.text = str(int(e.get("rank", idx + 1)))
			rkl.custom_minimum_size = Vector2(18, 0)
			rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			rkl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			rkl.add_theme_font_size_override("font_size", 12)
			rkl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if is_u else Color("#CBD5E1"))
			rhb.add_child(rkl)

			var cr_c := CenterContainer.new()
			var cr := ClubCrest.new()
			cr.custom_minimum_size = Vector2(16, 16)
			cr.set_club(int(e.get("club_id", 0)))
			cr_c.add_child(cr)
			rhb.add_child(cr_c)

			var pnm := Label.new()
			pnm.text = str(e.get("name", "Pemain"))
			pnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pnm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pnm.clip_text = true
			pnm.add_theme_font_size_override("font_size", 12)
			pnm.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if is_u else UITheme.TEXT_WHITE)
			rhb.add_child(pnm)

			var mnl := Label.new()
			mnl.text = str(int(e.get("matches", 0)))
			mnl.custom_minimum_size = Vector2(24, 0)
			mnl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			mnl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mnl.add_theme_font_size_override("font_size", 11)
			mnl.add_theme_color_override("font_color", Color("#CBD5E1"))
			rhb.add_child(mnl)

			var vl := Label.new()
			vl.text = format_rating_id(float(e.get("value", 6.0))) if is_flt else str(int(e.get("value", 0)))
			vl.custom_minimum_size = Vector2(36, 0)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vl.add_theme_font_override("font", UITheme.get_display_font())
			vl.add_theme_font_size_override("font_size", 14)
			vl.add_theme_color_override("font_color", GOLD_STAT)
			rhb.add_child(vl)

	# Bottom full-width TUTUP button (Gambar 7)
	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 38)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_flat_btn(close_b, Color("#111B2D"), Color("#24354F"), 13, Color("#CBD5E1"))
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	outer.add_child(close_b)
	return layer

# ==============================================================================
# INNER CLASSES: ESC-ENABLED CANVASLAYER & PIXEL ICON PAINTER
# ==============================================================================
class OverlayCanvasLayer extends CanvasLayer:
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				AudioSynth.play_click()
				get_viewport().set_input_as_handled()
				queue_free()

class CompIconControl extends Control:
	var icon_kind: String = "elite"
	var icon_color: Color = Color("#CBD5E1")

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		var cy: float = h * 0.5
		var c: Color = icon_color
		match icon_kind:
			"elite", "ELITE":
				# Classic trophy cup with handles
				draw_rect(Rect2(w * 0.25, h * 0.14, w * 0.50, h * 0.42), c)
				draw_rect(Rect2(w * 0.12, h * 0.20, w * 0.14, h * 0.22), c, false, 1.4)
				draw_rect(Rect2(w * 0.74, h * 0.20, w * 0.14, h * 0.22), c, false, 1.4)
				draw_rect(Rect2(w * 0.43, h * 0.56, w * 0.14, h * 0.22), c)
				draw_rect(Rect2(w * 0.28, h * 0.78, w * 0.44, h * 0.14), c)
			"europa", "EUROPA":
				# Tall chalice cup
				var pts := PackedVector2Array([Vector2(w * 0.22, h * 0.14), Vector2(w * 0.78, h * 0.14), Vector2(w * 0.64, h * 0.62), Vector2(w * 0.36, h * 0.62)])
				draw_colored_polygon(pts, c)
				draw_rect(Rect2(w * 0.44, h * 0.62, w * 0.12, h * 0.18), c)
				draw_rect(Rect2(w * 0.30, h * 0.80, w * 0.40, h * 0.12), c)
			"challenge", "CHALLENGE", "CONF.":
				# Shield/cup crest
				var pts := PackedVector2Array([Vector2(w * 0.20, h * 0.14), Vector2(w * 0.80, h * 0.14), Vector2(w * 0.74, h * 0.64), Vector2(cx, h * 0.88), Vector2(w * 0.26, h * 0.64)])
				draw_colored_polygon(pts, c)
				draw_circle(Vector2(cx, h * 0.42), minf(w, h) * 0.14, Color("#070F1C"))
			"promo", "PROMO":
				var pts := PackedVector2Array([Vector2(cx, h * 0.12), Vector2(w * 0.84, h * 0.62), Vector2(w * 0.62, h * 0.62), Vector2(w * 0.62, h * 0.88), Vector2(w * 0.38, h * 0.88), Vector2(w * 0.38, h * 0.62), Vector2(w * 0.16, h * 0.62)])
				draw_colored_polygon(pts, c)
			"releg", "RELEG":
				var pts := PackedVector2Array([Vector2(w * 0.38, h * 0.12), Vector2(w * 0.62, h * 0.12), Vector2(w * 0.62, h * 0.40), Vector2(w * 0.84, h * 0.40), Vector2(cx, h * 0.88), Vector2(w * 0.16, h * 0.40), Vector2(w * 0.38, h * 0.40)])
				draw_colored_polygon(pts, c)
			"ball":
				draw_circle(Vector2(cx, cy), minf(w, h) * 0.44, c)
				draw_circle(Vector2(cx, cy), minf(w, h) * 0.16, Color("#070F1C"))
			"assist":
				# Right pass arrow
				draw_circle(Vector2(w * 0.24, cy), minf(w, h) * 0.18, c)
				draw_line(Vector2(w * 0.42, cy), Vector2(w * 0.86, cy), c, 2.0)
				draw_line(Vector2(w * 0.66, h * 0.26), Vector2(w * 0.86, cy), c, 2.0)
				draw_line(Vector2(w * 0.66, h * 0.74), Vector2(w * 0.86, cy), c, 2.0)
			"star":
				var pts := PackedVector2Array()
				for i in range(10):
					var ang: float = -PI * 0.5 + float(i) * PI / 5.0
					var rad: float = minf(w, h) * (0.46 if i % 2 == 0 else 0.20)
					pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
				draw_colored_polygon(pts, c)
			"calendar":
				draw_rect(Rect2(w * 0.12, h * 0.22, w * 0.76, h * 0.68), c, false, 1.5)
				draw_rect(Rect2(w * 0.12, h * 0.22, w * 0.76, h * 0.22), c)
				draw_rect(Rect2(w * 0.26, h * 0.10, w * 0.12, h * 0.18), c)
				draw_rect(Rect2(w * 0.62, h * 0.10, w * 0.12, h * 0.18), c)
			"podium":
				draw_rect(Rect2(w * 0.10, h * 0.48, w * 0.24, h * 0.40), c)
				draw_rect(Rect2(w * 0.38, h * 0.22, w * 0.24, h * 0.66), c)
				draw_rect(Rect2(w * 0.66, h * 0.58, w * 0.24, h * 0.30), c)
			"club", "KLUB":
				draw_arc(Vector2(cx, cy), minf(w, h) * 0.40, 0.0, TAU, 16, c, 1.5)
				draw_line(Vector2(cx, h * 0.10), Vector2(cx, h * 0.90), c, 1.2)
				draw_line(Vector2(w * 0.10, cy), Vector2(w * 0.90, cy), c, 1.2)
			_:
				draw_rect(Rect2(w * 0.20, h * 0.20, w * 0.60, h * 0.60), c)
