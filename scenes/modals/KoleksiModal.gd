extends Control

signal closed

var _filter: String = "SEMUA"
var _tab: String = "PRESTASI"  # PRESTASI | ALBUM
var _list_vb: VBoxContainer
var _filter_bar: HBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var bg := ColorRect.new()
	bg.color = Color("#060D17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	var unlocked: Dictionary = CareerState.global_profile.get("unlocked_achievements", {})
	var counts := {"UMUM": [0, 32], "LANGKA": [0, 106], "EPIK": [0, 162], "LEGENDARIS": [0, 86]}
	for a in GameData.achievements:
		if unlocked.has(a["id"]):
			counts[a["rarity"]][0] += 1

	var total_u := unlocked.size()
	var owned_cards: Array = CareerState.career.get("careerMeta", {}).get("albumCards", []) if CareerState.has_active_career else []
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)
	var t := Label.new()
	t.text = "KOLEKSI  •  PRESTASI & ALBUM"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("font", UITheme.get_display_font())
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)

	var tab_p := Button.new()
	tab_p.text = "PRESTASI (%d/386)" % total_u
	UITheme.style_btn(tab_p, Color("#173B66"), UITheme.ACCENT_GOLD, 11)
	var tab_a := Button.new()
	tab_a.text = "ALBUM (%d/%d)" % [owned_cards.size(), GameData.album_cards_catalog.size()]
	UITheme.style_btn(tab_a, Color("#0B1626"), UITheme.BORDER_STEEL, 11)
	tab_p.pressed.connect(func():
		AudioSynth.play_click()
		_tab = "PRESTASI"
		UITheme.style_btn(tab_p, Color("#173B66"), UITheme.ACCENT_GOLD, 11)
		UITheme.style_btn(tab_a, Color("#0B1626"), UITheme.BORDER_STEEL, 11)
		if _filter_bar != null:
			_filter_bar.visible = true
		_render_list()
	)
	tab_a.pressed.connect(func():
		AudioSynth.play_click()
		_tab = "ALBUM"
		UITheme.style_btn(tab_a, Color("#4E320E"), UITheme.ACCENT_GOLD, 11)
		UITheme.style_btn(tab_p, Color("#0B1626"), UITheme.BORDER_STEEL, 11)
		if _filter_bar != null:
			_filter_bar.visible = false
		_render_list()
	)
	hdr.add_child(tab_p)
	hdr.add_child(tab_a)

	# Rarity Filter Pills
	_filter_bar = HBoxContainer.new()
	_filter_bar.add_theme_constant_override("separation", 4)
	vb.add_child(_filter_bar)
	for rf in ["UMUM", "LANGKA", "EPIK", "LEGENDARIS", "SEMUA"]:
		var fb := Button.new()
		if rf == "SEMUA":
			fb.text = "SEMUA"
		else:
			fb.text = "%s\n%d/%d" % [rf, counts[rf][0], counts[rf][1]]
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(fb, Color("#173B66") if _filter == rf else Color("#0B1626"), UITheme.BORDER_CYAN if _filter == rf else UITheme.BORDER_STEEL, 11)
		fb.pressed.connect(func():
			AudioSynth.play_click()
			_filter = rf
			_render_list()
		)
		_filter_bar.add_child(fb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_list_vb = VBoxContainer.new()
	_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vb.add_theme_constant_override("separation", 6)
	scroll.add_child(_list_vb)

	var back := Button.new()
	back.text = "< BALIK"
	back.custom_minimum_size = Vector2(110, 38)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UITheme.style_btn(back, Color("#18332B"), Color("#2E6454"))
	back.pressed.connect(func(): AudioSynth.play_click(); closed.emit(); queue_free())
	vb.add_child(back)

	_render_list()

func _render_list() -> void:
	for c in _list_vb.get_children():
		c.queue_free()
	if _tab == "ALBUM":
		var owned_cards: Array = CareerState.career.get("careerMeta", {}).get("albumCards", []) if CareerState.has_active_career else []
		var tier_cols := {"PERUNGGU": Color("#D97706"), "PERAK": Color("#CBD5E1"), "EMAS": UITheme.ACCENT_GOLD, "LEGENDARIS": Color("#C084FC")}
		var grid := GridContainer.new()
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_list_vb.add_child(grid)
		for cd in GameData.album_cards_catalog:
			var has_it: bool = owned_cards.has(str(cd["id"]))
			var t_col: Color = tier_cols.get(str(cd["tier"]), UITheme.BORDER_STEEL)
			var cp := PanelContainer.new()
			cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cp.custom_minimum_size = Vector2(0, 96)
			cp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#13233A") if has_it else Color("#0A101A"), t_col if has_it else UITheme.BORDER_STEEL, 2 if has_it else 1, 6))
			grid.add_child(cp)
			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 3)
			cp.add_child(cv)
			var l_num := Label.new()
			l_num.text = "#%d  •  %s" % [int(cd["num"]), str(cd["tier"])]
			l_num.add_theme_color_override("font_color", t_col if has_it else UITheme.TEXT_MUTED)
			l_num.add_theme_font_size_override("font_size", 10)
			cv.add_child(l_num)
			var l_tit := Label.new()
			l_tit.text = str(cd["title"]) if has_it else "???"
			l_tit.add_theme_font_override("font", UITheme.get_display_font())
			l_tit.add_theme_color_override("font_color", Color.WHITE if has_it else Color("#475569"))
			l_tit.add_theme_font_size_override("font_size", 13)
			cv.add_child(l_tit)
			var l_q := Label.new()
			l_q.text = str(cd["quote"]) if has_it else "Mainkan event karier untuk membuka kartu ini."
			l_q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l_q.add_theme_color_override("font_color", Color("#CBD5E1") if has_it else Color("#475569"))
			l_q.add_theme_font_size_override("font_size", 10)
			cv.add_child(l_q)
		return
	var unlocked: Dictionary = CareerState.global_profile.get("unlocked_achievements", {})
	var rarity_cols := {
		"UMUM": UITheme.TEXT_MUTED,
		"LANGKA": UITheme.ACCENT_CYAN,
		"EPIK": Color("#C084FC"),
		"LEGENDARIS": UITheme.ACCENT_GOLD,
	}
	var shown := 0
	for a in GameData.achievements:
		if _filter != "SEMUA" and a["rarity"] != _filter:
			continue
		shown += 1
		if shown > 80 and _filter == "SEMUA":
			var more := Label.new()
			more.text = "... Pilih filter UMUM / LANGKA / EPIK / LEGENDARIS untuk melihat semua 386 prestasi."
			more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_list_vb.add_child(more)
			break
		var is_done := unlocked.has(a["id"])
		var card := PanelContainer.new()
		var rcol: Color = rarity_cols.get(a["rarity"], UITheme.BORDER_STEEL)
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12263C") if is_done else UITheme.BG_CARD, rcol if is_done else UITheme.BORDER_STEEL, 1, 3))
		_list_vb.add_child(card)
		var hb := HBoxContainer.new()
		card.add_child(hb)

		var lvb := VBoxContainer.new()
		lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lvb)
		var tl := Label.new()
		tl.text = str(a["title"])
		tl.add_theme_font_override("font", UITheme.get_display_font())
		tl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_done else UITheme.TEXT_WHITE)
		lvb.add_child(tl)
		var dl := Label.new()
		dl.text = str(a["desc"])
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		dl.add_theme_font_size_override("font_size", 12)
		lvb.add_child(dl)

		var cur_p := CareerState.get_achievement_progress(a)
		var tgt := int(a["target"])
		if not is_done and cur_p > 0 and tgt > 1:
			var pb := ProgressBar.new()
			pb.max_value = tgt
			pb.value = mini(cur_p, tgt)
			pb.custom_minimum_size = Vector2(0, 10)
			pb.show_percentage = false
			lvb.add_child(pb)

		var badge := Label.new()
		badge.text = "%s%s" % [a["rarity"], " ✓" if is_done else ""]
		badge.add_theme_color_override("font_color", rcol)
		badge.add_theme_font_size_override("font_size", 11)
		hb.add_child(badge)
