extends CanvasLayer

signal play_requested

const DAY_HDRS: Array[String] = ["SEN", "SEL", "RAB", "KAM", "JUM", "SAB", "MIN"]

const COMP_META := {
	"LIGA": {
		"label": "LIGA",
		"accent": Color("#F59E0B"),
		"border": Color("#B47616"),
		"bg": Color("#1D170C"),
		"bar": Color("#E09B1B"),
	},
	"KONTINENTAL": {
		"label": "KONTINENTAL",
		"accent": Color("#F472B6"),
		"border": Color("#C4638E"),
		"bg": Color("#211426"),
		"bar": Color("#E272A2"),
	},
	"DOMESTIK": {
		"label": "DOMESTIK",
		"accent": Color("#22D3EE"),
		"border": Color("#1CA3BA"),
		"bg": Color("#0D222D"),
		"bar": Color("#22D3EE"),
	},
	"TIMNAS": {
		"label": "TIMNAS",
		"accent": Color("#EAB308"),
		"border": Color("#A99B1D"),
		"bg": Color("#21210E"),
		"bar": Color("#D4C826"),
	},
}

var _root: Control
var _stats_card_vb: VBoxContainer
var _next_card_vb: VBoxContainer
var _recent_card_vb: VBoxContainer
var _filter_hb: HBoxContainer
var _month_jump_hb: HBoxContainer
var _cal_scroll: ScrollContainer
var _cal_body_vb: VBoxContainer

var _sel_week: int = 1
var _cal_month: int = 0
var _comp_filter: String = "ALL"
var _month_nodes: Dictionary = {}

func _init() -> void:
	layer = 20

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			AudioSynth.play_click()
			get_viewport().set_input_as_handled()
			queue_free()

func _ready() -> void:
	if CareerState.has_active_career:
		var m: Dictionary = CareerState.career.get("careerMeta", {})
		_sel_week = clampi(int(m.get("week", 1)), 1, int(m.get("maxWeeks", 45)))
		_cal_month = CareerState.get_season_month_index(_sel_week)
	_build()
	_refresh(true)

func _build() -> void:
	_root = Control.new()
	_root.theme = UITheme.build_theme()
	_root.clip_contents = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.09, 0.94)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color("#071122")
	fsb.border_color = Color("#243C60")
	fsb.set_border_width_all(2)
	fsb.set_corner_radius_all(8)
	fsb.content_margin_left = 12
	fsb.content_margin_right = 12
	fsb.content_margin_top = 10
	fsb.content_margin_bottom = 10
	frame.add_theme_stylebox_override("panel", fsb)
	margin.add_child(frame)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	frame.add_child(vb)

	# Header Row
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	var back_btn := Button.new()
	back_btn.text = "<- BALIK"
	back_btn.custom_minimum_size = Vector2(98, 32)
	UITheme.style_btn(back_btn, Color("#112138"), Color("#475E7D"), 11)
	back_btn.pressed.connect(func():
		AudioSynth.play_click()
		queue_free()
	)
	hdr.add_child(back_btn)

	var title := Label.new()
	title.text = "JADWAL & KALENDER MUSIM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	hdr.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "TUTUP"
	close_btn.custom_minimum_size = Vector2(98, 32)
	UITheme.style_btn(close_btn, Color("#2A1520"), Color("#FB7185"), 11)
	close_btn.pressed.connect(func():
		AudioSynth.play_click()
		queue_free()
	)
	hdr.add_child(close_btn)

	# Main 2-Column Body: Left (Gambar 3 Stats + Laga Berikut + Hasil) | Right (Gambar 4 Calendar)
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	vb.add_child(body)

	# LEFT COLUMN
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(338, 0)
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 8)
	body.add_child(left_vb)

	var stats_panel := PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_panel.add_theme_stylebox_override("panel", _make_dark_card_sb())
	left_vb.add_child(stats_panel)
	_stats_card_vb = VBoxContainer.new()
	_stats_card_vb.add_theme_constant_override("separation", 8)
	stats_panel.add_child(_stats_card_vb)

	var next_panel := PanelContainer.new()
	next_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_panel.add_theme_stylebox_override("panel", _make_dark_card_sb())
	left_vb.add_child(next_panel)
	_next_card_vb = VBoxContainer.new()
	_next_card_vb.add_theme_constant_override("separation", 7)
	next_panel.add_child(_next_card_vb)

	var recent_panel := PanelContainer.new()
	recent_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recent_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recent_panel.add_theme_stylebox_override("panel", _make_dark_card_sb())
	left_vb.add_child(recent_panel)
	_recent_card_vb = VBoxContainer.new()
	_recent_card_vb.add_theme_constant_override("separation", 4)
	recent_panel.add_child(_recent_card_vb)

	# RIGHT COLUMN: Competition Filter Pills + Month Quick-Jump + Multi-Month Calendar Grid (Gambar 4!)
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)
	body.add_child(right_vb)

	_filter_hb = HBoxContainer.new()
	_filter_hb.add_theme_constant_override("separation", 6)
	right_vb.add_child(_filter_hb)

	_month_jump_hb = HBoxContainer.new()
	_month_jump_hb.add_theme_constant_override("separation", 4)
	right_vb.add_child(_month_jump_hb)

	var cal_wrap := PanelContainer.new()
	cal_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cal_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cwsb := StyleBoxFlat.new()
	cwsb.bg_color = Color("#060D1A")
	cwsb.border_color = Color("#182840")
	cwsb.set_border_width_all(1)
	cwsb.set_corner_radius_all(6)
	cwsb.content_margin_left = 8
	cwsb.content_margin_right = 8
	cwsb.content_margin_top = 8
	cwsb.content_margin_bottom = 8
	cal_wrap.add_theme_stylebox_override("panel", cwsb)
	right_vb.add_child(cal_wrap)

	_cal_scroll = ScrollContainer.new()
	_cal_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cal_wrap.add_child(_cal_scroll)

	_cal_body_vb = VBoxContainer.new()
	_cal_body_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cal_body_vb.add_theme_constant_override("separation", 10)
	_cal_scroll.add_child(_cal_body_vb)

func _make_dark_card_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#081120")
	sb.border_color = Color("#172740")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	return sb

func _clear_box(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

static func get_comp_category(comp: String) -> String:
	var c: String = comp.to_upper()
	if c == "LIGA":
		return "LIGA"
	if c == "PIALA":
		return "DOMESTIK"
	if c in ["TIMNAS", "TURNAMEN_ASIA"]:
		return "TIMNAS"
	return "KONTINENTAL"

static func _get_day_col_for_fixture(fix: Dictionary) -> int:
	var cat: String = get_comp_category(str(fix.get("comp", "LIGA")))
	match cat:
		"LIGA":
			return 6  # MIN (Sunday — matches Gambar 4!)
		"KONTINENTAL":
			return 3  # KAM (Thursday — matches Gambar 4!)
		"DOMESTIK":
			return 2  # RAB (Wednesday domestic cup)
		"TIMNAS":
			return 2  # RAB (Wednesday international break — matches Gambar 4!)
	return 6

static func _get_rest_days(sched: Array, wk: int) -> int:
	var cur_col: int = 6
	var prev_col: int = 6
	for f in sched:
		var fw: int = int(f.get("week", 0))
		if fw == wk:
			cur_col = _get_day_col_for_fixture(f)
		elif fw == wk - 1:
			prev_col = _get_day_col_for_fixture(f)
	if wk <= 1:
		return 7
	var diff: int = (7 - prev_col) + cur_col
	return clampi(diff, 3, 7)

func _find_fixture(sched: Array, wk: int) -> Dictionary:
	for f in sched:
		if int(f.get("week", 0)) == wk:
			return f
	return sched[0] if not sched.is_empty() else {}

func _refresh(scroll_to_cur_month: bool = false) -> void:
	if not CareerState.has_active_career:
		return
	var prev_scroll: int = _cal_scroll.scroll_vertical if _cal_scroll != null else 0
	var meta: Dictionary = CareerState.career.get("careerMeta", {})
	var cur_wk: int = clampi(int(meta.get("week", 1)), 1, int(meta.get("maxWeeks", 45)))
	var sched: Array = CareerState.career.get("schedule", [])
	var sel_fix: Dictionary = _find_fixture(sched, _sel_week)

	_build_season_stats_card(sched)
	_build_next_match_card(sel_fix, sched, cur_wk)
	_build_recent_results_card(sched)
	_build_comp_filter_bar()
	_build_month_jump_bar(cur_wk)
	_build_calendar_months(sched, cur_wk)

	if scroll_to_cur_month:
		call_deferred("_scroll_to_month", _cal_month)
	else:
		call_deferred("_restore_scroll", prev_scroll)

func _restore_scroll(y_pos: int) -> void:
	if _cal_scroll != null:
		_cal_scroll.scroll_vertical = maxi(0, y_pos)

func _scroll_to_month(m_idx: int) -> void:
	if _cal_scroll == null or not _month_nodes.has(m_idx):
		return
	var node: Control = _month_nodes[m_idx] as Control
	if is_instance_valid(node):
		_cal_scroll.scroll_vertical = maxi(0, int(node.position.y) - 4)

# ==============================================================================
# LEFT CARD 1: SEASON PERFORMANCE STATS (Gambar 3 Top Card)
# ==============================================================================
func _build_season_stats_card(sched: Array) -> void:
	_clear_box(_stats_card_vb)

	var wins: int = 0
	var draws: int = 0
	var losses: int = 0
	for f in sched:
		if bool(f.get("played", false)):
			var su: int = int(f.get("score_us", 0))
			var st: int = int(f.get("score_them", 0))
			if su > st:
				wins += 1
			elif su == st:
				draws += 1
			else:
				losses += 1
	var tot: int = wins + draws + losses
	var w_pct: int = int(round(float(wins) * 100.0 / float(tot))) if tot > 0 else 0
	var d_pct: int = int(round(float(draws) * 100.0 / float(tot))) if tot > 0 else 0
	var l_pct: int = maxi(0, 100 - w_pct - d_pct) if tot > 0 else 0

	# Top 3-Column W / D / L Percentages + Counts
	var pct_hb := HBoxContainer.new()
	pct_hb.add_theme_constant_override("separation", 6)
	_stats_card_vb.add_child(pct_hb)

	for col_d in [
		["%d%%" % w_pct, "M  %d" % wins, UITheme.TEXT_WHITE],
		["%d%%" % d_pct, "S  %d" % draws, Color("#94A3B8")],
		["%d%%" % l_pct, "K  %d" % losses, Color("#E05252")],
	]:
		var cvb := VBoxContainer.new()
		cvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cvb.alignment = BoxContainer.ALIGNMENT_CENTER
		cvb.add_theme_constant_override("separation", 0)
		pct_hb.add_child(cvb)

		var pl := Label.new()
		pl.text = str(col_d[0])
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_override("font", UITheme.get_display_font())
		pl.add_theme_font_size_override("font_size", 19)
		pl.add_theme_color_override("font_color", col_d[2])
		cvb.add_child(pl)

		var sub := Label.new()
		sub.text = str(col_d[1])
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_override("font", UITheme.get_display_font())
		sub.add_theme_font_size_override("font_size", 9)
		sub.add_theme_color_override("font_color", Color("#7C90AB"))
		cvb.add_child(sub)

	# Full-Width Horizontal W / D / L Segmented Bar
	var bar_hb := HBoxContainer.new()
	bar_hb.custom_minimum_size = Vector2(0, 6)
	bar_hb.add_theme_constant_override("separation", 1)
	_stats_card_vb.add_child(bar_hb)

	if tot == 0:
		var empty_bar := ColorRect.new()
		empty_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_bar.color = Color("#1A283F")
		bar_hb.add_child(empty_bar)
	else:
		for seg_d in [
			[wins, Color("#F1F5F9")],
			[draws, Color("#475569")],
			[losses, Color("#E05252")],
		]:
			var cnt: int = int(seg_d[0])
			if cnt <= 0:
				continue
			var sr := ColorRect.new()
			sr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sr.size_flags_stretch_ratio = float(cnt)
			sr.color = seg_d[1]
			bar_hb.add_child(sr)

	var div_line := ColorRect.new()
	div_line.custom_minimum_size = Vector2(0, 1)
	div_line.color = Color("#132238")
	_stats_card_vb.add_child(div_line)

	# Bottom 3 Stat Badges: Avg Rating | Goals | Assists (Gambar 3!)
	var meta: Dictionary = CareerState.career.get("careerMeta", {})
	var st: Dictionary = CareerState.career.get("stats", {})
	var s_m: int = int(meta.get("seasonMatches", 0))
	var s_g: int = int(meta.get("seasonGoals", 0))
	var s_a: int = int(meta.get("seasonAssists", 0))
	var s_rt_sum: float = float(meta.get("seasonTotalRating", 0.0))
	if s_m == 0 and int(st.get("matches", 0)) > 0:
		s_m = int(st.get("matches", 0))
		s_g = int(st.get("goals", 0))
		s_a = int(st.get("assists", 0))
		s_rt_sum = float(st.get("totalRating", 0.0))
	var avg_rt: float = snappedf(s_rt_sum / float(maxi(1, s_m)), 0.1) if s_m > 0 else 0.0
	var avg_txt: String = ("%.1f" % avg_rt).replace(".", ",")

	var bot_hb := HBoxContainer.new()
	bot_hb.add_theme_constant_override("separation", 6)
	_stats_card_vb.add_child(bot_hb)

	for bstat in [
		["star", avg_txt, Color("#E2E8F0")],
		["goal", str(s_g), Color("#4ADE80")],
		["assist", str(s_a), Color("#60A5FA")],
	]:
		var shb := HBoxContainer.new()
		shb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shb.alignment = BoxContainer.ALIGNMENT_CENTER
		shb.add_theme_constant_override("separation", 6)
		bot_hb.add_child(shb)

		var iw := CenterContainer.new()
		var ic := SchedMiniGlyph.new()
		ic.glyph = str(bstat[0])
		ic.glyph_color = bstat[2]
		ic.custom_minimum_size = Vector2(15, 15)
		iw.add_child(ic)
		shb.add_child(iw)

		var vl := Label.new()
		vl.text = str(bstat[1])
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 15)
		vl.add_theme_color_override("font_color", bstat[2])
		shb.add_child(vl)

# ==============================================================================
# LEFT CARD 2: LAGA BERIKUT (Gambar 3 Bottom Card)
# ==============================================================================
func _build_next_match_card(fix: Dictionary, sched: Array, cur_wk: int) -> void:
	_clear_box(_next_card_vb)
	if fix.is_empty():
		return

	var wk: int = int(fix.get("week", 1))
	var comp: String = str(fix.get("comp", "LIGA"))
	var cat: String = get_comp_category(comp)
	var cm: Dictionary = COMP_META[cat]
	var accent_c: Color = cm["accent"]
	var is_home: bool = bool(fix.get("is_home", true))
	var played: bool = bool(fix.get("played", false))
	var as_flag: bool = (cat == "TIMNAS")
	var club: Dictionary = CareerState.get_current_club()
	var my_nat_id: int = clampi(int(CareerState.career.get("playerProfile", {}).get("nationId", 16)), 0, GameData.nations.size() - 1)

	# Top Header: Comp Icon + "LAGA BERIKUT" + Comp Label | Right "KANDANG/TANDANG" Pill
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	_next_card_vb.add_child(hdr)

	var ic_c := CenterContainer.new()
	var cic := SchedCompIcon.new()
	var is_super_cup: bool = (comp.to_upper() == "PIALA_SUPER_EROPA")
	cic.category = "SUPER_EROPA" if is_super_cup else cat
	cic.icon_color = Color("#E2E8F0") if is_super_cup else accent_c
	cic.custom_minimum_size = Vector2(18, 18)
	ic_c.add_child(cic)
	hdr.add_child(ic_c)

	var ttl_vb := VBoxContainer.new()
	ttl_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl_vb.add_theme_constant_override("separation", 1)
	hdr.add_child(ttl_vb)

	var sub_l := Label.new()
	sub_l.text = "LAGA BERIKUT" if wk == cur_wk else ("HASIL PEKAN %d" % wk if played else "JADWAL PEKAN %d" % wk)
	sub_l.add_theme_font_size_override("font_size", 9)
	sub_l.add_theme_color_override("font_color", Color("#7C90AB"))
	ttl_vb.add_child(sub_l)

	var comp_l := Label.new()
	comp_l.text = str(fix.get("comp_label", "LIGA")).to_upper()
	comp_l.clip_text = true
	comp_l.add_theme_font_override("font", UITheme.get_display_font())
	comp_l.add_theme_font_size_override("font_size", 11)
	comp_l.add_theme_color_override("font_color", accent_c)
	ttl_vb.add_child(comp_l)

	var loc_pill := PanelContainer.new()
	loc_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color("#0D1829")
	lsb.border_color = Color("#465975")
	lsb.set_border_width_all(1)
	lsb.set_corner_radius_all(3)
	lsb.content_margin_left = 7
	lsb.content_margin_right = 7
	lsb.content_margin_top = 2
	lsb.content_margin_bottom = 2
	loc_pill.add_theme_stylebox_override("panel", lsb)
	var loc_l := Label.new()
	loc_l.text = "KANDANG" if is_home else "TANDANG"
	loc_l.add_theme_font_override("font", UITheme.get_display_font())
	loc_l.add_theme_font_size_override("font_size", 9)
	loc_l.add_theme_color_override("font_color", Color("#CBD5E1"))
	loc_pill.add_child(loc_l)
	hdr.add_child(loc_pill)

	# Compact Matchup Row: [Home Crest] HOME_CODE  VS  AWAY_CODE [Away Crest]
	var my_code: String = str(GameData.nations[my_nat_id].get("code", "IDN")).left(3).to_upper() if as_flag else str(club.get("code", "KITA")).left(3).to_upper()
	var opp_code: String = str(fix.get("opp_code", "LWN")).left(3).to_upper()
	var my_id: int = my_nat_id if as_flag else int(club.get("id", 0))
	var opp_id: int = int(fix.get("opp_nat_id", 0)) if as_flag else int(fix.get("opp_club_id", 0))

	var left_code: String = my_code if is_home else opp_code
	var right_code: String = opp_code if is_home else my_code
	var left_id: int = my_id if is_home else opp_id
	var right_id: int = opp_id if is_home else my_id
	var left_is_us: bool = is_home

	var vs_hb := HBoxContainer.new()
	vs_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vs_hb.add_theme_constant_override("separation", 8)
	_next_card_vb.add_child(vs_hb)

	vs_hb.add_child(_make_team_emblem(left_id, as_flag, 24))
	var lc_l := Label.new()
	lc_l.text = left_code
	lc_l.add_theme_font_override("font", UITheme.get_display_font())
	lc_l.add_theme_font_size_override("font_size", 13)
	lc_l.add_theme_color_override("font_color", accent_c if left_is_us else Color("#CBD5E1"))
	vs_hb.add_child(lc_l)

	var mid_l := Label.new()
	if played:
		var h_sc: int = int(fix.get("score_us", 0)) if is_home else int(fix.get("score_them", 0))
		var a_sc: int = int(fix.get("score_them", 0)) if is_home else int(fix.get("score_us", 0))
		mid_l.text = "%d - %d" % [h_sc, a_sc]
		mid_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	else:
		mid_l.text = "VS"
		mid_l.add_theme_color_override("font_color", Color("#7C90AB"))
	mid_l.add_theme_font_override("font", UITheme.get_display_font())
	mid_l.add_theme_font_size_override("font_size", 13)
	vs_hb.add_child(mid_l)

	var rc_l := Label.new()
	rc_l.text = right_code
	rc_l.add_theme_font_override("font", UITheme.get_display_font())
	rc_l.add_theme_font_size_override("font_size", 13)
	rc_l.add_theme_color_override("font_color", accent_c if not left_is_us else Color("#CBD5E1"))
	vs_hb.add_child(rc_l)
	vs_hb.add_child(_make_team_emblem(right_id, as_flag, 24))

	# 3 Status Rows: HARI ISTIRAHAT | ENERGI | PERANMU (Gambar 3!)
	var rest_days: int = _get_rest_days(sched, wk)
	var eng: int = clampi(int(CareerState.career.get("playerProfile", {}).get("energy", 80)), 0, 100)
	var role_txt: String = CareerState.get_player_role_status()
	var eng_col: Color = Color("#A3E635") if eng >= 60 else (Color("#F5C430") if eng >= 35 else Color("#EF4444"))
	var role_col: Color = UITheme.TEXT_WHITE if role_txt == "INTI" else (Color("#F5C430") if role_txt == "CADANGAN" else Color("#F87171"))

	_add_status_bar_row(_next_card_vb, "clock", "HARI ISTIRAHAT", "%dh" % rest_days, float(rest_days) / 7.0, 7, Color("#E5C93E"), Color("#E5C93E"))
	_add_status_bar_row(_next_card_vb, "bolt", "ENERGI", str(eng), float(eng) / 100.0, 10, eng_col, eng_col)

	var role_hb := HBoxContainer.new()
	role_hb.add_theme_constant_override("separation", 6)
	_next_card_vb.add_child(role_hb)
	var r_ic := SchedMiniGlyph.new()
	r_ic.glyph = "shirt"
	r_ic.glyph_color = Color("#E2E8F0")
	r_ic.custom_minimum_size = Vector2(13, 13)
	var r_ic_c := CenterContainer.new()
	r_ic_c.add_child(r_ic)
	role_hb.add_child(r_ic_c)

	var r_lbl := Label.new()
	r_lbl.text = "PERANMU"
	r_lbl.custom_minimum_size = Vector2(106, 0)
	r_lbl.add_theme_font_size_override("font_size", 10)
	r_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	role_hb.add_child(r_lbl)

	var r_val := Label.new()
	r_val.text = role_txt
	r_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_val.add_theme_font_override("font", UITheme.get_display_font())
	r_val.add_theme_font_size_override("font_size", 12)
	r_val.add_theme_color_override("font_color", role_col)
	role_hb.add_child(r_val)

	var det_btn := Button.new()
	det_btn.text = "DETAIL"
	det_btn.custom_minimum_size = Vector2(68, 22)
	UITheme.style_btn(det_btn, Color("#122036"), Color("#94A3B8") if comp.to_upper() == "PIALA_SUPER_EROPA" else accent_c, 9)
	var fix_cap: Dictionary = fix.duplicate(true)
	det_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_match_detail_modal(fix_cap)
	)
	role_hb.add_child(det_btn)

func _add_status_bar_row(parent_vb: VBoxContainer, icon_kind: String, label_txt: String, val_txt: String, ratio: float, segs: int, icon_col: Color, bar_col: Color) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	parent_vb.add_child(hb)

	var ic_c := CenterContainer.new()
	var ic := SchedMiniGlyph.new()
	ic.glyph = icon_kind
	ic.glyph_color = icon_col
	ic.custom_minimum_size = Vector2(13, 13)
	ic_c.add_child(ic)
	hb.add_child(ic_c)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.custom_minimum_size = Vector2(106, 0)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	hb.add_child(lbl)

	var vl := Label.new()
	vl.text = val_txt
	vl.custom_minimum_size = Vector2(30, 0)
	vl.add_theme_font_override("font", UITheme.get_display_font())
	vl.add_theme_font_size_override("font_size", 12)
	vl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	hb.add_child(vl)

	var bar_c := CenterContainer.new()
	bar_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(bar_c)

	var seg_bar := SegmentedMeterControl.new()
	seg_bar.ratio = clampf(ratio, 0.0, 1.0)
	seg_bar.segments = segs
	seg_bar.fill_color = bar_col
	seg_bar.custom_minimum_size = Vector2(138, 10)
	bar_c.add_child(seg_bar)

func _make_team_emblem(id_val: int, is_flag: bool, sz_px: int) -> Control:
	var wrap := CenterContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_flag:
		var fl := UITheme.make_flag_rect(id_val, Vector2(sz_px, int(round(float(sz_px) * 0.68))))
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(fl)
	else:
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(sz_px, sz_px)
		cr.set_club(id_val)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(cr)
	return wrap

# ==============================================================================
# LEFT CARD 3: COMPACT RECENT RESULTS
# ==============================================================================
func _build_recent_results_card(sched: Array) -> void:
	_clear_box(_recent_card_vb)
	var hdr := Label.new()
	hdr.text = "▸ HASIL TERAKHIR"
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	_recent_card_vb.add_child(hdr)

	var played: Array = []
	for f in sched:
		if bool(f.get("played", false)):
			played.append(f)
	if played.is_empty():
		var empty_l := Label.new()
		empty_l.text = "Belum ada hasil musim ini."
		empty_l.add_theme_font_size_override("font_size", 10)
		empty_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		_recent_card_vb.add_child(empty_l)
		return

	var start_idx: int = maxi(0, played.size() - 4)
	for i in range(played.size() - 1, start_idx - 1, -1):
		var f: Dictionary = played[i]
		var su: int = int(f.get("score_us", 0))
		var st: int = int(f.get("score_them", 0))
		var code: String = "M" if su > st else ("S" if su == st else "K")
		var col: Color = Color("#2F9E57") if su > st else (Color("#64748B") if su == st else Color("#C93A3A"))
		var cat: String = get_comp_category(str(f.get("comp", "LIGA")))
		var accent_c: Color = COMP_META[cat]["accent"]

		var rb := Button.new()
		rb.flat = true
		rb.custom_minimum_size = Vector2(0, 22)
		rb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var rh := HBoxContainer.new()
		rh.set_anchors_preset(Control.PRESET_FULL_RECT)
		rh.add_theme_constant_override("separation", 6)
		rh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rb.add_child(rh)

		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(18, 18)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", UITheme.make_box(col, Color.TRANSPARENT, 0, 2))
		var bl := Label.new()
		bl.text = code
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bl.add_theme_font_size_override("font_size", 9)
		bl.add_theme_color_override("font_color", Color.WHITE)
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(bl)
		rh.add_child(badge)

		var sc_l := Label.new()
		sc_l.text = "%d-%d  %s" % [su, st, str(f.get("opp_code", "LWN"))]
		sc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc_l.add_theme_font_override("font", UITheme.get_display_font())
		sc_l.add_theme_font_size_override("font_size", 10)
		sc_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		sc_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rh.add_child(sc_l)

		var tag_l := Label.new()
		tag_l.text = "%s • P%d" % [cat.left(4), int(f.get("week", 0))]
		tag_l.add_theme_font_size_override("font_size", 9)
		tag_l.add_theme_color_override("font_color", accent_c)
		tag_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rh.add_child(tag_l)

		var wk_cap: int = int(f.get("week", 1))
		rb.pressed.connect(func():
			AudioSynth.play_click()
			_sel_week = wk_cap
			_refresh(false)
		)
		_recent_card_vb.add_child(rb)

# ==============================================================================
# RIGHT HEADER: COMPETITION FILTER / LEGEND PILLS + MONTH JUMP (Gambar 4!)
# ==============================================================================
func _build_comp_filter_bar() -> void:
	_clear_box(_filter_hb)
	for cat_key in ["LIGA", "KONTINENTAL", "DOMESTIK", "TIMNAS"]:
		var cm: Dictionary = COMP_META[cat_key]
		var is_active: bool = (_comp_filter == cat_key)
		var is_dimmed: bool = (_comp_filter != "ALL" and not is_active)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 30)
		var sb := StyleBoxFlat.new()
		sb.bg_color = (cm["bg"] as Color).lightened(0.14) if is_active else cm["bg"]
		sb.border_color = cm["accent"] if is_active else cm["border"]
		sb.set_border_width_all(2 if is_active else 1)
		sb.set_corner_radius_all(5)
		var sbh := sb.duplicate()
		sbh.bg_color = (cm["bg"] as Color).lightened(0.18)
		sbh.border_color = cm["accent"]
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sbh)
		btn.add_theme_stylebox_override("pressed", sbh)
		btn.add_theme_stylebox_override("focus", sbh)
		btn.modulate = Color(1, 1, 1, 0.48) if is_dimmed else Color.WHITE

		var hb := HBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 8
		hb.offset_right = -8
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 6)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(hb)

		var iw := CenterContainer.new()
		iw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := SchedCompIcon.new()
		ic.category = cat_key
		ic.icon_color = cm["accent"]
		ic.custom_minimum_size = Vector2(13, 13)
		iw.add_child(ic)
		hb.add_child(iw)

		var lbl := Label.new()
		lbl.text = str(cm["label"])
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", UITheme.get_display_font())
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color("#F1F5F9"))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(lbl)

		var ck_copy: String = cat_key
		btn.pressed.connect(func():
			AudioSynth.play_click()
			_comp_filter = "ALL" if _comp_filter == ck_copy else ck_copy
			_refresh(false)
		)
		_filter_hb.add_child(btn)

func _build_month_jump_bar(cur_wk: int) -> void:
	_clear_box(_month_jump_hb)
	var cur_m: int = CareerState.get_season_month_index(cur_wk)
	for mi in range(CareerState.SEASON_MONTHS.size()):
		var is_cur: bool = (mi == cur_m)
		var mb := Button.new()
		mb.text = CareerState.SEASON_MONTHS[mi].left(3)
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.custom_minimum_size = Vector2(0, 22)
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color("#1B2D4A") if is_cur else Color("#0A1322")
		msb.border_color = UITheme.ACCENT_GOLD if is_cur else Color("#182840")
		msb.set_border_width_all(1)
		msb.set_corner_radius_all(3)
		var msbh := msb.duplicate()
		msbh.border_color = UITheme.ACCENT_CYAN
		mb.add_theme_stylebox_override("normal", msb)
		mb.add_theme_stylebox_override("hover", msbh)
		mb.add_theme_stylebox_override("pressed", msbh)
		mb.add_theme_font_override("font", UITheme.get_display_font())
		mb.add_theme_font_size_override("font_size", 8)
		mb.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_cur else Color("#94A3B8"))
		var mi_cap: int = mi
		mb.pressed.connect(func():
			AudioSynth.play_click()
			_cal_month = mi_cap
			_scroll_to_month(mi_cap)
		)
		_month_jump_hb.add_child(mb)

# ==============================================================================
# RIGHT BODY: MULTI-MONTH COMPETITION-TAGGED CALENDAR GRID (Gambar 4!)
# ==============================================================================
func _build_calendar_months(sched: Array, cur_wk: int) -> void:
	_clear_box(_cal_body_vb)
	_month_nodes.clear()

	var club: Dictionary = CareerState.get_current_club()
	var my_cid: int = int(club.get("id", 0))
	var my_nat_id: int = clampi(int(CareerState.career.get("playerProfile", {}).get("nationId", 16)), 0, GameData.nations.size() - 1)

	for m_idx in range(CareerState.SEASON_MONTHS.size()):
		var month_fixtures: Array[Dictionary] = []
		for f_item in sched:
			var f: Dictionary = f_item
			if CareerState.get_season_month_index(int(f.get("week", 1))) == m_idx:
				month_fixtures.append(f)
		if month_fixtures.is_empty():
			continue

		var m_sec := VBoxContainer.new()
		m_sec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_sec.add_theme_constant_override("separation", 4)
		_cal_body_vb.add_child(m_sec)
		_month_nodes[m_idx] = m_sec

		# Month Header Row: "FEBRUARI" on left | "• 5 ■■■■■" match count & colored pips on right
		var m_hdr := HBoxContainer.new()
		m_hdr.add_theme_constant_override("separation", 6)
		m_sec.add_child(m_hdr)

		var m_lbl := Label.new()
		m_lbl.text = CareerState.SEASON_MONTHS[m_idx]
		m_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_lbl.add_theme_font_override("font", UITheme.get_display_font())
		m_lbl.add_theme_font_size_override("font_size", 12)
		m_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		m_hdr.add_child(m_lbl)

		var match_cnt: int = month_fixtures.size()
		var cnt_l := Label.new()
		cnt_l.text = "• %d" % match_cnt
		cnt_l.add_theme_font_override("font", UITheme.get_display_font())
		cnt_l.add_theme_font_size_override("font_size", 10)
		cnt_l.add_theme_color_override("font_color", Color("#94A3B8"))
		m_hdr.add_child(cnt_l)

		var pips_hb := HBoxContainer.new()
		pips_hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pips_hb.add_theme_constant_override("separation", 2)
		m_hdr.add_child(pips_hb)
		for f in month_fixtures:
			var cat: String = get_comp_category(str(f.get("comp", "LIGA")))
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(6, 7)
			pip.color = COMP_META[cat]["accent"] if bool(f.get("played", false)) else Color("#CBD5E1")
			pips_hb.add_child(pip)

		# Colored Segmented Accent Bar below month title (Gambar 4!)
		var strip_hb := HBoxContainer.new()
		strip_hb.custom_minimum_size = Vector2(0, 3)
		strip_hb.add_theme_constant_override("separation", 2)
		m_sec.add_child(strip_hb)
		for f in month_fixtures:
			var cat: String = get_comp_category(str(f.get("comp", "LIGA")))
			var seg := ColorRect.new()
			seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			seg.color = COMP_META[cat]["bar"]
			strip_hb.add_child(seg)

		# Day-of-Week Header Row (22px week gutter + SEN..MIN)
		var dh_hb := HBoxContainer.new()
		dh_hb.add_theme_constant_override("separation", 4)
		m_sec.add_child(dh_hb)
		var gut := Control.new()
		gut.custom_minimum_size = Vector2(20, 0)
		dh_hb.add_child(gut)
		for dn in DAY_HDRS:
			var dl := Label.new()
			dl.text = dn
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dl.add_theme_font_override("font", UITheme.get_display_font())
			dl.add_theme_font_size_override("font_size", 8)
			dl.add_theme_color_override("font_color", Color("#CBD5E1") if dn in ["SAB", "MIN"] else Color("#64748B"))
			dh_hb.add_child(dl)

		# Week Rows (1 row per season week in this month)
		for f in month_fixtures:
			var w: int = int(f.get("week", 1))
			var cat: String = get_comp_category(str(f.get("comp", "LIGA")))
			var target_col: int = _get_day_col_for_fixture(f)
			var is_intl_wk: bool = (cat == "TIMNAS")

			var wk_hb := HBoxContainer.new()
			wk_hb.add_theme_constant_override("separation", 4)
			m_sec.add_child(wk_hb)

			var wk_l := Label.new()
			wk_l.text = str(w)
			wk_l.custom_minimum_size = Vector2(20, 52)
			wk_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			wk_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			wk_l.add_theme_font_override("font", UITheme.get_display_font())
			wk_l.add_theme_font_size_override("font_size", 9)
			wk_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if w == cur_wk else Color("#526682"))
			wk_hb.add_child(wk_l)

			for col_i in range(7):
				if col_i != target_col:
					var blank := PanelContainer.new()
					blank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					blank.custom_minimum_size = Vector2(0, 52)
					var bsb := StyleBoxFlat.new()
					bsb.bg_color = Color("#151E15") if is_intl_wk else Color("#0B1628")
					bsb.border_color = Color("#243122") if is_intl_wk else Color("#14233A")
					bsb.set_border_width_all(1)
					bsb.set_corner_radius_all(5)
					blank.add_theme_stylebox_override("panel", bsb)
					wk_hb.add_child(blank)
				else:
					wk_hb.add_child(_make_calendar_match_tile(f, sched, cur_wk, my_cid, my_nat_id))

func _make_calendar_match_tile(f: Dictionary, sched: Array, cur_wk: int, my_cid: int, my_nat_id: int) -> Button:
	var w: int = int(f.get("week", 1))
	var comp: String = str(f.get("comp", "LIGA"))
	var cat: String = get_comp_category(comp)
	var cm: Dictionary = COMP_META[cat]
	var accent_c: Color = cm["accent"]
	var played: bool = bool(f.get("played", false))
	var is_home: bool = bool(f.get("is_home", true))
	var as_flag: bool = (cat == "TIMNAS")
	var is_cur: bool = (w == cur_wk)
	var is_sel: bool = (w == _sel_week)
	var matches_filter: bool = (_comp_filter == "ALL" or _comp_filter == cat)

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 52)
	btn.clip_contents = true
	btn.modulate = Color.WHITE if matches_filter else Color(1, 1, 1, 0.25)

	var sb := StyleBoxFlat.new()
	sb.bg_color = (cm["bg"] as Color).lightened(0.08 if is_cur else 0.0)
	sb.border_color = UITheme.TEXT_WHITE if is_sel else (accent_c if is_cur else cm["border"])
	sb.set_border_width_all(2 if (is_sel or is_cur) else 1)
	sb.set_corner_radius_all(5)
	var sbh := sb.duplicate()
	sbh.bg_color = sb.bg_color.lightened(0.14)
	sbh.border_color = UITheme.TEXT_WHITE
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 3
	vb.offset_right = -3
	vb.offset_top = 2
	vb.offset_bottom = -2
	vb.add_theme_constant_override("separation", 1)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	# Top Row: Competition mini icon (left) + Rest days "4h" if upcoming or "K/T" if played (right)
	var top_hb := HBoxContainer.new()
	top_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top_hb)

	var is_super_cup: bool = (comp.to_upper() == "PIALA_SUPER_EROPA")
	var ic := SchedCompIcon.new()
	ic.category = "SUPER_EROPA" if is_super_cup else cat
	ic.icon_color = Color("#E2E8F0") if is_super_cup else accent_c
	ic.custom_minimum_size = Vector2(10, 10)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hb.add_child(ic)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hb.add_child(sp)

	var rt_l := Label.new()
	rt_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt_l.add_theme_font_override("font", UITheme.get_display_font())
	rt_l.add_theme_font_size_override("font_size", 7)
	if played:
		rt_l.text = "K" if is_home else "T"
		rt_l.add_theme_color_override("font_color", Color("#7C90AB"))
	else:
		rt_l.text = "%dh" % _get_rest_days(sched, w)
		rt_l.add_theme_color_override("font_color", Color("#F5C430"))
	top_hb.add_child(rt_l)

	# Center Row: 2 Mini Crests (Home vs Away) — matches Gambar 4!
	var my_id: int = my_nat_id if as_flag else my_cid
	var opp_id: int = int(f.get("opp_nat_id", 0)) if as_flag else int(f.get("opp_club_id", 0))
	var left_id: int = my_id if is_home else opp_id
	var right_id: int = opp_id if is_home else my_id

	var cr_hb := HBoxContainer.new()
	cr_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	cr_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cr_hb.add_theme_constant_override("separation", 3)
	cr_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(cr_hb)
	cr_hb.add_child(_make_team_emblem(left_id, as_flag, 16))
	cr_hb.add_child(_make_team_emblem(right_id, as_flag, 16))

	# Bottom Score / Venue Pill Strip
	var bot_p := PanelContainer.new()
	bot_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bpsb := StyleBoxFlat.new()
	bpsb.bg_color = Color(0.04, 0.07, 0.14, 0.85)
	bpsb.set_corner_radius_all(2)
	bpsb.content_margin_left = 2
	bpsb.content_margin_right = 2
	bpsb.content_margin_top = 0
	bpsb.content_margin_bottom = 0
	bot_p.add_theme_stylebox_override("panel", bpsb)
	vb.add_child(bot_p)

	var bot_l := Label.new()
	bot_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_l.add_theme_font_override("font", UITheme.get_display_font())
	bot_l.add_theme_font_size_override("font_size", 8)
	if played:
		var su: int = int(f.get("score_us", 0))
		var st: int = int(f.get("score_them", 0))
		var h_sc: int = su if is_home else st
		var a_sc: int = st if is_home else su
		bot_l.text = "%d - %d" % [h_sc, a_sc]
		bot_l.add_theme_color_override("font_color", Color("#4ADE80") if su > st else (Color("#E2E8F0") if su == st else Color("#FCA5A5")))
	else:
		bot_l.text = "KDG" if is_home else "TDG"
		bot_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE if is_cur else Color("#94A3B8"))
	bot_p.add_child(bot_l)

	var wk_cap: int = w
	var fix_cap: Dictionary = f.duplicate(true)
	btn.pressed.connect(func():
		AudioSynth.play_click()
		if _sel_week == wk_cap:
			open_match_detail_modal(fix_cap)
		else:
			_sel_week = wk_cap
			_refresh(false)
	)
	return btn

func open_match_detail_modal(fix: Dictionary) -> void:
	if _root == null or fix.is_empty():
		return
	var existing: Node = _root.get_node_or_null("MatchDetailOverlay")
	if existing != null:
		_root.remove_child(existing)
		existing.queue_free()

	var comp: String = str(fix.get("comp", "LIGA")).to_upper()
	var cat: String = get_comp_category(comp)
	var is_super_cup: bool = (comp == "PIALA_SUPER_EROPA")
	var as_flag: bool = (cat == "TIMNAS")
	var is_home: bool = bool(fix.get("is_home", true))
	var played: bool = bool(fix.get("played", false))
	var club: Dictionary = CareerState.get_current_club()
	var my_nat_id: int = clampi(int(CareerState.career.get("playerProfile", {}).get("nationId", 16)), 0, GameData.nations.size() - 1)
	var my_id: int = my_nat_id if as_flag else int(club.get("id", 0))
	var opp_id: int = int(fix.get("opp_nat_id", 0)) if as_flag else int(fix.get("opp_club_id", 0))
	var my_name: String = (str(GameData.nations[my_nat_id].get("name", "TIMNAS")) if as_flag else str(club.get("name", "KLUB"))).to_upper()
	var opp_name: String = str(fix.get("opp_name", "LAWAN")).to_upper()

	var left_id: int = my_id if is_home else opp_id
	var right_id: int = opp_id if is_home else my_id
	var left_name: String = my_name if is_home else opp_name
	var right_name: String = opp_name if is_home else my_name
	var su: int = int(fix.get("score_us", 0))
	var st: int = int(fix.get("score_them", 0))
	var left_sc: int = su if is_home else st
	var right_sc: int = st if is_home else su

	var ov := Control.new()
	ov.name = "MatchDetailOverlay"
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(ov)

	var bg := ColorRect.new()
	bg.color = Color("#07101C")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(bg)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left", 36)
	mc.add_theme_constant_override("margin_right", 36)
	mc.add_theme_constant_override("margin_top", 22)
	mc.add_theme_constant_override("margin_bottom", 20)
	ov.add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	mc.add_child(vb)

	# Top Header: Silver Trophy Emblem + "PIALA SUPER EROPA • FINAL" (exact Gambar 2!)
	var hdr_cc := CenterContainer.new()
	vb.add_child(hdr_cc)
	var hdr_hb := HBoxContainer.new()
	hdr_hb.add_theme_constant_override("separation", 10)
	hdr_cc.add_child(hdr_hb)

	var ic := SchedCompIcon.new()
	ic.category = "SUPER_EROPA" if is_super_cup else cat
	ic.icon_color = Color("#E2E8F0") if is_super_cup else (COMP_META[cat]["accent"] as Color)
	ic.custom_minimum_size = Vector2(22, 22)
	hdr_hb.add_child(ic)

	var ttl := Label.new()
	ttl.text = str(fix.get("comp_label", "PIALA SUPER EROPA • FINAL")).to_upper()
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 16)
	ttl.add_theme_color_override("font_color", Color("#E2E8F0") if is_super_cup else UITheme.TEXT_WHITE)
	hdr_hb.add_child(ttl)

	# Center Hero Row: Giant Home Crest | Giant Score (5-2 or VS) | Giant Away Crest
	var mid_cc := CenterContainer.new()
	mid_cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(mid_cc)

	var match_hb := HBoxContainer.new()
	match_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	match_hb.add_theme_constant_override("separation", 46)
	mid_cc.add_child(match_hb)

	var left_res: String = ("M" if left_sc > right_sc else ("S" if left_sc == right_sc else "K")) if played else "-"
	var right_res: String = ("M" if right_sc > left_sc else ("S" if right_sc == left_sc else "K")) if played else "-"

	for side_i in range(2):
		if side_i == 1:
			var sc_l := Label.new()
			sc_l.text = ("%d-%d" % [left_sc, right_sc]) if played else "VS"
			sc_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sc_l.add_theme_font_override("font", UITheme.get_display_font())
			sc_l.add_theme_font_size_override("font_size", 42)
			sc_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE if played else Color("#94A3B8"))
			match_hb.add_child(sc_l)

		var col_vb := VBoxContainer.new()
		col_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		col_vb.custom_minimum_size = Vector2(230, 0)
		col_vb.add_theme_constant_override("separation", 10)
		match_hb.add_child(col_vb)

		var cr_cc := CenterContainer.new()
		col_vb.add_child(cr_cc)
		cr_cc.add_child(_make_team_emblem(left_id if side_i == 0 else right_id, as_flag, 108))

		var nm_l := Label.new()
		nm_l.text = left_name if side_i == 0 else right_name
		nm_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm_l.add_theme_font_override("font", UITheme.get_display_font())
		nm_l.add_theme_font_size_override("font_size", 14)
		var is_u_side: bool = (side_i == 0 and is_home) or (side_i == 1 and not is_home)
		nm_l.add_theme_color_override("font_color", Color("#FDA4AF") if is_u_side else Color("#E2E8F0"))
		col_vb.add_child(nm_l)

		# 5-Slot Recent Form Strip (- - - - M / - - - - K)
		var frm_cc := CenterContainer.new()
		col_vb.add_child(frm_cc)
		var frm_hb := HBoxContainer.new()
		frm_hb.add_theme_constant_override("separation", 4)
		frm_cc.add_child(frm_hb)
		var res_ch: String = left_res if side_i == 0 else right_res
		for fi in range(5):
			var ch_t: String = res_ch if (fi == 4 and played) else "-"
			var fp := PanelContainer.new()
			fp.custom_minimum_size = Vector2(18, 18)
			var fcol: Color = Color("#94A3B8") if ch_t == "M" else (Color("#EF4444") if ch_t == "K" else Color("#334155"))
			var fsb: StyleBoxFlat = UITheme.make_box(Color("#121D2E"), fcol, 1, 2)
			fsb.content_margin_left = 2
			fsb.content_margin_right = 2
			fsb.content_margin_top = 0
			fsb.content_margin_bottom = 0
			fp.add_theme_stylebox_override("panel", fsb)
			var fl := Label.new()
			fl.text = ch_t
			fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fl.add_theme_font_override("font", UITheme.get_display_font())
			fl.add_theme_font_size_override("font_size", 9)
			fl.add_theme_color_override("font_color", UITheme.TEXT_WHITE if ch_t == "M" else (Color("#FCA5A5") if ch_t == "K" else Color("#64748B")))
			fp.add_child(fl)
			frm_hb.add_child(fp)

	# Bottom Full-Width TUTUP Button (exact Gambar 2!)
	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 38)
	UITheme.style_btn(close_b, Color("#0E1A2C"), Color("#334155"), 13)
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		ov.queue_free()
	)
	vb.add_child(close_b)

# ==============================================================================
# CUSTOM VECTOR ICON & METER CONTROLS (Zero Missing Unicode Glyphs!)
# ==============================================================================
class SchedCompIcon extends Control:
	var category: String = "LIGA"
	var icon_color: Color = Color("#F59E0B")
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if category == "SUPER_EROPA":
			# Silver European Super Cup Chalice inside subtle ring
			draw_arc(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.46, 0.0, TAU, 20, icon_color, 1.4)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.28, h * 0.22), Vector2(w * 0.72, h * 0.22),
				Vector2(w * 0.60, h * 0.58), Vector2(w * 0.40, h * 0.58),
			]), icon_color)
			draw_rect(Rect2(w * 0.44, h * 0.58, w * 0.12, h * 0.14), icon_color, true)
			draw_rect(Rect2(w * 0.34, h * 0.72, w * 0.32, h * 0.10), icon_color, true)
		elif category == "LIGA":
			# Mini League Trophy
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.22, h * 0.16), Vector2(w * 0.78, h * 0.16),
				Vector2(w * 0.66, h * 0.58), Vector2(w * 0.34, h * 0.58),
			]), icon_color)
			draw_rect(Rect2(w * 0.42, h * 0.58, w * 0.16, h * 0.18), icon_color, true)
			draw_rect(Rect2(w * 0.28, h * 0.76, w * 0.44, h * 0.14), icon_color, true)
		elif category == "KONTINENTAL":
			# Shield with Star (Continental Elite/Europa/Conf)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.16, h * 0.14), Vector2(w * 0.84, h * 0.14),
				Vector2(w * 0.80, h * 0.62), Vector2(w * 0.50, h * 0.90),
				Vector2(w * 0.20, h * 0.62),
			]), icon_color)
			draw_circle(Vector2(w * 0.50, h * 0.46), minf(w, h) * 0.14, Color("#180C1C"))
		elif category == "DOMESTIK":
			# Domestic Cup (Wide Chalice)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.16, h * 0.18), Vector2(w * 0.84, h * 0.18),
				Vector2(w * 0.58, h * 0.64), Vector2(w * 0.42, h * 0.64),
			]), icon_color)
			draw_rect(Rect2(w * 0.32, h * 0.70, w * 0.36, h * 0.16), icon_color, true)
		else:
			# Timnas Globe / Emblem
			var c := Vector2(w * 0.5, h * 0.5)
			var r: float = minf(w, h) * 0.38
			draw_circle(c, r, icon_color)
			draw_line(Vector2(c.x - r * 0.7, c.y), Vector2(c.x + r * 0.7, c.y), Color("#181808"), 1.2)
			draw_line(Vector2(c.x, c.y - r * 0.7), Vector2(c.x, c.y + r * 0.7), Color("#181808"), 1.2)

class SchedMiniGlyph extends Control:
	var glyph: String = "star"
	var glyph_color: Color = Color.WHITE
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var c := Vector2(w * 0.5, h * 0.5)
		if glyph == "star":
			var pts := PackedVector2Array()
			for i in range(10):
				var ang: float = -PI * 0.5 + float(i) * PI / 5.0
				var rad: float = (minf(w, h) * 0.44) if (i % 2 == 0) else (minf(w, h) * 0.20)
				pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
			draw_colored_polygon(pts, glyph_color)
		elif glyph == "goal":
			# Goal post + tiny ball
			draw_rect(Rect2(w * 0.14, h * 0.20, w * 0.72, h * 0.52), glyph_color, false, 1.5)
			draw_circle(Vector2(w * 0.50, h * 0.56), minf(w, h) * 0.16, glyph_color)
		elif glyph == "assist":
			# Pass arrow icon
			draw_circle(Vector2(w * 0.28, h * 0.52), minf(w, h) * 0.16, glyph_color)
			draw_line(Vector2(w * 0.44, h * 0.52), Vector2(w * 0.84, h * 0.52), glyph_color, 1.8)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.88, h * 0.52), Vector2(w * 0.66, h * 0.30), Vector2(w * 0.66, h * 0.74),
			]), glyph_color)
		elif glyph == "clock":
			var r: float = minf(w, h) * 0.38
			draw_arc(c, r, 0.0, TAU, 16, glyph_color, 1.4)
			draw_line(c, c + Vector2(0, -r * 0.62), glyph_color, 1.3)
			draw_line(c, c + Vector2(r * 0.52, 0), glyph_color, 1.3)
		elif glyph == "bolt":
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.58, h * 0.10), Vector2(w * 0.24, h * 0.54),
				Vector2(w * 0.48, h * 0.54), Vector2(w * 0.40, h * 0.90),
				Vector2(w * 0.76, h * 0.44), Vector2(w * 0.52, h * 0.44),
			]), glyph_color)
		else:
			# Shirt icon for PERANMU
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.30, h * 0.16), Vector2(w * 0.70, h * 0.16),
				Vector2(w * 0.90, h * 0.38), Vector2(w * 0.74, h * 0.48),
				Vector2(w * 0.70, h * 0.86), Vector2(w * 0.30, h * 0.86),
				Vector2(w * 0.26, h * 0.48), Vector2(w * 0.10, h * 0.38),
			]), glyph_color)

class SegmentedMeterControl extends Control:
	var ratio: float = 0.6
	var segments: int = 10
	var fill_color: Color = Color("#A3E635")
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 4.0:
			return
		var filled_w: float = w * clampf(ratio, 0.0, 1.0)
		draw_rect(Rect2(0, 1, w, h - 2), Color("#0C1626"), true)
		if filled_w > 0.5:
			draw_rect(Rect2(0, 1, filled_w, h - 2), fill_color, true)
		draw_rect(Rect2(0, 1, w, h - 2), Color("#253752"), false, 1.0)
		if segments > 1:
			var step: float = w / float(segments)
			for i in range(1, segments):
				var x: float = float(i) * step
				draw_line(Vector2(x, 1), Vector2(x, h - 1), Color("#071122"), 1.0)
