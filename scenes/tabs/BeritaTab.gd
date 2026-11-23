extends Control

const SquadPlayerCardScript := preload("res://scripts/ui/SquadPlayerCard.gd")

var _channel: String = "KLUB"  # KLUB, LIGA, DUNIA, SOSMED, PESAN
var _sel_article_idx: int = 0
var _sel_social_id: String = ""
var _social_filter: String = "SEMUA"
var _sel_msg_id: String = ""
var _show_all_list: bool = false

var _phone_root: Control
var _reader_overlay: Control

func _ready() -> void:
	theme = UITheme.build_theme()
	_phone_root = Control.new()
	_phone_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_phone_root)

	_reader_overlay = Control.new()
	_reader_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reader_overlay.visible = false
	_reader_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_reader_overlay)

	CareerState.career_updated.connect(refresh)
	refresh()

func set_channel(ch: String) -> void:
	_channel = ch
	_sel_article_idx = 0
	_show_all_list = false
	refresh()

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	CareerState.ensure_berita_data()
	for c in _phone_root.get_children():
		_phone_root.remove_child(c)
		c.queue_free()

	# Landscape Smartphone Outer Bezel (Gambar 2 - 7)
	var bezel := PanelContainer.new()
	bezel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezel.offset_left = 10
	bezel.offset_right = -10
	bezel.offset_top = 4
	bezel.offset_bottom = -6
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color("#070D19")
	bsb.border_color = Color("#24354F")
	bsb.set_border_width_all(3)
	bsb.set_corner_radius_all(18)
	bsb.content_margin_left = 10
	bsb.content_margin_right = 12
	bsb.content_margin_top = 6
	bsb.content_margin_bottom = 8
	bezel.add_theme_stylebox_override("panel", bsb)
	_phone_root.add_child(bezel)

	var main_hb := HBoxContainer.new()
	main_hb.add_theme_constant_override("separation", 12)
	bezel.add_child(main_hb)

	# =========================================================================
	# LEFT VERTICAL SMARTPHONE NAVIGATION RAIL (KLUB | LIGA | DUNIA | SOSMED | PESAN)
	# =========================================================================
	var rail := VBoxContainer.new()
	rail.custom_minimum_size = Vector2(64, 0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 6)
	main_hb.add_child(rail)

	var wk := int(CareerState.career["careerMeta"].get("week", 1))
	var day_lbl := Label.new()
	day_lbl.text = "%s\nP%d" % ["KAM" if wk % 2 == 0 else "MIN", wk]
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.add_theme_font_size_override("font_size", 9)
	day_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	rail.add_child(day_lbl)

	var unread: Dictionary = CareerState.get_unread_berita_counts()
	var nav_defs: Array = [
		["KLUB", Color("#E11D48"), 0],
		["LIGA", Color("#0EA5E9"), 0],
		["DUNIA", Color("#9333EA"), 0],
		["SOSMED", Color("#EC4899"), int(unread.get("sosmed", 0))],
		["PESAN", Color("#F97316"), int(unread.get("pesan", 0))],
	]
	for nd in nav_defs:
		var ch_key: String = str(nd[0])
		var ch_col: Color = nd[1] as Color
		var ch_cnt: int = int(nd[2])
		rail.add_child(_make_phone_nav_btn(ch_key, ch_col, ch_cnt))

	# =========================================================================
	# RIGHT SMARTPHONE SCREEN BODY
	# =========================================================================
	var screen_vb := VBoxContainer.new()
	screen_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_vb.add_theme_constant_override("separation", 8)
	main_hb.add_child(screen_vb)

	# Subtle Phone Top Status Strip
	var st_hb := HBoxContainer.new()
	screen_vb.add_child(st_hb)
	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_hb.add_child(spc)
	var st_lbl := Label.new()
	st_lbl.text = "5G  •  100%"
	st_lbl.add_theme_font_size_override("font_size", 8)
	st_lbl.add_theme_color_override("font_color", Color("#64748B"))
	st_hb.add_child(st_lbl)

	match _channel:
		"KLUB":
			_render_news_channel(screen_vb, "KLUBMU", "KLUB", Color("#E11D48"), _build_club_articles())
		"LIGA":
			_render_news_channel(screen_vb, "LIGAMU", "LIGA", Color("#0EA5E9"), _build_league_articles())
		"DUNIA":
			_render_news_channel(screen_vb, "DUNIA", "DUNIA", Color("#9333EA"), _build_world_articles())
		"SOSMED":
			_render_sosmed(screen_vb)
		"PESAN":
			_render_pesan(screen_vb)

func _make_phone_nav_btn(key: String, col: Color, unread_cnt: int) -> Control:
	var act: bool = (_channel == key)
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(44, 38)
	icon_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = col if act else Color("#101A2C")
	sb.border_color = col.lightened(0.25) if act else Color("#243652")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	icon_wrap.add_theme_stylebox_override("panel", sb)
	box.add_child(icon_wrap)

	var ic := PhoneNavIcon.new()
	ic.custom_minimum_size = Vector2(28, 26)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.configure(key, Color.WHITE if act else Color("#94A3B8"))
	icon_wrap.add_child(ic)

	if unread_cnt > 0:
		var dot := PanelContainer.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color("#EF4444")
		dsb.set_corner_radius_all(7)
		dsb.content_margin_left = 3
		dsb.content_margin_right = 3
		dot.add_theme_stylebox_override("panel", dsb)
		var dl := Label.new()
		dl.text = "!" if key == "SOSMED" else str(unread_cnt)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.add_theme_font_size_override("font_size", 8)
		dl.add_theme_color_override("font_color", Color.WHITE)
		dot.add_child(dl)
		icon_wrap.add_child(dot)
		dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		dot.offset_left = -13
		dot.offset_right = 2
		dot.offset_top = -3
		dot.offset_bottom = 11

	var hit := Button.new()
	hit.flat = true
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cap_k: String = key
	hit.pressed.connect(func(): AudioSynth.play_click(); set_channel(cap_k))
	icon_wrap.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var lbl := Label.new()
	lbl.text = key
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UITheme.get_display_font())
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color.WHITE if act else Color("#7D91AD"))
	box.add_child(lbl)
	return box

func _make_medsos_year_pill() -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(316, 30)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(btn, Color("#12233E"), Color("#3B5D8C"), 10)
	btn.pressed.connect(func():
		AudioSynth.play_click()
		_social_filter = "TAHUNMU"
		set_channel("SOSMED")
	)

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 6)
	btn.add_child(hb)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 8
	hb.offset_right = -8

	var l1 := Label.new()
	l1.text = "● MEDSOS"
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l1.add_theme_font_size_override("font_size", 9)
	l1.add_theme_color_override("font_color", Color("#C084FC"))
	hb.add_child(l1)

	var av := PixelAvatar.new()
	av.full_body = false
	av.custom_minimum_size = Vector2(22, 22)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.configure_from_career()
	hb.add_child(av)

	var l2 := Label.new()
	l2.text = "TAHUN MEDSOSMU"
	l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l2.add_theme_font_override("font", UITheme.get_display_font())
	l2.add_theme_font_size_override("font_size", 10)
	l2.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(l2)

	var yr := int(CareerState.career["careerMeta"].get("seasonCalendarYear", 2026))
	var yr_p := PanelContainer.new()
	yr_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	yr_p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	yr_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#EAB308"), Color.TRANSPARENT, 0, 5))
	var yr_l := Label.new()
	yr_l.text = "%02d/%02d" % [yr % 100, (yr + 1) % 100]
	yr_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	yr_l.add_theme_font_size_override("font_size", 8)
	yr_l.add_theme_color_override("font_color", Color("#1C1304"))
	yr_p.add_child(yr_l)
	hb.add_child(yr_p)

	var baru_l := Label.new()
	baru_l.text = "BARU"
	baru_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baru_l.add_theme_font_size_override("font_size", 8)
	baru_l.add_theme_color_override("font_color", Color("#93C5FD"))
	hb.add_child(baru_l)
	return btn

# =============================================================================
# CHANNELS 1 - 3: KLUB (Gambar 2), LIGA (Gambar 3), DUNIA (Gambar 4)
# =============================================================================
func _render_news_channel(parent: VBoxContainer, title_txt: String, ch_key: String, accent: Color, articles: Array[Dictionary]) -> void:
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	parent.add_child(hdr)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(24, 24)
	badge.add_theme_stylebox_override("panel", UITheme.make_box(accent, Color.TRANSPARENT, 0, 5))
	var bi := PhoneNavIcon.new()
	bi.custom_minimum_size = Vector2(18, 18)
	bi.configure(ch_key, Color.WHITE)
	badge.add_child(bi)
	hdr.add_child(badge)

	var tl := Label.new()
	tl.text = title_txt
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 16)
	tl.add_theme_color_override("font_color", Color.WHITE)
	hdr.add_child(tl)

	hdr.add_child(_make_medsos_year_pill())

	if articles.is_empty():
		var empty_l := Label.new()
		empty_l.text = "BELUM ADA BERITA TERBARU UNTUK KANAL INI."
		empty_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		parent.add_child(empty_l)
		return

	_sel_article_idx = clampi(_sel_article_idx, 0, articles.size() - 1)
	var feat: Dictionary = articles[_sel_article_idx]

	var body_hb := HBoxContainer.new()
	body_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hb.add_theme_constant_override("separation", 12)
	parent.add_child(body_hb)

	# LEFT FEATURED ARTICLE HERO CARD (Gambar 2, 3, 4)
	var hero := PanelContainer.new()
	hero.custom_minimum_size = Vector2(400, 0)
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1222"), accent.darkened(0.15), 2, 8))
	body_hb.add_child(hero)

	var hvb := VBoxContainer.new()
	hvb.add_theme_constant_override("separation", 6)
	hero.add_child(hvb)

	# Featured Top Meta Strip
	var f_top := HBoxContainer.new()
	f_top.add_theme_constant_override("separation", 6)
	hvb.add_child(f_top)
	var fc_cr := ClubCrest.new()
	fc_cr.custom_minimum_size = Vector2(22, 22)
	fc_cr.set_club(int(feat.get("club_id", 0)))
	f_top.add_child(fc_cr)
	var f_src_vb := VBoxContainer.new()
	f_src_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_src_vb.add_theme_constant_override("separation", 0)
	f_top.add_child(f_src_vb)
	var f_src := Label.new()
	f_src.text = str(feat.get("source", "KLUB"))
	f_src.add_theme_font_override("font", UITheme.get_display_font())
	f_src.add_theme_font_size_override("font_size", 11)
	f_src_vb.add_child(f_src)
	var f_wk := Label.new()
	f_wk.text = str(feat.get("meta_wk", "M1"))
	f_wk.add_theme_font_size_override("font_size", 9)
	f_wk.add_theme_color_override("font_color", Color("#94A3B8"))
	f_src_vb.add_child(f_wk)

	var tag_p := PanelContainer.new()
	tag_p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A0D18"), accent, 1, 3))
	var tag_l := Label.new()
	tag_l.text = str(feat.get("tag", "BERITA"))
	tag_l.add_theme_font_size_override("font_size", 9)
	tag_l.add_theme_color_override("font_color", accent.lightened(0.3))
	tag_p.add_child(tag_l)
	f_top.add_child(tag_p)

	# Featured Visual Stage (Giant Club Crest centered on obsidian stage like Gambar 2, 3, 4)
	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size = Vector2(0, 118)
	stage.add_theme_stylebox_override("panel", UITheme.make_box(Color("#05080F"), Color("#162338"), 1, 6))
	hvb.add_child(stage)
	var st_cc := CenterContainer.new()
	stage.add_child(st_cc)
	var big_cr := ClubCrest.new()
	big_cr.custom_minimum_size = Vector2(96, 96)
	big_cr.set_club(int(feat.get("club_id", 0)))
	st_cc.add_child(big_cr)

	# Bold White Headline
	var hl := Label.new()
	hl.text = str(feat.get("headline", ""))
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 14)
	hl.add_theme_color_override("font_color", Color.WHITE)
	hvb.add_child(hl)

	# Subject Footer + Hex OVR + Pos
	var sub_hb := HBoxContainer.new()
	sub_hb.add_theme_constant_override("separation", 6)
	hvb.add_child(sub_hb)
	var sub_l := Label.new()
	sub_l.text = "★ %s" % str(feat.get("subject", feat.get("source", "")))
	sub_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_l.add_theme_font_size_override("font_size", 11)
	sub_l.add_theme_color_override("font_color", Color("#CBD5E1"))
	sub_hb.add_child(sub_l)
	var subj_ovr := int(feat.get("ovr", 0))
	if subj_ovr > 0:
		var hx := MiniOvrHexBadge.new()
		hx.custom_minimum_size = Vector2(22, 22)
		hx.configure(subj_ovr)
		sub_hb.add_child(hx)
		var pp := PanelContainer.new()
		pp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1324"), accent, 1, 2))
		var pl := Label.new()
		pl.text = str(feat.get("pos", "ST"))
		pl.add_theme_font_size_override("font_size", 9)
		pp.add_child(pl)
		sub_hb.add_child(pp)

	# BACA Button -> Opens Full Article Reader inside the Smartphone!
	var read_b := Button.new()
	read_b.text = "BACA"
	read_b.custom_minimum_size = Vector2(138, 32)
	read_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	read_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(read_b, Color("#0E182A"), accent, 12)
	var cap_feat: Dictionary = feat
	read_b.pressed.connect(func(): AudioSynth.play_click(); _open_article_reader(cap_feat, accent))
	hvb.add_child(read_b)

	# RIGHT CLICKABLE STORY LIST (Gambar 2, 3, 4)
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_hb.add_child(list_scroll)

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 6)
	list_scroll.add_child(list_vb)

	var max_rows := articles.size() if _show_all_list else mini(5, articles.size())
	for idx in range(max_rows):
		var a: Dictionary = articles[idx]
		var is_sel := (idx == _sel_article_idx)
		var row_p := PanelContainer.new()
		row_p.custom_minimum_size = Vector2(0, 46)
		row_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12223A") if is_sel else Color("#0B1424"), accent if is_sel else Color("#1D2E47"), 1, 5))

		var rhb := HBoxContainer.new()
		rhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rhb.add_theme_constant_override("separation", 8)
		row_p.add_child(rhb)

		var r_cr := ClubCrest.new()
		r_cr.custom_minimum_size = Vector2(22, 22)
		r_cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r_cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r_cr.set_club(int(a.get("club_id", 0)))
		rhb.add_child(r_cr)

		var r_lbl := Label.new()
		r_lbl.text = "%s  •  %s" % [str(a.get("tag", "BERITA")), str(a.get("subject", a.get("source", "")))]
		r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_lbl.clip_text = true
		r_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r_lbl.add_theme_font_override("font", UITheme.get_display_font())
		r_lbl.add_theme_font_size_override("font_size", 11)
		r_lbl.add_theme_color_override("font_color", Color.WHITE if is_sel else Color("#CBD5E1"))
		rhb.add_child(r_lbl)

		var r_ovr := int(a.get("ovr", 0))
		if r_ovr > 0:
			var rhx := MiniOvrHexBadge.new()
			rhx.custom_minimum_size = Vector2(22, 22)
			rhx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rhx.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rhx.configure(r_ovr)
			rhb.add_child(rhx)
			var rpos := PanelContainer.new()
			rpos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rpos.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rpos.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1324"), Color("#64748B"), 1, 2))
			var rpl := Label.new()
			rpl.text = str(a.get("pos", "CM"))
			rpl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rpl.add_theme_font_size_override("font_size", 8)
			rpos.add_child(rpl)
			rhb.add_child(rpos)

		var hit := Button.new()
		hit.flat = true
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_i: int = idx
		hit.pressed.connect(func(): AudioSynth.play_click(); _sel_article_idx = cap_i; refresh())
		row_p.add_child(hit)
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		list_vb.add_child(row_p)

	if articles.size() > 5 and not _show_all_list:
		var more_b := Button.new()
		more_b.text = "☰  LAIN  •  %d" % (articles.size() - 5)
		more_b.custom_minimum_size = Vector2(0, 34)
		more_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		UITheme.style_btn(more_b, Color("#0C1628"), Color("#294063"), 11)
		more_b.pressed.connect(func(): AudioSynth.play_click(); _show_all_list = true; refresh())
		list_vb.add_child(more_b)

func _open_article_reader(art: Dictionary, accent: Color) -> void:
	for c in _reader_overlay.get_children():
		_reader_overlay.remove_child(c)
		c.queue_free()
	_reader_overlay.visible = true

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.07, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reader_overlay.add_child(dim)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reader_overlay.add_child(cc)

	var modal := PanelContainer.new()
	modal.custom_minimum_size = Vector2(600, 310)
	modal.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1529"), accent, 2, 10))
	cc.add_child(modal)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	modal.add_child(vb)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(36, 36)
	cr.set_club(int(art.get("club_id", 0)))
	hdr.add_child(cr)
	var tl := Label.new()
	tl.text = "%s • %s" % [str(art.get("tag", "BERITA")), str(art.get("source", "KLUB")).to_upper()]
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 14)
	tl.add_theme_color_override("font_color", accent.lightened(0.3))
	hdr.add_child(tl)
	var cl := Button.new()
	cl.text = "TUTUP"
	cl.custom_minimum_size = Vector2(88, 30)
	cl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(cl, Color("#2A1520"), Color("#FB7185"), 11)
	cl.pressed.connect(func(): AudioSynth.play_click(); _reader_overlay.visible = false)
	hdr.add_child(cl)

	var hl := Label.new()
	hl.text = str(art.get("headline", ""))
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 17)
	vb.add_child(hl)

	var body := Label.new()
	body.text = str(art.get("body", art.get("headline", "")))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(body)

# =============================================================================
# CHANNEL 4: SOSMED (Gambar 5 Brand Ads & Feed + Gambar 6 Club Follow Alert!)
# =============================================================================
func _render_sosmed(parent: VBoxContainer) -> void:
	var p: Dictionary = CareerState.career["playerProfile"]
	var uname := str(p.get("name", "ALFIAN"))
	var handle := "@" + uname.to_upper().replace(" ", "")
	var sfeed: Array = CareerState.career.get("socialFeed", [])

	# Top Social Header: MEDSOS @HANDLE | 7 Story Filter Circles | DIPANTAU + Profile Pill
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 8)
	parent.add_child(top_hb)

	var id_vb := VBoxContainer.new()
	id_vb.add_theme_constant_override("separation", 0)
	top_hb.add_child(id_vb)
	var m_lbl := Label.new()
	m_lbl.text = "MEDSOS"
	m_lbl.add_theme_font_override("font", UITheme.get_display_font())
	m_lbl.add_theme_font_size_override("font_size", 14)
	id_vb.add_child(m_lbl)
	var h_lbl := Label.new()
	h_lbl.text = handle
	h_lbl.add_theme_font_size_override("font_size", 9)
	h_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	id_vb.add_child(h_lbl)

	# 7 Clickable Story Filter Circles (TAHUNMU, KAU, PERS, TRIBUN, RUANG GANTI, LAWAN, MEREK)
	var stories: Array = [
		["TAHUNMU", Color("#EC4899")],
		["KAU", Color("#A855F7")],
		["PERS", Color("#F59E0B")],
		["TRIBUN", Color("#EF4444")],
		["RUANG GANTI", Color("#38BDF8")],
		["LAWAN", Color("#6366F1")],
		["MEREK", Color("#22C55E")],
	]
	var st_hb := HBoxContainer.new()
	st_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	st_hb.add_theme_constant_override("separation", 5)
	top_hb.add_child(st_hb)
	for st_item in stories:
		var sk: String = str(st_item[0])
		var sc: Color = st_item[1] as Color
		var svb := VBoxContainer.new()
		svb.alignment = BoxContainer.ALIGNMENT_CENTER
		svb.add_theme_constant_override("separation", 1)
		var ring := PanelContainer.new()
		ring.custom_minimum_size = Vector2(28, 28)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var is_act := (_social_filter == sk)
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color("#1A1328") if is_act else Color("#0C1526")
		rsb.border_color = Color.WHITE if is_act else sc
		rsb.set_border_width_all(2)
		rsb.set_corner_radius_all(14)
		ring.add_theme_stylebox_override("panel", rsb)
		var sl_i := Label.new()
		sl_i.text = sk.left(1)
		sl_i.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl_i.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sl_i.add_theme_font_override("font", UITheme.get_display_font())
		sl_i.add_theme_font_size_override("font_size", 10)
		sl_i.add_theme_color_override("font_color", sc.lightened(0.25))
		ring.add_child(sl_i)
		var sh_b := Button.new()
		sh_b.flat = true
		sh_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_sk: String = sk
		sh_b.pressed.connect(func():
			AudioSynth.play_click()
			_social_filter = "SEMUA" if _social_filter == cap_sk else cap_sk
			refresh()
		)
		ring.add_child(sh_b)
		sh_b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		svb.add_child(ring)
		var cap_l := Label.new()
		cap_l.text = sk.left(7)
		cap_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap_l.add_theme_font_size_override("font_size", 7)
		cap_l.add_theme_color_override("font_color", Color.WHITE if is_act else Color("#94A3B8"))
		svb.add_child(cap_l)
		st_hb.add_child(svb)

	# DIPANTAU + Profile Followers Pill (Top-Right of Gambar 5 & 6)
	var watch_vb := VBoxContainer.new()
	watch_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	watch_vb.add_theme_constant_override("separation", 2)
	top_hb.add_child(watch_vb)
	var w_lbl := Label.new()
	w_lbl.text = "DIPANTAU"
	w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_lbl.add_theme_font_size_override("font_size", 8)
	w_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	watch_vb.add_child(w_lbl)
	var w_row := HBoxContainer.new()
	w_row.alignment = BoxContainer.ALIGNMENT_CENTER
	w_row.add_theme_constant_override("separation", 3)
	watch_vb.add_child(w_row)
	var wids: Array = CareerState.career.get("watchingClubIds", [])
	for wi in range(mini(4, wids.size())):
		var wcr := ClubCrest.new()
		wcr.custom_minimum_size = Vector2(16, 16)
		wcr.set_club(int(wids[wi]))
		w_row.add_child(wcr)

	var fol_pill := PanelContainer.new()
	fol_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121D32"), Color("#334F73"), 1, 6))
	top_hb.add_child(fol_pill)
	var fphb := HBoxContainer.new()
	fphb.add_theme_constant_override("separation", 5)
	fol_pill.add_child(fphb)
	var uhx := MiniOvrHexBadge.new()
	uhx.custom_minimum_size = Vector2(22, 22)
	uhx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	uhx.configure(int(p.get("ovr", 62)))
	fphb.add_child(uhx)
	var fol_cnt := int(CareerState.career["stats"].get("followers", 1000))
	var fol_str := "%.1fM" % (float(fol_cnt) / 1000000.0) if fol_cnt >= 1000000 else ("%.1fK" % (float(fol_cnt) / 1000.0) if fol_cnt >= 1000 else str(fol_cnt))
	var fl_v := Label.new()
	fl_v.text = "%s\n%s" % [str(p.get("naturalPosition", "ST")), fol_str]
	fl_v.add_theme_font_override("font", UITheme.get_display_font())
	fl_v.add_theme_font_size_override("font_size", 10)
	fl_v.add_theme_color_override("font_color", Color.WHITE)
	fphb.add_child(fl_v)

	# Pick Featured Post (prioritize unhandled CLUB_FOLLOW or selected post)
	var filtered: Array = []
	for post in sfeed:
		if _social_filter == "SEMUA" or _social_filter == "TAHUNMU" or str(post.get("category", "")) == _social_filter:
			filtered.append(post)
	if filtered.is_empty():
		filtered = sfeed

	var sel_post: Dictionary = {}
	if not _sel_social_id.is_empty():
		for fp in filtered:
			if str(fp.get("id", "")) == _sel_social_id:
				sel_post = fp
				break
	if sel_post.is_empty() and not filtered.is_empty():
		sel_post = filtered[0]
		_sel_social_id = str(sel_post.get("id", ""))

	# MAIN 2-COLUMN SOSMED STAGE
	var body_hb := HBoxContainer.new()
	body_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hb.add_theme_constant_override("separation", 12)
	parent.add_child(body_hb)

	# LEFT FEATURED INTERACTIVE CARD (Gambar 5 #IKLAN or Gambar 6 CLUB FOLLOW!)
	var left_wrap := PanelContainer.new()
	left_wrap.custom_minimum_size = Vector2(438, 0)
	left_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_wrap.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1324"), Color("#2D1D42"), 1, 8))
	body_hb.add_child(left_wrap)

	if _social_filter == "TAHUNMU":
		_build_social_year_recap(left_wrap)
	elif not sel_post.is_empty():
		var kind := str(sel_post.get("kind", "TEAMMATE"))
		if kind == "CLUB_FOLLOW":
			_build_club_follow_card(left_wrap, sel_post)
		elif kind == "BRAND_AD":
			_build_brand_ad_card(left_wrap, sel_post)
		else:
			_build_generic_social_card(left_wrap, sel_post)

	# RIGHT SOCIAL FEED LIST (Gambar 5 & 6)
	var f_scroll := ScrollContainer.new()
	f_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	f_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_hb.add_child(f_scroll)

	var f_vb := VBoxContainer.new()
	f_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_vb.add_theme_constant_override("separation", 6)
	f_scroll.add_child(f_vb)

	for post in filtered:
		var pid: String = str(post.get("id", ""))
		var pkind: String = str(post.get("kind", ""))
		var is_sel := (pid == _sel_social_id and _social_filter != "TAHUNMU")
		var is_new := (pkind == "CLUB_FOLLOW" and not bool(post.get("handled", false))) or (pkind == "BRAND_AD" and not bool(post.get("posted", false)))
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1328") if is_sel else Color("#0B1424"), Color("#EC4899") if is_sel else (Color("#A855F7") if is_new else Color("#1D2E47")), 1, 6))

		var rhb := HBoxContainer.new()
		rhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rhb.add_theme_constant_override("separation", 8)
		row.add_child(rhb)

		if pkind == "CLUB_FOLLOW":
			var ccr := ClubCrest.new()
			ccr.custom_minimum_size = Vector2(24, 24)
			ccr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ccr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ccr.set_club(int(post.get("club_id", 0)))
			rhb.add_child(ccr)
		else:
			var av := PixelAvatar.new()
			av.full_body = false
			av.custom_minimum_size = Vector2(24, 24)
			av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if pkind == "PLAYER":
				av.configure_from_career()
			else:
				av.configure_from_seed(pid.hash(), CareerState.get_current_club(), 10)
			rhb.add_child(av)

		var rvb := VBoxContainer.new()
		rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rvb.add_theme_constant_override("separation", 2)
		rhb.add_child(rvb)

		var rtop := HBoxContainer.new()
		rtop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rvb.add_child(rtop)
		var auth_l := Label.new()
		auth_l.text = "%s  %s" % [str(post.get("author", "")), str(post.get("handle", ""))]
		auth_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		auth_l.clip_text = true
		auth_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		auth_l.add_theme_font_size_override("font_size", 9)
		auth_l.add_theme_color_override("font_color", Color("#F472B6") if pkind == "CLUB_FOLLOW" else Color("#93C5FD"))
		rtop.add_child(auth_l)
		var lk_n := int(post.get("likes", 0))
		if lk_n > 0:
			var lkl := Label.new()
			lkl.text = "▲ %d" % lk_n
			lkl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lkl.add_theme_font_size_override("font_size", 9)
			lkl.add_theme_color_override("font_color", Color("#94A3B8"))
			rtop.add_child(lkl)

		var txt_l := Label.new()
		txt_l.text = str(post.get("text", ""))
		txt_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt_l.add_theme_font_size_override("font_size", 10)
		txt_l.add_theme_color_override("font_color", Color.WHITE)
		rvb.add_child(txt_l)

		var hit := Button.new()
		hit.flat = true
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_pid: String = pid
		hit.pressed.connect(func():
			AudioSynth.play_click()
			_social_filter = "SEMUA"
			_sel_social_id = cap_pid
			refresh()
		)
		row.add_child(hit)
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		f_vb.add_child(row)

func _build_club_follow_card(host: PanelContainer, post: Dictionary) -> void:
	# EXACT GAMBAR 6: Club started following player -> IKUTI BALIK / ABAIKAN!
	var cid: int = clampi(int(post.get("club_id", 0)), 0, maxi(0, GameData.clubs.size() - 1))
	var club: Dictionary = GameData.clubs[cid]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	host.add_child(hb)

	# Left dark vertical club showcase card
	var left_c := PanelContainer.new()
	left_c.custom_minimum_size = Vector2(128, 0)
	left_c.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121D32"), Color("#294166"), 1, 8))
	hb.add_child(left_c)
	var lvb := VBoxContainer.new()
	lvb.alignment = BoxContainer.ALIGNMENT_CENTER
	lvb.add_theme_constant_override("separation", 8)
	left_c.add_child(lvb)
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(72, 72)
	cr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cr.set_club(cid)
	lvb.add_child(cr)
	var cnm := Label.new()
	cnm.text = str(club["name"]).to_upper()
	cnm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cnm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cnm.add_theme_font_override("font", UITheme.get_display_font())
	cnm.add_theme_font_size_override("font_size", 11)
	lvb.add_child(cnm)
	var cdiv := Label.new()
	cdiv.text = "KE-%d  •  OVR %d" % [int(club.get("division", 1)), int(club.get("ovr", 65))]
	cdiv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cdiv.add_theme_font_size_override("font_size", 9)
	cdiv.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	lvb.add_child(cdiv)

	# Right action panel
	var rvb := VBoxContainer.new()
	rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.alignment = BoxContainer.ALIGNMENT_CENTER
	rvb.add_theme_constant_override("separation", 8)
	hb.add_child(rvb)

	var top_r := HBoxContainer.new()
	rvb.add_child(top_r)
	var hdl := Label.new()
	hdl.text = "%s • KINI" % str(post.get("handle", "@KLUB"))
	hdl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdl.clip_text = true
	hdl.add_theme_font_override("font", UITheme.get_display_font())
	hdl.add_theme_font_size_override("font_size", 11)
	top_r.add_child(hdl)
	var k_p := PanelContainer.new()
	k_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#3B1C63"), Color("#A855F7"), 1, 4))
	var k_l := Label.new()
	k_l.text = "KLUB"
	k_l.add_theme_font_size_override("font_size", 8)
	k_l.add_theme_color_override("font_color", Color("#E9D5FF"))
	k_p.add_child(k_l)
	top_r.add_child(k_p)

	var msg_l := Label.new()
	msg_l.text = "MULAI MENGIKUTIMU"
	msg_l.add_theme_font_override("font", UITheme.get_display_font())
	msg_l.add_theme_font_size_override("font_size", 15)
	msg_l.add_theme_color_override("font_color", Color("#F472B6"))
	rvb.add_child(msg_l)

	var guar_l := Label.new()
	guar_l.text = "★ TAWARAN PASTI  •  JENDELA TRANSFER BERIKUT"
	guar_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guar_l.add_theme_font_size_override("font_size", 10)
	guar_l.add_theme_color_override("font_color", Color("#E2E8F0"))
	rvb.add_child(guar_l)

	var handled := bool(post.get("handled", false))
	var followed := bool(post.get("followed_back", false))
	if handled:
		var st_p := PanelContainer.new()
		st_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#123524") if followed else Color("#1E293B"), UITheme.ACCENT_GREEN if followed else Color("#475569"), 1, 6))
		var st_l := Label.new()
		st_l.text = "✓ DIIKUTI BALIK • TAWARAN MASUK DI BURSA BERIKUTNYA" if followed else "DIABAIKAN"
		st_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st_l.add_theme_font_override("font", UITheme.get_display_font())
		st_l.add_theme_font_size_override("font_size", 10)
		st_l.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if followed else Color("#94A3B8"))
		st_p.add_child(st_l)
		rvb.add_child(st_p)
	else:
		var btn_hb := HBoxContainer.new()
		btn_hb.add_theme_constant_override("separation", 8)
		rvb.add_child(btn_hb)

		var fb_btn := Button.new()
		fb_btn.text = "IKUTI BALIK"
		fb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb_btn.custom_minimum_size = Vector2(0, 38)
		fb_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		UITheme.style_btn(fb_btn, Color("#DB2777"), Color("#F9A8D4"), 12)
		var pid_c := str(post.get("id", ""))
		fb_btn.pressed.connect(func():
			AudioSynth.play_achievement()
			CareerState.follow_back_club_social(pid_c)
		)
		btn_hb.add_child(fb_btn)

		var ig_btn := Button.new()
		ig_btn.text = "ABAIKAN"
		ig_btn.custom_minimum_size = Vector2(88, 38)
		ig_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		UITheme.style_btn(ig_btn, Color("#111B2E"), Color("#475569"), 11)
		ig_btn.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.ignore_club_social(pid_c)
		)
		btn_hb.add_child(ig_btn)

		var warn_l := Label.new()
		warn_l.text = "Dampak Ikuti Balik:  -6 Pelatih   •   -4 Tim   •   -5 Fans"
		warn_l.add_theme_font_size_override("font_size", 9)
		warn_l.add_theme_color_override("font_color", Color("#FB7185"))
		rvb.add_child(warn_l)

func _build_brand_ad_card(host: PanelContainer, post: Dictionary) -> void:
	# EXACT GAMBAR 5: #IKLAN Brand Sponsorship Card
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	host.add_child(hb)

	var poster := PanelContainer.new()
	poster.custom_minimum_size = Vector2(132, 0)
	poster.add_theme_stylebox_override("panel", UITheme.make_box(Color("#3D1014"), Color("#EF4444"), 2, 8))
	hb.add_child(poster)
	var pvb := VBoxContainer.new()
	pvb.alignment = BoxContainer.ALIGNMENT_CENTER
	pvb.add_theme_constant_override("separation", 8)
	poster.add_child(pvb)
	var tag := PanelContainer.new()
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", UITheme.make_box(Color("#EAB308"), Color.TRANSPARENT, 0, 4))
	var tl := Label.new()
	tl.text = "#IKLAN"
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 9)
	tl.add_theme_color_override("font_color", Color("#1A1204"))
	tag.add_child(tl)
	pvb.add_child(tag)
	var bolt := Label.new()
	bolt.text = "⚡"
	bolt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bolt.add_theme_font_size_override("font_size", 32)
	bolt.add_theme_color_override("font_color", Color("#FB7185"))
	pvb.add_child(bolt)
	var bnm := Label.new()
	bnm.text = str(post.get("brand", "VOLT COLA"))
	bnm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bnm.add_theme_font_override("font", UITheme.get_display_font())
	bnm.add_theme_font_size_override("font_size", 13)
	pvb.add_child(bnm)

	var rvb := VBoxContainer.new()
	rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.alignment = BoxContainer.ALIGNMENT_CENTER
	rvb.add_theme_constant_override("separation", 7)
	hb.add_child(rvb)

	var h1 := Label.new()
	h1.text = "%s • M%d  [MEREK]" % [str(post.get("handle", "@VOLTCOLA")), int(post.get("week", 1))]
	h1.add_theme_font_override("font", UITheme.get_display_font())
	h1.add_theme_font_size_override("font_size", 11)
	h1.add_theme_color_override("font_color", Color("#FACC15"))
	rvb.add_child(h1)

	var sub := Label.new()
	sub.text = "MENAWARIMU #IKLAN"
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color("#94A3B8"))
	rvb.add_child(sub)

	var qt := Label.new()
	qt.text = str(post.get("text", "\"Fotomu dengan produk kami setelah latihan.\""))
	qt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qt.add_theme_font_override("font", UITheme.get_display_font())
	qt.add_theme_font_size_override("font_size", 13)
	rvb.add_child(qt)

	var pay := Label.new()
	pay.text = "+ %s" % UITheme.format_cash(int(post.get("payout", 12000)))
	pay.add_theme_font_override("font", UITheme.get_display_font())
	pay.add_theme_font_size_override("font_size", 17)
	pay.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	rvb.add_child(pay)

	var posted := bool(post.get("posted", false))
	var act_b := Button.new()
	act_b.custom_minimum_size = Vector2(150, 34)
	act_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	act_b.disabled = posted
	act_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if posted:
		act_b.text = "✓ TERPOSTING"
		UITheme.style_btn(act_b, Color("#2E2612"), UITheme.ACCENT_GOLD, 11)
	else:
		act_b.text = "POSTING IKLAN"
		UITheme.style_btn(act_b, Color("#15803D"), Color("#86EFAC"), 11)
		var pid_c := str(post.get("id", ""))
		act_b.pressed.connect(func():
			AudioSynth.play_achievement()
			CareerState.accept_brand_ad_social(pid_c)
		)
	rvb.add_child(act_b)

func _build_generic_social_card(host: PanelContainer, post: Dictionary) -> void:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	host.add_child(vb)
	var av := PixelAvatar.new()
	av.full_body = false
	av.custom_minimum_size = Vector2(68, 68)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if str(post.get("kind", "")) == "PLAYER":
		av.configure_from_career()
	else:
		av.configure_from_seed(str(post.get("id", "")).hash(), CareerState.get_current_club(), 10)
	vb.add_child(av)
	var h1 := Label.new()
	h1.text = "%s  %s" % [str(post.get("author", "")), str(post.get("handle", ""))]
	h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h1.add_theme_font_override("font", UITheme.get_display_font())
	h1.add_theme_font_size_override("font_size", 13)
	h1.add_theme_color_override("font_color", Color("#93C5FD"))
	vb.add_child(h1)
	var body := Label.new()
	body.text = str(post.get("text", ""))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", UITheme.get_display_font())
	body.add_theme_font_size_override("font_size", 15)
	vb.add_child(body)
	var lk := Label.new()
	lk.text = "▲ %d SUKA" % int(post.get("likes", 0))
	lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lk.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(lk)

func _build_social_year_recap(host: PanelContainer) -> void:
	var st: Dictionary = CareerState.career["stats"]
	var p: Dictionary = CareerState.career["playerProfile"]
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	host.add_child(vb)
	var ttl := Label.new()
	ttl.text = "★ TAHUN MEDSOSMU"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 18)
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(ttl)
	var av := PixelAvatar.new()
	av.full_body = false
	av.custom_minimum_size = Vector2(72, 72)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.configure_from_career()
	vb.add_child(av)
	var desc := Label.new()
	desc.text = "@%s • PENGIKUT: %s\nGOL KARIER: %d  •  ASIS: %d  •  MOTM: %d\nKLUB MEMANTAU: %d KLUB" % [
		str(p["name"]).to_upper(),
		UITheme.format_cash(int(st.get("followers", 0))).replace("$ ", ""),
		int(st.get("goals", 0)), int(st.get("assists", 0)), int(st.get("motm", 0)),
		CareerState.career.get("watchingClubIds", []).size()
	]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("#E2E8F0"))
	vb.add_child(desc)

# =============================================================================
# CHANNEL 5: PESAN INBOX (Gambar 7: Teammate Assist + Interactive Supporter Replies!)
# =============================================================================
func _render_pesan(parent: VBoxContainer) -> void:
	var p: Dictionary = CareerState.career["playerProfile"]
	var handle := "@" + str(p.get("name", "ALFIAN")).to_upper().replace(" ", "")
	var inbox: Array = CareerState.career.get("inboxMessages", [])

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	parent.add_child(hdr)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(26, 26)
	badge.add_theme_stylebox_override("panel", UITheme.make_box(Color("#F97316"), Color.TRANSPARENT, 0, 6))
	var bi := PhoneNavIcon.new()
	bi.custom_minimum_size = Vector2(18, 18)
	bi.configure("PESAN", Color.WHITE)
	badge.add_child(bi)
	hdr.add_child(badge)

	var hvb := VBoxContainer.new()
	hvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hvb.add_theme_constant_override("separation", 0)
	hdr.add_child(hvb)
	var tl := Label.new()
	tl.text = "PESAN"
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 15)
	hvb.add_child(tl)
	var hl := Label.new()
	hl.text = handle
	hl.add_theme_font_size_override("font_size", 9)
	hl.add_theme_color_override("font_color", Color("#94A3B8"))
	hvb.add_child(hl)

	hdr.add_child(_make_medsos_year_pill())

	if inbox.is_empty():
		var el := Label.new()
		el.text = "BELUM ADA PESAN MASUK. BERI ASIS ATAU CETAK GOL UNTUK MENDAPAT PESAN!"
		el.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		parent.add_child(el)
		return

	var sel_msg: Dictionary = {}
	for m in inbox:
		if str(m.get("id", "")) == _sel_msg_id:
			sel_msg = m
			break
	if sel_msg.is_empty():
		sel_msg = inbox[0]
		_sel_msg_id = str(sel_msg.get("id", ""))

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 12)
	parent.add_child(split)

	# LEFT CONVERSATION LIST (Gambar 7)
	var l_scroll := ScrollContainer.new()
	l_scroll.custom_minimum_size = Vector2(276, 0)
	l_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	l_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(l_scroll)

	var l_vb := VBoxContainer.new()
	l_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_vb.add_theme_constant_override("separation", 6)
	l_scroll.add_child(l_vb)

	for m in inbox:
		var mid: String = str(m.get("id", ""))
		var is_sel := (mid == _sel_msg_id)
		var is_rep := bool(m.get("replied", false))
		var is_fan := (str(m.get("sender_type", "")) == "SUPPORTER")
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1525") if is_sel else Color("#0B1424"), Color("#F97316") if is_sel else Color("#24354F"), 2 if is_sel else 1, 7))

		var cvb := VBoxContainer.new()
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_theme_constant_override("separation", 3)
		card.add_child(cvb)

		var r1 := HBoxContainer.new()
		r1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r1.add_theme_constant_override("separation", 5)
		cvb.add_child(r1)

		if is_fan:
			var fp := PanelContainer.new()
			fp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#3B1540"), Color("#EC4899"), 1, 3))
			var fl := Label.new()
			fl.text = "FAN"
			fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fl.add_theme_font_size_override("font_size", 8)
			fl.add_theme_color_override("font_color", Color("#FBCFE8"))
			fp.add_child(fl)
			r1.add_child(fp)
		else:
			var hx := MiniOvrHexBadge.new()
			hx.custom_minimum_size = Vector2(20, 20)
			hx.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hx.configure(int(m.get("sender_ovr", 62)))
			r1.add_child(hx)
			var pp := PanelContainer.new()
			pp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2B1120"), Color("#E11D48"), 1, 2))
			var pl := Label.new()
			pl.text = str(m.get("sender_pos", "ST"))
			pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pl.add_theme_font_size_override("font_size", 8)
			pp.add_child(pl)
			r1.add_child(pp)

		var sn := Label.new()
		sn.text = str(m.get("sender_name", "Rekan"))
		sn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sn.clip_text = true
		sn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sn.add_theme_font_override("font", UITheme.get_display_font())
		sn.add_theme_font_size_override("font_size", 11)
		r1.add_child(sn)

		if not is_rep:
			var bp := PanelContainer.new()
			bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#EA580C"), Color.TRANSPARENT, 0, 3))
			var bl := Label.new()
			bl.text = "BARU"
			bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bl.add_theme_font_size_override("font_size", 8)
			bl.add_theme_color_override("font_color", Color.WHITE)
			bp.add_child(bl)
			r1.add_child(bp)

		var prev := Label.new()
		prev.text = str(m.get("preview", ""))
		prev.clip_text = true
		prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prev.add_theme_font_size_override("font_size", 10)
		prev.add_theme_color_override("font_color", Color("#CBD5E1"))
		cvb.add_child(prev)

		var hit := Button.new()
		hit.flat = true
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_mid: String = mid
		hit.pressed.connect(func(): AudioSynth.play_click(); _sel_msg_id = cap_mid; refresh())
		card.add_child(hit)
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l_vb.add_child(card)

	# RIGHT MESSAGE THREAD + INTERACTIVE REPLIES (Gambar 7)
	var thread := PanelContainer.new()
	thread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thread.add_theme_stylebox_override("panel", UITheme.make_box(Color("#120E1D"), Color("#2D2540"), 1, 8))
	split.add_child(thread)

	var tvb := VBoxContainer.new()
	tvb.add_theme_constant_override("separation", 10)
	thread.add_child(tvb)

	# Thread Header
	var thdr := HBoxContainer.new()
	thdr.add_theme_constant_override("separation", 8)
	tvb.add_child(thdr)
	var is_sel_fan := (str(sel_msg.get("sender_type", "")) == "SUPPORTER")
	if is_sel_fan:
		var fp2 := PanelContainer.new()
		fp2.add_theme_stylebox_override("panel", UITheme.make_box(Color("#3B1540"), Color("#EC4899"), 1, 4))
		var fl2 := Label.new()
		fl2.text = "SUPORTER"
		fl2.add_theme_font_size_override("font_size", 9)
		fl2.add_theme_color_override("font_color", Color("#FBCFE8"))
		fp2.add_child(fl2)
		thdr.add_child(fp2)
	else:
		var hx2 := MiniOvrHexBadge.new()
		hx2.custom_minimum_size = Vector2(24, 24)
		hx2.configure(int(sel_msg.get("sender_ovr", 62)))
		thdr.add_child(hx2)
		var pp2 := PanelContainer.new()
		pp2.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2B1120"), Color("#E11D48"), 1, 3))
		var pl2 := Label.new()
		pl2.text = str(sel_msg.get("sender_pos", "ST"))
		pl2.add_theme_font_size_override("font_size", 9)
		pp2.add_child(pl2)
		thdr.add_child(pp2)

	var tnm := Label.new()
	tnm.text = str(sel_msg.get("sender_name", "Rekan"))
	tnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tnm.add_theme_font_override("font", UITheme.get_display_font())
	tnm.add_theme_font_size_override("font_size", 14)
	thdr.add_child(tnm)

	var st_chip := PanelContainer.new()
	st_chip.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1C2436"), Color("#475569"), 1, 4))
	var st_cl := Label.new()
	st_cl.text = "✓ DIBALAS" if bool(sel_msg.get("replied", false)) else "SISA %d" % int(sel_msg.get("expires_in", 2))
	st_cl.add_theme_font_size_override("font_size", 9)
	st_cl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if bool(sel_msg.get("replied", false)) else Color("#CBD5E1"))
	st_chip.add_child(st_cl)
	thdr.add_child(st_chip)

	# Incoming Message Bubble
	var in_bub := PanelContainer.new()
	in_bub.add_theme_stylebox_override("panel", UITheme.make_box(Color("#241C35"), Color("#3F335C"), 1, 8))
	tvb.add_child(in_bub)
	var in_l := Label.new()
	in_l.text = str(sel_msg.get("body", ""))
	in_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	in_l.add_theme_font_override("font", UITheme.get_display_font())
	in_l.add_theme_font_size_override("font_size", 13)
	in_bub.add_child(in_l)

	# Context Tag Chip (-> ASISTMU • P28 3 - 2 or ★ SUPORTER)
	var ctx_p := PanelContainer.new()
	ctx_p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ctx_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#47131D"), Color("#BE123C"), 1, 4))
	var ctx_l := Label.new()
	ctx_l.text = "-> %s" % str(sel_msg.get("context_tag", "PESAN"))
	ctx_l.add_theme_font_size_override("font_size", 10)
	ctx_l.add_theme_color_override("font_color", Color("#FDA4AF"))
	ctx_p.add_child(ctx_l)
	tvb.add_child(ctx_p)

	var mid_spc := Control.new()
	mid_spc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(mid_spc)

	# Bottom Sent Reply Bubble OR Interactive Reply Choices
	if bool(sel_msg.get("replied", false)):
		var out_hb := HBoxContainer.new()
		out_hb.alignment = BoxContainer.ALIGNMENT_END
		tvb.add_child(out_hb)
		var out_bub := PanelContainer.new()
		out_bub.add_theme_stylebox_override("panel", UITheme.make_box(Color("#5C3A1E"), Color("#D97706"), 1, 8))
		var out_l := Label.new()
		out_l.text = str(sel_msg.get("reply_text", "Terima kasih!"))
		out_l.add_theme_font_override("font", UITheme.get_display_font())
		out_l.add_theme_font_size_override("font_size", 12)
		out_l.add_theme_color_override("font_color", Color("#FEF3C7"))
		out_bub.add_child(out_l)
		out_hb.add_child(out_bub)
	else:
		var rep_hdr := Label.new()
		rep_hdr.text = "PILIH BALASANMU:"
		rep_hdr.add_theme_font_size_override("font_size", 9)
		rep_hdr.add_theme_color_override("font_color", Color("#FDBA74"))
		tvb.add_child(rep_hdr)
		var reps: Array = sel_msg.get("replies", [])
		var msg_id_c := str(sel_msg.get("id", ""))
		for ri in range(reps.size()):
			var r_dict: Dictionary = reps[ri]
			var rb := Button.new()
			var hint_parts: Array[String] = []
			if int(r_dict.get("rg", 0)) > 0: hint_parts.append("+%d Tim" % int(r_dict["rg"]))
			if int(r_dict.get("fans", 0)) > 0: hint_parts.append("+%d Fans" % int(r_dict["fans"]))
			if int(r_dict.get("pelatih", 0)) > 0: hint_parts.append("+%d Pelatih" % int(r_dict["pelatih"]))
			rb.text = "%s  [%s]" % [str(r_dict.get("text", "Balas")), " • ".join(hint_parts)]
			rb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			rb.custom_minimum_size = Vector2(0, 32)
			rb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			UITheme.style_btn(rb, Color("#241913"), Color("#EA580C"), 10)
			var cap_ri: int = ri
			rb.pressed.connect(func():
				AudioSynth.play_click()
				CareerState.reply_inbox_message(msg_id_c, cap_ri)
			)
			tvb.add_child(rb)

# =============================================================================
# DYNAMIC ARTICLE GENERATORS (Real Career / League / World Data)
# =============================================================================
func _build_club_articles() -> Array[Dictionary]:
	var club := CareerState.get_current_club()
	var p: Dictionary = CareerState.career["playerProfile"]
	var uname := str(p.get("name", "ALFIAN")).capitalize()
	var wk := int(CareerState.career["careerMeta"].get("week", 1))
	var cid := int(club["id"])
	var out: Array[Dictionary] = []

	out.append({
		"club_id": cid,
		"source": club["name"],
		"meta_wk": "M%d" % wk,
		"tag": "HADIAH",
		"headline": "%s memberikan jerseynya kepada seorang anak di tribun" % uname,
		"body": "Usai sesi latihan dan laga pekan ini bersama %s, %s menghampiri tribun suporter muda dan menyerahkan jersey bernomor punggung #%d. Aksi hangat tersebut langsung viral di kalangan pendukung setia klub." % [club["name"], uname, int(p["appearance"].get("shirt_num", 9))],
		"subject": uname,
		"ovr": int(p.get("ovr", 62)),
		"pos": str(p.get("naturalPosition", "ST")),
	})
	out.append({
		"club_id": cid,
		"source": club["name"],
		"meta_wk": "M%d" % wk,
		"tag": "DIREKSI",
		"headline": "Direksi %s puas dengan perkembangan skuat musim ini" % club["name"],
		"body": "Manajemen %s memuji konsistensi tim yang saat ini bertengger di peringkat ke-%d liga. Pelatih memastikan fokus penuh jelang pertandingan berikutnya." % [club["name"], CareerState.get_user_league_position()],
		"subject": club["name"],
		"ovr": 0,
	})
	for n in CareerState.career.get("news", []):
		if str(n.get("channel", "")) == "KLUB":
			out.append({
				"club_id": cid,
				"source": club["name"],
				"meta_wk": "M%d" % int(n.get("season", 1)),
				"tag": "KLUB",
				"headline": str(n.get("text", "")),
				"body": str(n.get("text", "")),
				"subject": uname,
				"ovr": int(p.get("ovr", 62)),
				"pos": str(p.get("naturalPosition", "ST")),
			})
	return out

func _build_league_articles() -> Array[Dictionary]:
	var club := CareerState.get_current_club()
	var wk := int(CareerState.career["careerMeta"].get("week", 1))
	var tbl: Array = CareerState.career.get("leagueTable", [])
	var out: Array[Dictionary] = []
	var nat_clubs := GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	if nat_clubs.size() >= 3:
		var c1: Dictionary = nat_clubs[nat_clubs.size() - 1]
		out.append({
			"club_id": int(c1["id"]),
			"source": c1["name"],
			"meta_wk": "M%d" % wk,
			"tag": "PRIMA",
			"headline": "%s tak menang dalam 5 laga terakhir" % c1["name"],
			"body": "Tekanan meningkat di kubu %s setelah gagal memetik kemenangan dalam lima pertandingan liga berturut-turut. Suporter menuntut perubahan taktik segera." % c1["name"],
			"subject": c1["name"],
			"ovr": 0,
		})
		for i in range(mini(3, nat_clubs.size() - 1)):
			var ci: Dictionary = nat_clubs[i]
			out.append({
				"club_id": int(ci["id"]),
				"source": ci["name"],
				"meta_wk": "M%d" % wk,
				"tag": "PRIMA",
				"headline": "%s bersaing ketat di papan atas klasemen" % ci["name"],
				"body": "Dengan kekuatan OVR %d, %s menjadi salah satu kandidat kuat promosi musim ini di divisi ke-%d." % [int(ci["ovr"]), ci["name"], int(club["division"])],
				"subject": ci["name"],
				"ovr": 0,
			})
	var starters: Array = CareerState.career.get("clubSquad", {}).get("starters", [])
	if starters.size() > 7:
		var stp: Dictionary = starters[7]
		out.append({
			"club_id": int(club["id"]),
			"source": club["name"],
			"meta_wk": "M%d" % wk,
			"tag": "RAJA ASSIST",
			"headline": "%s pimpin daftar kreator peluang liga" % str(stp.get("name", "Gelandang")),
			"body": "Gelandang %s tampil kreatif menciptakan umpan-umpan kunci sepanjang musim ini bersama %s." % [str(stp.get("name", "Gelandang")), club["name"]],
			"subject": str(stp.get("name", "Gelandang")),
			"ovr": int(stp.get("ovr", 62)),
			"pos": str(stp.get("pos", "CM")),
		})
	for n in CareerState.career.get("news", []):
		if str(n.get("channel", "")) == "LIGA":
			out.append({
				"club_id": int(club["id"]),
				"source": "LIGA",
				"meta_wk": "M%d" % wk,
				"tag": "SOROTAN",
				"headline": str(n.get("text", "")),
				"body": str(n.get("text", "")),
				"subject": str(CareerState.career["playerProfile"].get("name", "ALFIAN")),
				"ovr": int(CareerState.career["playerProfile"].get("ovr", 62)),
				"pos": str(CareerState.career["playerProfile"].get("naturalPosition", "ST")),
			})
	return out

func _build_world_articles() -> Array[Dictionary]:
	var wk := int(CareerState.career["careerMeta"].get("week", 1))
	var out: Array[Dictionary] = []
	for i in range(mini(8, CareerState.wp_rank_order.size())):
		var idx: int = CareerState.wp_rank_order[i]
		var wcid: int = clampi(int(CareerState.wp_club[idx]), 0, maxi(0, GameData.clubs.size() - 1))
		var wc: Dictionary = GameData.clubs[wcid]
		var wp_nm: String = str(CareerState.wp_name[idx])
		var wp_ov: int = int(CareerState.wp_ovr[idx])
		var wp_ps: String = GameData.POSITIONS[clampi(int(CareerState.wp_pos[idx]), 0, GameData.POSITIONS.size() - 1)]
		var tags := ["RAJA ASSIST", "PRIMA", "BINTANG DUNIA", "CADANGAN", "REKOR GOL"]
		var tg: String = tags[i % tags.size()]
		var hline := (
			"%s (%s) tampil gemilang dan memuncaki peringkat bintang dunia!" % [wp_nm, wc["name"]]
			if i % 2 == 0 else
			"%s membidik gelar Piala Elite bersama bintang andalan %s" % [wc["name"], wp_nm]
		)
		out.append({
			"club_id": wcid,
			"source": wc["name"],
			"meta_wk": "M%d" % wk,
			"tag": tg,
			"headline": hline,
			"body": "Bintang internasional %s (OVR %d, %s) terus menjadi sorotan media olahraga dunia musim ini bersama %s." % [wp_nm, wp_ov, wp_ps, wc["name"]],
			"subject": wp_nm,
			"ovr": wp_ov,
			"pos": wp_ps,
		})
	return out

class PhoneNavIcon extends Control:
	var _kind: String = "KLUB"
	var _col: Color = Color.WHITE

	func configure(kind: String, col: Color) -> void:
		_kind = kind
		_col = col
		queue_redraw()

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		match _kind:
			"KLUB":
				var pts := PackedVector2Array([
					Vector2(cx - 7, cy - 8), Vector2(cx + 7, cy - 8),
					Vector2(cx + 7, cy + 2), Vector2(cx, cy + 9), Vector2(cx - 7, cy + 2)
				])
				draw_colored_polygon(pts, _col)
			"LIGA":
				draw_rect(Rect2(cx - 6, cy - 7, 12, 8), _col)
				draw_rect(Rect2(cx - 2, cy + 1, 4, 4), _col)
				draw_rect(Rect2(cx - 5, cy + 5, 10, 2.5), _col)
			"DUNIA":
				draw_arc(Vector2(cx, cy), 8.0, 0.0, TAU, 20, _col, 1.8)
				draw_line(Vector2(cx - 8, cy), Vector2(cx + 8, cy), _col, 1.4)
				draw_line(Vector2(cx, cy - 8), Vector2(cx, cy + 8), _col, 1.4)
			"SOSMED":
				draw_rect(Rect2(cx - 8, cy - 7, 16, 12), _col)
				draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, cy + 5), Vector2(cx, cy + 9), Vector2(cx + 2, cy + 5)]), _col)
				draw_circle(Vector2(cx, cy - 1), 2.5, Color("#0A1222"))
			"PESAN":
				draw_rect(Rect2(cx - 8, cy - 6, 16, 12), _col)
				draw_line(Vector2(cx - 8, cy - 6), Vector2(cx, cy + 1), Color("#0A1222"), 1.8)
				draw_line(Vector2(cx + 8, cy - 6), Vector2(cx, cy + 1), Color("#0A1222"), 1.8)

class MiniOvrHexBadge extends Control:
	var _ovr: int = 62
	var _tier: Dictionary = {}

	func configure(ovr: int) -> void:
		_ovr = ovr
		_tier = SquadPlayerCardScript.get_ovr_tier(ovr)
		queue_redraw()

	func _draw() -> void:
		if _tier.is_empty():
			return
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.0
		var pts := PackedVector2Array()
		for k in range(6):
			var ang := -PI * 0.5 + float(k) * PI / 3.0
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		draw_colored_polygon(pts, _tier["hex_fill"])
		draw_polyline(pts + PackedVector2Array([pts[0]]), _tier["hex_rim"], 1.6)
		draw_string(UITheme.get_display_font(), Vector2(c.x - r, c.y + 3.5), str(_ovr), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 9, _tier["hex_txt"])
