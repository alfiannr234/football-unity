extends Control

var _stage_layer: Control
var _modal_layer: Control
var _crt_rect: ColorRect
var _toast_panel: PanelContainer
var _toast_lbl: Label
var _toast_timer: float = 0.0
var _splash_panel: Control
var _splash_bar: ColorRect
var _splash_ball: TextureRect
var _splash_lbl: Label
var _splash_timer: float = 0.0
var _splash_active: bool = false

var _home_screen: Control
var _career_shell: Control

func _ready() -> void:
	theme = UITheme.build_theme()

	_stage_layer = Control.new()
	_stage_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_stage_layer)

	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)

	# Achievement / Level Up Toast
	_toast_panel = PanelContainer.new()
	_toast_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast_panel.offset_left = 24
	_toast_panel.offset_right = -24
	_toast_panel.offset_top = 12
	_toast_panel.offset_bottom = 66
	_toast_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122B1E"), UITheme.ACCENT_GOLD, 2, 4))
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_panel)
	_toast_lbl = Label.new()
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_toast_panel.add_child(_toast_lbl)

	# Top-Layer CRT Scanlines Overlay
	_crt_rect = ColorRect.new()
	_crt_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/crt_overlay.gdshader")
	_crt_rect.material = mat
	add_child(_crt_rect)

	SettingsManager.crt_toggled.connect(_on_crt_toggled)
	_on_crt_toggled(bool(SettingsManager.data.get("crt_effect", true)))

	CareerState.achievement_unlocked.connect(func(ach: Dictionary):
		_show_toast("★ PRESTASI TERBUKA: %s (%s)" % [ach["title"], ach["rarity"]])
	)
	CareerState.level_up_triggered.connect(func(lvl: int, pts: int):
		AudioSynth.play_level_up()
		_show_toast("▲ NAIK LEVEL %d! (+%d SKILL POIN)" % [lvl, pts])
	)

	_show_home()
	if DisplayServer.get_name() != "headless":
		_build_splash_overlay()

func _build_splash_overlay() -> void:
	_splash_active = true
	_splash_timer = 0.0
	_splash_panel = ColorRect.new()
	_splash_panel.color = Color("#040914")
	_splash_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_splash_panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.custom_minimum_size = Vector2(300, 180)
	vb.offset_left = -150
	vb.offset_right = 150
	vb.offset_top = -90
	vb.offset_bottom = 90
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	_splash_panel.add_child(vb)

	_splash_ball = TextureRect.new()
	_splash_ball.texture = load("res://assets/sprites/ui/logo_ball.png")
	_splash_ball.custom_minimum_size = Vector2(54, 54)
	_splash_ball.pivot_offset = Vector2(27, 27)
	_splash_ball.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_splash_ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vb.add_child(_splash_ball)

	var t := Label.new()
	t.text = "FOOTBALL\nUNITY"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", UITheme.get_display_font())
	t.add_theme_font_size_override("font_size", 26)
	vb.add_child(t)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color("#1B2838")
	bar_bg.custom_minimum_size = Vector2(240, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(bar_bg)

	_splash_bar = ColorRect.new()
	_splash_bar.color = UITheme.ACCENT_GOLD
	_splash_bar.custom_minimum_size = Vector2(0, 8)
	_splash_bar.size = Vector2(10, 8)
	bar_bg.add_child(_splash_bar)

	_splash_lbl = Label.new()
	_splash_lbl.text = "0%"
	_splash_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_splash_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_splash_lbl.add_theme_font_size_override("font_size", 11)
	vb.add_child(_splash_lbl)

func _process(delta: float) -> void:
	if _splash_active and _splash_panel != null:
		_splash_timer += delta
		var p: float = clampf(_splash_timer / 0.85, 0.0, 1.0)
		_splash_ball.rotation += delta * 4.5
		_splash_bar.size.x = 240.0 * p
		_splash_lbl.text = "%d%%" % int(p * 100.0)
		if p >= 1.0:
			_splash_active = false
			_splash_panel.queue_free()
			_splash_panel = null
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_panel.visible = false

func _show_toast(msg: String) -> void:
	_toast_lbl.text = msg
	_toast_panel.visible = true
	_toast_timer = 3.2

func _on_crt_toggled(enabled: bool) -> void:
	_crt_rect.visible = enabled

func _clear_stage() -> void:
	for c in _stage_layer.get_children():
		_stage_layer.remove_child(c)
		c.queue_free()
	_home_screen = null
	_career_shell = null

func _show_home() -> void:
	_clear_stage()
	AudioSynth.bgm_track_override = "HOME"
	var HomeScript := load("res://scenes/main/HomeScreen.gd")
	_home_screen = HomeScript.new()
	_home_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_home_screen.continue_career.connect(func(slot_id: int):
		if CareerState.load_slot(slot_id):
			_show_career_shell()
	)
	_home_screen.open_home_apartment.connect(func(slot_id: int):
		if CareerState.load_slot(slot_id):
			_launch_city("APARTEMEN", true)
	)
	_home_screen.start_new_career_slot.connect(func(slot_id: int): _open_new_career_modal(slot_id))
	_home_screen.open_practice.connect(func(): _launch_match_practice())
	_home_screen.open_volley_practice.connect(func(): _launch_volley_minigame(false))
	_home_screen.open_city_practice.connect(func(): _launch_city("STADION", false))
	_home_screen.open_friends.connect(func(): _open_friends_modal())
	_home_screen.open_koleksi.connect(func(): _open_koleksi_modal())
	_home_screen.open_settings.connect(func(): _open_settings_modal())
	_home_screen.open_editor.connect(func(): _open_editor_modal())
	_home_screen.open_shop.connect(func(): _open_cosmetics_shop())
	_stage_layer.add_child(_home_screen)

func _show_career_shell() -> void:
	_clear_stage()
	AudioSynth.bgm_track_override = "HOME"
	var ShellScript := load("res://scenes/main/CareerShell.gd")
	_career_shell = ShellScript.new()
	_career_shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	_career_shell.back_to_home.connect(func(): _show_home())
	_career_shell.start_match_requested.connect(func(): _launch_career_match())
	_career_shell.sim_match_requested.connect(func(): _handle_quick_sim())
	_career_shell.open_dilemma_requested.connect(func(): _open_dilemma_modal())
	_career_shell.open_settings_requested.connect(func(): _open_settings_modal())
	_career_shell.open_friends_requested.connect(func(): _open_friends_modal())
	_career_shell.open_cosmetics_shop_requested.connect(func(): _open_cosmetics_shop())
	_career_shell.open_practice_requested.connect(func(): _launch_match_practice())
	_career_shell.inspect_player_requested.connect(func(pd: Dictionary, cl: Dictionary): _open_player_inspector(pd, cl))
	_career_shell.replay_clip_requested.connect(func(clip: Dictionary): _launch_moviola_replay(clip, true))
	_career_shell.open_city_requested.connect(func(lm: String, in_apt: bool): _launch_city(lm, in_apt))
	_career_shell.open_cutscene_requested.connect(func(m_idx: int): _open_cutscene(m_idx))
	_career_shell.open_volley_requested.connect(func(): _launch_volley_minigame(true))
	_career_shell.transfer_flow_requested.connect(func(offer: Dictionary): _transfer_step(1, offer))
	_career_shell.end_season_requested.connect(_on_end_season_requested)
	_stage_layer.add_child(_career_shell)

func _on_end_season_requested() -> void:
	if not CareerState.has_active_career:
		return
	var summary: Dictionary = CareerState.finalize_season_rollover()
	var ctx: Dictionary = CareerState.build_season_end_ceremony_context(summary)
	_open_season_end_ceremony_modal(ctx, func():
		_show_career_shell()
		if CareerState.has_active_career and bool(CareerState.career.get("contract", {}).get("isFreeAgent", false)):
			if _career_shell != null and _career_shell.has_method("switch_tab"):
				_career_shell.call("switch_tab", "DUNIA")
	)

func _launch_career_match(skip_pre_event: bool = false) -> void:
	if not skip_pre_event and CareerState.has_active_career:
		var prof: Dictionary = CareerState.career.get("playerProfile", {})
		var meta: Dictionary = CareerState.career.get("careerMeta", {})
		var wk: int = int(meta.get("week", 1))
		var fix: Dictionary = CareerState.get_current_fixture()
		var called_wks: Array = meta.get("timnasCalledWeeks", [])
		if str(fix.get("comp", "")) == "TIMNAS" and not called_wks.has(wk):
			_open_cutscene(25, func():
				if CareerState.has_active_career and int(CareerState.career["careerMeta"].get("week", 1)) == wk:
					var fx_after: Dictionary = CareerState.get_current_fixture()
					var m_after: Dictionary = CareerState.career.get("careerMeta", {})
					if CareerState.is_fixture_final(fx_after) and int(m_after.get("finalParadeDoneWeek", 0)) != wk:
						m_after["finalParadeDoneWeek"] = wk
						var pre_ctx_intl: Dictionary = CareerState.build_final_ceremony_context(fx_after)
						_open_final_ceremony_modal(0, pre_ctx_intl, func(): _launch_career_match(true))
					else:
						_launch_career_match(true)
				else:
					_show_career_shell()
			)
			return
		if CareerState.is_fixture_final(fix) and int(meta.get("finalParadeDoneWeek", 0)) != wk:
			meta["finalParadeDoneWeek"] = wk
			var pre_ctx: Dictionary = CareerState.build_final_ceremony_context(fix)
			_open_final_ceremony_modal(0, pre_ctx, func(): _launch_career_match(true))
			return
		var en: int = int(prof.get("energy", 80))
		var coach_rel: int = int(prof.get("relations", {}).get("pelatih", 60))
		if int(meta.get("preMatchDoneWeek", 0)) != wk:
			# Critical low energy / low coach relation warning
			if en < 35 or coach_rel < 30:
				meta["preMatchDoneWeek"] = wk
				_open_cutscene(6, func(): _launch_career_match(true))
				return
			# Automatic Pre-Match Event (throttled every 1-3 matches, strictly PRE timing!)
			if CareerState.consume_prematch_event_cooldown():
				meta["preMatchDoneWeek"] = wk
				if int(meta.get("dilemmaDoneWeek", 0)) != wk and (wk == 1 or wk % 2 == 1):
					CareerState.pick_contextual_dilemma("PRE")
					_open_dilemma_modal(func(): _launch_career_match(true))
					return
				var pre_modes: Array[int] = [31, 19, 20, 10, 7, 1] if wk <= 4 else [19, 20, 10, 7, 1]
				_open_cutscene(pre_modes[wk % pre_modes.size()], func(): _launch_career_match(true))
				return

	_clear_stage()
	AudioSynth.bgm_track_override = ""
	var ms: Node = (load("res://scenes/match/MatchScene.tscn") as PackedScene).instantiate()
	ms.call("configure_career_match")
	ms.connect("match_completed", func(report: Dictionary): _show_post_match(report))
	ms.connect("mode_exited", func(): _show_career_shell())
	_stage_layer.add_child(ms)

func _launch_match_practice() -> void:
	var return_to_career := (_career_shell != null)
	_clear_stage()
	var ms: Node = (load("res://scenes/match/MatchScene.tscn") as PackedScene).instantiate()
	ms.call("configure_practice")
	ms.connect("mode_exited", func():
		if return_to_career:
			_show_career_shell()
		else:
			_show_home()
	)
	_stage_layer.add_child(ms)

func _launch_duel_match(friend_dict: Dictionary) -> void:
	var return_to_career := (_career_shell != null)
	_clear_stage()
	var ms: Node = (load("res://scenes/match/MatchScene.tscn") as PackedScene).instantiate()
	ms.call("configure_duel", friend_dict)
	ms.connect("mode_exited", func():
		if return_to_career:
			_show_career_shell()
		else:
			_show_home()
	)
	_stage_layer.add_child(ms)

func _launch_moviola_replay(clip: Dictionary, from_career: bool) -> void:
	_clear_stage()
	var ms: Node = (load("res://scenes/match/MatchScene.tscn") as PackedScene).instantiate()
	ms.call("configure_moviola_replay", clip)
	ms.connect("mode_exited", func():
		if from_career:
			_show_career_shell()
		else:
			_show_post_match(CareerState.last_match_report)
	)
	_stage_layer.add_child(ms)

func _show_post_match(report: Dictionary) -> void:
	_clear_stage()
	var pm: Node = (load("res://scenes/match/PostMatchOverlay.tscn") as PackedScene).instantiate()
	pm.call("show_report", report)
	pm.connect("replay_requested", func(clip: Dictionary): _launch_moviola_replay(clip, false))
	pm.connect("finished", func():
		_show_career_shell()
		_trigger_post_match_chain(report)
	)
	_stage_layer.add_child(pm)

func _handle_quick_sim() -> void:
	if not CareerState.has_active_career:
		return
	var report := CareerState.sim_current_match()
	if not report.is_empty():
		_trigger_post_match_chain(report)

func _trigger_post_match_chain(report: Dictionary) -> void:
	if not CareerState.has_active_career:
		return
	var final_trophy: Dictionary = report.get("final_trophy_won", {})
	if not final_trophy.is_empty():
		_open_final_ceremony_modal(1, final_trophy)
		return
	var timnas_trophy: Dictionary = report.get("timnas_trophy_won", {})
	if not timnas_trophy.is_empty():
		var TimOverlays: GDScript = load("res://scripts/ui/TimnasOverlays.gd") as GDScript
		if TimOverlays != null:
			TimOverlays.call("open_championship_celebration", self, timnas_trophy)
			return
	var ballon_gala: Dictionary = report.get("ballon_gala", {})
	var potm: Dictionary = report.get("potm_award", {})
	var poty: Dictionary = report.get("poty_award", {})
	if not ballon_gala.is_empty():
		if not potm.is_empty():
			_open_ballon_gala_modal(ballon_gala, func(): _open_cutscene(14))
		else:
			_open_ballon_gala_modal(ballon_gala)
		return
	if not potm.is_empty():
		if not poty.is_empty():
			_open_cutscene(14, func(): _open_cutscene(15))
		else:
			_open_cutscene(14)
		return
	if not poty.is_empty():
		_open_cutscene(15)
		return
	var rec_ev: Dictionary = report.get("record_event", {})
	if not rec_ev.is_empty() or bool(report.get("broke_club_record", false)):
		_open_cutscene(28)
		return

	if not CareerState.consume_event_cooldown():
		return
	var meta: Dictionary = CareerState.career.get("careerMeta", {})
	var wk: int = int(meta.get("week", 1))
	if int(meta.get("dilemmaDoneWeek", 0)) != wk and (wk % 2 == 0 or bool(report.get("won_derby", false))):
		CareerState.pick_contextual_dilemma("POST", report)
		_open_dilemma_modal()
		return
	var post_mode: int = _pick_post_match_event(report, false)
	if post_mode >= 0:
		_open_cutscene(post_mode)

func _pick_post_match_event(report: Dictionary, check_cd: bool = true) -> int:
	if not CareerState.has_active_career:
		return -1
	# Throttle narrative/minigame events so they only appear once every 1-3 matches
	if check_cd and not CareerState.consume_event_cooldown():
		return -1
	var meta: Dictionary = CareerState.career.get("careerMeta", {})
	var sp: Dictionary = CareerState.career.get("sponsor", {})
	var wk: int = int(meta.get("week", 1))
	var won: bool = int(report.get("score_us", 0)) > int(report.get("score_them", 0))
	var draw: bool = int(report.get("score_us", 0)) == int(report.get("score_them", 0))
	var rtg: float = float(report.get("rating", 6.2))
	if not bool(meta.get("initiationDone", false)):
		return 3  # MAKAN_NYANYI (team initiation dinner)
	if bool(report.get("broke_club_record", false)):
		return 28  # CLUB_RECORD_GOALS
	if int(report.get("my_goals", 0)) >= 3:
		return 16  # HAT_TRICK_MIC (3+ goals TV interview)
	var fix: Dictionary = report.get("fixture", {})
	if won and not bool(fix.get("is_home", true)) and rtg >= 7.5 and wk % 2 == 1:
		return 17  # AWAY_OVATION (away fans applaud strong away win)
	if wk % 6 == 4:
		return 30  # PUNDIT_DEBATE (TV pundits debate performance)
	if (won or draw) and wk % 6 == 2:
		return 29  # TRIBUN_RAPI (fans clean stands spotlight)
	if wk % 5 == 3:
		return 27  # SUIT_MINIGAME (bench rock-paper-scissors)
	if bool(report.get("motm", false)) or int(report.get("my_goals", 0)) >= 2:
		return 13 if (wk % 2 == 0 and int(meta.get("scoutedByClubId", -1)) < 0) else 8  # SCOUT_DOSSIER or MVP_SHOWCASE
	if (won or draw) and wk % 4 == 1:
		return 11  # LEMPAKAN_JERSEY (celebrate with fans only after positive result)
	if won and wk % 4 == 2:
		return 12  # GUNTUR_DRUM (fan chant celebration after win)
	if (won or draw) and wk % 4 == 3:
		return 18  # JERSEY_SWAP (post-match shirt exchange)
	if rtg >= 7.3 and wk % 3 == 0:
		return 13  # SCOUT_DOSSIER (only when form impresses scouts!)
	if not str(sp.get("activeId", "")).is_empty() and (int(meta.get("clapperDoneSeason", 0)) != int(meta.get("year", 1)) or wk % 5 == 0):
		return 4  # SPONSOR_SHOOT Take 7
	if rtg >= 7.1:
		return 5  # COACH_TRAIT (earned on strong match rating)
	if int(meta.get("transferWindowWeeksLeft", 0)) > 0:
		return 0  # BURSA_CARDS
	return 9 if (won or draw or wk % 2 == 1) else 5

func _open_new_career_modal(slot_id: int) -> void:
	var m: Control = (load("res://scenes/modals/NewCareerModal.gd") as GDScript).new()
	m.call("configure", slot_id)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.connect("career_created", func(_s: int):
		_show_career_shell()
		_open_cutscene(0, func(): _open_cutscene(2))  # BURSA_CARDS -> PIDATO_SKUAD
	)
	_modal_layer.add_child(m)

func _launch_volley_minigame(return_to_career: bool) -> void:
	_clear_stage()
	AudioSynth.bgm_track_override = ""
	var mg: Control = (load("res://scenes/minigames/VolleyMinigame.gd") as GDScript).new()
	mg.set_anchors_preset(Control.PRESET_FULL_RECT)
	mg.connect("exited", func():
		if return_to_career:
			_show_career_shell()
		else:
			_show_home()
	)
	_stage_layer.add_child(mg)

func _launch_city(target_lm: String, start_inside_apt: bool) -> void:
	_clear_stage()
	AudioSynth.bgm_track_override = "HOME"
	var city: Node3D = (load("res://scenes/city/CityScene.gd") as GDScript).new()
	city.call("configure", target_lm, start_inside_apt)
	city.connect("exited", func():
		if CareerState.has_active_career:
			_show_career_shell()
		else:
			_show_home()
	)
	city.connect("start_match_from_city", func(): _launch_career_match())
	_stage_layer.add_child(city)

func _transfer_step(step: int, offer: Dictionary) -> void:
	# 1 TEKEN KONTRAK -> 2 BANDARA -> 3 NOMOR PUNGGUNG (resmi pindah) -> 4 REKRUTAN BARU -> daftar skuad -> pidato
	if step > 4:
		_open_cutscene(1, func(): _open_cutscene(2))
		return
	var scr: GDScript = load("res://scenes/modals/EventCutsceneModal.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		push_error("Failed to load EventCutsceneModal.gd during transfer step")
		return
	var cm: Control = scr.new()
	cm.call("configure", 20 + step)
	cm.set("transfer_offer", offer)
	cm.set_anchors_preset(Control.PRESET_FULL_RECT)
	cm.connect("finished", func(): _transfer_step(step + 1, offer))
	_modal_layer.add_child(cm)

func _open_season_end_ceremony_modal(ctx: Dictionary, on_done: Callable = Callable()) -> void:
	var scr: GDScript = load("res://scenes/modals/SeasonEndCeremonyModal.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		push_error("Failed to load SeasonEndCeremonyModal.gd")
		if on_done.is_valid():
			on_done.call()
		return
	var sm: Control = scr.new()
	sm.call("configure", ctx)
	sm.set_anchors_preset(Control.PRESET_FULL_RECT)
	if on_done.is_valid():
		sm.connect("finished", on_done)
	_modal_layer.add_child(sm)

func _open_final_ceremony_modal(mode_idx: int, ctx: Dictionary, on_done: Callable = Callable()) -> void:
	var scr: GDScript = load("res://scenes/modals/FinalCeremonyModal.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		push_error("Failed to load FinalCeremonyModal.gd for mode %d" % mode_idx)
		if on_done.is_valid():
			on_done.call()
		return
	var fm: Control = scr.new()
	fm.call("configure", mode_idx, ctx)
	fm.set_anchors_preset(Control.PRESET_FULL_RECT)
	if on_done.is_valid():
		fm.connect("finished", on_done)
	_modal_layer.add_child(fm)

func _open_ballon_gala_modal(gala_data: Dictionary, on_done: Callable = Callable()) -> void:
	var scr: GDScript = load("res://scenes/modals/BallonGalaModal.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		push_error("Failed to load BallonGalaModal.gd")
		if on_done.is_valid():
			on_done.call()
		return
	var gm: Control = scr.new()
	gm.call("configure", gala_data)
	gm.set_anchors_preset(Control.PRESET_FULL_RECT)
	if on_done.is_valid():
		gm.connect("finished", on_done)
	_modal_layer.add_child(gm)

func _open_cutscene(mode_idx: int, on_done: Callable = Callable()) -> void:
	var scr: GDScript = load("res://scenes/modals/EventCutsceneModal.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		push_error("Failed to load EventCutsceneModal.gd for mode %d" % mode_idx)
		if on_done.is_valid():
			on_done.call()
		return
	var cm: Control = scr.new()
	cm.call("configure", mode_idx)
	cm.set_anchors_preset(Control.PRESET_FULL_RECT)
	cm.connect("launch_volley_training", func(): _launch_volley_minigame(true))
	if on_done.is_valid():
		cm.connect("finished", on_done)
	_modal_layer.add_child(cm)

func _open_dilemma_modal(on_done: Callable = Callable()) -> void:
	var m: Control = (load("res://scenes/modals/DilemmaModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	if on_done.is_valid():
		m.connect("closed", on_done)
	_modal_layer.add_child(m)

func _open_settings_modal() -> void:
	var m: Control = (load("res://scenes/modals/SettingsModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.connect("open_editor_requested", func(): _open_editor_modal())
	m.connect("slot_loaded", func(): _show_career_shell())
	_modal_layer.add_child(m)

func _open_koleksi_modal() -> void:
	var m: Control = (load("res://scenes/modals/KoleksiModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(m)

func _open_friends_modal() -> void:
	var m: Control = (load("res://scenes/modals/TemanModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.connect("start_duel_requested", func(fd: Dictionary): _launch_duel_match(fd))
	_modal_layer.add_child(m)

func _open_editor_modal() -> void:
	var m: Control = (load("res://scenes/modals/EditorModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(m)

func _open_cosmetics_shop() -> void:
	var m: Control = (load("res://scenes/modals/CosmeticsShopModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(m)

func _open_player_inspector(pd: Dictionary, cl: Dictionary) -> void:
	var m: Control = (load("res://scenes/modals/PlayerInspectorModal.gd") as GDScript).new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(m)
	m.call("show_player", pd, cl)
