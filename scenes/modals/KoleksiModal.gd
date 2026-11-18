extends Control

signal closed

var _filter: String = "SEMUA"
var _list_vb: VBoxContainer

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
	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var t := Label.new()
	t.text = "KOLEKSI • PRESTASI"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("font", UITheme.get_display_font())
	t.add_theme_font_size_override("font_size", 20)
	hdr.add_child(t)
	var cnt_l := Label.new()
	cnt_l.text = "%d / 386 • %d%%" % [total_u, int(round(float(total_u) / 386.0 * 100.0))]
	cnt_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hdr.add_child(cnt_l)

	# Rarity Filter Pills
	var f_hb := HBoxContainer.new()
	f_hb.add_theme_constant_override("separation", 4)
	vb.add_child(f_hb)
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
		f_hb.add_child(fb)

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
