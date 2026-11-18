extends Control

signal closed
signal start_duel_requested(friend_dict: Dictionary)

var _tab: String = "TEMAN"
var _body: Control

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

	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var ttl := Label.new()
	ttl.text = "TEMAN"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 22)
	hdr.add_child(ttl)

	var code_lbl := Label.new()
	code_lbl.text = "KODEMU: %s" % str(CareerState.global_profile.get("friend_code", "RSRK48"))
	code_lbl.add_theme_color_override("font_color", Color("#E86E9E"))
	hdr.add_child(code_lbl)

	var inv_hb := HBoxContainer.new()
	inv_hb.add_theme_constant_override("separation", 8)
	vb.add_child(inv_hb)
	var name_in := LineEdit.new()
	name_in.placeholder_text = "TULIS NAMAMU..."
	name_in.text = str(CareerState.global_profile.get("my_code_name", ""))
	name_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_hb.add_child(name_in)
	var inv_btn := Button.new()
	inv_btn.text = "UNDANG"
	UITheme.style_btn(inv_btn, Color("#562A42"), Color("#A85680"))
	inv_btn.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.global_profile["my_code_name"] = name_in.text
		CareerState.save_global_profile()
		inv_btn.text = "TERSALIN!"
	)
	inv_hb.add_child(inv_btn)

	var m_lbl := Label.new()
	m_lbl.text = "★ MENTOR %d/1" % int(CareerState.global_profile.get("mentor_used", 0))
	m_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	m_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(m_lbl)

	# 4 Subtabs
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 4)
	vb.add_child(thb)
	for t in ["TEMAN", "DUEL", "TABEL", "YANG BARU"]:
		var tb := Button.new()
		tb.text = t
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(tb, Color("#122B4A") if _tab == t else Color("#0B1626"), UITheme.BORDER_CYAN if _tab == t else UITheme.BORDER_STEEL, 12)
		tb.pressed.connect(func():
			AudioSynth.play_click()
			_tab = t
			_render_tab()
		)
		thb.add_child(tb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(_body as VBoxContainer).add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	var back := Button.new()
	back.text = "< BALIK"
	back.custom_minimum_size = Vector2(110, 38)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UITheme.style_btn(back, Color("#18332B"), Color("#2E6454"))
	back.pressed.connect(func(): AudioSynth.play_click(); closed.emit(); queue_free())
	vb.add_child(back)

	_render_tab()

func _render_tab() -> void:
	for c in _body.get_children():
		c.queue_free()

	match _tab:
		"TEMAN":
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 8)
			grid.add_theme_constant_override("v_separation", 8)
			_body.add_child(grid)
			for f in GameData.preset_friends:
				var card := PanelContainer.new()
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				card.add_theme_stylebox_override("panel", UITheme.make_box(UITheme.BG_CARD, UITheme.ACCENT_GOLD if f["turn"] else UITheme.BORDER_STEEL, 1, 4))
				grid.add_child(card)
				var cvb := VBoxContainer.new()
				card.add_child(cvb)
				var top := HBoxContainer.new()
				cvb.add_child(top)
				var pl := Label.new()
				pl.text = f["pos"]
				pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				top.add_child(pl)
				top.add_child(UITheme.make_ovr_badge(int(f["ovr"]), "silver", Vector2(30, 28)))

				var av := PixelAvatar.new()
				av.custom_minimum_size = Vector2(96, 110)
				av.configure_from_seed(f["ovr"] * 17, GameData.find_club_by_name(f["club"]))
				cvb.add_child(av)

				var nl := Label.new()
				nl.text = "%s\n%s\n%s" % [f["name"], f["club"], f["status"]]
				nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				nl.add_theme_font_size_override("font_size", 11)
				cvb.add_child(nl)

				var sl := Label.new()
				sl.text = "G:%d  A:%d  T:%d" % [int(f["goals"]), int(f["assists"]), int(f["trophies"])]
				sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
				sl.add_theme_font_size_override("font_size", 11)
				cvb.add_child(sl)

				var cmp := Button.new()
				cmp.text = "TATAP MUKA"
				cmp.pressed.connect(func(): AudioSynth.play_click(); _open_h2h(f))
				cvb.add_child(cmp)

		"DUEL":
			var duels: Dictionary = CareerState.global_profile.get("friends_duels", {})
			for f in GameData.preset_friends:
				var card := PanelContainer.new()
				_body.add_child(card)
				var hb := HBoxContainer.new()
				card.add_child(hb)
				var lvb := VBoxContainer.new()
				lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(lvb)
				var t1 := Label.new()
				t1.text = f["full_name"].to_upper()
				t1.add_theme_font_override("font", UITheme.get_display_font())
				lvb.add_child(t1)
				var t2 := Label.new()
				var d_rec: Dictionary = duels.get(f["code"], {})
				var score_str := "%d : %d" % [int(d_rec.get("us", 0)), int(d_rec.get("them", f["score_them"]))] if not d_rec.is_empty() else "-- : --"
				t2.text = "%s  •  Skor: %s" % [f["challenge"], score_str]
				t2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
				lvb.add_child(t2)

				var play_b := Button.new()
				play_b.text = "▶ MAIN"
				UITheme.style_btn(play_b, Color("#1A4F8E"), UITheme.ACCENT_CYAN)
				play_b.pressed.connect(func():
					AudioSynth.play_click()
					start_duel_requested.emit(f)
					queue_free()
				)
				hb.add_child(play_b)

		"TABEL":
			var entries: Array[Dictionary] = []
			for f in GameData.preset_friends:
				entries.append({"name": f["full_name"], "club": f["club"], "goals": f["goals"], "is_me": false})
			var my_g := int(CareerState.career["stats"]["goals"]) if CareerState.has_active_career else 0
			var my_c: String = str(CareerState.get_current_club()["name"]) if CareerState.has_active_career else "Danderyd Edsviken"
			entries.append({"name": "KAU", "club": my_c, "goals": my_g, "is_me": true})
			entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["goals"]) > int(b["goals"]))
			for i in range(entries.size()):
				var e := entries[i]
				var p := PanelContainer.new()
				p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12304C") if e["is_me"] else Color("#24182C"), UITheme.BORDER_CYAN if e["is_me"] else UITheme.BORDER_STEEL))
				_body.add_child(p)
				var hb := HBoxContainer.new()
				p.add_child(hb)
				var l := Label.new()
				l.text = "%d. %s (%s)" % [i + 1, e["name"], e["club"]]
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(l)
				var gl := Label.new()
				gl.text = "G:%d" % int(e["goals"])
				gl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
				hb.add_child(gl)

		"YANG BARU":
			var feed := [
				"LEO VIDAL bergabung dengan Barcelona Azulgrana • KINI",
				"ANA RUIZ juara liga • 1 HR LALU",
				"MAX TORRES cedera: 6 minggu • 2 HR LALU",
				"SOFI GIL naik ke rating 72 • 3 HR LALU",
				"ANA RUIZ mencapai 200 gol • 5 HR LALU",
				"MAX TORRES meraih gelar Pemain Terbaik • 9 HR LALU",
			]
			for item in feed:
				var p := PanelContainer.new()
				_body.add_child(p)
				var l := Label.new()
				l.text = item
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p.add_child(l)

func _open_h2h(f: Dictionary) -> void:
	var ov := PanelContainer.new()
	ov.set_anchors_preset(Control.PRESET_CENTER)
	ov.offset_left = -280
	ov.offset_right = 280
	ov.offset_top = -200
	ov.offset_bottom = 200
	ov.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081428"), UITheme.BORDER_CYAN, 2, 4))
	add_child(ov)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	ov.add_child(vb)

	var h := Label.new()
	h.text = "%s  VS  KAMU" % f["name"].to_upper()
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_override("font", UITheme.get_display_font())
	vb.add_child(h)

	var st: Dictionary = CareerState.career.get("stats", {}) if CareerState.has_active_career else {}
	var my_ovr := int(CareerState.career["playerProfile"]["ovr"]) if CareerState.has_active_career else 60
	var my_leg := int(CareerState.career["careerMeta"]["legacyPoints"]) if CareerState.has_active_career else 0
	var rows := [
		["GOL", f["goals"], int(st.get("goals", 0))],
		["AST", f["assists"], int(st.get("assists", 0))],
		["GELAR", f["trophies"], int(st.get("trophies", 0))],
		["RATING", f["ovr"], my_ovr],
		["WARISAN", f["legacy"], my_leg],
	]
	for r in rows:
		var hb := HBoxContainer.new()
		vb.add_child(hb)
		var l1 := Label.new()
		l1.text = str(r[1])
		l1.add_theme_color_override("font_color", Color("#E86E9E"))
		var lc := Label.new()
		lc.text = r[0]
		lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var l2 := Label.new()
		l2.text = str(r[2])
		l2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		hb.add_child(l1)
		hb.add_child(lc)
		hb.add_child(l2)

	var ch := Button.new()
	ch.text = "TANTANG DUEL"
	UITheme.style_btn(ch, Color("#6C2440"), Color("#E86E9E"))
	ch.pressed.connect(func():
		AudioSynth.play_click()
		start_duel_requested.emit(f)
		queue_free()
	)
	vb.add_child(ch)

	var cl := Button.new()
	cl.text = "TUTUP"
	cl.pressed.connect(func(): AudioSynth.play_click(); ov.queue_free())
	vb.add_child(cl)
