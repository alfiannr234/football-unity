extends Control

signal inspect_player_requested(player_dict: Dictionary, club_dict: Dictionary)

var _subtab: String = "SKUAD"  # SKUAD or MANAJEMEN
var _scope: String = "KLUB"     # KLUB or TIMNAS
var _show_ovr: bool = false
var _body: VBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)

	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 6)
	outer.add_child(thb)
	for st in ["SKUAD", "MANAJEMEN"]:
		var b := Button.new()
		b.text = st
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(func(): AudioSynth.play_click(); _subtab = st; refresh())
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

	if _subtab == "SKUAD":
		_render_squad()
	else:
		_render_management()

func _render_squad() -> void:
	var club := CareerState.get_current_club()
	var squad: Dictionary = CareerState.career["clubSquad"]
	var starters: Array = squad["starters"]
	var bench: Array = squad["bench"]

	if _scope == "TIMNAS" and int(CareerState.career["playerProfile"]["ovr"]) < 68:
		var sc_hb_lock := HBoxContainer.new()
		sc_hb_lock.add_theme_constant_override("separation", 6)
		_body.add_child(sc_hb_lock)
		for s in ["KLUB", "TIMNAS"]:
			var b := Button.new()
			b.text = s
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UITheme.style_btn(b, Color("#173B66") if _scope == s else Color("#0B1626"), UITheme.BORDER_CYAN if _scope == s else UITheme.BORDER_STEEL)
			b.pressed.connect(func(): AudioSynth.play_click(); _scope = s; refresh())
			sc_hb_lock.add_child(b)
		var msg := PanelContainer.new()
		_body.add_child(msg)
		var l := Label.new()
		l.text = "Panggilan TIMNAS (%s) terbuka setelah OVR mencapai 68+ dan performa konsisten!" % GameData.nations[int(CareerState.career["playerProfile"]["nationId"])]["name"]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.add_child(l)
		return

	# Landscape 2-Column Squad View: Left = 5-3-2 Pitch | Right = Controls & Bench
	var split_hb := HBoxContainer.new()
	split_hb.add_theme_constant_override("separation", 12)
	_body.add_child(split_hb)

	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(455, 0)
	left_col.add_theme_constant_override("separation", 6)
	split_hb.add_child(left_col)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 6)
	split_hb.add_child(right_col)

	var hdr := HBoxContainer.new()
	left_col.add_child(hdr)
	var tl := Label.new()
	tl.text = "TIM INTI • %s  |  KAPTEN: ENGSTROM" % squad["formation"]
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	tl.add_theme_font_size_override("font_size", 11)
	hdr.add_child(tl)
	hdr.add_child(UITheme.make_ovr_badge(int(club["ovr"]), "default", Vector2(30, 28)))

	# Tactical 2D Green Pitch with 5-3-2 Player Cards
	var pitch := PanelContainer.new()
	pitch.custom_minimum_size = Vector2(0, 292)
	pitch.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1B6E2E"), Color("#D2E8D6"), 2, 4))
	left_col.add_child(pitch)

	var pvb := VBoxContainer.new()
	pvb.alignment = BoxContainer.ALIGNMENT_CENTER
	pvb.add_theme_constant_override("separation", 6)
	pitch.add_child(pvb)

	# Row 1: 2 Strikers, Row 2: 3 Midfielders, Row 3: 5 Defenders, Row 4: 1 GK
	var rows := [
		[10, 9],
		[6, 7, 8],
		[1, 2, 3, 4, 5],
		[0],
	]
	for r_indices in rows:
		var rhb := HBoxContainer.new()
		rhb.alignment = BoxContainer.ALIGNMENT_CENTER
		rhb.add_theme_constant_override("separation", 6)
		pvb.add_child(rhb)
		for idx in r_indices:
			if idx < starters.size():
				rhb.add_child(_make_mini_card(starters[idx], club))

	# Right Column: Scope + Mode + Bench Grid
	var sc_hb := HBoxContainer.new()
	sc_hb.add_theme_constant_override("separation", 6)
	right_col.add_child(sc_hb)
	for s in ["KLUB", "TIMNAS"]:
		var b := Button.new()
		b.text = s
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(b, Color("#173B66") if _scope == s else Color("#0B1626"), UITheme.BORDER_CYAN if _scope == s else UITheme.BORDER_STEEL)
		b.pressed.connect(func(): AudioSynth.play_click(); _scope = s; refresh())
		sc_hb.add_child(b)

	var mode_hb := HBoxContainer.new()
	mode_hb.add_theme_constant_override("separation", 6)
	right_col.add_child(mode_hb)
	for m in [["POSISI", false], ["OVR", true]]:
		var mb := Button.new()
		mb.text = m[0]
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(mb, Color("#173B66") if _show_ovr == m[1] else Color("#0B1626"), UITheme.BORDER_CYAN)
		mb.pressed.connect(func(): AudioSynth.play_click(); _show_ovr = m[1]; refresh())
		mode_hb.add_child(mb)

	right_col.add_child(UITheme.make_section_header("BANGKU CADANGAN"))
	var b_grid := GridContainer.new()
	b_grid.columns = 4
	b_grid.add_theme_constant_override("h_separation", 6)
	b_grid.add_theme_constant_override("v_separation", 6)
	right_col.add_child(b_grid)
	for bp in bench:
		b_grid.add_child(_make_mini_card(bp, club))

func _make_mini_card(pd: Dictionary, club: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(68, 62)
	var is_u := bool(pd.get("is_user", false))
	UITheme.style_btn(btn, Color("#153458") if is_u else Color("#3E3216"), UITheme.ACCENT_GOLD if is_u else Color("#9E8036"), 9)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var top := Label.new()
	top.text = "%s  %d" % [pd["pos"], int(pd["ovr"])]
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_font_size_override("font_size", 9)
	top.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if is_u else UITheme.ACCENT_GOLD)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top)

	var av := PixelAvatar.new()
	av.full_body = false
	av.custom_minimum_size = Vector2(32, 28)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_u:
		av.configure_from_career()
	else:
		av.configure_from_seed(int(pd.get("seed", 1)), club, int(pd.get("number", 9)))
	vb.add_child(av)

	var nm := Label.new()
	nm.text = str(pd["name"]).left(10)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 10)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(nm)

	btn.pressed.connect(func(): AudioSynth.play_click(); inspect_player_requested.emit(pd, club))
	return btn

func _render_management() -> void:
	# Manager Office Scene (matching Screenshot #13)
	var office := PanelContainer.new()
	office.custom_minimum_size = Vector2(0, 160)
	_body.add_child(office)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/backgrounds/manager_office.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	office.add_child(bg)
	var npc := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
	at.region = Rect2(2 * 24, 0, 24, 36)
	npc.texture = at
	npc.custom_minimum_size = Vector2(84, 110)
	npc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	office.add_child(npc)

	var lvl := int(CareerState.career["contract"].get("clubRequestsLevel", 1))
	var pts := int(CareerState.career["contract"].get("clubPoints", 33))
	_body.add_child(UITheme.make_section_header("LEVELMU DI KLUB • LEVEL %d (POIN %d)" % [lvl, pts]))

	var pb := ProgressBar.new()
	pb.max_value = 200
	pb.value = pts
	pb.custom_minimum_size = Vector2(0, 14)
	_body.add_child(pb)

	var reqs := [
		["LIHAT DAFTAR", 1, "Lihat daftar pemain incaran klub"],
		["USUL TRANSFER", 2, "Rekomendasikan pemain untuk dibeli"],
		["BELI & JUAL", 3, "Beri masukan posisi yang butuh penguatan"],
		["JANGAN JUAL", 3, "Minta klub mempertahankan rekan favorit"],
		["PERPANJANG DIA", 3, "Dorong kontrak baru untuk pemain kunci"],
		["NOMOR BARU", 3, "Ajukan ganti nomor punggungmu"],
		["NEGO ULANG", 3, "Minta kenaikan gaji lebih awal"],
		["KAPTEN", 4, "Ajukan diri menjadi Kapten tim"],
		["PELATIH BARU", 5, "Berikan masukan evaluasi pelatih"],
		["KONTRAKMU", 5, "Perpanjangan kontrak istimewa"],
		["BONUS LOYALITAS", 6, "Bonus loyalitas khusus legenda klub"],
		["FANS SETIA", 6, "Koreo & acara apresiasi suporter"],
		["LEBIH LUANG", 6, "Atur beban rotasi laga"],
	]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_body.add_child(grid)

	for r in reqs:
		var unlocked := lvl >= int(r[1])
		var rb := Button.new()
		rb.text = "%s\n[LV %d]" % [r[0], int(r[1])]
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.custom_minimum_size = Vector2(0, 56)
		rb.disabled = not unlocked
		UITheme.style_btn(rb, Color("#1B365C") if unlocked else Color("#0D1522"), UITheme.BORDER_CYAN if unlocked else UITheme.BORDER_STEEL, 10)
		rb.pressed.connect(func():
			AudioSynth.play_click()
			if r[0] == "NOMOR BARU":
				var cur_n := int(CareerState.career["playerProfile"]["appearance"].get("shirt_num", 9))
				CareerState.career["playerProfile"]["appearance"]["shirt_num"] = 10 if cur_n != 10 else 7
				CareerState.recalculate_ovr()
				CareerState.save_active_career()
				refresh()
			elif r[0] == "KAPTEN":
				CareerState.career["playerProfile"]["relations"]["pelatih"] = mini(100, int(CareerState.career["playerProfile"]["relations"]["pelatih"]) + 3)
				CareerState.save_active_career()
				refresh()
		)
		grid.add_child(rb)
