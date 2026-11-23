class_name UITheme
extends RefCounted

const BG_DARK := Color("#060D17")
const BG_PANEL := Color("#0B1626")
const BG_CARD := Color("#0F1E34")
const BG_CARD_HI := Color("#152A48")
const BORDER_STEEL := Color("#1F3858")
const BORDER_CYAN := Color("#3E9EFF")
const ACCENT_CYAN := Color("#46B2FF")
const ACCENT_GOLD := Color("#F2C438")
const ACCENT_GREEN := Color("#3AD656")
const ACCENT_RED := Color("#C93A3A")
const ACCENT_PURPLE := Color("#624A9E")
const ACCENT_AMBER := Color("#C9782C")
const TEXT_WHITE := Color("#EDF4FC")
const TEXT_MUTED := Color("#8AA3C0")

const TAB_COLORS := {
	"KINI": Color("#1E5CA8"),
	"PEMAINKU": Color("#2894AE"),
	"TIMKU": Color("#2E6699"),
	"DUNIA": Color("#467855"),
	"WARISAN": Color("#B86B28"),
}

static var _font_ui: Font
static var _font_display: Font
static var _theme_cache: Theme

static func get_ui_font() -> Font:
	if _font_ui == null:
		_font_ui = load("res://assets/fonts/pixel_ui.fnt")
	return _font_ui

static func get_stat_color(val: int) -> Color:
	var c_orange := Color("#F97316")
	var c_yellow := Color("#FACC15")
	var c_green := Color("#22E05A")
	var t: float = clampf((float(val) - 45.0) / 48.0, 0.0, 1.0)
	if t < 0.5:
		return c_orange.lerp(c_yellow, t * 2.0)
	return c_yellow.lerp(c_green, (t - 0.5) * 2.0)

static func get_display_font() -> Font:
	if _font_display == null:
		_font_display = load("res://assets/fonts/pixel_display.fnt")
	return _font_display

static func build_theme() -> Theme:
	if _theme_cache != null:
		return _theme_cache
	var t := Theme.new()
	var fui := get_ui_font()
	var fdisp := get_display_font()
	t.default_font = fui
	t.default_font_size = 14

	var btn_norm := make_box(Color("#122640"), BORDER_STEEL, 1, 2)
	btn_norm.content_margin_left = 8
	btn_norm.content_margin_right = 8
	btn_norm.content_margin_top = 6
	btn_norm.content_margin_bottom = 6
	var btn_hover := make_box(Color("#193458"), BORDER_CYAN, 1, 2)
	btn_hover.content_margin_left = 8
	btn_hover.content_margin_right = 8
	btn_hover.content_margin_top = 6
	btn_hover.content_margin_bottom = 6
	var btn_press := make_box(Color("#0D1C30"), ACCENT_GOLD, 1, 2)
	btn_press.content_margin_left = 8
	btn_press.content_margin_right = 8
	btn_press.content_margin_top = 6
	btn_press.content_margin_bottom = 6

	t.set_stylebox("normal", "Button", btn_norm)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_press)
	t.set_stylebox("focus", "Button", btn_hover)
	t.set_color("font_color", "Button", TEXT_WHITE)
	t.set_color("font_hover_color", "Button", TEXT_WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT_GOLD)
	t.set_color("font_disabled_color", "Button", Color("#4B607A"))
	t.set_font("font", "Button", fui)
	t.set_font_size("font_size", "Button", 14)

	t.set_color("font_color", "Label", TEXT_WHITE)
	t.set_font("font", "Label", fui)
	t.set_font_size("font_size", "Label", 14)

	var panel_sb := make_box(BG_CARD, BORDER_STEEL, 1, 2)
	t.set_stylebox("panel", "PanelContainer", panel_sb)
	t.set_stylebox("panel", "Panel", panel_sb)

	var le_sb := make_box(Color("#091424"), BORDER_STEEL, 1, 2)
	le_sb.content_margin_left = 8
	le_sb.content_margin_right = 8
	le_sb.content_margin_top = 6
	le_sb.content_margin_bottom = 6
	t.set_stylebox("normal", "LineEdit", le_sb)
	t.set_stylebox("focus", "LineEdit", make_box(Color("#0C1A30"), BORDER_CYAN, 1, 2))
	t.set_color("font_color", "LineEdit", TEXT_WHITE)
	t.set_font("font", "LineEdit", fui)

	t.set_font("font", "HeaderLabel", fdisp)

	_theme_cache = t
	return t

static func make_box(bg: Color, border: Color = BORDER_STEEL, bw: int = 1, radius: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(maxi(bw, 1) if border.a > 0.05 else 0)
	sb.set_corner_radius_all(radius)
	if bg.a > 0.6:
		sb.shadow_color = Color(0.0, 0.02, 0.06, 0.42)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 3)
	return sb

static func style_btn(btn: Button, bg: Color, border: Color = BORDER_STEEL, font_sz: int = 14) -> void:
	var pad_x := 4 if font_sz <= 11 else 8
	var n := make_box(bg, border.lightened(0.08), 2, 4)
	n.border_width_bottom = 3
	n.content_margin_left = pad_x
	n.content_margin_right = pad_x
	n.content_margin_top = 5
	n.content_margin_bottom = 5
	var h := make_box(bg.lightened(0.16), BORDER_CYAN, 2, 4)
	h.border_width_bottom = 3
	h.content_margin_left = pad_x
	h.content_margin_right = pad_x
	h.content_margin_top = 5
	h.content_margin_bottom = 5
	var pr := make_box(bg.darkened(0.15), ACCENT_GOLD, 2, 4)
	pr.content_margin_left = pad_x
	pr.content_margin_right = pad_x
	pr.content_margin_top = 6
	pr.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_font_size_override("font_size", font_sz)

static func make_section_header(title: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var tri := Label.new()
	tri.text = "▸"
	tri.add_theme_color_override("font_color", ACCENT_CYAN)
	tri.add_theme_font_size_override("font_size", 14)
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_override("font", get_display_font())
	lbl.add_theme_color_override("font_color", TEXT_WHITE)
	lbl.add_theme_font_size_override("font_size", 14)
	hb.add_child(tri)
	hb.add_child(lbl)
	return hb

static func format_cash(val: int) -> String:
	var neg := val < 0
	var s := str(abs(val))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "." + out
		out = s[i] + out
		cnt += 1
	return ("-$ " if neg else "$ ") + out

static func format_short_cash(val: int) -> String:
	if val >= 1000000:
		return "$%.1f M" % (float(val) / 1000000.0)
	elif val >= 1000:
		return "$%.0f K" % (float(val) / 1000.0)
	return "$%d" % val

static func make_ovr_badge(ovr: int, frame_id: String = "default", sz: Vector2 = Vector2(36, 36)) -> PanelContainer:
	var col := Color("#8B5A2B")
	if ovr >= 85 or frame_id == "diamond":
		col = Color("#38BDF8")
	elif ovr >= 75 or frame_id == "gold":
		col = Color("#EAB308")
	elif ovr >= 65 or frame_id == "silver":
		col = Color("#94A3B8")
	var pc := PanelContainer.new()
	pc.custom_minimum_size = sz
	pc.add_theme_stylebox_override("panel", make_box(Color("#0E1A2D"), col, 2, 4))
	var lbl := Label.new()
	lbl.text = str(ovr)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", get_display_font())
	lbl.add_theme_color_override("font_color", col.lightened(0.25))
	lbl.add_theme_font_size_override("font_size", 16)
	pc.add_child(lbl)
	return pc

static func parse_color(v, fallback: Color = Color.WHITE) -> Color:
	if v is Color:
		return v
	if v is String:
		var s: String = (v as String).strip_edges()
		if s.is_empty():
			return fallback
		if s.begins_with("#"):
			return Color.html(s)
		if s.begins_with("(") and s.ends_with(")"):
			var inner: String = s.substr(1, s.length() - 2)
			var parts: PackedStringArray = inner.split(",")
			if parts.size() >= 3:
				var r: float = float(parts[0].strip_edges())
				var g: float = float(parts[1].strip_edges())
				var b: float = float(parts[2].strip_edges())
				var a: float = float(parts[3].strip_edges()) if parts.size() >= 4 else 1.0
				return Color(r, g, b, a)
		if Color.html_is_valid(s):
			return Color.html(s)
		return fallback
	if v is Array and (v as Array).size() >= 3:
		var arr: Array = v
		return Color(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]) if arr.size() >= 4 else 1.0)
	return fallback

static func make_flag_rect(nat_id: int, sz: Vector2 = Vector2(20, 14)) -> Control:
	var c := FlagControl.new()
	c.custom_minimum_size = sz
	c.nat_id = nat_id
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func make_flag_by_code(code: String, fallback_colors: Array = [], sz: Vector2 = Vector2(20, 14)) -> Control:
	var c := FlagControl.new()
	c.custom_minimum_size = sz
	c.nat_id = -1
	c.flag_code_override = code.to_upper()
	c.fallback_colors = fallback_colors
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

class FlagControl extends Control:
	var nat_id: int = 0
	var flag_code_override: String = ""
	var fallback_colors: Array = []

	func _draw() -> void:
		var code: String = flag_code_override
		var cols: Array = fallback_colors
		if code == "":
			var idx := clampi(nat_id, 0, GameData.nations.size() - 1)
			var nat: Dictionary = GameData.nations[idx]
			code = str(nat.get("code", ""))
			cols = nat.get("colors", [Color.BLUE, Color.YELLOW])
		if cols.is_empty():
			cols = [Color("#2563EB"), Color("#F8FAFC")]
		var c1: Color = UITheme.parse_color(cols[0], Color("#2563EB"))
		var c2: Color = UITheme.parse_color(cols[1], Color.WHITE) if cols.size() > 1 else Color.WHITE
		var w: float = size.x
		var h: float = size.y
		match code:
			"VIE":
				draw_rect(Rect2(0, 0, w, h), Color("#DA251D"))
				var cx: float = w * 0.5
				var cy: float = h * 0.5
				var pts := PackedVector2Array()
				for i in range(10):
					var ang: float = -PI * 0.5 + float(i) * PI / 5.0
					var rad: float = minf(w, h) * (0.34 if i % 2 == 0 else 0.14)
					pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
				draw_colored_polygon(pts, Color("#FFDE00"))
			"OMA":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#DB161B"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#008000"))
				draw_rect(Rect2(0, 0, w * 0.28, h), Color("#DB161B"))
			"SYR":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#CE1126"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#111318"))
				draw_circle(Vector2(w * 0.38, h * 0.50), minf(w, h) * 0.08, Color("#007A3D"))
				draw_circle(Vector2(w * 0.62, h * 0.50), minf(w, h) * 0.08, Color("#007A3D"))
			"IRN":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#239F40"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#DA0000"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.12, Color("#DA0000"))
			"LBN":
				draw_rect(Rect2(0, 0, w, h * 0.25), Color("#ED1C24"))
				draw_rect(Rect2(0, h * 0.25, w, h * 0.50), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.75, w, h * 0.25), Color("#ED1C24"))
				var cedar := PackedVector2Array([Vector2(w * 0.50, h * 0.28), Vector2(w * 0.62, h * 0.70), Vector2(w * 0.38, h * 0.70)])
				draw_colored_polygon(cedar, Color("#00A651"))
			"UZB":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#0099B5"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#1EB53A"))
				draw_line(Vector2(0, h * 0.34), Vector2(w, h * 0.34), Color("#CE1126"), 1.0)
				draw_line(Vector2(0, h * 0.66), Vector2(w, h * 0.66), Color("#CE1126"), 1.0)
			"KOR":
				draw_rect(Rect2(0, 0, w, h), Color("#F8FAFC"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.26, Color("#CD2E3A"))
				draw_rect(Rect2(w * 0.34, h * 0.50, w * 0.32, h * 0.24), Color("#0047A0"))
			"AUS", "NZL":
				draw_rect(Rect2(0, 0, w, h), Color("#00247D"))
				draw_rect(Rect2(0, 0, w * 0.45, h * 0.50), Color("#012169"))
				draw_line(Vector2(w * 0.22, 0), Vector2(w * 0.22, h * 0.50), Color("#FFFFFF"), 2.0)
				draw_line(Vector2(0, h * 0.25), Vector2(w * 0.45, h * 0.25), Color("#FFFFFF"), 2.0)
				draw_line(Vector2(w * 0.22, 0), Vector2(w * 0.22, h * 0.50), Color("#C8102E"), 1.0)
				draw_line(Vector2(0, h * 0.25), Vector2(w * 0.45, h * 0.25), Color("#C8102E"), 1.0)
				var sc: Color = Color("#FFFFFF") if code == "AUS" else Color("#CC142B")
				draw_circle(Vector2(w * 0.72, h * 0.30), 1.4, sc)
				draw_circle(Vector2(w * 0.80, h * 0.52), 1.4, sc)
				draw_circle(Vector2(w * 0.68, h * 0.72), 1.4, sc)
			"KSA":
				draw_rect(Rect2(0, 0, w, h), Color("#006C35"))
				draw_rect(Rect2(w * 0.22, h * 0.40, w * 0.56, h * 0.14), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.28, h * 0.62, w * 0.44, h * 0.08), Color("#F8FAFC"))
			"QAT":
				draw_rect(Rect2(0, 0, w, h), Color("#8A1538"))
				draw_rect(Rect2(0, 0, w * 0.30, h), Color("#F8FAFC"))
			"THA":
				draw_rect(Rect2(0, 0, w, h), Color("#A51931"))
				draw_rect(Rect2(0, h * 0.18, w, h * 0.64), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.32, w, h * 0.36), Color("#2D2A4A"))
			"MAS":
				draw_rect(Rect2(0, 0, w, h), Color("#CC0001"))
				for s in range(1, 6, 2):
					draw_rect(Rect2(0, h * float(s) / 6.0, w, h / 6.0), Color("#F8FAFC"))
				draw_rect(Rect2(0, 0, w * 0.46, h * 0.54), Color("#010066"))
				draw_circle(Vector2(w * 0.22, h * 0.27), minf(w, h) * 0.16, Color("#FFCC00"))
			"USA":
				draw_rect(Rect2(0, 0, w, h), Color("#B22234"))
				for s in range(1, 7, 2):
					draw_rect(Rect2(0, h * float(s) / 7.0, w, h / 7.0), Color("#F8FAFC"))
				draw_rect(Rect2(0, 0, w * 0.44, h * 0.56), Color("#3C3B6E"))
			"MEX":
				draw_rect(Rect2(0, 0, w * 0.34, h), Color("#006847"))
				draw_rect(Rect2(w * 0.33, 0, w * 0.34, h), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.66, 0, w * 0.34, h), Color("#CE1126"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.12, Color("#6E4B26"))
			"CAN":
				draw_rect(Rect2(0, 0, w * 0.28, h), Color("#FF0000"))
				draw_rect(Rect2(w * 0.28, 0, w * 0.44, h), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.72, 0, w * 0.28, h), Color("#FF0000"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.18, Color("#FF0000"))
			"COL", "ECU":
				draw_rect(Rect2(0, 0, w, h * 0.50), Color("#FCD116"))
				draw_rect(Rect2(0, h * 0.50, w, h * 0.25), Color("#003893"))
				draw_rect(Rect2(0, h * 0.75, w, h * 0.25), Color("#CE1126"))
			"URU":
				draw_rect(Rect2(0, 0, w, h), Color("#F8FAFC"))
				for s in range(1, 6, 2):
					draw_rect(Rect2(0, h * float(s) / 6.0, w, h / 6.0), Color("#0038A8"))
				draw_rect(Rect2(0, 0, w * 0.36, h * 0.50), Color("#F8FAFC"))
				draw_circle(Vector2(w * 0.18, h * 0.25), minf(w, h) * 0.14, Color("#FCD116"))
			"MAR":
				draw_rect(Rect2(0, 0, w, h), Color("#C1272D"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.18, Color("#006233"))
			"NGA":
				draw_rect(Rect2(0, 0, w * 0.34, h), Color("#008751"))
				draw_rect(Rect2(w * 0.33, 0, w * 0.34, h), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.66, 0, w * 0.34, h), Color("#008751"))
			"SEN", "CMR":
				draw_rect(Rect2(0, 0, w * 0.34, h), Color("#00853F"))
				draw_rect(Rect2(w * 0.33, 0, w * 0.34, h), Color("#FDEF42") if code == "SEN" else Color("#CE1126"))
				draw_rect(Rect2(w * 0.66, 0, w * 0.34, h), Color("#E31B23") if code == "SEN" else Color("#FCD116"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.13, Color("#00853F") if code == "SEN" else Color("#FCD116"))
			"EGY":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#CE1126"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#111318"))
				draw_circle(Vector2(w * 0.50, h * 0.50), minf(w, h) * 0.11, Color("#C09300"))
			"SWE":
				draw_rect(Rect2(0, 0, w, h), Color("#005293"))
				draw_rect(Rect2(w * 0.28, 0, w * 0.16, h), Color("#FECB00"))
				draw_rect(Rect2(0, h * 0.40, w, h * 0.20), Color("#FECB00"))
			"ESP":
				draw_rect(Rect2(0, 0, w, h), Color("#C60B1E"))
				draw_rect(Rect2(0, h * 0.25, w, h * 0.50), Color("#FFC400"))
			"ENG":
				draw_rect(Rect2(0, 0, w, h), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.42, 0, w * 0.16, h), Color("#CE1124"))
				draw_rect(Rect2(0, h * 0.38, w, h * 0.24), Color("#CE1124"))
			"GER":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#111318"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#DD0000"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#FFCE00"))
			"ITA":
				draw_rect(Rect2(0, 0, w * 0.34, h), Color("#009246"))
				draw_rect(Rect2(w * 0.33, 0, w * 0.34, h), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.66, 0, w * 0.34, h), Color("#CE2B37"))
			"FRA":
				draw_rect(Rect2(0, 0, w * 0.34, h), Color("#0055A4"))
				draw_rect(Rect2(w * 0.33, 0, w * 0.34, h), Color("#F8FAFC"))
				draw_rect(Rect2(w * 0.66, 0, w * 0.34, h), Color("#EF4135"))
			"POR":
				draw_rect(Rect2(0, 0, w * 0.40, h), Color("#006600"))
				draw_rect(Rect2(w * 0.40, 0, w * 0.60, h), Color("#DA291C"))
				draw_circle(Vector2(w * 0.40, h * 0.50), minf(w, h) * 0.20, Color("#FFCC00"))
			"NED":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#AE1C28"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#21468B"))
			"SCO":
				draw_rect(Rect2(0, 0, w, h), Color("#005EB8"))
				draw_line(Vector2(0, 0), Vector2(w, h), Color("#FFFFFF"), maxf(1.8, h * 0.16))
				draw_line(Vector2(w, 0), Vector2(0, h), Color("#FFFFFF"), maxf(1.8, h * 0.16))
			"SUI":
				draw_rect(Rect2(0, 0, w, h), Color("#DA291C"))
				draw_rect(Rect2(w * 0.42, h * 0.20, w * 0.16, h * 0.60), Color("#FFFFFF"))
				draw_rect(Rect2(w * 0.28, h * 0.38, w * 0.44, h * 0.24), Color("#FFFFFF"))
			"SRB":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#C6363C"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#0C4076"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#F8FAFC"))
			"BEL":
				draw_rect(Rect2(0, 0, w * 0.34, h), Color("#111318"))
				draw_rect(Rect2(w * 0.33, 0, w * 0.34, h), Color("#FDDA24"))
				draw_rect(Rect2(w * 0.66, 0, w * 0.34, h), Color("#EF3340"))
			"BRA":
				draw_rect(Rect2(0, 0, w, h), Color("#009C3B"))
				var pts := PackedVector2Array([Vector2(w * 0.5, h * 0.12), Vector2(w * 0.88, h * 0.5), Vector2(w * 0.5, h * 0.88), Vector2(w * 0.12, h * 0.5)])
				draw_colored_polygon(pts, Color("#FFDF00"))
				draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.18, Color("#002776"))
			"ARG":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#74ACDF"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#74ACDF"))
				draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.12, Color("#F6B40E"))
			"JPN":
				draw_rect(Rect2(0, 0, w, h), Color("#F8FAFC"))
				draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.28, Color("#BC002D"))
			"IDN":
				draw_rect(Rect2(0, 0, w, h * 0.50), Color("#CE1126"))
				draw_rect(Rect2(0, h * 0.50, w, h * 0.50), Color("#F8FAFC"))
			"DEN":
				draw_rect(Rect2(0, 0, w, h), Color("#C60C30"))
				draw_rect(Rect2(w * 0.28, 0, w * 0.14, h), Color("#FFFFFF"))
				draw_rect(Rect2(0, h * 0.42, w, h * 0.16), Color("#FFFFFF"))
			"NOR":
				draw_rect(Rect2(0, 0, w, h), Color("#BA0C2F"))
				draw_rect(Rect2(w * 0.25, 0, w * 0.20, h), Color("#FFFFFF"))
				draw_rect(Rect2(0, h * 0.36, w, h * 0.28), Color("#FFFFFF"))
				draw_rect(Rect2(w * 0.29, 0, w * 0.12, h), Color("#00205B"))
				draw_rect(Rect2(0, h * 0.42, w, h * 0.16), Color("#00205B"))
			"AUT":
				draw_rect(Rect2(0, 0, w, h * 0.34), Color("#ED2939"))
				draw_rect(Rect2(0, h * 0.33, w, h * 0.34), Color("#F8FAFC"))
				draw_rect(Rect2(0, h * 0.66, w, h * 0.34), Color("#ED2939"))
			"GRE":
				draw_rect(Rect2(0, 0, w, h), Color("#0D5EAF"))
				for s in range(1, 5, 2):
					draw_rect(Rect2(0, h * float(s) / 5.0, w, h / 5.0), Color("#FFFFFF"))
				draw_rect(Rect2(0, 0, w * 0.42, h * 0.56), Color("#0D5EAF"))
				draw_rect(Rect2(w * 0.17, 0, w * 0.08, h * 0.56), Color("#FFFFFF"))
				draw_rect(Rect2(0, h * 0.22, w * 0.42, h * 0.12), Color("#FFFFFF"))
			_:
				draw_rect(Rect2(0, 0, w, h), c1)
				draw_rect(Rect2(0, h * 0.50, w, h * 0.50), c2)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#1C2C42"), false, 1.0)
