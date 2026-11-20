extends SceneTree

var _out_dir: String = ""

func _initialize() -> void:
	var env_dir: String = OS.get_environment("CAPTURE_OUT_DIR").strip_edges()
	if env_dir.is_empty():
		_out_dir = ProjectSettings.globalize_path("user://visual_captures/")
	else:
		_out_dir = env_dir if env_dir.ends_with("/") else (env_dir + "/")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	call_deferred("_capture")

func _wait_frames(n: int = 4) -> void:
	for _i in range(n):
		await process_frame

func _snap(filename: String) -> void:
	await _wait_frames(5)
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png(_out_dir + filename)
		print("Captured: ", filename, " size=", img.get_size())

func _capture() -> void:
	var CareerState: Node = root.get_node("CareerState")
	var AppRootPacked: PackedScene = load("res://scenes/main/AppRoot.tscn")
	var app: Control = AppRootPacked.instantiate()
	root.add_child(app)

	# 1. Splash Loading Screen -> Home Screen (empty / slot preview)
	await _snap("21_splash_loading.png")
	if app._splash_panel != null:
		app._splash_active = false
		app._splash_panel.queue_free()
		app._splash_panel = null
	await _snap("01_home.png")

	# 1b. New Career Onboarding Wizard captures (Step 1 -> Step 2 Offers -> Brasil Div 3 Browser -> Step 3 KESULITAN -> Step 4 BURSA DIBUKA)
	var WizardScript: GDScript = load("res://scenes/modals/NewCareerModal.gd")
	var wiz: Control = WizardScript.new()
	wiz.configure(1)
	wiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	app._modal_layer.add_child(wiz)
	await _snap("08_wizard_create_player.png")

	wiz._custom_tab = "POTONGAN"
	wiz._render_step()
	await _snap("22_wizard_potongan.png")
	wiz._custom_tab = "KAU"
	wiz._render_step()

	wiz._step = wiz.WizardStep.CHOOSE_CLUB
	wiz._render_step()
	await _snap("09_wizard_offers.png")

	wiz._browser_nat_idx = 18  # Brasil
	wiz._browser_div = 3
	wiz.call("_open_club_browser_popup")
	await _snap("10_wizard_pilih_klub_div3.png")
	wiz.call("_clear_sub_modals")

	wiz._step = wiz.WizardStep.CHOOSE_MODE
	wiz._render_step()
	await _snap("11_wizard_kesulitan.png")

	wiz._step = wiz.WizardStep.SEASON_INTRO
	wiz._render_step()
	await _snap("13_wizard_bursa_dibuka.png")
	wiz.queue_free()
	await _wait_frames(3)

	# 2. Start a sample career in Slot 1 (matching ALFIAN / Div 3 Brasil) and show KINI + ENERGI popup
	CareerState.start_new_career(1, "ALFIAN", 16, "ST", "Sao Luis Tricolor")
	# Record 2 sample shots so Shot Map has visual data too!
	CareerState.career["shotTelemetry"].append({
		"season": 1, "matchId": "W01", "type": "OPEN_PLAY", "outcome": "GOAL",
		"pitchCoord": {"x": 0.48, "y": 0.84}, "goalCoord": {"x": 0.72, "y": 0.65}, "distanceMeters": 16.5
	})
	CareerState.career["shotTelemetry"].append({
		"season": 1, "matchId": "W01", "type": "OPEN_PLAY", "outcome": "ON_TARGET",
		"pitchCoord": {"x": 0.54, "y": 0.76}, "goalCoord": {"x": 0.35, "y": 0.48}, "distanceMeters": 21.0
	})
	app.call("_show_career_shell")
	await _snap("02_kini.png")

	app._career_shell.call("_show_energy_modal")
	await _snap("12_energy_modal.png")
	app._career_shell._energy_modal.visible = false
	await _wait_frames(2)

	# 3. PEMAINKU
	app._career_shell.call("switch_tab", "PEMAINKU")
	await _snap("03_pemainku.png")
	var ptab: Control = app._career_shell._pemainku_tab
	ptab._subtab = "GAYA"
	ptab._gaya_sub = "LOOK"
	ptab.call("refresh")
	await _snap("23_pemainku_gaya_look.png")
	ptab._subtab = "SKILL"
	ptab.call("refresh")

	# 4. TIMKU
	app._career_shell.call("switch_tab", "TIMKU")
	await _snap("04_timku.png")

	# 5. DUNIA
	app._career_shell.call("switch_tab", "DUNIA")
	await _snap("05_dunia.png")

	# 6. WARISAN -> PETA TEMBAKAN
	app._career_shell.call("switch_tab", "WARISAN")
	app._career_shell._warisan_tab._subtab = "PETA"
	app._career_shell._warisan_tab.call("refresh")
	await _snap("06_warisan_peta.png")

	# 7. New Feature Visual Captures (TIM INTI, PIDATO, TEKEN CLAPPER, VOLI, KOTA 3D, MATCH BOARD & HALFTIME)
	app.call("_open_cutscene", 1)  # TIM_INTI
	await _snap("14_cutscene_tim_inti.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 2)  # PIDATO_SKUAD
	await _snap("15_cutscene_pidato.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 4)  # SPONSOR_SHOOT (TEKEN CLAPPER TAKE 7)
	await _snap("16_cutscene_clapper.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	CareerState.career["lastMatch"] = {"rating": 9.1, "my_goals": 2, "my_assists": 1}
	app.call("_open_cutscene", 8)  # MVP_SHOWCASE
	await _snap("24_cutscene_mvp.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 6)  # COACH_REJECT
	await _snap("25_cutscene_coach_reject.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	# New 3 Cutscenes & Minigames
	app.call("_open_cutscene", 9)  # TEKEN_JERSEY
	await _snap("32_cutscene_teken_jersey.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 10)  # PREMATCH_PREDIKSI + Top Skor Spotlight
	await _snap("33_cutscene_prediksi.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 11)  # LEMPAKAN_JERSEY
	await _snap("34_cutscene_lempakan_jersey.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 12)  # GUNTUR_DRUM
	await _snap("35_cutscene_guntur_drum.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_open_cutscene", 13)  # SCOUT_DOSSIER (with scouting club's logo on dossier & pill!)
	await _snap("36_cutscene_scout_dossier.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	CareerState.evaluate_player_of_the_month(3)
	app.call("_open_cutscene", 14)  # POTM_AWARD
	await _snap("44_cutscene_potm_award.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	CareerState.evaluate_player_of_the_year(1, 1)
	app.call("_open_cutscene", 15)  # POTY_AWARD
	await _snap("45_cutscene_poty_award.png")
	app._modal_layer.get_child(0).queue_free()
	await _wait_frames(2)

	app.call("_launch_volley_minigame", true)
	await _wait_frames(8)
	var vmg: Node = app._stage_layer.get_child(0)
	vmg._playing = true
	vmg.call("_spawn_ball")
	await _wait_frames(18)
	await _snap("17_minigame_voli.png")

	app.call("_launch_city", "SNEAKERS", false)
	await _wait_frames(10)
	await _snap("18_city_3d.png")

	# 8. Pre-Match Animated Lineup Showcase -> 2D Live Match Board (Portraits, >2 Cards, Coach Sub) -> Halftime -> 2.5D Match Scene
	app.call("_launch_career_match", true)
	await create_timer(2.0).timeout
	await _wait_frames(4)
	var ms: Node = app._stage_layer.get_child(0)
	await _snap("41_match_lineup_intro.png")

	ms.call("_start_match_kickoff")
	ms.set("_halftime_done", true)
	ms.set("_board_paused", true)
	ms.set("_minute", 14.0)
	var gk_p: Dictionary = ms.call("_pick_roster_player", false, true, false)
	ms.call("_add_rich_board_highlight", 14, "SAVE", "PENYELAMATAN %s!" % str(gk_p.get("name", "KIPER")), "Kiper menepis sepakan keras jarak dekat!", gk_p, {}, false)
	ms.set("_minute", 21.0)
	ms.call("_trigger_match_card", false, false)
	ms.set("_minute", 29.0)
	ms.call("_trigger_match_card", false, false)
	ms.set("_minute", 37.0)
	ms.call("_trigger_match_card", false, false)
	ms.set("_minute", 41.0)
	ms.call("_trigger_match_injury", true, 0, -1)
	ms.set("_minute", 54.0)
	ms.set("_score_us", 2)
	ms.set("_score_them", 1)
	var u_p: Dictionary = ms.call("_get_user_roster_dict")
	var ast_p: Dictionary = ms.call("_pick_roster_player", true, false, false)
	ms.call("_add_rich_board_highlight", 54, "GOAL", "GOL! %s" % str(u_p.get("name", "PEMAIN")), "Assist brilian: %s!" % str(ast_p.get("name", "REKAN")), u_p, ast_p, true)
	ms.call("_sync_board_hud")
	await _wait_frames(6)
	await _snap("19_match_2d_board.png")

	ms.set("_minute", 68.0)
	ms.set("_user_match_energy", 18.0)
	ms.call("_check_coach_user_substitution")
	ms.call("_sync_board_hud")
	await _wait_frames(6)
	await _snap("42_match_coach_sub_highlights.png")
	ms.set("_board_paused", false)
	ms.set("_user_subbed_out", false)
	ms.set("_user_match_energy", 82.0)

	ms.call("_open_halftime_locker")
	await _snap("20_match_halftime.png")
	ms._halftime_panel.visible = false

	ms.call("_trigger_key_moment", 0)  # Unified Open Play: TEMBAK / UMPAN + Joystick + Stamina + Slingshot
	await _wait_frames(8)
	await _snap("26_match_openplay_modes.png")

	ms._dribble_input = Vector2(0.55, -0.83)
	ms._dribble_pad._active = true
	ms._dribble_pad.joy_vec = Vector2(0.55, -0.83)
	ms._dribble_pad.queue_redraw()
	ms.call("_process_dribble_control", 0.08)
	await _wait_frames(8)
	await _snap("31_match_dribble_joystick.png")

	ms._dribble_input = Vector2.ZERO
	ms._dribble_pad.reset_joy()
	ms._dragging = true
	ms._drag_start = Vector2(480, 310)
	ms._drag_current = Vector2(525, 420)
	ms.call("_draw_aim_and_ring")
	await _wait_frames(10)
	await _snap("28_match_pass_movement.png")

	ms.call("_trigger_key_moment", 5)  # TEAMMATE_PENALTY: kicker + player & defenders poised on box arc!
	await _wait_frames(8)
	await _snap("29_match_teammate_penalty.png")

	ms._ball_pos = Vector3(1.8, 0.45, -45.5)
	ms._ball_vel = Vector3(-1.2, 1.5, 4.2)
	ms.call("_enter_rebound_scramble", "DITEPIS KIPER! BEREBUT REBOUND!")
	await _wait_frames(16)
	await _snap("30_match_rebound_scramble.png")

	ms.call("_trigger_key_moment", 0)
	ms.call("_open_pause_menu")
	await _snap("27_match_jeda_pause.png")
	ms._is_paused = false
	if is_instance_valid(ms._pause_panel):
		ms._pause_panel.queue_free()

	ms.call("_trigger_key_moment", 3)  # FREE_KICK with wall + 3 stationary optimal teammates!
	ms._dragging = true
	ms._drag_start = Vector2(480, 300)
	ms._drag_current = Vector2(505, 430)
	ms._spin_offset = Vector2(-0.75, 0.05)
	ms.call("_draw_aim_and_ring")
	await _wait_frames(12)
	await _snap("07_match_25d_slingshot.png")

	# Offside live visual warning (red teammate ring + dashed red offside line across pitch)
	ms.call("_trigger_key_moment", 0)
	for di in range(ms._defender_positions.size()):
		ms._defender_positions[di] = Vector3(float(di - 1) * 5.0, 0.0, -37.0)
	ms._teammate_positions[0] = Vector3(4.5, 0.0, -44.5)
	ms.call("_sync_3d_sprites")
	ms.call("_draw_aim_and_ring")
	await _wait_frames(6)
	await _snap("37_match_offside_warning.png")

	# New Interactive Moments: Aerial Cross Header QTE, 1v1 Dribble Duel QTE, Long Pass Control QTE
	ms.call("_trigger_key_moment", ms.MomentType.HEADER_CROSS)
	ms._drag_start = Vector2(480, 290)
	ms._drag_current = Vector2(495, 420)
	ms.call("_release_slingshot")
	ms._qte_progress = 0.72
	ms.call("_process_header_timing", 0.02)
	await _wait_frames(4)
	await _snap("38_match_header_qte.png")

	ms.call("_trigger_key_moment", ms.MomentType.DRIBBLE_DUEL)
	ms._qte_progress = 0.88
	ms.call("_process_qte_dribble_duel", 0.02)
	await _wait_frames(4)
	await _snap("39_match_dribble_duel_qte.png")

	ms.call("_trigger_key_moment", ms.MomentType.LONG_PASS_CONTROL)
	ms._qte_progress = 0.96
	ms.call("_process_qte_long_control", 0.02)
	await _wait_frames(4)
	await _snap("40_match_long_control_qte.png")

	# Defender Slide-Tackle Interception on Incoming Pass
	ms.call("_trigger_key_moment", ms.MomentType.TEAMMATE_PASS)
	ms.set("_incoming_pass_kicked", true)
	var bpos_s: Vector3 = ms.get("_ball_pos")
	var upos_s: Vector3 = ms.get("_player_pos")
	var mid_s: Vector3 = bpos_s.lerp(upos_s, 0.35)
	var d_arr: Array[Vector3] = [Vector3(mid_s.x + 1.5, 0.0, mid_s.z - 1.2), Vector3(-6.0, 0.0, -40.0), Vector3(6.0, 0.0, -40.0)]
	ms.set("_defender_positions", d_arr)
	ms.call("_process_incoming_pass", 0.04)
	ms.call("_sync_3d_sprites")
	await _wait_frames(2)
	await _snap("43_match_defender_slide.png")

	# Batch B Captures: Corner Kick (User Taker Curved Aim), GK Build-Up, & Controlled Teammate
	ms.call("setup_corner_variant", true)
	ms._dragging = true
	ms._drag_start = Vector2(480, 310)
	ms._drag_current = Vector2(495, 445)
	ms._spin_offset = Vector2(-0.7, 0.05)
	ms.call("_draw_aim_and_ring")
	await _wait_frames(8)
	await _snap("46_match_corner_kick.png")

	ms.call("_trigger_key_moment", ms.MomentType.GK_BUILDUP)
	ms.set("_incoming_pass_kicked", true)
	ms.set("_incoming_pass_timer", 0.65)
	ms.call("_process_incoming_pass", 0.08)
	await _wait_frames(8)
	await _snap("47_match_gk_buildup.png")

	ms.call("_trigger_key_moment", ms.MomentType.SHOT)
	ms.call("_enter_teammate_user_control", 0, true)
	await _wait_frames(8)
	await _snap("48_match_teammate_control.png")

	# Clean up test save slot 1 so Home Screen starts clean!
	CareerState.delete_slot(1)
	quit(0)
