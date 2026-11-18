extends Control

signal closed

var _top_tab: String = "PERK"  # PERK or GAYA
var _gaya_cat: String = "CINCIN"
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
	var back := Button.new()
	back.text = "< BALIK"
	back.pressed.connect(func(): AudioSynth.play_click(); closed.emit(); queue_free())
	hdr.add_child(back)
	var ttl := Label.new()
	ttl.text = "TOKO GAYA & PERK"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hdr.add_child(ttl)
	var cash_l := Label.new()
	cash_l.text = UITheme.format_cash(int(CareerState.career["playerProfile"]["cash"])) if CareerState.has_active_career else "$ 0"
	cash_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hdr.add_child(cash_l)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 8)
	vb.add_child(top_hb)
	for t in ["PERK", "GAYA"]:
		var b := Button.new()
		b.text = t
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		UITheme.style_btn(b, Color("#7A6218") if _top_tab == t else Color("#0B1626"), UITheme.ACCENT_GOLD if _top_tab == t else UITheme.BORDER_STEEL)
		b.pressed.connect(func(): AudioSynth.play_click(); _top_tab = t; _render_body())
		top_hb.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(_body as VBoxContainer).add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	_render_body()

func _render_body() -> void:
	for c in _body.get_children():
		c.queue_free()

	if _top_tab == "PERK":
		var owned_perks: Array = CareerState.global_profile.get("owned_perks", [])
		for p in GameData.cosmetics_catalog.get("PERK", []):
			var has_p := owned_perks.has(p["id"])
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A2230"), UITheme.ACCENT_GOLD if has_p else UITheme.BORDER_STEEL, 2, 4))
			_body.add_child(card)
			var hb := HBoxContainer.new()
			card.add_child(hb)
			var lvb := VBoxContainer.new()
			lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(lvb)
			var tl := Label.new()
			tl.text = p["name"]
			tl.add_theme_font_override("font", UITheme.get_display_font())
			tl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
			lvb.add_child(tl)
			var dl := Label.new()
			dl.text = p["desc"]
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lvb.add_child(dl)

			var btn := Button.new()
			btn.text = "AKTIF ✓" if has_p else UITheme.format_cash(int(p["price"]))
			btn.disabled = has_p
			UITheme.style_btn(btn, Color("#245E38") if has_p else Color("#9E7B1C"), UITheme.ACCENT_GOLD)
			btn.pressed.connect(func():
				AudioSynth.play_click()
				if CareerState.unlock_perk(p["id"], int(p["price"])):
					_render_body()
			)
			hb.add_child(btn)
	else:
		var cat_hb := HBoxContainer.new()
		cat_hb.add_theme_constant_override("separation", 4)
		_body.add_child(cat_hb)
		for cat in ["CINCIN", "AIM", "JEJAK", "LENCANA", "KARTU"]:
			var owned: Array = CareerState.global_profile["owned_cosmetics"].get(cat, ["default"])
			var tot: int = GameData.cosmetics_catalog.get(cat, []).size()
			var cb := Button.new()
			cb.text = "%s\n%d/%d" % [cat, owned.size(), tot]
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UITheme.style_btn(cb, Color("#173B66") if _gaya_cat == cat else Color("#0B1626"), UITheme.ACCENT_GOLD if _gaya_cat == cat else UITheme.BORDER_STEEL, 10)
			cb.pressed.connect(func(): AudioSynth.play_click(); _gaya_cat = cat; _render_body())
			cat_hb.add_child(cb)

		var owned_list: Array = CareerState.global_profile["owned_cosmetics"].get(_gaya_cat, ["default"])
		var slot_map := {"CINCIN": "ringId", "AIM": "aimId", "JEJAK": "trailId", "LENCANA": "badgeId", "KARTU": "cardFrameId"}
		var equipped := str(CareerState.career["playerProfile"]["cosmetics"].get(slot_map[_gaya_cat], "default")) if CareerState.has_active_career else "default"

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_body.add_child(grid)
		for item in GameData.cosmetics_catalog.get(_gaya_cat, []):
			var iid := str(item["id"])
			var is_own := owned_list.has(iid)
			var is_eq := (equipped == iid)
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12263C"), UITheme.ACCENT_GOLD if is_eq else UITheme.BORDER_STEEL, 2 if is_eq else 1, 3))
			grid.add_child(card)
			var ivb := VBoxContainer.new()
			card.add_child(ivb)

			var swatch := ColorRect.new()
			swatch.color = item.get("color", Color.WHITE)
			swatch.custom_minimum_size = Vector2(0, 14)
			ivb.add_child(swatch)

			var nm := Label.new()
			nm.text = item["name"]
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ivb.add_child(nm)

			var btn := Button.new()
			btn.text = "DIPAKAI" if is_eq else ("PAKAI" if is_own else UITheme.format_cash(int(item["price"])))
			btn.pressed.connect(func():
				AudioSynth.play_click()
				if CareerState.buy_or_equip_cosmetic(_gaya_cat, iid, int(item["price"])):
					_render_body()
			)
			ivb.add_child(btn)
