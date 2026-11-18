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

static func make_flag_rect(nat_id: int, sz: Vector2 = Vector2(20, 14)) -> Control:
	var c := FlagControl.new()
	c.custom_minimum_size = sz
	c.nat_id = nat_id
	return c

class FlagControl extends Control:
	var nat_id: int = 0
	func _draw() -> void:
		var nat: Dictionary = GameData.nations[clampi(nat_id, 0, GameData.nations.size() - 1)]
		var cols: Array = nat.get("colors", [Color.BLUE, Color.YELLOW])
		var c1: Color = cols[0]
		var c2: Color = cols[1] if cols.size() > 1 else Color.WHITE
		draw_rect(Rect2(Vector2.ZERO, size), c1)
		if nat_id == 0:  # Sweden cross
			draw_rect(Rect2(size.x * 0.28, 0, size.x * 0.16, size.y), c2)
			draw_rect(Rect2(0, size.y * 0.4, size.x, size.y * 0.2), c2)
		else:
			draw_rect(Rect2(0, size.y * 0.5, size.x, size.y * 0.5), c2)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#1C2C42"), false, 1.0)
