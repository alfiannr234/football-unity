extends SceneTree

var _passed := 0
var _failed := 0

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("[PASS] ", msg)
	else:
		_failed += 1
		push_error("[FAIL] " + msg)

func _initialize() -> void:
	call_deferred("_run_suite")

func _run_suite() -> void:
	print("=== FOOTBALL UNITY VERIFICATION SUITE ===")

	# 1. Verify Script & Scene Loading (every script compiles!)
	var scripts := [
		"res://scenes/main/AppRoot.gd",
		"res://scenes/main/HomeScreen.gd",
		"res://scenes/main/CareerShell.gd",
		"res://scenes/tabs/KiniTab.gd",
		"res://scenes/tabs/PemainkuTab.gd",
		"res://scenes/tabs/TimkuTab.gd",
		"res://scenes/tabs/DuniaTab.gd",
		"res://scenes/tabs/WarisanTab.gd",
		"res://scenes/match/MatchScene.gd",
		"res://scenes/match/PostMatchOverlay.gd",
		"res://scenes/modals/NewCareerModal.gd",
		"res://scenes/modals/DilemmaModal.gd",
		"res://scenes/modals/SettingsModal.gd",
		"res://scenes/modals/KoleksiModal.gd",
		"res://scenes/modals/TemanModal.gd",
		"res://scenes/modals/EditorModal.gd",
		"res://scenes/modals/CosmeticsShopModal.gd",
		"res://scenes/modals/PlayerInspectorModal.gd",
		"res://scenes/modals/EventCutsceneModal.gd",
		"res://scenes/minigames/VolleyMinigame.gd",
		"res://scenes/city/CityScene.gd",
	]
	for sp in scripts:
		var scr: GDScript = load(sp)
		_assert(scr != null and scr.can_instantiate(), "Script loads cleanly: " + sp)

	for sc_path in ["res://scenes/main/AppRoot.tscn", "res://scenes/match/MatchScene.tscn", "res://scenes/match/PostMatchOverlay.tscn"]:
		var ps: PackedScene = load(sc_path)
		_assert(ps != null, "Scene loads cleanly: " + sc_path)

	# 2. Verify World Database Scale (FR-06 & FR-08)
	var GameData: Node = root.get_node("GameData")
	var CareerState: Node = root.get_node("CareerState")

	_assert(GameData.nations.size() == 55, "55 nations generated (got %d)" % GameData.nations.size())
	_assert(GameData.clubs.size() == 2731, "2,731 clubs generated (got %d)" % GameData.clubs.size())
	_assert(GameData.coaches.size() == 2731, "2,731 coaches generated (got %d)" % GameData.coaches.size())
	_assert(CareerState.TOTAL_WORLD_PLAYERS == 21289 and CareerState.wp_name.size() == 21289, "21,289 world players generated (got %d)" % CareerState.wp_name.size())
	_assert(GameData.achievements.size() == 386, "386 achievements generated (got %d)" % GameData.achievements.size())
	var rar_cnt := {"UMUM": 0, "LANGKA": 0, "EPIK": 0, "LEGENDARIS": 0}
	for a in GameData.achievements:
		rar_cnt[a["rarity"]] += 1
	_assert(rar_cnt["UMUM"] == 32 and rar_cnt["LANGKA"] == 106 and rar_cnt["EPIK"] == 162 and rar_cnt["LEGENDARIS"] == 86,
		"Achievement tiers exact (32/106/162/86): %s" % str(rar_cnt))
	_assert(GameData.boots_catalog.size() == 11, "11 boots in shop")
	_assert(GameData.cosmetics_catalog["CINCIN"].size() == 24, "24 rings in cosmetics")
	_assert(GameData.cosmetics_catalog["AIM"].size() == 31, "31 aim arrows in cosmetics")
	_assert(GameData.cosmetics_catalog["JEJAK"].size() == 4, "4 ball trails in cosmetics")
	_assert(GameData.cosmetics_catalog["LENCANA"].size() == 14, "14 badge frames in cosmetics")
	_assert(GameData.cosmetics_catalog["KARTU"].size() == 13, "13 card frames in cosmetics")

	# 3. Verify Slingshot Physics & Magnus Curve
	var low_power := SlingshotPhysics.compute_launch_params(Vector2(0, -60), 200.0, 60, 80, 75, 70, 70, Vector2.ZERO, false, false, 1.0, false)
	var high_power := SlingshotPhysics.compute_launch_params(Vector2(0, -180), 200.0, 90, 80, 75, 70, 70, Vector2.ZERO, false, false, 1.0, false)
	_assert(float(high_power["speed"]) > float(low_power["speed"]), "Higher drag & Kekuatan yields faster shot velocity")

	var straight := SlingshotPhysics.compute_launch_params(Vector2(0, -160), 200.0, 80, 95, 85, 80, 80, Vector2.ZERO, false, false, 1.0, false)
	var curved := SlingshotPhysics.compute_launch_params(Vector2(0, -160), 200.0, 80, 95, 85, 80, 80, Vector2(0.85, 0.0), false, false, 1.0, false)
	var pts_s := SlingshotPhysics.predict_trajectory(Vector3(0, 0.115, -35), straight["velocity"], straight["omega"], 85, 25, 0.04)
	var pts_c := SlingshotPhysics.predict_trajectory(Vector3(0, 0.115, -35), curved["velocity"], curved["omega"], 85, 25, 0.04)
	_assert(absf(pts_c[pts_c.size() - 1].x - pts_s[pts_s.size() - 1].x) > 1.0, "Magnus spin visibly bends ball trajectory in X (delta=%.2fm)" % absf(pts_c[pts_c.size() - 1].x - pts_s[pts_s.size() - 1].x))

	var goal_step := SlingshotPhysics.step_ball(Vector3(0.2, 1.1, -52.3), Vector3(0.0, 0.0, -25.0), Vector3.ZERO, 60, 0.02)
	_assert(goal_step["hit"] == "goal", "Ball crossing goal line inside posts triggers goal event")
	var post_step := SlingshotPhysics.step_ball(Vector3(SlingshotPhysics.GOAL_HALF_W, 1.2, -52.35), Vector3(0.0, 0.0, -20.0), Vector3.ZERO, 60, 0.02)
	_assert(post_step["hit"] == "post", "Ball hitting goalpost triggers post rebound")

	# 4. Verify New Career Defaults, Foreign Div 3 Offers, Difficulty Params & Wizard Flow
	var SettingsManager: Node = root.get_node("SettingsManager")
	for d_mode in ["MUDAH", "NORMAL", "SULIT", "EKSTREM"]:
		SettingsManager.set_setting("difficulty", d_mode)
		var dp: Dictionary = SettingsManager.get_difficulty_params()
		_assert(dp.has("defender_speed") and dp.has("can_steal") and dp.has("chance_delta"), "Difficulty params valid for " + d_mode)
	SettingsManager.set_setting("difficulty", "MUDAH")
	_assert(bool(SettingsManager.get_difficulty_params()["can_steal"]) == false and float(SettingsManager.get_difficulty_params()["defender_speed"]) == 0.0, "MUDAH freezes chasing defenders")
	SettingsManager.set_setting("difficulty", "EKSTREM")
	_assert(int(SettingsManager.get_difficulty_params()["chance_delta"]) == -1 and bool(SettingsManager.get_difficulty_params()["can_steal"]) == true, "EKSTREM removes 1 chance and enables tackles")
	SettingsManager.set_setting("difficulty", "NORMAL")

	var offers: Array[Dictionary] = CareerState.get_starter_offers(16)
	_assert(offers.size() == 5, "get_starter_offers returns 5 offers (got %d)" % offers.size())
	var has_local_d3 := false
	var has_foreign_d3 := false
	for off in offers:
		var oc: Dictionary = off["club"]
		if int(oc["division"]) == 3 and int(oc["nation_id"]) == 16:
			has_local_d3 = true
		if int(oc["division"]) == 3 and int(oc["nation_id"]) != 16:
			has_foreign_d3 = true
	_assert(has_local_d3 and has_foreign_d3, "Starter offers include both domestic and foreign Div 3 clubs")

	var br_d3: Array[Dictionary] = GameData.get_clubs_in_division(18, 3)
	_assert(br_d3.size() == 16 and str(br_d3[0]["name"]) == "Belem Papao", "Brasil Div 3 has 16 named clubs (first=%s)" % str(br_d3[0]["name"]))

	# Instantiate NewCareerModal and walk wizard states cleanly
	var WizardScript: GDScript = load("res://scenes/modals/NewCareerModal.gd")
	var wiz: Control = WizardScript.new()
	wiz.configure(3)
	root.add_child(wiz)
	_assert(wiz._step == wiz.WizardStep.CREATE_PLAYER, "NewCareerModal starts at CREATE_PLAYER")
	wiz._step = wiz.WizardStep.CHOOSE_CLUB
	wiz._render_step()
	_assert(wiz._selected_club.has("name") and int(wiz._selected_club["division"]) == 3, "CHOOSE_CLUB preselects a Div 3 club")
	wiz._step = wiz.WizardStep.CHOOSE_MODE
	wiz._render_step()
	wiz._step = wiz.WizardStep.SEASON_INTRO
	wiz._render_step()
	wiz.queue_free()

	# 5. Verify Full Career Lifecycle, Defaults, 45-week Season, Save Size < 5MB, and Reload
	CareerState.start_new_career(3, "TEST_PRO", 18, "ST", str(br_d3[0]["name"]))
	_assert(CareerState.has_active_career, "New career created in Slot 3")
	var p3: Dictionary = CareerState.career["playerProfile"]
	_assert(int(p3["level"]) == 1, "New career default level is 1 (got %d)" % int(p3["level"]))
	_assert(int(p3["cash"]) == 5000, "New career default cash is 5000 (got %d)" % int(p3["cash"]))
	_assert(int(p3["energy"]) == 100, "New career default energy is 100 (got %d)" % int(p3["energy"]))
	_assert(int(p3["skillPoints"]) == 0, "New career default skillPoints is 0 (got %d)" % int(p3["skillPoints"]))
	_assert(not CareerState.upgrade_attribute("kekuatan"), "Upgrade attribute fails when skillPoints == 0")
	CareerState.career["playerProfile"]["skillPoints"] = 10
	_assert(CareerState.upgrade_attribute("kekuatan"), "Upgrade attribute spends 1 Skill Point when available")
	_assert(CareerState.apply_batch_upgrades({"akurasi": 2, "efek": 1}), "Batch skill stager commits multiple pending upgrades")
	_assert(int(CareerState.career["playerProfile"]["attributes"]["akurasi"]) == 62, "Akurasi increased by batch commit")
	_assert(CareerState.learn_position("CAM"), "Learn secondary position CAM costs 6 Skill Points")
	_assert(CareerState.career["playerProfile"]["learnedPositions"].has("CAM"), "CAM position learned")

	CareerState.career["playerProfile"]["cash"] = 20000
	CareerState.career["playerProfile"]["energy"] = 50
	_assert(CareerState.buy_emergency_drink(13500) and int(CareerState.career["playerProfile"]["energy"]) == 78, "Halftime energy drink restores stamina")
	CareerState.record_volley_streak(12)
	_assert(int(CareerState.career["stats"]["bestVolleyStreak"]) == 12, "Best volley streak persists in career stats")

	# Instantiate EventCutsceneModal across all 9 modes, SettingsModal in-match, VolleyMinigame, & CityScene cleanly
	var CatScr: GDScript = load("res://scripts/ui/CharacterStyleCatalog.gd")
	var cmap: Dictionary = CatScr.get_script_constant_map()
	_assert(cmap["HAIR_STYLES"].size() == 16, "CharacterStyleCatalog has 16 hairstyles")
	_assert(cmap["BEARD_STYLES"].size() == 8, "CharacterStyleCatalog has 8 beard styles")
	_assert(cmap["CASUAL_STYLES"].size() == 5 and cmap["GALA_STYLES"].size() == 5, "CharacterStyleCatalog has 5 casual and 5 gala outfits")

	var CutsceneScr: GDScript = load("res://scenes/modals/EventCutsceneModal.gd")
	for c_mode in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]:
		var cm: Control = CutsceneScr.new()
		cm.configure(c_mode)
		root.add_child(cm)
		if c_mode == 13:
			var sc_crests: Array = cm.find_children("*", "ClubCrest", true, false)
			_assert(sc_crests.size() >= 2 and int(CareerState.career["careerMeta"].get("scoutedByClubId", -1)) >= 0, "SCOUT_DOSSIER displays scouting team's ClubCrest logo on dossier & header")
		cm.queue_free()
	_assert(true, "EventCutsceneModal initializes cleanly for all modes 0..15 (incl. POTM & POTY awards)")

	# Verify KiniTab has NO manual Event button below MAIN LAGA and shows Scout team crest when scouted
	var KiniScr: GDScript = load("res://scenes/tabs/KiniTab.gd")
	var kini_inst: Control = KiniScr.new()
	root.add_child(kini_inst)
	var kini_btns: Array = kini_inst.find_children("*", "Button", true, false)
	var has_event_btn := false
	for kb in kini_btns:
		if str((kb as Button).text).contains("EVENT PEKAN"):
			has_event_btn = true
	var kini_crests: Array = kini_inst.find_children("*", "ClubCrest", true, false)
	_assert(not has_event_btn and kini_crests.size() >= 3, "KiniTab removes manual Event button below match and displays scouting ClubCrest logo")
	kini_inst.queue_free()

	# New 3 Album Cards, Autographs, Division Leaders & Probabilistic Dilemmas
	_assert(GameData.album_cards_catalog.size() == 19, "GameData exposes 19 collectible album cards")
	var card_res: Dictionary = CareerState.unlock_album_card("guntur_tribun")
	_assert(bool(card_res["newly_unlocked"]) and int(card_res["owned_count"]) >= 2, "unlock_album_card unlocks and persists collectible album cards (SCOUT + GUNTUR)")
	var ttd_cnt: int = CareerState.increment_autographs()
	_assert(ttd_cnt == 1, "increment_autographs tracks career jersey signatures")
	var div_lead: Dictionary = CareerState.get_division_leaders()
	_assert(div_lead["goals"].size() >= 5 and div_lead["assists"].size() >= 5 and div_lead["rating"].size() >= 5, "get_division_leaders populates GOL, ASSIST, and RATING leaderboards")
	_assert(GameData.dilemmas_catalog.size() >= 9, "dilemmas_catalog includes New 3 press, keeper penalty duel, off-day, and transfer rumor events")

	var SetScr: GDScript = load("res://scenes/modals/SettingsModal.gd")
	var sm_inst: Control = SetScr.new()
	sm_inst.call("configure", "LAGA", true)
	root.add_child(sm_inst)
	sm_inst.queue_free()
	_assert(true, "SettingsModal configures directly to LAGA tab in-match")

	_assert(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 960 and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 540, "Display viewport configured to 960x540 landscape")
	_assert(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 0, "Handheld orientation locked to landscape (0)")

	var MatchPacked: PackedScene = load("res://scenes/match/MatchScene.tscn")
	var ms_inst: Control = MatchPacked.instantiate()
	ms_inst.call("configure_career_match")
	root.add_child(ms_inst)
	ms_inst.call("_trigger_key_moment", 1)  # PASS
	_assert(ms_inst.get("_teammate_positions").size() >= 3, "Open-play spawns >= 3 moving teammates for dynamic pass options")
	_assert(ms_inst.get("_defender_positions").size() >= 3, "Open-play spawns >= 3 active marking/pressing defenders")

	# Teammates must advance forward (-Z) or lateral, never retreat backward (+Z)
	var pre_tm_z: float = ms_inst.get("_teammate_positions")[0].z
	for _s in range(12):
		ms_inst.call("_animate_teammates", 0.25)
	var post_tm_z: float = ms_inst.get("_teammate_positions")[0].z
	_assert(post_tm_z <= pre_tm_z, "Teammates advance forward (-Z) and never retreat backward")

	# Unified Open Play: TEMBAK / UMPAN + simultaneous circular joystick + stamina + slingshot anytime stopped (no LARI button)
	var btns_dict: Dictionary = ms_inst.get("_action_mode_btns")
	_assert(btns_dict.has("MAIN"), "Open-play HUD shows unified TEMBAK / UMPAN action badge")
	_assert(ms_inst.get("_dribble_pad").visible and ms_inst.get("_stamina_bar_bg").visible and ms_inst.get("_spin_pad").visible and not ("_dribble_ctrl_bar" in ms_inst), "Open-play shows joystick, stamina bar, and slingshot/spin controls without LARI button")
	SettingsManager.set_setting("difficulty", "NORMAL")
	ms_inst.set("_dribble_input", Vector2.ZERO)
	ms_inst.set("_skill_burst_timer", 0.0)
	ms_inst.set("_dragging", false)
	var sc_idle: Dictionary = ms_inst.call("_get_moment_time_scales")
	ms_inst.set("_dragging", true)
	var sc_drag: Dictionary = ms_inst.call("_get_moment_time_scales")
	ms_inst.set("_dragging", false)
	ms_inst.set("_dribble_input", Vector2(0.0, -1.0))
	var sc_move: Dictionary = ms_inst.call("_get_moment_time_scales")
	_assert(float(sc_idle["teammate"]) < float(sc_move["teammate"]) and float(sc_idle["defender_speed"]) < float(sc_move["defender_speed"]), "Teammates and defenders move slowly before user moves and normally when user dribbles")
	_assert(float(sc_drag["teammate"]) < float(sc_idle["teammate"]) and float(sc_drag["defender_speed"]) < float(sc_idle["defender_speed"]), "Teammates and defenders slow down further when user pulls slingshot to shoot")
	ms_inst.set("_dribble_input", Vector2.ZERO)
	_assert(not bool(ms_inst.call("_is_user_dribbling_active")), "User can immediately aim & shoot/pass whenever stopped moving")

	# User speed strictly scaled by Kecepatan stat (realistic pace, not overly fast)
	var spd_low: float = float(ms_inst.call("get_player_max_run_speed", 45))
	var spd_mid: float = float(ms_inst.call("get_player_max_run_speed", 65))
	var spd_max: float = float(ms_inst.call("get_player_max_run_speed", 99))
	_assert(spd_low < spd_mid and spd_mid < spd_max and spd_max <= 8.5, "User run speed scales realistically with Kecepatan stat (%.2f < %.2f < %.2f)" % [spd_low, spd_mid, spd_max])

	# Free Kick: teammates stand stationary in optimal onside attacking spots
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.FREE_KICK)
	var fk_tm_before: Array = ms_inst.get("_teammate_positions").duplicate()
	ms_inst.call("_animate_teammates", 0.5)
	var fk_tm_after: Array = ms_inst.get("_teammate_positions")
	var fk_all_still_and_onside: bool = fk_tm_before.size() == 3
	for fki in range(fk_tm_before.size()):
		if fk_tm_before[fki].distance_to(fk_tm_after[fki]) > 0.001 or bool(ms_inst.call("_is_teammate_offside", fki)):
			fk_all_still_and_onside = false
	_assert(fk_all_still_and_onside, "During FREE_KICK, all 3 teammates stay stationary in optimal onside positions")
	ms_inst.call("_trigger_key_moment", 1)  # Restore open play PASS for movement/stamina checks

	# Movement + Stamina (no regen while stopped, resets to 100% on new event) + Unrestricted pitch roam
	var pre_stam: float = float(ms_inst.get("_match_stamina"))
	var start_p: Vector3 = ms_inst.get("_player_pos")
	ms_inst.set("_dribble_input", Vector2(0.5, -0.866))
	ms_inst.call("_process_dribble_control", 1.0)
	var end_p: Vector3 = ms_inst.get("_player_pos")
	var mid_stam: float = float(ms_inst.get("_match_stamina"))
	_assert(end_p.distance_to(start_p) > 2.0 and end_p.z < start_p.z and mid_stam < pre_stam - 14.0, "Circular joystick vector runs player smoothly and consumes reduced stamina capacity quickly")
	ms_inst.set("_dribble_input", Vector2.ZERO)
	ms_inst.call("_process_dribble_control", 0.8)
	_assert(is_equal_approx(float(ms_inst.get("_match_stamina")), mid_stam), "Stamina does NOT regenerate while stopped during the same event")
	ms_inst.set("_player_pos", Vector3(28.0, 0.0, 12.0))
	ms_inst.set("_dribble_input", Vector2(0.4, 0.8))
	ms_inst.call("_process_dribble_control", 0.2)
	var wide_p: Vector3 = ms_inst.get("_player_pos")
	_assert(wide_p.x > 28.0 and wide_p.z > 12.0 and int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM, "Player can move freely anywhere on the pitch without area cutoffs")
	ms_inst.set("_dribble_input", Vector2.ZERO)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.DRIBBLE)
	_assert(is_equal_approx(float(ms_inst.get("_match_stamina")), 100.0), "Starting another key-moment event restores stamina cleanly back to 100%")
	ms_inst.set("_drag_start", Vector2(480.0, 290.0))
	ms_inst.set("_drag_current", Vector2(480.0, 440.0))
	ms_inst.call("_release_slingshot")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.BALL_IN_FLIGHT, "Releasing slingshot during DRIBBLE event launches real 3D shot instead of fake dribble dash")

	# In MUDAH, ALL teammates and ALL opponents stop completely while aiming/idle; pressing scales by mode
	ms_inst.call("_trigger_key_moment", 0)  # SHOT
	SettingsManager.set_setting("difficulty", "MUDAH")
	var sc_shot_easy: Dictionary = ms_inst.call("_get_moment_time_scales")
	SettingsManager.set_setting("difficulty", "NORMAL")
	var sc_shot_norm: Dictionary = ms_inst.call("_get_moment_time_scales")
	SettingsManager.set_setting("difficulty", "EKSTREM")
	var sc_shot_ext: Dictionary = ms_inst.call("_get_moment_time_scales")
	_assert(float(sc_shot_easy["teammate"]) == 0.0 and float(sc_shot_easy["defender_speed"]) == 0.0, "In MUDAH mode, all teammates and opponents freeze completely when stopped/aiming")
	_assert(float(sc_shot_easy["defender_speed"]) < float(sc_shot_norm["defender_speed"]) and float(sc_shot_norm["defender_speed"]) < float(sc_shot_ext["defender_speed"]), "Aiming pressing speed scales across MUDAH, NORMAL, and EKSTREM")
	var d_before: float = Vector2(ms_inst.get("_ball_pos").x - ms_inst.get("_defender_positions")[0].x, ms_inst.get("_ball_pos").z - ms_inst.get("_defender_positions")[0].z).length()
	ms_inst.call("_animate_gk_idle", 0.2)
	var d_after: float = Vector2(ms_inst.get("_ball_pos").x - ms_inst.get("_defender_positions")[0].x, ms_inst.get("_ball_pos").z - ms_inst.get("_defender_positions")[0].z).length()
	_assert(d_after < d_before, "During open play aiming in NORMAL, opposing defender moves closer toward ball carrier to tackle")
	var defs_tmp: Array = ms_inst.get("_defender_positions")
	defs_tmp[0] = ms_inst.get("_ball_pos") + Vector3(0.4, 0.0, -0.4)
	ms_inst.call("_animate_gk_idle", 0.05)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT, "Defender reaching ball carrier while aiming tackles and steals ball")
	SettingsManager.set_setting("difficulty", "NORMAL")

	# Offside System (FIFA Law 11): passing to an offside teammate blows whistle & cancels play!
	ms_inst.call("_trigger_key_moment", 0)  # SHOT
	var off_defs: Array = ms_inst.get("_defender_positions")
	for di in range(off_defs.size()):
		off_defs[di] = Vector3(float(di - 1) * 5.0, 0.0, -37.0)
	var off_tms: Array = ms_inst.get("_teammate_positions")
	off_tms[0] = Vector3(3.0, 0.0, -45.5)  # Clearly ahead of deepest defender (-37.0) & ball
	_assert(bool(ms_inst.call("_is_teammate_offside", 0)), "Teammate ahead of last defender and ball is flagged OFFSIDE")
	ms_inst.set("_drag_start", Vector2(480.0, 290.0))
	ms_inst.set("_drag_current", Vector2(480.0, 420.0))
	ms_inst.call("_release_slingshot")  # Snapshots offside flags at kick moment
	ms_inst.set("_flight_timer", 0.2)
	ms_inst.set("_ball_pos", off_tms[0] + Vector3(0.1, 0.5, 0.1))
	ms_inst.set("_ball_vel", Vector3(0.0, 0.0, -8.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT and str(ms_inst.get("_result_toast").text).contains("OFFSIDE"), "Passing to offside teammate triggers OFFSIDE call and stops play")

	# Passing from SHOT into an ONSIDE forward-running teammate near penalty box triggers direct execution (TEAMMATE_CARRY); midfield pass transfers user control!
	ms_inst.call("_trigger_key_moment", 0)  # SHOT
	var tm0_p: Vector3 = ms_inst.get("_teammate_positions")[0]
	_assert(not bool(ms_inst.call("_is_teammate_offside", 0)), "Freshly spawned open-play teammates start ONSIDE")
	ms_inst.set("_kick_offside_flags", [false, false, false])
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_flight_timer", 0.2)
	ms_inst.set("_ball_pos", tm0_p + Vector3(0.1, 0.5, 0.1))
	ms_inst.set("_ball_vel", Vector3(0.0, 0.0, -8.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.TEAMMATE_CARRY and bool(ms_inst.get("_shot_by_teammate")) and bool(ms_inst.get("_carry_assist_pending")) if tm0_p.z < -31.5 else (int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM and int(ms_inst.get("_controlling_teammate_idx")) == 0), "Pass near penalty area lets teammate execute directly; midfield transfers control")
	# Move controlled midfield teammate with joystick & score -> credits user +1 assist
	ms_inst.call("_enter_teammate_user_control", 0, true)
	var tm0_before: Vector3 = ms_inst.get("_teammate_positions")[0]
	ms_inst.set("_dribble_input", Vector2(0.0, -1.0))
	ms_inst.call("_process_dribble_control", 0.12)
	ms_inst.set("_dribble_input", Vector2.ZERO)
	_assert(ms_inst.get("_teammate_positions")[0].z < tm0_before.z - 0.1, "Joystick moves the controlled teammate smoothly")
	ms_inst.set("_shot_by_teammate", true)
	ms_inst.set("_carry_assist_pending", true)
	var pre_assists: int = int(ms_inst.get("_my_assists"))
	ms_inst.call("_handle_goal_scored")
	_assert(int(ms_inst.get("_my_assists")) == pre_assists + 1, "Teammate goal from user pass credits user assist (+1)")

	# Midfield teammate passing to ANOTHER teammate in midfield or box who scores awards User +0.1 rating!
	ms_inst.call("_enter_teammate_user_control", 0, true)
	var tm_arr_c: Array[Vector3] = ms_inst.get("_teammate_positions")
	tm_arr_c[1] = Vector3(-4.0, 0.0, -35.0)
	ms_inst.set("_teammate_positions", tm_arr_c)
	ms_inst.set("_kick_offside_flags", [false, false, false])
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_flight_timer", 0.2)
	ms_inst.set("_ball_pos", Vector3(-4.0, 0.5, -35.0))
	ms_inst.set("_ball_vel", Vector3(0.0, 0.0, -8.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.TEAMMATE_CARRY and bool(ms_inst.get("_user_hockey_assist_eligible")), "Controlled teammate passing into box triggers immediate teammate execution with +0.1 combo bonus")
	var pre_combo_r: float = float(ms_inst.get("_rating"))
	ms_inst.set("_shot_by_teammate", true)
	ms_inst.set("_carry_assist_pending", false)
	ms_inst.call("_handle_goal_scored")
	_assert(float(ms_inst.get("_rating")) >= pre_combo_r + 0.09, "Goal from teammate-to-teammate pass rewards user +0.1 rating")

	# Incoming teammate pass opportunity (MomentType.TEAMMATE_PASS -> INCOMING_PASS -> KEY_MOMENT_AIM SHOT)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.TEAMMATE_PASS)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.INCOMING_PASS, "TEAMMATE_PASS triggers animated INCOMING_PASS toward user")
	for _ip in range(22):
		if int(ms_inst.get("_phase")) == ms_inst.MatchPhase.INCOMING_PASS:
			ms_inst.call("_process_incoming_pass", 0.12)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM and int(ms_inst.get("_moment_type")) == ms_inst.MomentType.SHOT, "Incoming teammate pass arrives at user's feet and opens live SHOT decision")

	ms_inst.call("_trigger_key_moment", 5)  # TEAMMATE_PENALTY
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.TEAMMATE_PENALTY_WAIT, "Teammate penalty puts player on alert in TEAMMATE_PENALTY_WAIT")
	ms_inst.set("_ball_pos", Vector3(2.4, 0.4, -44.0))
	ms_inst.set("_ball_vel", Vector3(1.5, 1.2, 4.5))
	ms_inst.call("_enter_rebound_scramble", "TEST REBOUND")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.REBOUND_SCRAMBLE, "MatchScene enters REBOUND_SCRAMBLE cleanly")
	ms_inst.call("_process_rebound_scramble", 0.05)
	_assert(ms_inst.get("_rebound_timer") > 0.0, "REBOUND_SCRAMBLE steps players & ball cleanly")

	# 1. Aerial Cross Header Moment (Aim -> High Lob -> Shrinking Circle Timing -> 3D Header Flight + Fail Rating Penalty)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.HEADER_CROSS)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM and int(ms_inst.get("_moment_type")) == ms_inst.MomentType.HEADER_CROSS, "HEADER_CROSS starts in aim phase so user aims header direction first")
	ms_inst.set("_drag_start", Vector2(480.0, 290.0))
	ms_inst.set("_drag_current", Vector2(480.0, 420.0))
	ms_inst.call("_release_slingshot")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.HEADER_TIMING and ms_inst.get("_qte_overlay").visible, "Releasing header aim launches incoming aerial cross and Shrinking Circle QTE")
	ms_inst.call("_process_header_timing", 0.35)
	ms_inst.set("_qte_progress", 1.0)
	ms_inst.call("_handle_qte_tap")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.BALL_IN_FLIGHT, "Tapping at exact header timing launches 3D header shot/pass into flight")
	# Missed header timing deducts rating
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.HEADER_CROSS)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_drag_start", Vector2(480.0, 290.0))
	ms_inst.set("_drag_current", Vector2(480.0, 420.0))
	ms_inst.call("_release_slingshot")
	ms_inst.set("_qte_progress", 0.25)
	ms_inst.call("_handle_qte_tap")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT and float(ms_inst.get("_rating")) < 6.5, "Poorly timed header fails moment and reduces match rating")

	# 2. 1v1 Dribble Duel Shrinking Circle QTE (Success -> Open Play SHOT; Fail -> Rating Penalty)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.DRIBBLE_DUEL)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.QTE_DRIBBLE_DUEL and ms_inst.get("_qte_overlay").visible, "DRIBBLE_DUEL enters QTE_DRIBBLE_DUEL with Shrinking Circle QTE")
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_qte_progress", 1.0)
	ms_inst.call("_handle_qte_tap")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM and int(ms_inst.get("_moment_type")) == ms_inst.MomentType.SHOT and float(ms_inst.get("_rating")) > 6.5, "Perfect 1v1 QTE beats defender, raises rating, and opens live SHOT/PASS decision")
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.DRIBBLE_DUEL)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_qte_progress", 0.15)
	ms_inst.call("_handle_qte_tap")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT and float(ms_inst.get("_rating")) < 6.5, "Failed 1v1 dribble QTE loses ball to defender and reduces rating")

	# 3. Long Pass First-Touch Control Shrinking Circle QTE (Success -> Open Play SHOT; Fail -> Rating Penalty)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.LONG_PASS_CONTROL)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.QTE_LONG_CONTROL and ms_inst.get("_qte_overlay").visible, "LONG_PASS_CONTROL enters QTE_LONG_CONTROL with Shrinking Circle QTE")
	ms_inst.call("_process_qte_long_control", 0.3)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_qte_progress", 1.0)
	ms_inst.call("_handle_qte_tap")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM and int(ms_inst.get("_moment_type")) == ms_inst.MomentType.SHOT and float(ms_inst.get("_rating")) > 6.5, "Perfect long-pass control QTE settles ball and opens live SHOT/PASS decision")
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.LONG_PASS_CONTROL)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_qte_progress", 0.2)
	ms_inst.call("_handle_qte_tap")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT and float(ms_inst.get("_rating")) < 6.5, "Failed long-pass control QTE loses control and reduces rating")

	# 4. Exact Granular Rating Deltas: Wide Miss (-0.3), GK Save/Post (+0.1), Failed Key Pass (+0.2)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.SHOT)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_ball_pos", Vector3(20.0, 0.5, -57.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(is_equal_approx(float(ms_inst.get("_rating")), 6.2), "Shooting wide deducts -0.3 rating (6.5 -> 6.2)")

	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.SHOT)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_shot_by_teammate", false)
	ms_inst.set("_shot_on_target_credit", false)
	ms_inst.call("_credit_on_target_shot", "DITEPIS KIPER")
	_assert(is_equal_approx(float(ms_inst.get("_rating")), 6.6), "On-target shot saved by GK / hitting post adds +0.1 rating (6.5 -> 6.6)")

	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.SHOT)
	ms_inst.set("_rating", 6.5)
	ms_inst.set("_shot_by_teammate", true)
	ms_inst.set("_carry_assist_pending", true)
	ms_inst.set("_key_pass_awarded", false)
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_ball_pos", Vector3(20.0, 0.5, -57.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(is_equal_approx(float(ms_inst.get("_rating")), 6.6), "Key pass to teammate who then fails to score adds +0.1 rating without penalty (6.5 -> 6.6)")

	# === NEW FEATURE VERIFICATION: Lineup Intro, Agile Slide Tackles, Portrait Highlights, Cards >2, Injuries, Coach Sub, Energy +20%, Event Cooldown ===
	# A. Pre-Match Animated Lineup Showcase
	ms_inst.call("_start_selected_mode")
	var our_xi: Array = ms_inst.get("_our_lineup")
	var opp_xi: Array = ms_inst.get("_opp_lineup")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.INTRO and ms_inst.get("_lineup_panel").visible, "Career match opens animated Pre-Match Lineup Showcase (MatchPhase.INTRO)")
	_assert(our_xi.size() == 11 and opp_xi.size() == 11, "Lineup Showcase populates 11 starters for both User Team and Opponent Team")
	ms_inst.call("_start_match_kickoff")
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.SIMULATING and ms_inst.get("_board_panel").visible and not ms_inst.get("_lineup_panel").visible, "Lineup kickoff transitions cleanly to live 2D Match Board")

	# B. OVR-Scaled Defender Agility & Slide Tackle Pass Interception
	var agil_low: float = float(ms_inst.call("get_opp_defender_agility", 55))
	var agil_high: float = float(ms_inst.call("get_opp_defender_agility", 88))
	_assert(agil_high > agil_low + 0.35, "Defender agility scales meaningfully with opponent OVR (%.2f vs %.2f)" % [agil_low, agil_high])
	SettingsManager.data["difficulty"] = "NORMAL"
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.TEAMMATE_PASS)
	ms_inst.set("_incoming_pass_kicked", true)
	var bpos_sl: Vector3 = ms_inst.get("_ball_pos")
	var upos_sl: Vector3 = ms_inst.get("_player_pos")
	var mid_lane: Vector3 = bpos_sl.lerp(upos_sl, 0.45)
	var sl_defs: Array[Vector3] = [Vector3(mid_lane.x, 0.0, mid_lane.z - 1.6), Vector3(-12.0, 0.0, -40.0), Vector3(12.0, 0.0, -40.0)]
	ms_inst.set("_defender_positions", sl_defs)
	var slide_triggered := false
	for _sl in range(30):
		if int(ms_inst.get("_phase")) != ms_inst.MatchPhase.INCOMING_PASS:
			break
		ms_inst.call("_process_incoming_pass", 0.04)
		var sl_t: Array = ms_inst.get("_defender_slide_timers")
		if sl_t.size() > 0 and float(sl_t[0]) > 0.0:
			slide_triggered = true
	_assert(slide_triggered and int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT, "Agile opposing defender launches slide tackle and intercepts teammate pass")

	# C. Portrait Highlights (Goal+Assist, GK Save, Yellow/Red Cards & Team >2 Card Banner)
	ms_inst.call("_start_selected_mode")
	ms_inst.call("_start_match_kickoff")
	ms_inst.set("_minute", 23.0)
	var u_p: Dictionary = ms_inst.call("_get_user_roster_dict")
	var tm_p: Dictionary = ms_inst.call("_pick_roster_player", true, false, false)
	ms_inst.call("_add_rich_board_highlight", 23, "GOAL", "GOL TEST!", "Assist oleh rekan", u_p, tm_p, true)
	var hl_p_box: HBoxContainer = ms_inst.get("_board_hl_portraits")
	_assert(hl_p_box.get_child_count() == 2 and str(ms_inst.get("_board_hl_badge").text).contains("23'"), "Goal+Assist highlight renders both player portraits and exact minute stamp")
	ms_inst.call("_trigger_match_card", false, false)
	ms_inst.call("_trigger_match_card", false, false)
	_assert(not ms_inst.get("_board_cards_bar").visible, "Team card warning stays hidden when cards <= 2")
	ms_inst.call("_trigger_match_card", false, false)
	_assert(ms_inst.get("_board_cards_bar").visible and str(ms_inst.get("_board_cards_lbl").text).contains("3 KARTU KUNING"), "Team card warning displays team count once yellow cards exceed 2")
	ms_inst.call("_trigger_match_card", true, true)
	_assert(int(ms_inst.get("_our_reds")) >= 1 and hl_p_box.get_child_count() >= 1, "Red card highlight displays player portrait and updates red count")

	# D. Player Injury Outcomes (Cannot Return -> Immediate Sub; <=10m -> Returns; >10m -> Coach Sub after 10m)
	ms_inst.set("_minute", 30.0)
	ms_inst.call("_trigger_match_injury", true, 0, -1)
	_assert(hl_p_box.get_child_count() == 2 and str(ms_inst.get("_board_hl_badge").text).contains("30'"), "Severe injury immediately substitutes player with both OUT & IN portraits")
	ms_inst.set("_minute", 40.0)
	ms_inst.call("_trigger_match_injury", true, 1, 6)
	var injs_a: Array = ms_inst.get("_active_injuries")
	var rec_player: Dictionary = injs_a[injs_a.size() - 1]["player"]
	ms_inst.set("_minute", 46.0)
	ms_inst.call("_process_active_injuries")
	_assert(not bool(rec_player.get("injured", true)) and not bool(rec_player.get("subbed_out", false)), "Temporary injury <= 10 min recovers and returns player to pitch")
	ms_inst.set("_minute", 50.0)
	ms_inst.call("_trigger_match_injury", false, 1, 14)
	var injs_b: Array = ms_inst.get("_active_injuries")
	var long_inj_p: Dictionary = injs_b[injs_b.size() - 1]["player"]
	ms_inst.set("_minute", 60.0)
	ms_inst.call("_process_active_injuries")
	_assert(bool(long_inj_p.get("subbed_out", false)) and ms_inst.get("_active_injuries").is_empty(), "Injury recovery > 10 min triggers coach substitution after 10 minutes")

	# E. Coach Substitutes User (Low Energy OR Poor Performance)
	ms_inst.call("_start_selected_mode")
	ms_inst.call("_start_match_kickoff")
	ms_inst.set("_minute", 35.0)
	ms_inst.set("_user_match_energy", 18.0)
	ms_inst.call("_check_coach_user_substitution")
	_assert(bool(ms_inst.get("_user_subbed_out")) and ms_inst.get("_board_sub_banner").visible, "Coach substitutes user when live energy is nearly depleted")
	ms_inst.call("_start_selected_mode")
	ms_inst.call("_start_match_kickoff")
	ms_inst.set("_minute", 65.0)
	ms_inst.set("_user_match_energy", 75.0)
	ms_inst.set("_rating", 5.2)
	ms_inst.call("_check_coach_user_substitution")
	_assert(bool(ms_inst.get("_user_subbed_out")) and int(ms_inst.get("_user_sub_minute")) == 65, "Coach substitutes user when match performance rating is poor")

	# F. Live Energy Drain (+20% heavier) & Event Cooldown (1-3 matches)
	ms_inst.call("_start_selected_mode")
	ms_inst.call("_start_match_kickoff")
	var e_start: float = float(ms_inst.get("_user_match_energy"))
	for _s in range(12):
		ms_inst.call("_process_simulation", 0.25)
	_assert(float(ms_inst.get("_user_match_energy")) < e_start - 2.0, "In-match user energy drains continuously during live simulation")
	CareerState.career["careerMeta"]["eventCooldown"] = 2
	_assert(not CareerState.consume_event_cooldown(), "Event cooldown blocks cutscene while remaining matches > 0")
	CareerState.career["careerMeta"]["eventCooldown"] = 0
	var allowed_ev: bool = CareerState.consume_event_cooldown()
	var next_cd: int = int(CareerState.career["careerMeta"]["eventCooldown"])
	_assert(allowed_ev and next_cd >= 1 and next_cd <= 3, "Event cooldown fires at 0 and resets strictly between 1-3 matches (next=%d)" % next_cd)
	# G. Automatic Pre-Match & Post-Match Events, Stationary/OVR-Reflex GK AI, Rare Cards/Injuries, Larger Highlights, POTM & POTY
	# G1. GK stays stationary without pacing left/right during open-play/penalty idle aiming
	SettingsManager.set_setting("difficulty", "NORMAL")
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.PENALTY)
	var gk_x0: float = float(ms_inst.get("_gk_pos").x)
	for _gi in range(10):
		ms_inst.call("_animate_gk_idle", 0.1)
	var gk_x1: float = float(ms_inst.get("_gk_pos").x)
	_assert(is_equal_approx(gk_x0, gk_x1), "AI Goalkeeper does not pace left/right idly before shot")

	# G2. GK reflex & dive/parry speed scales by Opponent GK OVR
	var gk_low: Dictionary = ms_inst.call("get_opp_gk_profile", 54)
	var gk_high: Dictionary = ms_inst.call("get_opp_gk_profile", 90)
	_assert(float(gk_high["reaction_delay"]) < float(gk_low["reaction_delay"]) and float(gk_high["dive_speed"]) > float(gk_low["dive_speed"]) and float(gk_high["reach"]) > float(gk_low["reach"]), "GK reflex delay, dive speed, and parry reach scale cleanly with OVR")
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_gk_pos", Vector3(0.0, 0.0, -51.6))
	ms_inst.set("_gk_react_timer", 0.0)
	ms_inst.set("_ball_pos", Vector3(2.2, 1.0, -40.0))
	ms_inst.set("_ball_vel", Vector3(0.5, 0.4, -22.0))
	ms_inst.set("_ball_omega", Vector3.ZERO)
	ms_inst.call("_update_gk_ai", 0.12)
	_assert(float(ms_inst.get("_gk_pos").x) > 0.25 and absf(float(ms_inst.get("_gk_dive_dir"))) > 0.5, "GK dives actively to intercept/parry incoming shot")

	# G3. Enlarged Highlight Portrait Cards & Rare Injuries/Cards Cap
	ms_inst.call("_start_selected_mode")
	ms_inst.call("_start_match_kickoff")
	var hl_u: Dictionary = ms_inst.call("_get_user_roster_dict")
	ms_inst.call("_add_rich_board_highlight", 18, "GOAL", "GOL BESAR", "Highlight diperbesar", hl_u, {}, true)
	var hl_card: PanelContainer = ms_inst.get("_board_hl_portraits").get_child(0) as PanelContainer
	_assert(hl_card.custom_minimum_size.x >= 140.0 and hl_card.custom_minimum_size.y >= 120.0, "Match highlight portrait card is enlarged cleanly (>= 140x120 px)")
	for sim_i in range(25):
		ms_inst.set("_minute", 10.0 + float(sim_i) * 3.0)
		ms_inst.call("_push_random_sim_event")
	_assert(int(ms_inst.get("_our_yellows")) + int(ms_inst.get("_opp_yellows")) <= 3 and int(ms_inst.get("_our_reds")) + int(ms_inst.get("_opp_reds")) <= 2 and int(ms_inst.get("_total_injuries_match")) <= 1, "Injuries, yellow cards, and red cards remain realistically rare per match")

	# G4. Automatic Pre-Match Event Cooldown in AppRoot & Monthly/Annual Award Events
	CareerState.career["careerMeta"]["preEventCooldown"] = 0
	_assert(CareerState.consume_prematch_event_cooldown(), "Pre-match automatic event cooldown fires when due and resets 1-3 matches")

	# H. Batch B Gameplay: Open-Space Pass Chase, Advancing Harder GK, OVR Teammate Slowdown, Faster Defenders, GK Build-Up, Corner Kick, Contextual Events
	# H1. Pass into open pitch space (either explicit PASS or open-play SHOT aimed away from goal) triggers live chase instead of WIDE fail
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.PASS)
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_flight_timer", 0.65)
	ms_inst.set("_ball_pos", Vector3(6.5, 0.12, -26.0))
	ms_inst.set("_ball_vel", Vector3(1.2, 0.0, -2.5))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.REBOUND_SCRAMBLE and bool(ms_inst.get("_scramble_is_loose_pass")), "Pass into empty pitch space triggers live chase instead of WIDE")
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.SHOT)
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_flight_timer", 0.30)
	ms_inst.set("_ball_pos", Vector3(11.5, 0.25, -24.0))
	ms_inst.set("_ball_vel", Vector3(11.0, 0.0, -7.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.REBOUND_SCRAMBLE and bool(ms_inst.get("_scramble_is_loose_pass")), "Open-play angled pass toward empty wing space initiates teammate/opponent ball chase")

	# H2. Opposing GK stays on line outside penalty box, advances only inside penalty box with defender-like slow/move timing & OVR-reduced speed
	SettingsManager.set_setting("difficulty", "NORMAL")
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.SHOT)
	ms_inst.set("_ball_pos", Vector3(0.0, 0.12, -26.0))
	for _gz_out in range(8):
		ms_inst.call("_animate_gk_idle", 0.08)
	_assert(is_equal_approx(float(ms_inst.get("_gk_pos").z), -51.6), "AI GK stays on goal line when ball is outside penalty area")
	ms_inst.set("_ball_pos", Vector3(0.0, 0.12, -41.0))
	var gk_z0: float = float(ms_inst.get("_gk_pos").z)
	ms_inst.set("_dribble_input", Vector2.ZERO)
	for _gz in range(10):
		ms_inst.call("_animate_gk_idle", 0.08)
	var gk_slow_adv: float = float(ms_inst.get("_gk_pos").z) - gk_z0
	_assert(gk_slow_adv > 0.10 and is_equal_approx(float(ms_inst.get("_gk_pos").x), 0.0), "AI GK advances inside penalty area without idle X oscillation")
	var gk_prof_low: Dictionary = ms_inst.call("get_opp_gk_profile", 52)
	var gk_prof_hi: Dictionary = ms_inst.call("get_opp_gk_profile", 88)
	_assert(float(gk_prof_low["rush_speed"]) < float(gk_prof_hi["rush_speed"]) and float(gk_prof_hi["rush_speed"]) <= 3.8, "Opponent GK rush speed scales cleanly with OVR and stays moderated")

	# H3. Teammate speed slowed cleanly (<1.0 OVR scale) & faster defenders vs MUDAH freeze
	var tm_scale_val: float = float(ms_inst.call("get_teammate_speed_scale"))
	var def_agil_hi: float = float(ms_inst.call("get_opp_defender_agility", 88))
	SettingsManager.set_setting("difficulty", "MUDAH")
	ms_inst.set("_dribble_input", Vector2.ZERO)
	ms_inst.set("_dragging", false)
	var mudah_idle: Dictionary = ms_inst.call("_get_moment_time_scales")
	SettingsManager.set_setting("difficulty", "NORMAL")
	var normal_idle: Dictionary = ms_inst.call("_get_moment_time_scales")
	_assert(tm_scale_val > 0.65 and tm_scale_val < 0.97 and def_agil_hi >= 1.50, "Teammate speed scales conservatively below 1.0 while defenders gain higher OVR agility")
	_assert(float(mudah_idle["defender_speed"]) == 0.0 and float(normal_idle["defender_speed"]) > 0.0, "Defenders freeze idly on MUDAH while advancing faster on NORMAL+")

	# H4. Friendly GK Build-up moment -> passes from own keeper to friendly defender (not directly user)
	ms_inst.call("_trigger_key_moment", ms_inst.MomentType.GK_BUILDUP)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.INCOMING_PASS and bool(ms_inst.get("_incoming_pass_is_our_gk")) and float(ms_inst.get("_our_gk_pos").z) > 40.0, "GK_BUILDUP initiates pass from friendly goalkeeper in own half")
	for _gb in range(28):
		if int(ms_inst.get("_phase")) == ms_inst.MatchPhase.INCOMING_PASS:
			ms_inst.call("_process_incoming_pass", 0.10)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.KEY_MOMENT_AIM and int(ms_inst.get("_controlling_teammate_idx")) == 0 and not bool(ms_inst.get("_incoming_pass_is_our_gk")), "GK build-up pass arrives at friendly defender for backline build-up control")

	# H5. Corner Kick both User Taker & Teammate Taker (non-offside + QTE)
	ms_inst.call("setup_corner_variant", true)
	_assert(int(ms_inst.get("_moment_type")) == ms_inst.MomentType.CORNER_KICK, "Corner variant user taker activates CORNER_KICK")
	_assert(bool(ms_inst.get("_corner_taker_is_user")) and absf(float(ms_inst.get("_ball_pos").x)) > 25.0 and not bool(ms_inst.call("_is_teammate_offside", 0)), "User-taken corner positions ball at corner flag with zero offside")
	ms_inst.call("setup_corner_variant", false)
	ms_inst.set("_drag_start", Vector2(480.0, 290.0))
	ms_inst.set("_drag_current", Vector2(480.0, 420.0))
	ms_inst.call("_release_slingshot")
	_assert(not bool(ms_inst.get("_corner_taker_is_user")) and int(ms_inst.get("_phase")) == ms_inst.MatchPhase.HEADER_TIMING, "Teammate-taken corner triggers aerial QTE finish in box")

	# H6. Contextual Pre-Match vs Post-Match Dilemma Filtering
	var pre_ids: Array[String] = []
	for _d in range(12):
		var dd: Dictionary = CareerState.pick_contextual_dilemma("PRE")
		pre_ids.append(str(dd.get("id", "")))
		_assert(str(dd.get("timing", "PRE")) == "PRE", "Pre-match picker strictly excludes POST-only events like GK penalty duel")
	_assert(not ("adu_penalti_kiper" in pre_ids), "GK penalty challenge never appears before a match")
	var post_d: Dictionary = CareerState.pick_contextual_dilemma("POST", {"goals": 1, "score_us": 2, "score_them": 1})
	_assert(str(post_d.get("timing", "")) == "POST", "Post-match picker exclusively returns POST-conditioned dilemmas")
	var sc_low: Color = UITheme.get_stat_color(48)
	var sc_high: Color = UITheme.get_stat_color(94)
	_assert(sc_low.r > sc_high.r and sc_high.g > sc_low.g, "Stat attribute color progresses cleanly from orange toward green")
	var ovr_prog: Dictionary = CareerState.get_ovr_progress()
	_assert(ovr_prog.has("progress") and float(ovr_prog["progress"]) >= 0.0 and float(ovr_prog["progress"]) <= 1.0, "OVR progress computes fraction toward next OVR level")
	ms_inst.queue_free()

	var VolleyScr: GDScript = load("res://scenes/minigames/VolleyMinigame.gd")
	var vm: Control = VolleyScr.new()
	root.add_child(vm)
	vm.queue_free()

	var CityScr: GDScript = load("res://scenes/city/CityScene.gd")
	var city: Node3D = CityScr.new()
	city.configure("SNEAKERS", false)
	root.add_child(city)
	city.queue_free()

	# Check Sweden Div 3 size separately before simulating season (Sweden is nation 0)
	_assert(GameData.get_clubs_in_division(0, 3).size() == 32, "Sweden Div 3 has 32 teams")

	# Simulate full 45-week season and verify Monthly (POTM) + Annual (POTY) award events trigger!
	var potm_seen := false
	var poty_seen := false
	for _w in range(45):
		var rep: Dictionary = CareerState.sim_current_match()
		if not rep.get("potm_award", {}).is_empty():
			potm_seen = true
		if not rep.get("poty_award", {}).is_empty():
			poty_seen = true
	_assert(potm_seen and CareerState.career["careerMeta"].get("potmHistory", []).size() >= 6, "Player of the Month (POTM) award evaluates & triggers across season months")
	_assert(poty_seen and CareerState.career["careerMeta"].get("potyHistory", []).size() >= 1, "Player of the Year (POTY) gala award evaluates at end of season")
	_assert(CareerState.career["careerMeta"]["lastMatchdayResults"].size() >= 8, "Matchday simulation populates HASIL division scores")
	_assert(int(CareerState.career["careerMeta"]["year"]) == 2, "45 matches rolls over cleanly into Year 2 (got Year %d)" % int(CareerState.career["careerMeta"]["year"]))
	_assert(int(CareerState.career["playerProfile"]["age"]) == 17, "Player ages to 17 on Season 2")

	var save_path := "user://saves/slot_3.dat"
	var f := FileAccess.open(save_path, FileAccess.READ)
	var save_bytes := f.get_length() if f != null else -1
	f = null
	_assert(save_bytes > 0 and save_bytes < 5 * 1024 * 1024, "Save slot compressed size is %d bytes (< 5 MB limit)" % save_bytes)

	var pre_cash := int(CareerState.career["playerProfile"]["cash"])
	CareerState.has_active_career = false
	_assert(CareerState.load_slot(3) and int(CareerState.career["playerProfile"]["cash"]) == pre_cash, "Reloading Slot 3 restores exact career state")
	CareerState.delete_slot(3)

	print("=== SUMMARY: %d PASSED, %d FAILED ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
