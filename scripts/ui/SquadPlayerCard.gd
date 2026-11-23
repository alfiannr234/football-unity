extends Control

# Collectible football squad card (Gambar 3 & 4):
# - OVR-tiered border & metallic foil backdrop (<=69 Bronze, 70-75 Silver, 76-84 Gold, 85-90 Diamond, 91+ Purple)
# - Pointy-top Hexagon OVR badge at top-right
# - 3 position tags at top-left (1 active + 2 playable alternatives)
# - Crisp PixelAvatar bust + 2-person Friend badge + Role badges (Captain, Corner, Penalty + Pen Goals)
# - Dark name footer + mini form/energy pip strip

signal card_clicked(player_dict: Dictionary)

var _pd: Dictionary = {}
var _club: Dictionary = {}
var _ovr_focus: bool = false
var _is_friend: bool = false
var _is_captain: bool = false
var _is_corner: bool = false
var _is_penalty: bool = false
var _pen_goals: int = 0
var _positions: Array[String] = []
var _tier: Dictionary = {}
var _av: PixelAvatar

static func get_ovr_tier(ovr: int) -> Dictionary:
	if ovr >= 91:
		return {
			"name": "UNGU",
			"border": Color("#C084FC"),
			"bg_top": Color("#581C87"),
			"bg_mid": Color("#7E22CE"),
			"footer": Color("#3B0764"),
			"hex_fill": Color("#240640"),
			"hex_rim": Color("#E9D5FF"),
			"hex_txt": Color("#FAF5FF"),
		}
	elif ovr >= 85:
		return {
			"name": "DIAMOND",
			"border": Color("#67E8F9"),
			"bg_top": Color("#1E5F7A"),
			"bg_mid": Color("#38A3B8"),
			"footer": Color("#163D52"),
			"hex_fill": Color("#0B2A3B"),
			"hex_rim": Color("#CFFAFE"),
			"hex_txt": Color("#ECFEFF"),
		}
	elif ovr >= 76:
		return {
			"name": "GOLD",
			"border": Color("#EAB308"),
			"bg_top": Color("#9A6A12"),
			"bg_mid": Color("#D1A126"),
			"footer": Color("#543A0C"),
			"hex_fill": Color("#3A2707"),
			"hex_rim": Color("#FDE047"),
			"hex_txt": Color("#FEF08A"),
		}
	elif ovr >= 70:
		return {
			"name": "SILVER",
			"border": Color("#CBD5E1"),
			"bg_top": Color("#64748B"),
			"bg_mid": Color("#94A3B8"),
			"footer": Color("#334155"),
			"hex_fill": Color("#1E293B"),
			"hex_rim": Color("#F1F5F9"),
			"hex_txt": Color("#FFFFFF"),
		}
	return {
		"name": "COKLAT",
		"border": Color("#C6874E"),
		"bg_top": Color("#754722"),
		"bg_mid": Color("#A06837"),
		"footer": Color("#452914"),
		"hex_fill": Color("#2F1B0C"),
		"hex_rim": Color("#E8AD76"),
		"hex_txt": Color("#FDE6CD"),
	}

static func get_playable_positions(pd: Dictionary) -> Array[String]:
	var cur := str(pd.get("pos", "ST")).to_upper()
	var out: Array[String] = [cur]
	if bool(pd.get("is_user", false)) and CareerState.has_active_career:
		var learned: Dictionary = CareerState.career["playerProfile"].get("learnedPositions", {})
		for lk in learned.keys():
			var u := str(lk).to_upper()
			if not out.has(u) and out.size() < 3:
				out.append(u)
	var alt_map := {
		"ST": ["LW", "CF"],
		"CF": ["ST", "CAM"],
		"LW": ["LM", "ST"],
		"RW": ["RM", "ST"],
		"LM": ["LW", "CM"],
		"RM": ["RW", "CM"],
		"CAM": ["CM", "CF"],
		"CM": ["CDM", "CAM"],
		"CDM": ["CM", "CB"],
		"LB": ["LWB", "CB"],
		"RB": ["RWB", "CB"],
		"LWB": ["LB", "LM"],
		"RWB": ["RB", "RM"],
		"CB": ["CDM", "RB"],
		"GK": ["SW", "CB"],
	}
	var fallbacks: Array = alt_map.get(cur, ["CM", "ST"])
	for fb in fallbacks:
		var s := str(fb)
		if not out.has(s) and out.size() < 3:
			out.append(s)
	return out

func configure(pd: Dictionary, club: Dictionary, opts: Dictionary = {}) -> void:
	_pd = pd
	_club = club
	_ovr_focus = bool(opts.get("ovr_focus", false))
	_is_friend = bool(opts.get("is_friend", false))
	_is_captain = bool(opts.get("is_captain", false))
	_is_corner = bool(opts.get("is_corner", false))
	_is_penalty = bool(opts.get("is_penalty", false))
	_pen_goals = int(opts.get("pen_goals", 0))
	var ovr: int = int(pd.get("ovr", 60))
	if bool(pd.get("is_user", false)) and CareerState.has_active_career:
		ovr = int(CareerState.career["playerProfile"].get("ovr", ovr))
	_tier = get_ovr_tier(ovr)
	_positions = get_playable_positions(pd)
	_rebuild_children()
	queue_redraw()

func _rebuild_children() -> void:
	for c in get_children():
		c.queue_free()
	_av = PixelAvatar.new()
	_av.full_body = false
	_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_u := bool(_pd.get("is_user", false))
	var p_num := int(_pd.get("number", 9))
	if is_u and CareerState.has_active_career:
		_av.configure_from_career()
		_av.casual_style = 0
		_av.apply_kit(_club)
	else:
		_av.configure_from_seed(int(_pd.get("seed", 1)), _club, p_num)
		if str(_pd.get("pos", "")).to_upper() == "GK":
			_av.apply_kit({"primary": Color("#D93B88"), "secondary": Color("#111827"), "shorts": Color("#111827"), "pattern": "chest_band"})
			_av.glove_color = Color("#F8FAFC")
	add_child(_av)

	var overlay := CardOverlayLayer.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.card = self
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var hit := Button.new()
	hit.flat = true
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	hov.set_corner_radius_all(4)
	var foc := StyleBoxFlat.new()
	foc.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	foc.border_color = Color.WHITE
	foc.set_border_width_all(1)
	foc.set_corner_radius_all(4)
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", hov)
	hit.add_theme_stylebox_override("pressed", hov)
	hit.add_theme_stylebox_override("focus", foc)
	hit.pressed.connect(func(): AudioSynth.play_click(); card_clicked.emit(_pd))
	add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_avatar()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_avatar()
		queue_redraw()

func _layout_avatar() -> void:
	if _av == null or not is_instance_valid(_av):
		return
	var w := size.x if size.x > 10.0 else custom_minimum_size.x
	var h := size.y if size.y > 10.0 else custom_minimum_size.y
	var av_w := w * 0.68
	var av_h := h * 0.56
	_av.position = Vector2((w - av_w) * 0.5 + 3.0, h * 0.16)
	_av.size = Vector2(av_w, av_h)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 4.0 or h <= 4.0 or _tier.is_empty():
		return
	var is_u := bool(_pd.get("is_user", false))
	var foot_h := 19.0
	var body_h := h - foot_h

	# Layered metallic foil card background matching OVR tier
	draw_rect(Rect2(0, 0, w, h), _tier["footer"])
	draw_rect(Rect2(2, 2, w - 4, body_h - 2), _tier["bg_top"])
	draw_rect(Rect2(2, body_h * 0.36, w - 4, body_h * 0.44), _tier["bg_mid"])
	# Diagonal specular highlight ribbon
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, body_h * 0.22), Vector2(w - 2, 2),
		Vector2(w - 2, body_h * 0.26), Vector2(2, body_h * 0.48)
	]), Color(1, 1, 1, 0.10))
	# Subtle grass horizon strip behind shoulders (like Gambar 3)
	draw_rect(Rect2(2, body_h - 9.0, w - 4, 9.0), Color("#2B7A3E", 0.55))

	# Outer OVR-tier border (brighter highlight if User)
	draw_rect(Rect2(0.5, 0.5, w - 1.0, h - 1.0), _tier["border"], false, 2.2)
	if is_u:
		draw_rect(Rect2(2.5, 2.5, w - 5.0, h - 5.0), Color("#38BDF8", 0.70), false, 1.0)

func _draw_overlay(canvas: Control) -> void:
	var w := canvas.size.x
	var h := canvas.size.y
	if w <= 4.0 or h <= 4.0 or _tier.is_empty():
		return
	var ui_font := UITheme.get_ui_font()
	var disp_font := UITheme.get_display_font()
	var ovr: int = int(_pd.get("ovr", 60))
	if bool(_pd.get("is_user", false)) and CareerState.has_active_career:
		ovr = int(CareerState.career["playerProfile"].get("ovr", ovr))
	var foot_h := 19.0
	var body_h := h - foot_h

	# 1. TOP-LEFT 3 POSITION STACK (1 active + 2 playable alternatives, Gambar 3 & 4)
	if not _positions.is_empty():
		var p0 := _positions[0]
		var b0 := Rect2(3.0, 3.0, 26.0, 12.0)
		canvas.draw_rect(b0, Color("#0A1324", 0.90))
		canvas.draw_rect(b0, _tier["border"], false, 1.0)
		canvas.draw_string(disp_font, Vector2(b0.position.x + 1.0, b0.position.y + 10.0), p0, HORIZONTAL_ALIGNMENT_CENTER, b0.size.x - 2.0, 8, Color.WHITE)
		for pi in range(1, mini(3, _positions.size())):
			var py := 16.0 + float(pi - 1) * 10.0
			var bi := Rect2(3.0, py, 22.0, 9.0)
			canvas.draw_rect(bi, Color("#0C1628", 0.86))
			canvas.draw_rect(bi, Color("#475569"), false, 0.8)
			canvas.draw_string(ui_font, Vector2(bi.position.x, bi.position.y + 7.5), _positions[pi], HORIZONTAL_ALIGNMENT_CENTER, bi.size.x, 7, Color("#CBD5E1"))

	# 2. TOP-RIGHT HEXAGON OVR BADGE (Segi Enam Jelas, warna mengikuti tier OVR!)
	var hex_r := 12.5 if _ovr_focus else 11.0
	var hc := Vector2(w - hex_r - 2.5, hex_r + 2.5)
	var hpts := PackedVector2Array()
	for k in range(6):
		var ang := -PI * 0.5 + float(k) * PI / 3.0
		hpts.append(hc + Vector2(cos(ang), sin(ang)) * hex_r)
	canvas.draw_colored_polygon(hpts, _tier["hex_fill"])
	canvas.draw_polyline(hpts + PackedVector2Array([hpts[0]]), _tier["hex_rim"], 1.8)
	var ovr_fs := 10 if _ovr_focus else 9
	canvas.draw_string(disp_font, Vector2(hc.x - hex_r, hc.y + 3.5), str(ovr), HORIZONTAL_ALIGNMENT_CENTER, hex_r * 2.0, ovr_fs, _tier["hex_txt"])

	# 3. BADGES ABOVE FOOTER (Gambar 3: Friend Duo | Gambar 4: Left->Right Captain, Corner, Penalty + Pen Goals)
	var by := body_h - 8.5
	var bx := 10.0
	var badge_r := 7.0
	var has_role_badge := _is_captain or _is_corner or _is_penalty

	if _is_captain:
		# Captain Gold Badge [C]
		canvas.draw_circle(Vector2(bx, by), badge_r, Color("#0F172A"))
		canvas.draw_circle(Vector2(bx, by), badge_r - 1.0, Color("#D99B1E"))
		canvas.draw_arc(Vector2(bx, by), badge_r, 0.0, TAU, 16, Color("#FEF08A"), 1.3)
		canvas.draw_string(disp_font, Vector2(bx - 6.0, by + 3.5), "C", HORIZONTAL_ALIGNMENT_CENTER, 12.0, 8, Color("#1C1304"))
		bx += badge_r * 2.0 + 2.5

	if _is_corner:
		# Main Corner Taker Blue Badge (Corner Flag icon)
		canvas.draw_circle(Vector2(bx, by), badge_r, Color("#0F172A"))
		canvas.draw_circle(Vector2(bx, by), badge_r - 1.0, Color("#1D62B8"))
		canvas.draw_arc(Vector2(bx, by), badge_r, 0.0, TAU, 16, Color("#93C5FD"), 1.3)
		# Mini corner flag pole + pennant
		canvas.draw_line(Vector2(bx - 2.0, by - 4.0), Vector2(bx - 2.0, by + 4.0), Color.WHITE, 1.4)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(bx - 1.5, by - 4.0), Vector2(bx + 4.0, by - 2.0), Vector2(bx - 1.5, by + 0.2)
		]), Color("#E0F2FE"))
		bx += badge_r * 2.0 + 2.5

	if _is_penalty:
		# Main Penalty Taker Blue Badge (P + ball + penalty goal count)
		canvas.draw_circle(Vector2(bx, by), badge_r, Color("#0F172A"))
		canvas.draw_circle(Vector2(bx, by), badge_r - 1.0, Color("#1D62B8"))
		canvas.draw_arc(Vector2(bx, by), badge_r, 0.0, TAU, 16, Color("#93C5FD"), 1.3)
		canvas.draw_string(disp_font, Vector2(bx - 7.0, by + 3.0), "P", HORIZONTAL_ALIGNMENT_CENTER, 11.0, 8, Color.WHITE)
		canvas.draw_circle(Vector2(bx + 3.2, by + 2.2), 1.8, Color("#F8FAFC"))
		# Mini Penalty Goals counter pill at bottom-right of P badge
		var pg_txt := str(_pen_goals)
		var pill_w := 12.0 if _pen_goals < 10 else 16.0
		var pill_r := Rect2(bx + 2.0, by + 1.0, pill_w, 9.0)
		canvas.draw_rect(pill_r, Color("#0B1626"))
		canvas.draw_rect(pill_r, Color("#FDE047"), false, 1.0)
		canvas.draw_string(ui_font, Vector2(pill_r.position.x, pill_r.position.y + 7.5), pg_txt, HORIZONTAL_ALIGNMENT_CENTER, pill_w, 7, Color("#FEF08A"))
		bx += badge_r * 2.0 + 4.0

	if _is_friend and not has_role_badge:
		# Teammate Friendship Badge (2-person silhouettes inside gold-rimmed dark circle, Gambar 3)
		canvas.draw_circle(Vector2(bx, by), badge_r, Color("#11151C"))
		canvas.draw_arc(Vector2(bx, by), badge_r, 0.0, TAU, 16, Color("#EAB308"), 1.3)
		# Left friend silhouette (bright gold)
		canvas.draw_circle(Vector2(bx - 2.3, by - 2.0), 1.8, Color("#FACC15"))
		canvas.draw_rect(Rect2(bx - 4.4, by + 0.2, 4.2, 3.2), Color("#FACC15"))
		# Right friend silhouette (warm olive/amber)
		canvas.draw_circle(Vector2(bx + 2.3, by - 1.8), 1.8, Color("#A88B4A"))
		canvas.draw_rect(Rect2(bx + 0.2, by + 0.4, 4.2, 3.0), Color("#A88B4A"))
	elif _is_friend and has_role_badge and bx < w - 10.0:
		# Compact friend badge if room remains
		canvas.draw_circle(Vector2(w - 9.0, 28.0), 5.5, Color("#11151C"))
		canvas.draw_arc(Vector2(w - 9.0, 28.0), 5.5, 0.0, TAU, 12, Color("#EAB308"), 1.0)
		canvas.draw_circle(Vector2(w - 10.6, 26.8), 1.3, Color("#FACC15"))
		canvas.draw_circle(Vector2(w - 7.4, 26.8), 1.3, Color("#A88B4A"))

	# Shirt number bottom-right of portrait (when penalty badge doesn't occupy right edge)
	if not _is_penalty or bx < w - 18.0:
		var num_s := str(int(_pd.get("number", 9)))
		canvas.draw_string(disp_font, Vector2(w - 20.0, body_h - 2.0), num_s, HORIZONTAL_ALIGNMENT_RIGHT, 17.0, 9, Color(0, 0, 0, 0.75))
		canvas.draw_string(disp_font, Vector2(w - 21.0, body_h - 3.0), num_s, HORIZONTAL_ALIGNMENT_RIGHT, 17.0, 9, Color.WHITE)

	# 4. DARK FOOTER NAME + BOTTOM ENERGY/FORM MINI PIP STRIP
	canvas.draw_rect(Rect2(2.0, body_h, w - 4.0, foot_h - 2.0), _tier["footer"])
	var nm := str(_pd.get("name", "PEMAIN")).left(10)
	canvas.draw_string(disp_font, Vector2(2.0, body_h + 11.5), nm, HORIZONTAL_ALIGNMENT_CENTER, w - 4.0, 8, Color.WHITE)

	var pips := 5
	var eng_ratio := 0.85
	if bool(_pd.get("is_user", false)) and CareerState.has_active_career:
		eng_ratio = clampf(float(CareerState.career["playerProfile"].get("energy", 85)) / 100.0, 0.0, 1.0)
	else:
		eng_ratio = clampf(0.55 + float(abs(int(_pd.get("seed", 3))) % 45) / 100.0, 0.4, 1.0)
	var lit := int(round(eng_ratio * float(pips)))
	var pip_w := (w - 8.0) / float(pips)
	var pip_col := Color("#4ADE80") if eng_ratio >= 0.65 else (Color("#FACC15") if eng_ratio >= 0.35 else Color("#F87171"))
	for pi in range(pips):
		var px := 4.0 + float(pi) * pip_w
		canvas.draw_rect(Rect2(px, h - 4.5, pip_w - 1.5, 2.5), pip_col if pi < lit else Color("#0F172A"))

class CardOverlayLayer extends Control:
	var card: Control
	func _draw() -> void:
		if card != null and card.has_method("_draw_overlay"):
			card.call("_draw_overlay", self)
