extends Control

signal closed
signal open_editor_requested
signal slot_loaded

var _tab: String = "SUARA"
var _in_match: bool = false
var _body: Control
var _reset_hold: float = 0.0
var _reset_holding: bool = false
var _reset_btn: Button

func configure(start_tab: String = "SUARA", in_match: bool = false) -> void:
	_tab = start_tab
	_in_match = in_match

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

	# Header
	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var ttl := Label.new()
	ttl.text = "SETELAN"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 22)
	hdr.add_child(ttl)

	var lang_btn := Button.new()
	lang_btn.text = "[ID] Indonesia" if SettingsManager.data.get("language", "id") == "id" else "[EN] English"
	UITheme.style_btn(lang_btn, Color("#3B285A"), Color("#825BC2"))
	lang_btn.pressed.connect(func():
		AudioSynth.play_click()
		var nl := "en" if SettingsManager.data.get("language", "id") == "id" else "id"
		SettingsManager.set_setting("language", nl)
		lang_btn.text = "[ID] Indonesia" if nl == "id" else "[EN] English"
		_render_tab()
	)
	hdr.add_child(lang_btn)

	# Tabs (when opened mid-match via JEDA > SETELAN, show SUARA, LAGA, LAYAR)
	var tab_hb := HBoxContainer.new()
	tab_hb.add_theme_constant_override("separation", 4)
	vb.add_child(tab_hb)
	var tabs := ["SUARA", "LAGA", "LAYAR"] if _in_match else ["SUARA", "LAGA", "LAYAR", "KARIER", "PONSEL"]
	if not ( _tab in tabs ):
		_tab = tabs[0]
	for t in tabs:
		var b := Button.new()
		b.text = t
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 44)
		UITheme.style_btn(b, Color("#1A4B78") if _tab == t else Color("#0C182A"), UITheme.BORDER_CYAN if _tab == t else UITheme.BORDER_STEEL, 12)
		b.pressed.connect(func():
			AudioSynth.play_click()
			_tab = t
			for child in tab_hb.get_children():
				var cb := child as Button
				UITheme.style_btn(cb, Color("#1A4B78") if cb.text == _tab else Color("#0C182A"), UITheme.BORDER_CYAN if cb.text == _tab else UITheme.BORDER_STEEL, 12)
			_render_tab()
		)
		tab_hb.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(_body as VBoxContainer).add_theme_constant_override("separation", 10)
	scroll.add_child(_body)

	var back_btn := Button.new()
	back_btn.text = "< BALIK"
	back_btn.custom_minimum_size = Vector2(110, 38)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UITheme.style_btn(back_btn, Color("#18332B"), Color("#2E6454"))
	back_btn.pressed.connect(func(): AudioSynth.play_click(); closed.emit(); queue_free())
	vb.add_child(back_btn)

	_render_tab()

func _process(delta: float) -> void:
	if _reset_holding and is_instance_valid(_reset_btn):
		_reset_hold += delta
		_reset_btn.text = "MENAHAN... %.0f%%" % minf(100.0, (_reset_hold / 1.5) * 100.0)
		if _reset_hold >= 1.5:
			_reset_holding = false
			_reset_hold = 0.0
			CareerState.reset_all_data()
			_reset_btn.text = "DATA DIRESET!"
			_render_tab()

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _render_tab() -> void:
	_clear_body()
	match _tab:
		"SUARA":
			_add_slider("MUSIK", "music_vol")
			_add_slider("EFEK", "sfx_vol")
			var tracks := ["PRAMUSIM", "STADION", "MALAM JUARA", "MATI"]
			var rad_btn := Button.new()
			rad_btn.text = "RADIO: %s (KETUK GANTI LAGU)" % str(SettingsManager.data.get("radio_track", "PRAMUSIM"))
			rad_btn.custom_minimum_size = Vector2(0, 44)
			rad_btn.pressed.connect(func():
				AudioSynth.play_click()
				var cur := str(SettingsManager.data.get("radio_track", "PRAMUSIM"))
				var next_i := (tracks.find(cur) + 1) % tracks.size()
				SettingsManager.set_setting("radio_track", tracks[next_i])
				rad_btn.text = "RADIO: %s (KETUK GANTI LAGU)" % tracks[next_i]
			)
			_body.add_child(rad_btn)

			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_body.add_child(row)
			row.add_child(_make_big_toggle("ACAK", "radio_shuffle", Color("#1C4860")))
			row.add_child(_make_big_toggle("GETARAN", "vibration", Color("#1C4860")))

		"LAGA":
			_body.add_child(UITheme.make_section_header("KESULITAN"))
			var diff_hb := HBoxContainer.new()
			diff_hb.add_theme_constant_override("separation", 4)
			_body.add_child(diff_hb)
			var desc_lbl := Label.new()
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.text = str(SettingsManager.get_difficulty_params()["desc_id"])
			for d in ["MUDAH", "NORMAL", "SULIT", "EKSTREM"]:
				var db := Button.new()
				db.text = d
				db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var act: bool = str(SettingsManager.data.get("difficulty", "NORMAL")) == str(d)
				UITheme.style_btn(db, Color("#B4962C") if act else Color("#182A3E"), UITheme.ACCENT_GOLD if act else UITheme.BORDER_STEEL, 12)
				db.pressed.connect(func():
					AudioSynth.play_click()
					SettingsManager.set_setting("difficulty", d)
					_render_tab()
				)
				diff_hb.add_child(db)
			_body.add_child(desc_lbl)

			_body.add_child(UITheme.make_section_header("PERSPEKTIF"))
			var persp_hb := HBoxContainer.new()
			persp_hb.add_theme_constant_override("separation", 6)
			_body.add_child(persp_hb)
			for p_name in ["TV", "LAPANGAN", "BELAKANG"]:
				var pb := Button.new()
				pb.text = p_name
				pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				pb.custom_minimum_size = Vector2(0, 68)
				var is_sel: bool = str(SettingsManager.data.get("perspective", "TV")) == str(p_name)
				UITheme.style_btn(pb, Color("#173F73") if is_sel else Color("#0B1320"), UITheme.BORDER_CYAN if is_sel else UITheme.BORDER_STEEL, 14)
				pb.pressed.connect(func():
					AudioSynth.play_click()
					SettingsManager.set_setting("perspective", p_name)
					_render_tab()
				)
				persp_hb.add_child(pb)

			_add_slider("JARAK KAMERA", "camera_dist")
			_add_slider("PUTAR SUDUT", "camera_angle")
			_add_slider("GETAR KAMERA", "camera_shake")
			_body.add_child(_make_big_toggle("GERAKAN", "motion_controls", Color("#173B66"), 88))

		"LAYAR":
			var row1 := HBoxContainer.new()
			row1.add_theme_constant_override("separation", 6)
			_body.add_child(row1)
			row1.add_child(_make_big_toggle("EFEK CRT\nGaris TV jadul", "crt_effect", Color("#4A346E"), 86))
			row1.add_child(_make_big_toggle("MODE RINGAN\nTanpa CRT", "light_mode", Color("#182C46"), 86))
			row1.add_child(_make_big_toggle("SANGAT RINGAN\nPerforma maks", "ultra_light_mode", Color("#182C46"), 86))
			_body.add_child(_make_big_toggle("HEMAT BATERAI\nMenu 30 fps saat tidak disentuh", "battery_saver", Color("#162336"), 68))

			var rot_btn := Button.new()
			rot_btn.text = "ROTASI LAYAR: %s" % str(SettingsManager.data.get("rotation_mode", "BUKA"))
			rot_btn.custom_minimum_size = Vector2(0, 56)
			UITheme.style_btn(rot_btn, Color("#5E2258"), Color("#B850AC"))
			rot_btn.pressed.connect(func():
				AudioSynth.play_click()
				var nr := "KUNCI LANDSCAPE" if SettingsManager.data.get("rotation_mode", "BUKA") == "BUKA" else "BUKA"
				SettingsManager.set_setting("rotation_mode", nr)
				rot_btn.text = "ROTASI LAYAR: %s" % nr
			)
			_body.add_child(rot_btn)

		"KARIER":
			var meta := CareerState.get_slots_meta()
			for s in range(1, CareerState.get_max_slots() + 1):
				var row := HBoxContainer.new()
				_body.add_child(row)
				var info := Label.new()
				info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if meta.has(str(s)):
					var d: Dictionary = meta[str(s)]
					var act := " • AKTIF" if CareerState.active_slot == s else ""
					info.text = "SLOT %d%s\n%s • %s (OVR %d)" % [s, act, d["name"], d["clubName"], int(d["ovr"])]
				else:
					info.text = "SLOT %d\nKOSONG" % s
				row.add_child(info)
				if meta.has(str(s)):
					var load_b := Button.new()
					load_b.text = "MUAT"
					load_b.pressed.connect(func():
						AudioSynth.play_click()
						CareerState.load_slot(s)
						slot_loaded.emit()
						queue_free()
					)
					row.add_child(load_b)
					var del_b := Button.new()
					del_b.text = "HAPUS"
					UITheme.style_btn(del_b, Color("#7A2828"), UITheme.ACCENT_RED)
					del_b.pressed.connect(func():
						AudioSynth.play_click()
						CareerState.delete_slot(s)
						_render_tab()
					)
					row.add_child(del_b)

			var act_row := HBoxContainer.new()
			act_row.add_theme_constant_override("separation", 8)
			_body.add_child(act_row)
			var ed_btn := Button.new()
			ed_btn.text = "✎ EDITOR DATABASE"
			ed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ed_btn.custom_minimum_size = Vector2(0, 76)
			UITheme.style_btn(ed_btn, Color("#24446E"), UITheme.BORDER_CYAN)
			ed_btn.pressed.connect(func(): AudioSynth.play_click(); open_editor_requested.emit(); queue_free())
			act_row.add_child(ed_btn)

			var res_btn := Button.new()
			res_btn.text = "● PULIHKAN BELIAN"
			res_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			res_btn.custom_minimum_size = Vector2(0, 76)
			UITheme.style_btn(res_btn, Color("#6C5818"), UITheme.ACCENT_GOLD)
			res_btn.pressed.connect(func(): AudioSynth.play_click(); CareerState.save_global_profile())
			act_row.add_child(res_btn)

		"PONSEL":
			var r_tog := HBoxContainer.new()
			r_tog.add_theme_constant_override("separation", 6)
			_body.add_child(r_tog)
			r_tog.add_child(_make_big_toggle("NOTIF", "notif_enabled", Color("#17364C"), 120))
			r_tog.add_child(_make_big_toggle("DATA", "data_analytics", Color("#17364C"), 120))
			r_tog.add_child(_make_big_toggle("LIHAT ANGKA", "show_numbers", Color("#17364C"), 120))

			_body.add_child(UITheme.make_section_header("MULAI DARI NOL"))
			var warn := Label.new()
			warn.text = "Menghapus semua karier DAN semua prestasi. Game kembali seperti baru dipasang. Tidak bisa diurungkan."
			warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_body.add_child(warn)

			_reset_btn = Button.new()
			_reset_btn.text = "TAHAN UNTUK RESET SEMUA"
			_reset_btn.custom_minimum_size = Vector2(0, 46)
			UITheme.style_btn(_reset_btn, Color("#8E2C2C"), UITheme.ACCENT_RED, 15)
			_reset_btn.button_down.connect(func(): _reset_holding = true; _reset_hold = 0.0)
			_reset_btn.button_up.connect(func(): _reset_holding = false; _reset_hold = 0.0; _reset_btn.text = "TAHAN UNTUK RESET SEMUA")
			_body.add_child(_reset_btn)

func _add_slider(label_txt: String, key: String) -> void:
	var hb := HBoxContainer.new()
	_body.add_child(hb)
	var lbl := Label.new()
	lbl.text = label_txt
	lbl.custom_minimum_size = Vector2(130, 0)
	hb.add_child(lbl)

	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(SettingsManager.data.get(key, 0.8))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sl)

	var pct := Label.new()
	pct.text = "%d%%" % int(round(sl.value * 100.0))
	pct.custom_minimum_size = Vector2(52, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(pct)

	sl.value_changed.connect(func(v: float):
		pct.text = "%d%%" % int(round(v * 100.0))
		SettingsManager.set_setting(key, v)
	)

func _make_big_toggle(txt: String, key: String, active_col: Color, h: int = 120) -> Button:
	var b := Button.new()
	var is_on := bool(SettingsManager.data.get(key, false))
	b.text = "%s\n[%s]" % [txt, "YA" if is_on else "TAK"]
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, h)
	UITheme.style_btn(b, active_col if is_on else Color("#0B1320"), UITheme.BORDER_CYAN if is_on else UITheme.BORDER_STEEL, 13)
	b.pressed.connect(func():
		AudioSynth.play_click()
		var nv := not bool(SettingsManager.data.get(key, false))
		SettingsManager.set_setting(key, nv)
		_render_tab()
	)
	return b
