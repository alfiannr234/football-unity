extends Control

signal continue_career(slot_id: int)
signal start_new_career_slot(slot_id: int)
signal open_home_apartment(slot_id: int)
signal open_practice
signal open_volley_practice
signal open_city_practice
signal open_friends
signal open_koleksi
signal open_settings
signal open_editor
signal open_shop

var _selected_slot: int = 1
var _slots_hb: HBoxContainer
var _koleksi_btn: Button
var _koleksi_badge: Label
var _lang_flag_wrap: CenterContainer
var _lang_lbl: Label

func _ready() -> void:
	theme = UITheme.build_theme()
	_build_ui()
	CareerState.career_updated.connect(refresh)
	refresh()

func _draw() -> void:
	# Midnight starfield backdrop matching Gambar 4
	draw_rect(Rect2(Vector2.ZERO, size), Color("#050B16"))
	for i in range(110):
		var sx := fmod(float(i * 173 + 41), maxf(1.0, size.x))
		var sy := fmod(float(i * 251 + 97), maxf(1.0, size.y))
		var a := 0.22 + float(i % 5) * 0.14
		var sz := 3.0 if i % 9 == 0 else 2.0
		draw_rect(Rect2(sx, sy, sz, sz), Color(0.86, 0.92, 1.0, a))

func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 22
	vb.offset_right = -22
	vb.offset_top = 12
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	# --- TOP BAR (Left icons | Center Stacked Logo Title | Right Country Flag Pill) ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	vb.add_child(top)

	var left_tools := HBoxContainer.new()
	left_tools.add_theme_constant_override("separation", 6)
	top.add_child(left_tools)
	for btn_def in [
		["⚙", func(): open_settings.emit()],
		["☰", func(): open_koleksi.emit()],
		["✎", func(): open_editor.emit()],
	]:
		var b := Button.new()
		b.text = btn_def[0]
		b.custom_minimum_size = Vector2(38, 36)
		UITheme.style_btn(b, Color("#0C1322"), UITheme.BORDER_STEEL, 15)
		b.pressed.connect(func(): AudioSynth.play_click(); btn_def[1].call())
		left_tools.add_child(b)

	var title_center := HBoxContainer.new()
	title_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_center.alignment = BoxContainer.ALIGNMENT_CENTER
	title_center.add_theme_constant_override("separation", 10)
	top.add_child(title_center)

	var ball := TextureRect.new()
	ball.texture = load("res://assets/sprites/ui/logo_ball.png")
	ball.custom_minimum_size = Vector2(36, 36)
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_center.add_child(ball)

	var ttl := Label.new()
	ttl.text = "FOOTBALL\nUNITY"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	title_center.add_child(ttl)

	var lang_panel := PanelContainer.new()
	lang_panel.custom_minimum_size = Vector2(150, 36)
	lang_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0C1322"), UITheme.BORDER_STEEL, 1, 5))
	top.add_child(lang_panel)
	var lang_hb := HBoxContainer.new()
	lang_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_hb.add_theme_constant_override("separation", 6)
	lang_panel.add_child(lang_hb)
	_lang_flag_wrap = CenterContainer.new()
	_lang_flag_wrap.custom_minimum_size = Vector2(24, 16)
	lang_hb.add_child(_lang_flag_wrap)
	_lang_lbl = Label.new()
	_lang_lbl.text = "INDONESIA"
	_lang_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_lang_lbl.add_theme_font_size_override("font_size", 12)
	lang_hb.add_child(_lang_lbl)
	var lang_click := Button.new()
	lang_click.set_anchors_preset(Control.PRESET_FULL_RECT)
	lang_click.flat = true
	lang_click.pressed.connect(func():
		AudioSynth.play_click()
		var nl: String = "en" if str(SettingsManager.data.get("language", "id")) == "id" else "id"
		SettingsManager.set_setting("language", nl)
		refresh()
	)
	lang_panel.add_child(lang_click)

	# --- CENTER: 3 EQUAL SIDE-BY-SIDE CAREER CARDS (or scrollable if 4 slots) ---
	_slots_hb = HBoxContainer.new()
	_slots_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slots_hb.add_theme_constant_override("separation", 10)
	vb.add_child(_slots_hb)

	# --- BOTTOM CENTER DOCK (LATIHAN / TEMAN / KOLEKSI + wide slim TOKO bar) ---
	var dock := VBoxContainer.new()
	dock.custom_minimum_size = Vector2(600, 0)
	dock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dock.add_theme_constant_override("separation", 6)
	vb.add_child(dock)

	var q_hb := HBoxContainer.new()
	q_hb.add_theme_constant_override("separation", 8)
	dock.add_child(q_hb)

	var lat_b := Button.new()
	lat_b.text = "▲  LATIHAN"
	lat_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lat_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(lat_b, Color("#0C2034"), UITheme.ACCENT_CYAN, 13)
	lat_b.pressed.connect(func(): AudioSynth.play_click(); _show_practice_picker())
	q_hb.add_child(lat_b)

	var tem_b := Button.new()
	tem_b.text = "★  TEMAN"
	tem_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tem_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(tem_b, Color("#151D39"), Color("#94A3B8"), 13)
	tem_b.pressed.connect(func(): AudioSynth.play_click(); open_friends.emit())
	q_hb.add_child(tem_b)

	var kol_wrap := Control.new()
	kol_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kol_wrap.custom_minimum_size = Vector2(0, 42)
	q_hb.add_child(kol_wrap)
	_koleksi_btn = Button.new()
	_koleksi_btn.text = "✓  KOLEKSI"
	_koleksi_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	UITheme.style_btn(_koleksi_btn, Color("#1D1633"), Color("#A855F7"), 13)
	_koleksi_btn.pressed.connect(func(): AudioSynth.play_click(); open_koleksi.emit())
	kol_wrap.add_child(_koleksi_btn)
	_koleksi_badge = Label.new()
	_koleksi_badge.text = "0"
	_koleksi_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_koleksi_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_koleksi_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_koleksi_badge.offset_left = -28
	_koleksi_badge.offset_right = -4
	_koleksi_badge.offset_top = -6
	_koleksi_badge.offset_bottom = 12
	_koleksi_badge.add_theme_font_override("font", UITheme.get_display_font())
	_koleksi_badge.add_theme_font_size_override("font_size", 10)
	_koleksi_badge.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	kol_wrap.add_child(_koleksi_badge)

	# Bottom slim wide TOKO bar (matching Gambar 4)
	var toko_card := PanelContainer.new()
	toko_card.custom_minimum_size = Vector2(0, 40)
	toko_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121722"), UITheme.ACCENT_GOLD, 1, 5))
	dock.add_child(toko_card)
	var toko_hb := HBoxContainer.new()
	toko_hb.add_theme_constant_override("separation", 8)
	toko_card.add_child(toko_hb)
	toko_hb.add_child(_make_pixel_icon("shop", UITheme.ACCENT_GOLD, Vector2(18, 18)))
	var toko_lbl := Label.new()
	toko_lbl.text = "TOKO KOSMETIK & PERK"
	toko_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toko_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toko_lbl.add_theme_font_override("font", UITheme.get_display_font())
	toko_lbl.add_theme_font_size_override("font_size", 14)
	toko_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	toko_hb.add_child(toko_lbl)
	for mini_tag in [["+ AIM", Color("#166534")], ["o CINCIN", Color("#0F766E")], ["★ PERK", Color("#6B21A8")]]:
		var pill := PanelContainer.new()
		pill.add_theme_stylebox_override("panel", UITheme.make_box(mini_tag[1], UITheme.ACCENT_GOLD, 1, 4))
		var pl := Label.new()
		pl.text = mini_tag[0]
		pl.add_theme_font_size_override("font_size", 10)
		pill.add_child(pl)
		toko_hb.add_child(pill)
	var toko_click := Button.new()
	toko_click.set_anchors_preset(Control.PRESET_FULL_RECT)
	toko_click.flat = true
	toko_click.pressed.connect(func(): AudioSynth.play_click(); open_shop.emit())
	toko_card.add_child(toko_click)

func refresh() -> void:
	if not is_inside_tree():
		return
	var is_id: bool = (str(SettingsManager.data.get("language", "id")) == "id")
	_lang_lbl.text = "INDONESIA" if is_id else "ENGLISH"
	for fc in _lang_flag_wrap.get_children():
		fc.queue_free()
	_lang_flag_wrap.add_child(UITheme.make_flag_rect(16 if is_id else 0, Vector2(22, 15)))
	var u_cnt: int = CareerState.global_profile.get("unlocked_achievements", {}).size()
	_koleksi_badge.text = str(u_cnt)

	for c in _slots_hb.get_children():
		c.queue_free()

	var meta := CareerState.get_slots_meta()
	var max_s := CareerState.get_max_slots()
	for s in range(1, max_s + 1):
		_slots_hb.add_child(_build_slot_card(s, meta))

func _build_slot_card(slot_id: int, meta: Dictionary) -> Control:
	var has_data := meta.has(str(slot_id))
	var is_sel := (slot_id == _selected_slot)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 0)
	card.size_flags_stretch_ratio = 1.0
	card.clip_contents = true

	if not has_data:
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#08101C"), UITheme.ACCENT_CYAN if is_sel else UITheme.BORDER_STEEL, 2 if is_sel else 1, 8))
		var evb := VBoxContainer.new()
		evb.alignment = BoxContainer.ALIGNMENT_CENTER
		evb.add_theme_constant_override("separation", 12)
		card.add_child(evb)
		var elbl := Label.new()
		elbl.text = "SLOT %d KOSONG\nSiap memulai karier baru?" % slot_id
		elbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		evb.add_child(elbl)
		var nb := Button.new()
		nb.text = "+ KARIER BARU"
		nb.custom_minimum_size = Vector2(150, 44)
		nb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		UITheme.style_btn(nb, Color("#154566"), UITheme.ACCENT_CYAN, 14)
		var cap_s := slot_id
		nb.pressed.connect(func(): AudioSynth.play_click(); _selected_slot = cap_s; start_new_career_slot.emit(cap_s))
		evb.add_child(nb)
		return card

	var d: Dictionary = meta[str(slot_id)]
	var cid := clampi(int(d.get("clubId", 0)), 0, maxi(0, GameData.clubs.size() - 1))
	var club: Dictionary = GameData.clubs[cid]
	var pri: Color = club.get("primary", Color("#1A66D2"))
	var sec: Color = club.get("secondary", Color("#F8FAFC"))
	var nat_id := clampi(int(d.get("nationId", club.get("nation_id", 16))), 0, maxi(0, GameData.nations.size() - 1))
	var nat_cols: Array = GameData.nations[nat_id]["colors"]
	var border_col := Color("#E2E8F0") if is_sel else pri.lightened(0.25)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091426"), border_col, 2 if is_sel else 1, 8))

	var cvb := VBoxContainer.new()
	cvb.add_theme_constant_override("separation", 0)
	card.add_child(cvb)

	# 1. Top Flag/Avatar Banner
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(0, 108)
	banner.clip_contents = true
	banner.draw.connect(func():
		var bs := banner.size
		var c0: Color = nat_cols[0].darkened(0.18)
		var c1: Color = nat_cols[1].darkened(0.18)
		banner.draw_rect(Rect2(0, 0, bs.x, bs.y * 0.52), c0)
		banner.draw_rect(Rect2(0, bs.y * 0.52, bs.x, bs.y * 0.48), c1)
		banner.draw_rect(Rect2(0, 0, bs.x * 0.35, bs.y), Color(pri.r, pri.g, pri.b, 0.32))
	)
	cvb.add_child(banner)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(74, 96)
	av.position = Vector2(18, 12)
	av.primary_color = pri
	av.secondary_color = sec
	av.kit_pattern = str(club.get("pattern", "stripes"))
	var app: Dictionary = d.get("appearance", {})
	av.skin_idx = int(app.get("skin", 1))
	av.hair_style = int(app.get("hair_style", 0))
	av.hair_idx = int(app.get("hair_color", 1))
	av.beard = bool(app.get("beard", false))
	av.tattoo_arm = int(app.get("tattoo_arm", 0))
	av.headwear = int(app.get("headwear", 0))
	av.eyewear = int(app.get("eyewear", 0))
	av.shirt_num = int(d.get("shirtNum", 9))
	banner.add_child(av)

	var top_meta_vb := VBoxContainer.new()
	top_meta_vb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_meta_vb.offset_left = -170
	top_meta_vb.offset_right = -8
	top_meta_vb.offset_top = 8
	top_meta_vb.add_theme_constant_override("separation", 5)
	banner.add_child(top_meta_vb)

	var meta_pill := PanelContainer.new()
	meta_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#09111E", 0.9), Color("#FFFFFF", 0.2), 1, 5))
	top_meta_vb.add_child(meta_pill)
	var meta_l := Label.new()
	meta_l.text = "M%d  •  %dTH  •  %s" % [int(d.get("year", 1)), int(d.get("age", 16)), UITheme.format_short_cash(int(d.get("cash", 0)))]
	meta_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_l.add_theme_font_override("font", UITheme.get_display_font())
	meta_l.add_theme_font_size_override("font_size", 11)
	meta_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	meta_pill.add_child(meta_l)

	if is_sel or slot_id == CareerState.active_slot:
		var act_pill := PanelContainer.new()
		act_pill.size_flags_horizontal = Control.SIZE_SHRINK_END
		act_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#F1F5F9"), Color("#FFFFFF"), 1, 4))
		top_meta_vb.add_child(act_pill)
		var act_l := Label.new()
		act_l.text = " ✓ AKTIF "
		act_l.add_theme_font_override("font", UITheme.get_display_font())
		act_l.add_theme_font_size_override("font_size", 10)
		act_l.add_theme_color_override("font_color", Color("#0A1424"))
		act_pill.add_child(act_l)

	# 2. Identity Strip (OVR Badge + Name + Club • Div • [POS] #Num)
	var id_band := PanelContainer.new()
	id_band.add_theme_stylebox_override("panel", UITheme.make_box(pri.darkened(0.45), Color("#FFFFFF", 0.14), 1, 0))
	cvb.add_child(id_band)
	var id_hb := HBoxContainer.new()
	id_hb.add_theme_constant_override("separation", 10)
	id_band.add_child(id_hb)

	id_hb.add_child(UITheme.make_ovr_badge(int(d.get("ovr", 60)), "default", Vector2(46, 44)))
	var id_vb := VBoxContainer.new()
	id_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	id_hb.add_child(id_vb)

	var p_name_l := Label.new()
	p_name_l.text = str(d.get("name", "ALFIAN")).to_upper()
	p_name_l.clip_text = true
	p_name_l.add_theme_font_override("font", UITheme.get_display_font())
	p_name_l.add_theme_font_size_override("font_size", 16)
	id_vb.add_child(p_name_l)

	var cl_hb := HBoxContainer.new()
	cl_hb.add_theme_constant_override("separation", 5)
	id_vb.add_child(cl_hb)
	var mini_cr := ClubCrest.new()
	mini_cr.custom_minimum_size = Vector2(16, 16)
	mini_cr.set_club(cid)
	cl_hb.add_child(mini_cr)
	var cl_l := Label.new()
	cl_l.text = "%s • %s #%d" % [str(club["name"]), str(d.get("pos", "ST")), int(d.get("shirtNum", 9))]
	cl_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl_l.clip_text = true
	cl_l.add_theme_font_size_override("font_size", 11)
	cl_l.add_theme_color_override("font_color", Color("#DCE8F8"))
	cl_hb.add_child(cl_l)

	# 3. Compact 6-Stat Strip
	var stats_panel := PanelContainer.new()
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1527"), Color("#FFFFFF", 0.08), 0, 0))
	cvb.add_child(stats_panel)
	var st_hb := HBoxContainer.new()
	st_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	st_hb.add_theme_constant_override("separation", 4)
	stats_panel.add_child(st_hb)
	var stat_items := [
		["ball", "GOL", str(int(d.get("goals", 0))), UITheme.ACCENT_CYAN],
		["boot", "AST", str(int(d.get("assists", 0))), UITheme.ACCENT_GREEN],
		["star", "RTG", "%.1f" % float(d.get("bestRating", 0.0)), UITheme.ACCENT_GOLD],
		["trophy", "TRO", str(int(d.get("trophies", 0))), UITheme.ACCENT_AMBER],
		["medal", "MOTM", str(int(d.get("motm", 0))), UITheme.ACCENT_GOLD],
		["match", "MAIN", str(int(d.get("matches", 0))), UITheme.TEXT_WHITE],
	]
	for si in stat_items:
		var svb := VBoxContainer.new()
		svb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		svb.alignment = BoxContainer.ALIGNMENT_CENTER
		svb.add_theme_constant_override("separation", 2)
		st_hb.add_child(svb)
		var ic_wrap := CenterContainer.new()
		ic_wrap.add_child(_make_pixel_icon(str(si[0]), si[3], Vector2(14, 14)))
		svb.add_child(ic_wrap)
		var vl := Label.new()
		vl.text = si[2]
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 12)
		svb.add_child(vl)

	# 4. Bottom Action Row: ▶ LANJUTKAN | RUMAH
	var act_pad := PanelContainer.new()
	act_pad.add_theme_stylebox_override("panel", UITheme.make_box(Color("#08101E"), Color("#FFFFFF", 0.08), 0, 0))
	cvb.add_child(act_pad)
	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 8)
	act_pad.add_child(btn_hb)

	var cap_slot := slot_id
	var cont_b := Button.new()
	cont_b.text = "▶ LANJUTKAN"
	cont_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(cont_b, Color("#0C182B"), Color("#F1F5F9"), 14)
	cont_b.pressed.connect(func(): AudioSynth.play_click(); _selected_slot = cap_slot; continue_career.emit(cap_slot))
	btn_hb.add_child(cont_b)

	var home_b := Button.new()
	home_b.text = "▲ RUMAH"
	home_b.custom_minimum_size = Vector2(96, 42)
	UITheme.style_btn(home_b, Color("#0F1B2E"), UITheme.BORDER_STEEL, 12)
	home_b.pressed.connect(func(): AudioSynth.play_click(); _selected_slot = cap_slot; open_home_apartment.emit(cap_slot))
	btn_hb.add_child(home_b)

	return card

func _make_pixel_icon(kind: String, col: Color, sz: Vector2 = Vector2(14, 14)) -> Control:
	var c := Control.new()
	c.custom_minimum_size = sz
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var w := sz.x
		var h := sz.y
		match kind:
			"ball":
				c.draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.42, Color("#F8FAFC"))
				c.draw_rect(Rect2(w * 0.35, h * 0.35, w * 0.30, h * 0.30), Color("#1E293B"))
			"boot":
				c.draw_rect(Rect2(w * 0.15, h * 0.25, w * 0.42, h * 0.45), col)
				c.draw_rect(Rect2(w * 0.15, h * 0.55, w * 0.72, h * 0.24), col)
				c.draw_rect(Rect2(w * 0.15, h * 0.79, w * 0.72, h * 0.10), Color("#F8FAFC"))
			"star":
				c.draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.36, col)
				c.draw_rect(Rect2(w * 0.43, 1.0, w * 0.14, h - 2.0), col)
				c.draw_rect(Rect2(1.0, h * 0.43, w - 2.0, h * 0.14), col)
			"trophy":
				c.draw_rect(Rect2(w * 0.22, h * 0.14, w * 0.56, h * 0.42), col)
				c.draw_rect(Rect2(w * 0.40, h * 0.56, w * 0.20, h * 0.22), col)
				c.draw_rect(Rect2(w * 0.26, h * 0.78, w * 0.48, h * 0.14), col)
			"medal":
				c.draw_rect(Rect2(w * 0.30, 1.0, w * 0.40, h * 0.35), Color("#EF4444"))
				c.draw_circle(Vector2(w * 0.5, h * 0.65), minf(w, h) * 0.28, col)
			"match":
				c.draw_rect(Rect2(w * 0.14, h * 0.18, w * 0.72, h * 0.68), Color("#166534"))
				c.draw_rect(Rect2(w * 0.14, h * 0.18, w * 0.72, h * 0.68), col, false, 1.5)
				c.draw_line(Vector2(w * 0.5, h * 0.18), Vector2(w * 0.5, h * 0.86), col, 1.0)
			"shop":
				c.draw_rect(Rect2(2, 2, w - 4, h * 0.32), Color("#EF4444"))
				c.draw_rect(Rect2(3, h * 0.36, w - 6, h * 0.52), col)
	)
	return c

func _show_practice_picker() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.custom_minimum_size = Vector2(400, 300)
	pc.offset_left = -200
	pc.offset_right = 200
	pc.offset_top = -150
	pc.offset_bottom = 150
	pc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0C1829"), UITheme.ACCENT_CYAN, 2, 12))
	dim.add_child(pc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)

	var h := Label.new()
	h.text = "PILIH MODE LATIHAN"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_override("font", UITheme.get_display_font())
	h.add_theme_font_size_override("font_size", 18)
	vb.add_child(h)

	var b1 := Button.new()
	b1.text = "TENDANGAN KETAPEL & FREE KICK"
	b1.custom_minimum_size = Vector2(0, 46)
	UITheme.style_btn(b1, Color("#173B66"), UITheme.ACCENT_CYAN, 13)
	b1.pressed.connect(func(): AudioSynth.play_click(); dim.queue_free(); open_practice.emit())
	vb.add_child(b1)

	var b2 := Button.new()
	b2.text = "KONTROL DAN VOLI (MINIGAME)"
	b2.custom_minimum_size = Vector2(0, 46)
	UITheme.style_btn(b2, Color("#4E2C66"), UITheme.ACCENT_GOLD, 13)
	b2.pressed.connect(func(): AudioSynth.play_click(); dim.queue_free(); open_volley_practice.emit())
	vb.add_child(b2)

	var b3 := Button.new()
	b3.text = "JELAJAH KOTA & STADION 3D"
	b3.custom_minimum_size = Vector2(0, 46)
	UITheme.style_btn(b3, Color("#17462E"), UITheme.ACCENT_GREEN, 13)
	b3.pressed.connect(func(): AudioSynth.play_click(); dim.queue_free(); open_city_practice.emit())
	vb.add_child(b3)

	var cancel := Button.new()
	cancel.text = "BATAL"
	cancel.custom_minimum_size = Vector2(0, 36)
	cancel.pressed.connect(func(): AudioSynth.play_click(); dim.queue_free())
	vb.add_child(cancel)
