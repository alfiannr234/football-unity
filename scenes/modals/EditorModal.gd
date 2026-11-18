extends Control

signal closed

var _nat_idx: int = 1
var _div_num: int = 1
var _search_edit: LineEdit
var _list_vb: VBoxContainer
var _nat_lbl: Label

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
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	var ttl := Label.new()
	ttl.text = "EDITOR DATABASE"
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 22)
	vb.add_child(ttl)

	var sub := Label.new()
	sub.text = "Transfer, atribut, nama klub & OVR. Tersimpan otomatis."
	sub.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	vb.add_child(sub)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "CARI KLUB / PEMAIN..."
	_search_edit.text_changed.connect(func(_t: String): _render_list())
	vb.add_child(_search_edit)

	# Nation Selector
	var nhb := HBoxContainer.new()
	vb.add_child(nhb)
	var nl := Button.new()
	nl.text = "<"
	nl.custom_minimum_size = Vector2(44, 34)
	nl.pressed.connect(func(): AudioSynth.play_click(); _nat_idx = posmod(_nat_idx - 1, GameData.nations.size()); _render_list())
	_nat_lbl = Label.new()
	_nat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nr := Button.new()
	nr.text = ">"
	nr.custom_minimum_size = Vector2(44, 34)
	nr.pressed.connect(func(): AudioSynth.play_click(); _nat_idx = posmod(_nat_idx + 1, GameData.nations.size()); _render_list())
	nhb.add_child(nl)
	nhb.add_child(_nat_lbl)
	nhb.add_child(nr)

	# Division Selector
	var dhb := HBoxContainer.new()
	dhb.add_theme_constant_override("separation", 6)
	vb.add_child(dhb)
	for d in [1, 2, 3]:
		var db := Button.new()
		db.text = ["PERTAMA", "KEDUA", "KETIGA"][d - 1]
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		db.pressed.connect(func(): AudioSynth.play_click(); _div_num = d; _render_list())
		dhb.add_child(db)

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
	_nat_lbl.text = GameData.nations[_nat_idx]["name"].to_upper()
	var q := _search_edit.text.strip_edges().to_lower()
	var list: Array[Dictionary] = []
	if q.is_empty():
		list = GameData.get_clubs_in_division(_nat_idx, _div_num)
	else:
		for cl in GameData.clubs:
			if cl["name"].to_lower().contains(q):
				list.append(cl)
				if list.size() >= 40:
					break

	for club in list:
		var card := PanelContainer.new()
		_list_vb.add_child(card)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		card.add_child(hb)

		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(32, 32)
		cr.set_club(int(club["id"]))
		hb.add_child(cr)

		var nl := Label.new()
		nl.text = club["name"].to_upper()
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nl)

		hb.add_child(UITheme.make_ovr_badge(int(club["ovr"]), "silver", Vector2(34, 30)))

		var edit_b := Button.new()
		edit_b.text = "UBAH"
		edit_b.pressed.connect(func(): AudioSynth.play_click(); _open_club_editor(club))
		hb.add_child(edit_b)

func _open_club_editor(club: Dictionary) -> void:
	var pop := PanelContainer.new()
	pop.set_anchors_preset(Control.PRESET_CENTER)
	pop.offset_left = -210
	pop.offset_right = 210
	pop.offset_top = -150
	pop.offset_bottom = 150
	pop.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A172B"), UITheme.BORDER_CYAN, 2, 4))
	add_child(pop)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pop.add_child(vb)

	var hdr := Label.new()
	hdr.text = "EDIT KLUB"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hdr)

	var name_ed := LineEdit.new()
	name_ed.text = club["name"]
	vb.add_child(name_ed)

	var ovr_sl := HSlider.new()
	ovr_sl.min_value = 45
	ovr_sl.max_value = 95
	ovr_sl.value = int(club["ovr"])
	var ovr_l := Label.new()
	ovr_l.text = "OVR KLUB: %d" % int(ovr_sl.value)
	ovr_sl.value_changed.connect(func(v: float): ovr_l.text = "OVR KLUB: %d" % int(v))
	vb.add_child(ovr_l)
	vb.add_child(ovr_sl)

	var save_b := Button.new()
	save_b.text = "SIMPAN"
	UITheme.style_btn(save_b, Color("#1D5C9E"), UITheme.ACCENT_GOLD)
	save_b.pressed.connect(func():
		AudioSynth.play_click()
		club["name"] = name_ed.text.strip_edges()
		club["ovr"] = int(ovr_sl.value)
		pop.queue_free()
		_render_list()
	)
	vb.add_child(save_b)
	var cancel_b := Button.new()
	cancel_b.text = "TUTUP"
	cancel_b.pressed.connect(func(): pop.queue_free())
	vb.add_child(cancel_b)
