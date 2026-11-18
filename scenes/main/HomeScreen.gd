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
var _slot_container: Control
var _dots_hb: HBoxContainer
var _koleksi_btn: Button
var _lang_btn: Button

func _ready() -> void:
	theme = UITheme.build_theme()
	_build_ui()
	CareerState.career_updated.connect(refresh)
	refresh()

func _draw() -> void:
	# Midnight starfield backdrop matching Screenshot #36
	draw_rect(Rect2(Vector2.ZERO, size), Color("#040914"))
	for i in range(95):
		var sx := fmod(float(i * 173 + 41), maxf(1.0, size.x))
		var sy := fmod(float(i * 251 + 97), maxf(1.0, size.y))
		var a := 0.25 + float(i % 5) * 0.14
		draw_rect(Rect2(sx, sy, 2, 2), Color(0.85, 0.92, 1.0, a))

func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20
	vb.offset_right = -20
	vb.offset_top = 12
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	# Top Bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	vb.add_child(top)

	for btn_def in [
		["⚙", func(): open_settings.emit()],
		["☰", func(): open_koleksi.emit()],
		["✎", func(): open_editor.emit()],
	]:
		var b := Button.new()
		b.text = btn_def[0]
		b.custom_minimum_size = Vector2(38, 34)
		b.pressed.connect(func(): AudioSynth.play_click(); btn_def[1].call())
		top.add_child(b)

	var ball := TextureRect.new()
	ball.texture = load("res://assets/sprites/ui/logo_ball.png")
	ball.custom_minimum_size = Vector2(34, 34)
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(ball)

	var ttl := Label.new()
	ttl.text = "FOOTBALL UNITY"
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	top.add_child(ttl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)

	_lang_btn = Button.new()
	_lang_btn.custom_minimum_size = Vector2(130, 34)
	_lang_btn.pressed.connect(func():
		AudioSynth.play_click()
		var nl := "en" if SettingsManager.data.get("language", "id") == "id" else "id"
		SettingsManager.set_setting("language", nl)
		refresh()
	)
	top.add_child(_lang_btn)

	# Main Landscape 2-Column Body
	var body_hb := HBoxContainer.new()
	body_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hb.add_theme_constant_override("separation", 14)
	vb.add_child(body_hb)

	# Left Column: Career Slot Carousel + Dots
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 1.15
	left_vb.add_theme_constant_override("separation", 6)
	body_hb.add_child(left_vb)

	var slot_row := HBoxContainer.new()
	slot_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_row.add_theme_constant_override("separation", 6)
	left_vb.add_child(slot_row)

	var prev_s := Button.new()
	prev_s.text = "<"
	prev_s.custom_minimum_size = Vector2(36, 0)
	prev_s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_s.pressed.connect(func():
		AudioSynth.play_click()
		_selected_slot = posmod(_selected_slot - 2, CareerState.get_max_slots()) + 1
		refresh()
	)
	slot_row.add_child(prev_s)

	_slot_container = Control.new()
	_slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_row.add_child(_slot_container)

	var next_s := Button.new()
	next_s.text = ">"
	next_s.custom_minimum_size = Vector2(36, 0)
	next_s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	next_s.pressed.connect(func():
		AudioSynth.play_click()
		_selected_slot = (_selected_slot % CareerState.get_max_slots()) + 1
		refresh()
	)
	slot_row.add_child(next_s)

	_dots_hb = HBoxContainer.new()
	_dots_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_hb.add_theme_constant_override("separation", 8)
	left_vb.add_child(_dots_hb)

	# Right Column: Quick Buttons + TOKO Banner
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 0.90
	right_vb.add_theme_constant_override("separation", 10)
	body_hb.add_child(right_vb)

	var q_hb := HBoxContainer.new()
	q_hb.add_theme_constant_override("separation", 8)
	right_vb.add_child(q_hb)

	var lat_b := Button.new()
	lat_b.text = "● LATIHAN"
	lat_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lat_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(lat_b, Color("#0E223B"), UITheme.ACCENT_CYAN, 13)
	lat_b.pressed.connect(func(): AudioSynth.play_click(); _show_practice_picker())
	q_hb.add_child(lat_b)

	var tem_b := Button.new()
	tem_b.text = "★ TEMAN"
	tem_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tem_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(tem_b, Color("#1A2044"), Color("#818CF8"), 13)
	tem_b.pressed.connect(func(): AudioSynth.play_click(); open_friends.emit())
	q_hb.add_child(tem_b)

	_koleksi_btn = Button.new()
	_koleksi_btn.text = "✓ KOLEKSI"
	_koleksi_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_koleksi_btn.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(_koleksi_btn, Color("#24193E"), Color("#A855F7"), 13)
	_koleksi_btn.pressed.connect(func(): AudioSynth.play_click(); open_koleksi.emit())
	q_hb.add_child(_koleksi_btn)

	# TOKO Banner
	var shop_card := PanelContainer.new()
	shop_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0C1829"), UITheme.ACCENT_GOLD, 2, 8))
	right_vb.add_child(shop_card)
	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 8)
	shop_card.add_child(svb)

	var sh_hb := HBoxContainer.new()
	svb.add_child(sh_hb)
	var stl := Label.new()
	stl.text = "TOKO KOSMETIK & PERK"
	stl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stl.add_theme_font_override("font", UITheme.get_display_font())
	stl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	sh_hb.add_child(stl)

	var thumb_vb := VBoxContainer.new()
	thumb_vb.add_theme_constant_override("separation", 8)
	thumb_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svb.add_child(thumb_vb)
	for prev_item in [
		["AIM KETAPEL • 31 ITEM", Color("#1C5D32")],
		["CINCIN PEMAIN • 24 ITEM", Color("#1A4E3E")],
		["KARTU & LENCANA • PERK", Color("#322252")],
	]:
		var btn := Button.new()
		btn.text = prev_item[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(btn, prev_item[1], UITheme.ACCENT_GOLD, 13)
		btn.pressed.connect(func(): AudioSynth.play_click(); open_shop.emit())
		thumb_vb.add_child(btn)

func refresh() -> void:
	if not is_inside_tree():
		return
	_lang_btn.text = "[ID] INDONESIA" if SettingsManager.data.get("language", "id") == "id" else "[EN] ENGLISH"
	var u_cnt: int = CareerState.global_profile.get("unlocked_achievements", {}).size()
	_koleksi_btn.text = "✓ KOLEKSI (%d)" % u_cnt

	for c in _slot_container.get_children():
		c.queue_free()
	for c in _dots_hb.get_children():
		c.queue_free()

	var max_s := CareerState.get_max_slots()
	for s in range(1, max_s + 1):
		var dot := Label.new()
		dot.text = "●" if s == _selected_slot else "○"
		dot.add_theme_color_override("font_color", UITheme.ACCENT_CYAN if s == _selected_slot else UITheme.TEXT_MUTED)
		_dots_hb.add_child(dot)

	var meta := CareerState.get_slots_meta()
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slot_container.add_child(card)

	if meta.has(str(_selected_slot)):
		var d: Dictionary = meta[str(_selected_slot)]
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D2F64"), UITheme.BORDER_CYAN, 2, 6))
		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 8)
		card.add_child(cvb)

		var top_hb := HBoxContainer.new()
		top_hb.add_theme_constant_override("separation", 10)
		cvb.add_child(top_hb)

		var av := PixelAvatar.new()
		av.custom_minimum_size = Vector2(96, 118)
		var club := GameData.clubs[clampi(int(d.get("clubId", 0)), 0, GameData.clubs.size() - 1)]
		av.primary_color = club["primary"]
		av.secondary_color = club["secondary"]
		av.kit_pattern = club["pattern"]
		var app: Dictionary = d.get("appearance", {})
		av.skin_idx = int(app.get("skin", 1))
		av.hair_style = int(app.get("hair_style", 0))
		av.hair_idx = int(app.get("hair_color", 1))
		av.beard = bool(app.get("beard", false))
		av.tattoo_arm = int(app.get("tattoo_arm", 0))
		av.headwear = int(app.get("headwear", 0))
		av.eyewear = int(app.get("eyewear", 0))
		av.shirt_num = int(d.get("shirtNum", 9))
		av.show_number_badge = true
		top_hb.add_child(av)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_hb.add_child(info_vb)
		var badge_l := Label.new()
		badge_l.text = "M%d  •  %d THN  •  %s  [✓ AKTIF]" % [int(d.get("year", 1)), int(d.get("age", 16)), UITheme.format_short_cash(int(d.get("cash", 0)))]
		badge_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		info_vb.add_child(badge_l)

		var nm_hb := HBoxContainer.new()
		nm_hb.add_theme_constant_override("separation", 8)
		info_vb.add_child(nm_hb)
		nm_hb.add_child(UITheme.make_ovr_badge(int(d.get("ovr", 60)), "default", Vector2(40, 38)))
		var nml := Label.new()
		nml.text = "%s\n%s  •  %s #%d" % [d.get("name", "ALFIAN"), club["name"], d.get("pos", "ST"), int(d.get("shirtNum", 9))]
		nml.add_theme_font_override("font", UITheme.get_display_font())
		nm_hb.add_child(nml)

		var st_lbl := Label.new()
		st_lbl.text = "G:%d  •  A:%d  •  ★%.1f  •  MOTM:%d  •  TROFI:%d" % [
			int(d.get("goals", 0)), int(d.get("assists", 0)), float(d.get("bestRating", 0.0)),
			int(d.get("motm", 0)), int(d.get("trophies", 0))
		]
		st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cvb.add_child(st_lbl)

		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cvb.add_child(sp)

		var btn_hb := HBoxContainer.new()
		btn_hb.add_theme_constant_override("separation", 8)
		cvb.add_child(btn_hb)

		var cont_b := Button.new()
		cont_b.text = "LANJUTKAN"
		cont_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont_b.custom_minimum_size = Vector2(0, 48)
		UITheme.style_btn(cont_b, Color("#0A1628"), Color("#FFFFFF"), 18)
		cont_b.pressed.connect(func(): AudioSynth.play_click(); continue_career.emit(_selected_slot))
		btn_hb.add_child(cont_b)

		var home_b := Button.new()
		home_b.text = "RUMAH"
		home_b.custom_minimum_size = Vector2(88, 48)
		UITheme.style_btn(home_b, Color("#142840"), UITheme.ACCENT_CYAN, 14)
		home_b.pressed.connect(func(): AudioSynth.play_click(); open_home_apartment.emit(_selected_slot))
		btn_hb.add_child(home_b)
	else:
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091624"), UITheme.BORDER_STEEL, 2, 6))
		var evb := VBoxContainer.new()
		evb.alignment = BoxContainer.ALIGNMENT_CENTER
		evb.add_theme_constant_override("separation", 14)
		card.add_child(evb)

		var empty_l := Label.new()
		empty_l.text = "+\nSlot %d kosong." % _selected_slot
		empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		evb.add_child(empty_l)

		var new_b := Button.new()
		new_b.text = "+ KARIER BARU"
		new_b.custom_minimum_size = Vector2(240, 48)
		new_b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		UITheme.style_btn(new_b, Color("#174C6B"), UITheme.ACCENT_CYAN, 16)
		new_b.pressed.connect(func(): AudioSynth.play_click(); start_new_career_slot.emit(_selected_slot))
		evb.add_child(new_b)

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
