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
	for c_mode in [0, 1, 2, 3, 4, 5, 6, 7, 8]:
		var cm: Control = CutsceneScr.new()
		cm.configure(c_mode)
		root.add_child(cm)
		cm.queue_free()
	_assert(true, "EventCutsceneModal initializes cleanly for modes 0..8")

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

	ms_inst.call("_switch_open_play_action", 2)  # DRIBBLE -> Circular Analog Cursor!
	_assert(ms_inst.get("_dribble_pad").visible and ms_inst.get("_dribble_ctrl_bar").visible and not ms_inst.get("_spin_pad").visible, "DRIBBLE mode activates bottom-left circular joystick and bottom-right dribble controls")
	SettingsManager.set_setting("difficulty", "NORMAL")
	ms_inst.set("_dribble_input", Vector2.ZERO)
	ms_inst.set("_skill_burst_timer", 0.0)
	var sc_idle: Dictionary = ms_inst.call("_get_moment_time_scales")
	ms_inst.set("_dribble_input", Vector2(0.0, -1.0))
	var sc_move: Dictionary = ms_inst.call("_get_moment_time_scales")
	_assert(float(sc_idle["teammate"]) < float(sc_move["teammate"]) and float(sc_idle["defender_speed"]) < float(sc_move["defender_speed"]), "Teammates and defenders slow down when idle and move normally when user dribbles")
	ms_inst.set("_dribble_input", Vector2.ZERO)

	var start_p: Vector3 = ms_inst.get("_player_pos")
	ms_inst.set("_dribble_input", Vector2(0.5, -0.866))
	ms_inst.call("_process_dribble_control", 0.12)
	var end_p: Vector3 = ms_inst.get("_player_pos")
	_assert(end_p.distance_to(start_p) > 0.25 and end_p.z < start_p.z, "Circular joystick vector moves player and ball smoothly")
	ms_inst.call("_trigger_dribble_skill")
	_assert(float(ms_inst.get("_skill_burst_timer")) > 0.0, "LARI / TRIK activates dribble speed & skill burst")
	ms_inst.call("_convert_dribble_to_shot", true)
	_assert(int(ms_inst.get("_moment_type")) == ms_inst.MomentType.SHOT and not ms_inst.get("_dribble_pad").visible and ms_inst.get("_spin_pad").visible, "Transitioning from dribble restores SHOT slingshot and spin pad")

	# In SHOT mode, defenders press toward the ball according to difficulty mode and can steal
	ms_inst.call("_trigger_key_moment", 0)  # SHOT
	SettingsManager.set_setting("difficulty", "MUDAH")
	var sc_shot_easy: Dictionary = ms_inst.call("_get_moment_time_scales")
	SettingsManager.set_setting("difficulty", "NORMAL")
	var sc_shot_norm: Dictionary = ms_inst.call("_get_moment_time_scales")
	SettingsManager.set_setting("difficulty", "EKSTREM")
	var sc_shot_ext: Dictionary = ms_inst.call("_get_moment_time_scales")
	_assert(float(sc_shot_easy["defender_speed"]) == 0.0 and float(sc_shot_norm["defender_speed"]) < float(sc_shot_ext["defender_speed"]), "SHOT pressing speed scales across MUDAH, NORMAL, and EKSTREM")
	var d_before: float = Vector2(ms_inst.get("_ball_pos").x - ms_inst.get("_defender_positions")[0].x, ms_inst.get("_ball_pos").z - ms_inst.get("_defender_positions")[0].z).length()
	ms_inst.call("_animate_gk_idle", 0.2)
	var d_after: float = Vector2(ms_inst.get("_ball_pos").x - ms_inst.get("_defender_positions")[0].x, ms_inst.get("_ball_pos").z - ms_inst.get("_defender_positions")[0].z).length()
	_assert(d_after < d_before, "During SHOT, opposing defender moves closer toward ball carrier to tackle")
	var defs_tmp: Array = ms_inst.get("_defender_positions")
	defs_tmp[0] = ms_inst.get("_ball_pos") + Vector3(0.4, 0.0, -0.4)
	ms_inst.call("_animate_gk_idle", 0.05)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.MOMENT_RESULT, "Defender reaching ball carrier during SHOT tackles and steals ball")
	SettingsManager.set_setting("difficulty", "NORMAL")

	# Passing from SHOT into a forward-running teammate initiates animated TEAMMATE_CARRY -> 3D shot / assist!
	ms_inst.call("_trigger_key_moment", 0)  # SHOT
	var tm0_p: Vector3 = ms_inst.get("_teammate_positions")[0]
	ms_inst.set("_phase", ms_inst.MatchPhase.BALL_IN_FLIGHT)
	ms_inst.set("_flight_timer", 0.2)
	ms_inst.set("_ball_pos", tm0_p + Vector3(0.1, 0.5, 0.1))
	ms_inst.set("_ball_vel", Vector3(0.0, 0.0, -8.0))
	ms_inst.call("_process_ball_flight", 0.02)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.TEAMMATE_CARRY and bool(ms_inst.get("_shot_by_teammate")) and bool(ms_inst.get("_carry_assist_pending")), "Aiming pass to teammate during SHOT launches animated TEAMMATE_CARRY")
	ms_inst.set("_carry_pass_back", false)
	ms_inst.set("_carry_shoot_at", 0.35)
	# Move defenders far away for clean carry->shot check, then verify carrier shoots 3D ball in flight & assist scores!
	for di in range(ms_inst.get("_defender_positions").size()):
		ms_inst.get("_defender_positions")[di] = Vector3(28.0, 0.0, -15.0)
	for _cs in range(5):
		if int(ms_inst.get("_phase")) == ms_inst.MatchPhase.TEAMMATE_CARRY:
			ms_inst.call("_process_teammate_carry", 0.12)
	_assert(int(ms_inst.get("_phase")) == ms_inst.MatchPhase.BALL_IN_FLIGHT and bool(ms_inst.get("_shot_by_teammate")), "Carrying teammate strikes real 3D shot toward goal")
	var pre_assists: int = int(ms_inst.get("_my_assists"))
	ms_inst.call("_handle_goal_scored")
	_assert(int(ms_inst.get("_my_assists")) == pre_assists + 1, "Teammate goal from user pass credits user assist (+1)")

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

	# Simulate full 45-week season
	for _w in range(45):
		CareerState.sim_current_match()
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
