extends Node

signal career_updated
signal achievement_unlocked(ach: Dictionary)
signal news_added(item: Dictionary)
signal level_up_triggered(new_level: int, points_added: int)

const SAVES_DIR := "user://saves/"
const META_PATH := "user://saves/slots_meta.json"
const GLOBAL_PATH := "user://global_profile.json"
const TOTAL_WORLD_PLAYERS := 21289

var active_slot: int = -1
var has_active_career: bool = false
var career: Dictionary = {}

# Global account-wide collections, perks, cosmetics & friend code
var global_profile: Dictionary = {
	"friend_code": "RSRK48",
	"my_code_name": "",
	"mentor_used": 0,
	"unlocked_achievements": {},
	"owned_cosmetics": {
		"CINCIN": ["default"],
		"AIM": ["default"],
		"JEJAK": ["default"],
		"LENCANA": ["default"],
		"KARTU": ["default"],
	},
	"owned_perks": [],
	"friends_duels": {},
	"editor_overrides": {},
}

# Fast packed world player database (21,289 players)
var wp_name: PackedStringArray = PackedStringArray()
var wp_club: PackedInt32Array = PackedInt32Array()
var wp_nat: PackedByteArray = PackedByteArray()
var wp_pos: PackedByteArray = PackedByteArray()
var wp_age: PackedByteArray = PackedByteArray()
var wp_ovr: PackedByteArray = PackedByteArray()
var wp_val: PackedInt32Array = PackedInt32Array()
var wp_goals: PackedInt32Array = PackedInt32Array()
var wp_assists: PackedInt32Array = PackedInt32Array()
var wp_seed: PackedInt32Array = PackedInt32Array()
var wp_rank_order: PackedInt32Array = PackedInt32Array()
var world_built: bool = false

# Last match runtime payload for PostMatchSummary / Moviola / Interview
var last_match_report: Dictionary = {}
var last_moviola_clip: Dictionary = {}
var current_match_context: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	load_global_profile()
	ensure_world_database()

func load_global_profile() -> void:
	if not FileAccess.file_exists(GLOBAL_PATH):
		return
	var f := FileAccess.open(GLOBAL_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			global_profile[k] = parsed[k]

func save_global_profile() -> void:
	var f := FileAccess.open(GLOBAL_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(global_profile))

func ensure_world_database(seed_val: int = 994411) -> void:
	if world_built and wp_name.size() == TOTAL_WORLD_PLAYERS:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	wp_name.resize(TOTAL_WORLD_PLAYERS)
	wp_club.resize(TOTAL_WORLD_PLAYERS)
	wp_nat.resize(TOTAL_WORLD_PLAYERS)
	wp_pos.resize(TOTAL_WORLD_PLAYERS)
	wp_age.resize(TOTAL_WORLD_PLAYERS)
	wp_ovr.resize(TOTAL_WORLD_PLAYERS)
	wp_val.resize(TOTAL_WORLD_PLAYERS)
	wp_goals.resize(TOTAL_WORLD_PLAYERS)
	wp_assists.resize(TOTAL_WORLD_PLAYERS)
	wp_seed.resize(TOTAL_WORLD_PLAYERS)

	var clubs_count := GameData.clubs.size()
	var pos_count := GameData.POSITIONS.size()

	# Index 0..8: famous top stars from screenshot #19
	var idx := 0
	for ts in GameData.TOP_SEEDED_PLAYERS:
		var club_d := GameData.find_club_by_name(ts["club"])
		wp_name[idx] = ts["name"]
		wp_club[idx] = int(club_d["id"])
		wp_nat[idx] = int(ts["nat"])
		wp_pos[idx] = maxi(0, GameData.POSITIONS.find(ts["pos"]))
		wp_age[idx] = int(ts["age"])
		wp_ovr[idx] = int(ts["ovr"])
		wp_val[idx] = int(ts["val"])
		wp_goals[idx] = 0
		wp_assists[idx] = 0
		wp_seed[idx] = idx * 31 + 7
		idx += 1

	# Distribute remaining players across all 2,731 clubs (~7-8 core players per club)
	while idx < TOTAL_WORLD_PLAYERS:
		var c_id := idx % clubs_count
		var c_dict: Dictionary = GameData.clubs[c_id]
		var nat_id := int(c_dict["nation_id"])
		if rng.randf() < 0.22:
			nat_id = rng.randi_range(0, GameData.nations.size() - 1)
		var fn: String = GameData.FIRST_NAMES[(idx * 7 + rng.randi_range(0, 11)) % GameData.FIRST_NAMES.size()]
		var ln: String = GameData.LAST_NAMES[(idx * 13 + rng.randi_range(0, 17)) % GameData.LAST_NAMES.size()]
		var p_ovr := clampi(int(c_dict["ovr"]) + rng.randi_range(-6, 7), 44, 89)
		var p_age := rng.randi_range(17, 35)
		var age_factor := 1.45 if p_age <= 23 else (1.0 if p_age <= 29 else 0.48)
		var p_val := int(pow(maxf(1.0, float(p_ovr) - 42.0), 2.15) * 42.0 * age_factor)

		wp_name[idx] = "%s %s" % [fn, ln]
		wp_club[idx] = c_id
		wp_nat[idx] = nat_id
		wp_pos[idx] = (idx % pos_count)
		wp_age[idx] = p_age
		wp_ovr[idx] = p_ovr
		wp_val[idx] = maxi(50, p_val)
		wp_goals[idx] = 0
		wp_assists[idx] = 0
		wp_seed[idx] = rng.randi()
		idx += 1

	rebuild_world_ovr_ranking()
	world_built = true

func rebuild_world_ovr_ranking() -> void:
	# O(N) bucket sort by OVR descending (0..99)
	var buckets: Array = []
	buckets.resize(100)
	for i in range(100):
		buckets[i] = PackedInt32Array()
	for idx in range(TOTAL_WORLD_PLAYERS):
		var o := clampi(int(wp_ovr[idx]), 0, 99)
		buckets[o].append(idx)

	wp_rank_order.resize(TOTAL_WORLD_PLAYERS)
	var out_i := 0
	for o in range(99, -1, -1):
		var b: PackedInt32Array = buckets[o]
		for k in range(b.size()):
			wp_rank_order[out_i] = b[k]
			out_i += 1

func get_player_global_rank(ovr_val: int) -> int:
	var better := 0
	for idx in range(TOTAL_WORLD_PLAYERS):
		if int(wp_ovr[idx]) > ovr_val:
			better += 1
	return better + 1

func get_max_slots() -> int:
	return 4 if global_profile.get("owned_perks", []).has("slot_keempat") else 3

func get_slots_meta() -> Dictionary:
	if not FileAccess.file_exists(META_PATH):
		return {}
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _write_slot_meta(slot_id: int, summary: Dictionary) -> void:
	var meta := get_slots_meta()
	if summary.is_empty():
		meta.erase(str(slot_id))
	else:
		meta[str(slot_id)] = summary
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta))

func start_new_career(
	slot_id: int,
	player_name: String = "ALFIAN",
	nat_id: int = 16,
	natural_pos: String = "ST",
	club_name: String = "Danderyd Edsviken",
	appearance: Dictionary = {}
) -> void:
	ensure_world_database()
	var club := GameData.find_club_by_name(club_name)
	var club_id := int(club["id"])
	var clean_name := player_name.strip_edges().to_upper()
	if clean_name.is_empty():
		clean_name = "ALFIAN"

	var base_attrs := {
		"kekuatan": 60, "akurasi": 60, "efek": 60, "visi": 60, "fisik": 60,
		"kecepatan": 60, "akselerasi": 60, "dribel": 60, "penalti": 60, "bolaMati": 60,
	}
	var beard_style_val := int(appearance.get("beard_style", 1 if bool(appearance.get("beard", false)) else 0))
	var app := {
		"skin": int(appearance.get("skin", 1)),
		"hair_style": int(appearance.get("hair_style", 2)),
		"hair_color": int(appearance.get("hair_color", 1)),
		"tip_color": int(appearance.get("tip_color", 0)),
		"beard": beard_style_val > 0,
		"beard_style": beard_style_val,
		"sleeve": str(appearance.get("sleeve", "PENDEK")),
		"boot_id": int(appearance.get("boot_id", 0)),
		"glove_color": int(appearance.get("glove_color", -1)),
		"wrist_side": str(appearance.get("wrist_side", "TAK ADA")),
		"wrist_color": int(appearance.get("wrist_color", 0)),
		"tattoo_face": int(appearance.get("tattoo_face", 0)),
		"tattoo_arm": int(appearance.get("tattoo_arm", 0)),
		"tattoo_leg": int(appearance.get("tattoo_leg", 0)),
		"headwear": int(appearance.get("headwear", 0)),
		"eyewear": int(appearance.get("eyewear", 0)),
		"casual_style": int(appearance.get("casual_style", 0)),
		"outfit_variant": int(appearance.get("outfit_variant", 0)),
		"back_name": clean_name,
		"shirt_num": int(appearance.get("shirt_num", 9)),
	}

	var div_clubs := GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	var league_table := _init_league_table(div_clubs)
	var schedule := _build_season_schedule(div_clubs, club_id, int(club["nation_id"]), int(club["division"]))
	var squad := _build_club_squad(club_id, clean_name, natural_pos, app)

	career = {
		"saveSlotId": slot_id,
		"careerMeta": {
			"year": 1,
			"seasonCalendarYear": 2026,
			"week": 1,
			"maxWeeks": 45,
			"legacyPoints": 0,
			"legacyTier": "PROSPEK",
			"dilemmaDoneWeek": 0,
			"currentDilemma": GameData.dilemmas_catalog[0],
			"transferWindowWeeksLeft": 4,
			"retired": false,
			"firstSpeechDone": false,
			"initiationDone": false,
			"clapperDoneSeason": 0,
			"visitedHomeWeek": 0,
			"strategy": "SEIMBANG",
			"intensity": "SEDANG",
			"unlockedCoachTraits": ["KORNER_PENALTI"],
			"lastMatchdayResults": [],
			"boughtSneakers": [],
		},
		"playerProfile": {
			"name": clean_name,
			"nationId": nat_id,
			"clubId": club_id,
			"age": 16,
			"level": 1,
			"xp": 0,
			"xpToNext": 100,
			"ovr": 60,
			"energy": 100,
			"cash": 5000,
			"skillPoints": 0,
			"marketValue": 1342302,
			"naturalPosition": natural_pos,
			"favoritePosition": natural_pos,
			"learnedPositions": {natural_pos: 100},
			"attributes": base_attrs,
			"appearance": app,
			"relations": {
				"pelatih": 45, "ruangGanti": 33, "fans": 27, "pers": 18, "agen": 33,
			},
			"cosmetics": {
				"ringId": "default", "aimId": "default", "trailId": "default",
				"cardFrameId": "default", "badgeId": "default",
			},
		},
		"contract": {
			"salaryPerMatch": 601,
			"yearsLeft": 3,
			"goalTarget": 8,
			"goalsScoredThisSeason": 0,
			"targetBonus": 1996,
			"targetAgreed": false,
			"clause": "NONE",
			"clubRequestsLevel": 1,
			"clubPoints": 33,
		},
		"sponsor": {
			"activeId": "roti_lokal",
			"goalsProgress": 0,
		},
		"inventory": {
			"bootsOwned": [0],
			"staffHired": [],
			"lifestyleOwned": [],
			"energyDrinks": 1,
		},
		"stats": {
			"matches": 0, "starts": 0, "subs": 0, "wins": 0, "draws": 0, "losses": 0,
			"goals": 0, "assists": 0, "motm": 0, "bestRating": 0.0, "totalRating": 0.0,
			"bestMatchGoals": 0, "penaltiesScored": 0, "freekicksScored": 0,
			"dribblesWon": 0, "passesWon": 0, "trophies": 0, "promotions": 0,
			"transfers": 0, "styleEdits": 0, "sponsorsSigned": 1, "seasonsDiv3": 0,
			"finalsLost": 0, "intlCaps": 0, "intlGoals": 0, "followers": 2600,
			"longestGoalMeters": 0.0,
		},
		"trophiesList": [],
		"seasonHistory": [
			{"season": 1, "clubId": club_id, "clubCode": club["code"], "matches": 0, "goals": 0, "assists": 0, "avgRating": 0.0}
		],
		"shotTelemetry": [],
		"moviolaClips": [],
		"leagueTable": league_table,
		"schedule": schedule,
		"clubSquad": squad,
		"news": [
			{"channel": "KLUB", "season": 1, "text": "%s menandatangani kontrak senior pertama bersama %s." % [clean_name, club["name"]]},
			{"channel": "LIGA", "season": 1, "text": "Bursa transfer musim panas dibuka selama 4 pekan."},
			{"channel": "SOSMED", "season": 1, "text": "@%s bergabung dengan %s (+2.600 pengikut)." % [clean_name.to_lower(), club["name"]]},
		],
		"transferOffers": [],
	}

	active_slot = slot_id
	has_active_career = true
	recalculate_ovr()
	evaluate_achievements()
	save_active_career()
	career_updated.emit()

func _init_league_table(div_clubs: Array[Dictionary]) -> Array[Dictionary]:
	var tbl: Array[Dictionary] = []
	for c in div_clubs:
		tbl.append({
			"club_id": int(c["id"]),
			"name": c["name"],
			"code": c["code"],
			"ovr": int(c["ovr"]),
			"p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0,
			"form": [],
		})
	return tbl

func _build_season_schedule(div_clubs: Array[Dictionary], user_club_id: int, nat_id: int, div_num: int) -> Array[Dictionary]:
	var sched: Array[Dictionary] = []
	var opponents: Array[Dictionary] = []
	for c in div_clubs:
		if int(c["id"]) != user_club_id:
			opponents.append(c)
	if opponents.is_empty():
		opponents.append(GameData.clubs[0])

	var opp_ptr := 0
	for w in range(1, 46):
		var comp := "LIGA"
		var comp_label := "LIGA ke-%d" % div_num
		var opp: Dictionary = opponents[opp_ptr % opponents.size()]
		if w in [6, 12, 20, 28, 36, 42]:
			comp = "PIALA"
			comp_label = "PIALA NASIONAL"
			var cup_pool := GameData.get_clubs_in_division(nat_id, maxi(1, div_num - (1 if w > 18 else 0)))
			if cup_pool.size() > 1:
				opp = cup_pool[(w * 7) % cup_pool.size()]
				if int(opp["id"]) == user_club_id:
					opp = opponents[opp_ptr % opponents.size()]
		elif w in [16, 32] and int(career.get("playerProfile", {}).get("ovr", 60)) >= 68:
			comp = "TIMNAS"
			comp_label = "KUALIFIKASI TIMNAS"
		else:
			opp_ptr += 1

		var is_home := (w % 2 == 1)
		sched.append({
			"week": w,
			"comp": comp,
			"comp_label": comp_label,
			"opp_club_id": int(opp["id"]),
			"opp_name": opp["name"],
			"opp_code": opp["code"],
			"opp_ovr": int(opp["ovr"]),
			"is_home": is_home,
			"played": false,
			"score_us": 0,
			"score_them": 0,
		})
	return sched

func _build_club_squad(club_id: int, user_name: String, user_pos: String, user_app: Dictionary) -> Dictionary:
	var c := GameData.clubs[club_id]
	var base_ovr := int(c["ovr"])
	var starters: Array[Dictionary] = []
	var bench: Array[Dictionary] = []

	var preset_names := [
		["Berglund", "GK", 58, 1],
		["Bjork", "LB", 46, 3],
		["Fredriksson", "CB", 63, 4],
		["Martensson", "CB", 59, 5],
		["Sandberg", "CB", 61, 6],
		["Nystrom", "RB", 56, 2],
		["Wallin", "CM", 59, 8],
		["Eklund", "CM", 57, 15],
		["Engstrom", "CM", 57, 10],
		["Hakansson", "ST", 55, 11],
		[user_name.capitalize(), user_pos, 60, int(user_app.get("shirt_num", 9))],
	]
	if c["name"] != "Danderyd Edsviken":
		for i in range(10):
			var fn: String = GameData.FIRST_NAMES[(club_id + i * 3) % GameData.FIRST_NAMES.size()]
			var ln: String = GameData.LAST_NAMES[(club_id + i * 7) % GameData.LAST_NAMES.size()]
			preset_names[i][0] = ln
			preset_names[i][2] = clampi(base_ovr + (i % 5) - 2, 46, 92)

	for i in range(preset_names.size()):
		var p: Array = preset_names[i]
		var is_user := (i == 10)
		var attrs := {}
		for ak in GameData.ATTRIBUTE_KEYS:
			attrs[ak] = clampi(int(p[2]) + ((i * 5 + ak.length()) % 9) - 4, 35, 95)
		starters.append({
			"id": "sq_%d" % i,
			"name": p[0],
			"pos": p[1],
			"ovr": int(p[2]),
			"number": int(p[3]),
			"age": 16 if is_user else (20 + (i * 2) % 13),
			"contract": 3 if is_user else (1 + i % 4),
			"value": int(p[2]) * 22000,
			"matches": 0, "goals": 0, "assists": 0, "rating": 6.0,
			"is_user": is_user,
			"is_captain": (i == 8),
			"seed": club_id * 100 + i,
			"attrs": attrs,
		})

	var bench_names := [
		["Lundin", "GK", 46, 25], ["Holmberg", "CB", 51, 22], ["Andersson", "CDM", 50, 14],
		["Bjork II", "CB", 53, 20], ["Eriksson", "RM", 58, 17], ["Oberg", "CAM", 54, 18], ["Danielsson", "ST", 56, 26],
	]
	for j in range(bench_names.size()):
		var b: Array = bench_names[j]
		var ov := int(b[2]) if c["name"] == "Danderyd Edsviken" else clampi(base_ovr - 5 + j, 44, 86)
		var attrs := {}
		for ak in GameData.ATTRIBUTE_KEYS:
			attrs[ak] = clampi(ov + ((j * 3 + ak.length()) % 7) - 3, 35, 92)
		bench.append({
			"id": "bn_%d" % j,
			"name": b[0] if c["name"] == "Danderyd Edsviken" else GameData.LAST_NAMES[(club_id * 3 + j) % GameData.LAST_NAMES.size()],
			"pos": b[1],
			"ovr": ov,
			"number": int(b[3]),
			"age": 19 + (j * 3) % 14,
			"contract": 1 + j % 3,
			"value": ov * 15000,
			"matches": 0, "goals": 0, "assists": 0, "rating": 5.8,
			"is_user": false,
			"is_captain": false,
			"seed": club_id * 100 + 50 + j,
			"attrs": attrs,
		})

	return {"formation": "5-3-2", "starters": starters, "bench": bench}

func save_active_career() -> void:
	if not has_active_career or active_slot < 1:
		return
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	var path := SAVES_DIR + "slot_%d.dat" % active_slot
	var f := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if f != null:
		f.store_string(JSON.stringify(career))
	var p: Dictionary = career["playerProfile"]
	var m: Dictionary = career["careerMeta"]
	var st: Dictionary = career["stats"]
	var club := GameData.clubs[int(p["clubId"])]
	_write_slot_meta(active_slot, {
		"slot": active_slot,
		"name": p["name"],
		"age": p["age"],
		"ovr": p["ovr"],
		"cash": p["cash"],
		"year": m["year"],
		"week": m["week"],
		"clubId": p["clubId"],
		"clubName": club["name"],
		"pos": p["naturalPosition"],
		"shirtNum": p["appearance"].get("shirt_num", 9),
		"goals": st["goals"],
		"assists": st["assists"],
		"bestRating": st["bestRating"],
		"motm": st["motm"],
		"trophies": st["trophies"],
		"legacyPoints": m["legacyPoints"],
		"appearance": p["appearance"],
	})
	save_global_profile()

func load_slot(slot_id: int) -> bool:
	ensure_world_database()
	var path := SAVES_DIR + "slot_%d.dat" % slot_id
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	career = parsed
	active_slot = slot_id
	has_active_career = true
	ensure_career_fields()
	career_updated.emit()
	return true

func ensure_career_fields() -> void:
	if not has_active_career:
		return
	var m: Dictionary = career.get("careerMeta", {})
	for k in [
		["firstSpeechDone", false], ["initiationDone", false], ["clapperDoneSeason", 0],
		["visitedHomeWeek", 0], ["strategy", "SEIMBANG"], ["intensity", "SEDANG"],
		["unlockedCoachTraits", ["KORNER_PENALTI"]], ["lastMatchdayResults", []], ["boughtSneakers", []]
	]:
		if not m.has(k[0]):
			m[k[0]] = k[1]
	var app: Dictionary = career["playerProfile"].get("appearance", {})
	for k2 in [
		["tattoo_face", 0], ["tattoo_arm", 0], ["tattoo_leg", 0],
		["headwear", 0], ["eyewear", 0], ["casual_style", 0]
	]:
		if not app.has(k2[0]):
			app[k2[0]] = k2[1]
	if not career["stats"].has("bestVolleyStreak"):
		career["stats"]["bestVolleyStreak"] = 0

func delete_slot(slot_id: int) -> void:
	var path := SAVES_DIR + "slot_%d.dat" % slot_id
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_write_slot_meta(slot_id, {})
	if active_slot == slot_id:
		has_active_career = false
		active_slot = -1
		career = {}
	career_updated.emit()

func reset_all_data() -> void:
	for s in range(1, 5):
		delete_slot(s)
	if FileAccess.file_exists(META_PATH):
		DirAccess.remove_absolute(META_PATH)
	global_profile = {
		"friend_code": "RSRK48",
		"my_code_name": "",
		"mentor_used": 0,
		"unlocked_achievements": {},
		"owned_cosmetics": {"CINCIN": ["default"], "AIM": ["default"], "JEJAK": ["default"], "LENCANA": ["default"], "KARTU": ["default"]},
		"owned_perks": [],
		"friends_duels": {},
		"editor_overrides": {},
	}
	save_global_profile()
	career_updated.emit()

func get_current_club() -> Dictionary:
	if not has_active_career:
		return GameData.clubs[0]
	var cid := int(career["playerProfile"]["clubId"])
	return GameData.clubs[clampi(cid, 0, GameData.clubs.size() - 1)]

func get_current_fixture() -> Dictionary:
	if not has_active_career:
		return {}
	var week := int(career["careerMeta"]["week"])
	var sched: Array = career["schedule"]
	var idx := clampi(week - 1, 0, sched.size() - 1)
	return sched[idx]

func get_user_league_position() -> int:
	if not has_active_career:
		return 1
	var my_cid := int(career["playerProfile"]["clubId"])
	var sorted := get_sorted_league_table()
	for i in range(sorted.size()):
		if int(sorted[i]["club_id"]) == my_cid:
			return i + 1
	return 1

func get_sorted_league_table() -> Array[Dictionary]:
	var tbl: Array[Dictionary] = []
	for row in career.get("leagueTable", []):
		tbl.append(row)
	tbl.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["pts"]) != int(b["pts"]):
			return int(a["pts"]) > int(b["pts"])
		var gd_a := int(a["gf"]) - int(a["ga"])
		var gd_b := int(b["gf"]) - int(b["ga"])
		if gd_a != gd_b:
			return gd_a > gd_b
		return int(a["gf"]) > int(b["gf"])
	)
	return tbl

func recalculate_ovr() -> void:
	if not has_active_career:
		return
	var attrs: Dictionary = career["playerProfile"]["attributes"]
	var total := 0.0
	for k in GameData.ATTRIBUTE_KEYS:
		total += float(attrs.get(k, 60))
	var boot_id := int(career["playerProfile"]["appearance"].get("boot_id", 0))
	var boot_bonus := int(GameData.boots_catalog[clampi(boot_id, 0, 10)]["bonus_val"])
	var avg := int(round(total / float(GameData.ATTRIBUTE_KEYS.size()))) + int(boot_bonus * 0.4)
	avg = clampi(avg, 45, 99)
	career["playerProfile"]["ovr"] = avg
	var age := int(career["playerProfile"]["age"])
	var age_mult := 1.6 if age <= 21 else (1.1 if age <= 28 else 0.6)
	career["playerProfile"]["marketValue"] = int(pow(maxf(1.0, float(avg) - 38.0), 2.3) * 1400.0 * age_mult)

	# Sync user card inside clubSquad
	var starters: Array = career["clubSquad"]["starters"]
	for s in starters:
		if s.get("is_user", false):
			s["ovr"] = avg
			s["value"] = career["playerProfile"]["marketValue"]
			s["name"] = career["playerProfile"]["name"].capitalize()
			s["number"] = career["playerProfile"]["appearance"].get("shirt_num", 9)

func get_effective_attribute(attr_key: String) -> int:
	if not has_active_career:
		return 60
	var base := int(career["playerProfile"]["attributes"].get(attr_key, 60))
	var boot_id := int(career["playerProfile"]["appearance"].get("boot_id", 0))
	var boot_d: Dictionary = GameData.boots_catalog[clampi(boot_id, 0, 10)]
	if boot_d["bonus_attr"] == attr_key:
		base += int(boot_d["bonus_val"])
	var staff: Array = career["inventory"].get("staffHired", [])
	if staff.has("analis_video") and (attr_key == "akurasi" or attr_key == "visi"):
		base += 3
	return clampi(base, 1, 99)

func upgrade_attribute(attr_key: String) -> bool:
	if not has_active_career:
		return false
	var sp := int(career["playerProfile"]["skillPoints"])
	var cur := int(career["playerProfile"]["attributes"].get(attr_key, 60))
	if sp < 1 or cur >= 99:
		return false
	career["playerProfile"]["skillPoints"] = sp - 1
	career["playerProfile"]["attributes"][attr_key] = cur + 1
	recalculate_ovr()
	evaluate_achievements()
	save_active_career()
	career_updated.emit()
	return true

func apply_batch_upgrades(pending: Dictionary) -> bool:
	if not has_active_career or pending.is_empty():
		return false
	var total_cost: int = 0
	for k in pending.keys():
		total_cost += maxi(0, int(pending[k]))
	var sp: int = int(career["playerProfile"]["skillPoints"])
	if total_cost <= 0 or total_cost > sp:
		return false
	var attrs: Dictionary = career["playerProfile"]["attributes"]
	for k in pending.keys():
		var delta: int = maxi(0, int(pending[k]))
		if delta > 0:
			attrs[k] = clampi(int(attrs.get(k, 60)) + delta, 1, 99)
	career["playerProfile"]["skillPoints"] = sp - total_cost
	recalculate_ovr()
	evaluate_achievements()
	save_active_career()
	career_updated.emit()
	return true

func buy_emergency_drink(cost: int = 13500) -> bool:
	if not has_active_career:
		return false
	var cash: int = int(career["playerProfile"]["cash"])
	if cash < cost:
		return false
	career["playerProfile"]["cash"] = cash - cost
	career["playerProfile"]["energy"] = mini(100, int(career["playerProfile"]["energy"]) + 28)
	save_active_career()
	career_updated.emit()
	return true

func record_volley_streak(streak: int) -> void:
	global_profile["best_volley_streak"] = maxi(int(global_profile.get("best_volley_streak", 0)), streak)
	save_global_profile()
	if has_active_career:
		career["stats"]["bestVolleyStreak"] = maxi(int(career["stats"].get("bestVolleyStreak", 0)), streak)
		if streak >= 3:
			_award_xp(streak * 6)
		save_active_career()
		career_updated.emit()

func apply_cutscene_effects(eff: Dictionary) -> void:
	if not has_active_career:
		return
	var rel: Dictionary = career["playerProfile"]["relations"]
	for rk in GameData.RELATION_KEYS:
		if eff.has(rk):
			rel[rk] = clampi(int(rel[rk]) + int(eff[rk]), 0, 100)
	if eff.has("energy"):
		career["playerProfile"]["energy"] = clampi(int(career["playerProfile"]["energy"]) + int(eff["energy"]), 0, 100)
	if eff.has("cash"):
		career["playerProfile"]["cash"] = maxi(0, int(career["playerProfile"]["cash"]) + int(eff["cash"]))
	if eff.has("xp"):
		_award_xp(int(eff["xp"]))
	if eff.has("followers"):
		career["stats"]["followers"] = maxi(0, int(career["stats"]["followers"]) + int(eff["followers"]))
	save_active_career()
	career_updated.emit()

func learn_position(pos_code: String) -> bool:
	if not has_active_career:
		return false
	var learned: Dictionary = career["playerProfile"]["learnedPositions"]
	if learned.has(pos_code):
		return false
	var sp := int(career["playerProfile"]["skillPoints"])
	if sp < 6:
		return false
	career["playerProfile"]["skillPoints"] = sp - 6
	learned[pos_code] = 45
	evaluate_achievements()
	save_active_career()
	career_updated.emit()
	return true

func set_favorite_position(pos_code: String) -> void:
	if not has_active_career:
		return
	career["playerProfile"]["favoritePosition"] = pos_code
	save_active_career()
	career_updated.emit()

func get_player_role_status() -> String:
	var eng := int(career["playerProfile"]["energy"])
	if eng < 30:
		return "ABSEN"
	var coach_rel := int(career["playerProfile"]["relations"]["pelatih"])
	if eng < 45 or coach_rel < 35:
		return "CADANGAN"
	return "INTI"

func get_starter_offers(nat_id: int) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var local_div3 := GameData.get_clubs_in_division(nat_id, 3)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# 3 Local Division 3 offers
	var used_ids := {}
	for i in range(mini(3, local_div3.size())):
		var pick_idx := (i * 5 + rng.randi_range(0, maxi(0, local_div3.size() - 1))) % local_div3.size()
		var c: Dictionary = local_div3[pick_idx]
		while used_ids.has(int(c["id"])) and used_ids.size() < local_div3.size():
			pick_idx = (pick_idx + 1) % local_div3.size()
			c = local_div3[pick_idx]
		used_ids[int(c["id"])] = true
		offers.append({
			"club": c,
			"is_local": true,
			"role": "ROTASI" if int(c["ovr"]) >= 60 else "INTI",
		})

	# 2 Foreign Division 3 offers from other countries
	var foreign_nations: Array[int] = [0, 1, 2, 16, 18, 19, 28, 3, 4, 5]
	var f_added := 0
	for _attempt in range(25):
		if f_added >= 2:
			break
		var fn_id: int = foreign_nations[rng.randi_range(0, foreign_nations.size() - 1)]
		if fn_id == nat_id:
			fn_id = (nat_id + 1 + _attempt) % GameData.nations.size()
		var f_div3 := GameData.get_clubs_in_division(fn_id, 3)
		if f_div3.is_empty():
			continue
		var fc: Dictionary = f_div3[rng.randi_range(0, f_div3.size() - 1)]
		if not used_ids.has(int(fc["id"])):
			used_ids[int(fc["id"])] = true
			offers.append({
				"club": fc,
				"is_local": false,
				"role": "ROTASI",
			})
			f_added += 1
	return offers

func get_relation_tier(val: int) -> String:
	if val < 20:
		return "RUSAK"
	elif val < 40:
		return "BEKU"
	elif val < 60:
		return "NETRAL"
	elif val < 80:
		return "AKRAB"
	else:
		return "IDOLA"

func apply_dilemma_choice(choice_dict: Dictionary) -> void:
	if not has_active_career:
		return
	var week := int(career["careerMeta"]["week"])
	if int(career["careerMeta"].get("dilemmaDoneWeek", 0)) == week:
		return
	var eff: Dictionary = choice_dict.get("effects", {})
	var rel: Dictionary = career["playerProfile"]["relations"]
	for rk in GameData.RELATION_KEYS:
		if eff.has(rk):
			rel[rk] = clampi(int(rel[rk]) + int(eff[rk]), 0, 100)
	if eff.has("energy"):
		career["playerProfile"]["energy"] = clampi(int(career["playerProfile"]["energy"]) + int(eff["energy"]), 0, 100)
	if eff.has("cash"):
		career["playerProfile"]["cash"] = maxi(0, int(career["playerProfile"]["cash"]) + int(eff["cash"]))
	if eff.has("xp"):
		_award_xp(int(eff["xp"]))
	career["careerMeta"]["dilemmaDoneWeek"] = week
	save_active_career()
	career_updated.emit()

func _award_xp(amount: int) -> void:
	var mult := 2.0 if _has_perk("xp_ganda") or _has_perk("paket_legenda") else 1.0
	if career["inventory"]["staffHired"].has("pelatih_pribadi"):
		mult += 0.15
	var gained := int(round(float(amount) * mult))
	var p: Dictionary = career["playerProfile"]
	p["xp"] = int(p["xp"]) + gained
	while int(p["xp"]) >= int(p["xpToNext"]):
		p["xp"] = int(p["xp"]) - int(p["xpToNext"])
		p["level"] = int(p["level"]) + 1
		p["skillPoints"] = int(p["skillPoints"]) + 3
		p["xpToNext"] = int(round(float(p["xpToNext"]) * 1.18))
		level_up_triggered.emit(int(p["level"]), 3)

func _has_perk(perk_id: String) -> bool:
	return global_profile.get("owned_perks", []).has(perk_id)

func sim_current_match() -> Dictionary:
	var fix := get_current_fixture()
	if fix.is_empty():
		return {}
	var club := get_current_club()
	var our_ovr := int(club["ovr"]) + int((int(career["playerProfile"]["ovr"]) - 58) * 0.4)
	var opp_ovr := int(fix["opp_ovr"])
	var diff := our_ovr - opp_ovr + (2 if fix["is_home"] else -1)
	var us_goals := clampi(int(randf_range(0.0, 2.5) + float(diff) * 0.06), 0, 5)
	var them_goals := clampi(int(randf_range(0.0, 2.3) - float(diff) * 0.05), 0, 5)
	var my_goals := 1 if (us_goals > 0 and randf() < 0.45) else 0
	var my_assists := 1 if (us_goals - my_goals > 0 and randf() < 0.35) else 0
	var rating := clampf(6.1 + float(my_goals) * 1.3 + float(my_assists) * 0.8 + (0.6 if us_goals > them_goals else -0.3), 4.5, 9.8)
	return finish_match({
		"score_us": us_goals,
		"score_them": them_goals,
		"my_goals": my_goals,
		"my_assists": my_assists,
		"rating": rating,
		"penalties_scored": 0,
		"freekicks_scored": 0,
		"dribbles_won": 1 if randf() < 0.5 else 0,
		"passes_won": 1 if my_assists > 0 else 0,
		"shots": [],
		"moviola_clip": {},
	})

func finish_match(result: Dictionary) -> Dictionary:
	if not has_active_career:
		return {}
	var fix := get_current_fixture()
	var week := int(career["careerMeta"]["week"])
	var us := int(result.get("score_us", 0))
	var them := int(result.get("score_them", 0))
	var my_g := int(result.get("my_goals", 0))
	var my_a := int(result.get("my_assists", 0))
	var rating := clampf(float(result.get("rating", 6.2)), 1.0, 10.0)
	var is_motm := rating >= 8.2 or (my_g >= 2 and us >= them)

	# Record fixture
	fix["played"] = true
	fix["score_us"] = us
	fix["score_them"] = them

	# Update League Table (user match + AI matches for other 30 teams in division!)
	if fix["comp"] == "LIGA":
		_simulate_division_round(us, them, int(fix["opp_club_id"]))

	# Update Stats
	var st: Dictionary = career["stats"]
	st["matches"] = int(st["matches"]) + 1
	if get_player_role_status() == "INTI":
		st["starts"] = int(st["starts"]) + 1
	else:
		st["subs"] = int(st["subs"]) + 1
	if us > them:
		st["wins"] = int(st["wins"]) + 1
	elif us == them:
		st["draws"] = int(st["draws"]) + 1
	else:
		st["losses"] = int(st["losses"]) + 1
	st["goals"] = int(st["goals"]) + my_g
	st["assists"] = int(st["assists"]) + my_a
	if is_motm:
		st["motm"] = int(st["motm"]) + 1
	st["bestMatchGoals"] = maxi(int(st["bestMatchGoals"]), my_g)
	st["bestRating"] = maxf(float(st["bestRating"]), snappedf(rating, 0.1))
	st["totalRating"] = float(st["totalRating"]) + rating
	st["penaltiesScored"] = int(st["penaltiesScored"]) + int(result.get("penalties_scored", 0))
	st["freekicksScored"] = int(st["freekicksScored"]) + int(result.get("freekicks_scored", 0))
	st["dribblesWon"] = int(st["dribblesWon"]) + int(result.get("dribbles_won", 0))
	st["passesWon"] = int(st["passesWon"]) + int(result.get("passes_won", 0))
	if fix["comp"] == "TIMNAS":
		st["intlCaps"] = int(st["intlCaps"]) + 1
		st["intlGoals"] = int(st["intlGoals"]) + my_g

	# Update season history row
	var sh: Array = career["seasonHistory"]
	if not sh.is_empty():
		var cur_sh: Dictionary = sh[sh.size() - 1]
		cur_sh["matches"] = int(cur_sh["matches"]) + 1
		cur_sh["goals"] = int(cur_sh["goals"]) + my_g
		cur_sh["assists"] = int(cur_sh["assists"]) + my_a
		cur_sh["avgRating"] = snappedf(float(st["totalRating"]) / maxf(1.0, float(st["matches"])), 0.1)

	# Telemetry & Moviola
	var shots: Array = result.get("shots", [])
	for s_entry in shots:
		s_entry["season"] = career["careerMeta"]["year"]
		s_entry["matchId"] = "W%02d_%s" % [week, fix["opp_code"]]
		career["shotTelemetry"].append(s_entry)
		if s_entry.get("outcome") == "GOAL":
			st["longestGoalMeters"] = maxf(float(st["longestGoalMeters"]), float(s_entry.get("distanceMeters", 0.0)))

	var clip: Dictionary = result.get("moviola_clip", {})
	if not clip.is_empty():
		clip["match_title"] = "%s %d - %d %s" % [get_current_club()["code"], us, them, fix["opp_code"]]
		clip["season"] = career["careerMeta"]["year"]
		career["moviolaClips"].append(clip)
		if career["moviolaClips"].size() > 25:
			career["moviolaClips"].pop_front()
		last_moviola_clip = clip

	# Payouts: wage + sponsor + double salary perk
	var gaji_mult := 2 if (_has_perk("gaji_ganda") or _has_perk("paket_legenda")) else 1
	var wage := int(career["contract"]["salaryPerMatch"]) * gaji_mult
	var sp_pay := 0
	var sp_goal_bonus := 0
	var active_sp_id := str(career["sponsor"].get("activeId", ""))
	for sp_item in GameData.sponsors_catalog:
		if sp_item["id"] == active_sp_id:
			sp_pay = int(sp_item["per_match"]) * gaji_mult
			sp_goal_bonus = int(sp_item["per_goal"]) * my_g * gaji_mult
			career["sponsor"]["goalsProgress"] = int(career["sponsor"]["goalsProgress"]) + my_g
	career["contract"]["goalsScoredThisSeason"] = int(career["contract"]["goalsScoredThisSeason"]) + my_g
	var total_cash_earned := wage + sp_pay + sp_goal_bonus
	career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) + total_cash_earned

	# Energy drain & weekly recovery
	var fisik := get_effective_attribute("fisik")
	var drain := int(round(lerpf(18.0, 9.0, float(fisik) / 99.0)))
	if career["inventory"]["staffHired"].has("kebugaran"):
		drain = int(round(float(drain) * 0.8))
	var rec := 10
	if career["inventory"]["staffHired"].has("fisioterapis"):
		rec += 8
	for l_id in career["inventory"]["lifestyleOwned"]:
		if l_id == "apartemen":
			rec += 5
		elif l_id == "rumah_kota":
			rec += 10
		elif l_id == "vila_mewah":
			rec += 18
	career["playerProfile"]["energy"] = clampi(int(career["playerProfile"]["energy"]) - drain + rec, 15, 100)

	# Relations & Legacy points & Followers
	var rel: Dictionary = career["playerProfile"]["relations"]
	var perf_delta := 2 if rating >= 7.2 else (0 if rating >= 6.0 else -2)
	rel["pelatih"] = clampi(int(rel["pelatih"]) + perf_delta + (1 if us > them else 0), 0, 100)
	rel["fans"] = clampi(int(rel["fans"]) + my_g * 2 + (2 if is_motm else 0) + perf_delta, 0, 100)
	rel["pers"] = clampi(int(rel["pers"]) + (2 if is_motm else 0) + (1 if my_g > 0 else 0), 0, 100)
	rel["ruangGanti"] = clampi(int(rel["ruangGanti"]) + my_a * 2 + (1 if us > them else 0), 0, 100)

	var follower_gain := (my_g * 450 + my_a * 250 + (800 if is_motm else 120))
	if career["inventory"]["staffHired"].has("agen_pr"):
		follower_gain = int(round(float(follower_gain) * 1.25))
	st["followers"] = int(st["followers"]) + follower_gain

	var legacy_add := my_g * 2 + my_a + (2 if is_motm else 0) + (2 if fix["comp"] == "TIMNAS" else 0)
	career["careerMeta"]["legacyPoints"] = int(career["careerMeta"]["legacyPoints"]) + legacy_add
	_update_legacy_tier()

	# Position proficiency improvement
	var fav_pos := str(career["playerProfile"]["favoritePosition"])
	var learned: Dictionary = career["playerProfile"]["learnedPositions"]
	if learned.has(fav_pos):
		learned[fav_pos] = mini(100, int(learned[fav_pos]) + 3)

	# XP & Level Up
	var prev_level := int(career["playerProfile"]["level"])
	var xp_gain := 45 + my_g * 25 + my_a * 15 + (25 if is_motm else 0) + (20 if us > them else 5)
	_award_xp(xp_gain)

	# News feed
	if is_motm:
		_push_news("LIGA", "%s menjadi Pemain Terbaik Laga saat %s vs %s (%d-%d)." % [career["playerProfile"]["name"], get_current_club()["code"], fix["opp_code"], us, them])
	elif my_g > 0:
		_push_news("KLUB", "%s mencetak %d gol kontra %s." % [career["playerProfile"]["name"], my_g, fix["opp_name"]])

	# Advance week & transfer window
	var tw := int(career["careerMeta"].get("transferWindowWeeksLeft", 0))
	if tw > 0:
		career["careerMeta"]["transferWindowWeeksLeft"] = tw - 1
		_refresh_transfer_offers()
	else:
		career["transferOffers"] = []

	career["contract"]["clubPoints"] = clampi(int(career["contract"]["clubPoints"]) + 1 + (1 if us > them else 0), 0, 200)
	career["contract"]["clubRequestsLevel"] = clampi(1 + int(int(career["contract"]["clubPoints"]) / 35), 1, 6)

	var season_ended := false
	var season_summary := {}
	if week >= int(career["careerMeta"]["maxWeeks"]):
		season_summary = _rollover_season()
		season_ended = true
	else:
		career["careerMeta"]["week"] = week + 1
		career["careerMeta"]["currentDilemma"] = GameData.dilemmas_catalog[week % GameData.dilemmas_catalog.size()]

	evaluate_achievements()
	save_active_career()

	last_match_report = {
		"fixture": fix,
		"score_us": us,
		"score_them": them,
		"my_goals": my_g,
		"my_assists": my_a,
		"rating": snappedf(rating, 0.1),
		"motm": is_motm,
		"xp_gained": xp_gain,
		"leveled_up": int(career["playerProfile"]["level"]) > prev_level,
		"new_level": int(career["playerProfile"]["level"]),
		"cash_earned": total_cash_earned,
		"legacy_add": legacy_add,
		"follower_gain": follower_gain,
		"season_ended": season_ended,
		"season_summary": season_summary,
	}
	career_updated.emit()
	return last_match_report

func _simulate_division_round(user_us: int, user_them: int, opp_id: int) -> void:
	var my_cid := int(career["playerProfile"]["clubId"])
	var tbl: Array = career["leagueTable"]
	var other_rows: Array[Dictionary] = []
	var results_log: Array[Dictionary] = []
	var my_row: Dictionary = {}
	var opp_row: Dictionary = {}
	for row in tbl:
		var cid := int(row["club_id"])
		if cid == my_cid:
			my_row = row
			_apply_match_to_table_row(row, user_us, user_them)
		elif cid == opp_id:
			opp_row = row
			_apply_match_to_table_row(row, user_them, user_us)
		else:
			other_rows.append(row)
	if not my_row.is_empty() and not opp_row.is_empty():
		results_log.append({
			"home_name": str(my_row["name"]), "home_id": my_cid, "home_g": user_us,
			"away_name": str(opp_row["name"]), "away_id": opp_id, "away_g": user_them, "is_user": true,
		})

	for i in range(0, other_rows.size() - 1, 2):
		var a := other_rows[i]
		var b := other_rows[i + 1]
		var diff := int(a["ovr"]) - int(b["ovr"])
		var ga := clampi(int(randf_range(0.0, 2.4) + float(diff) * 0.05), 0, 5)
		var gb := clampi(int(randf_range(0.0, 2.2) - float(diff) * 0.05), 0, 5)
		_apply_match_to_table_row(a, ga, gb)
		_apply_match_to_table_row(b, gb, ga)
		results_log.append({
			"home_name": str(a["name"]), "home_id": int(a["club_id"]), "home_g": ga,
			"away_name": str(b["name"]), "away_id": int(b["club_id"]), "away_g": gb, "is_user": false,
		})
	career["careerMeta"]["lastMatchdayResults"] = results_log

func _apply_match_to_table_row(row: Dictionary, gf: int, ga: int) -> void:
	row["p"] = int(row["p"]) + 1
	row["gf"] = int(row["gf"]) + gf
	row["ga"] = int(row["ga"]) + ga
	var res_ch := "S"
	if gf > ga:
		row["w"] = int(row["w"]) + 1
		row["pts"] = int(row["pts"]) + 3
		res_ch = "M"
	elif gf == ga:
		row["d"] = int(row["d"]) + 1
		row["pts"] = int(row["pts"]) + 1
	else:
		row["l"] = int(row["l"]) + 1
		res_ch = "K"
	var fm: Array = row["form"]
	fm.append(res_ch)
	if fm.size() > 5:
		fm.pop_front()

func _update_legacy_tier() -> void:
	var pts := int(career["careerMeta"]["legacyPoints"])
	var trophies := int(career["stats"]["trophies"])
	var tier := "PROSPEK"
	if pts >= 650 and trophies >= 8:
		tier = "LEGENDA"
	elif pts >= 650:
		tier = "BINTANG DUNIA"
	elif pts >= 300:
		tier = "ANDALAN"
	elif pts >= 100:
		tier = "PROFESIONAL"
	career["careerMeta"]["legacyTier"] = tier

func _rollover_season() -> Dictionary:
	var pos := get_user_league_position()
	var club := get_current_club()
	var div_num := int(club["division"])
	var nat_id := int(club["nation_id"])
	var st: Dictionary = career["stats"]
	var trophies_won: Array[String] = []

	if div_num == 3:
		st["seasonsDiv3"] = int(st["seasonsDiv3"]) + 1

	# Champion or Promotion (Top 3 in Div 3, Top 2 in Div 2)
	if pos == 1:
		var t_name := "JUARA LIGA ke-%d (%s)" % [div_num, GameData.nations[nat_id]["name"]]
		trophies_won.append(t_name)
		career["trophiesList"].append({"name": t_name, "season": career["careerMeta"]["year"], "type": "LIGA"})
		st["trophies"] = int(st["trophies"]) + 1
		career["careerMeta"]["legacyPoints"] = int(career["careerMeta"]["legacyPoints"]) + 40
	if pos <= 3 and div_num > 1:
		st["promotions"] = int(st["promotions"]) + 1
		club["division"] = div_num - 1
		_push_news("LIGA", "%s PROMOSI ke Divisi ke-%d!" % [club["name"], div_num - 1])

	# Sponsor end-of-season bonus
	var sp_id := str(career["sponsor"].get("activeId", ""))
	var sp_payout := 0
	for sp_item in GameData.sponsors_catalog:
		if sp_item["id"] == sp_id and int(career["sponsor"]["goalsProgress"]) >= int(sp_item["target_goals"]):
			sp_payout = int(sp_item["season_bonus"]) * (2 if _has_perk("gaji_ganda") else 1)
			career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) + sp_payout
	career["sponsor"]["goalsProgress"] = 0

	# Contract target bonus
	if int(career["contract"]["goalsScoredThisSeason"]) >= int(career["contract"]["goalTarget"]):
		career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) + int(career["contract"]["targetBonus"])
	career["contract"]["goalsScoredThisSeason"] = 0
	career["contract"]["yearsLeft"] = maxi(1, int(career["contract"]["yearsLeft"]) - 1)

	# Advance year & age
	career["careerMeta"]["year"] = int(career["careerMeta"]["year"]) + 1
	career["careerMeta"]["seasonCalendarYear"] = int(career["careerMeta"]["seasonCalendarYear"]) + 1
	career["careerMeta"]["week"] = 1
	career["careerMeta"]["transferWindowWeeksLeft"] = 4
	career["playerProfile"]["age"] = int(career["playerProfile"]["age"]) + 1

	var new_div_clubs := GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	career["leagueTable"] = _init_league_table(new_div_clubs)
	career["schedule"] = _build_season_schedule(new_div_clubs, int(club["id"]), int(club["nation_id"]), int(club["division"]))
	career["seasonHistory"].append({
		"season": career["careerMeta"]["year"],
		"clubId": int(club["id"]),
		"clubCode": club["code"],
		"matches": 0, "goals": 0, "assists": 0, "avgRating": 0.0,
	})
	_update_legacy_tier()
	return {"league_pos": pos, "trophies": trophies_won, "sponsor_bonus": sp_payout}

func _refresh_transfer_offers() -> void:
	if not career.get("transferOffers", []).is_empty():
		return
	var ovr := int(career["playerProfile"]["ovr"])
	var my_cid := int(career["playerProfile"]["clubId"])
	var offers: Array[Dictionary] = []
	for c in GameData.clubs:
		var covr := int(c["ovr"])
		if int(c["id"]) != my_cid and abs(covr - ovr) <= 8:
			offers.append({
				"club_id": int(c["id"]),
				"club_name": c["name"],
				"nation": GameData.nations[int(c["nation_id"])]["name"],
				"division": int(c["division"]),
				"ovr": covr,
				"salary": int(covr * 18 + randi_range(80, 320)),
				"years": 3,
			})
			if offers.size() >= 3:
				break
	career["transferOffers"] = offers

func accept_transfer(offer: Dictionary, chosen_num: int = 9) -> void:
	if not has_active_career:
		return
	var new_cid := int(offer["club_id"])
	var new_club := GameData.clubs[new_cid]
	career["playerProfile"]["clubId"] = new_cid
	career["playerProfile"]["appearance"]["shirt_num"] = chosen_num
	career["contract"]["salaryPerMatch"] = int(offer["salary"])
	career["contract"]["yearsLeft"] = int(offer["years"])
	career["contract"]["clubPoints"] = 20
	career["contract"]["clubRequestsLevel"] = 1
	career["stats"]["transfers"] = int(career["stats"]["transfers"]) + 1
	career["transferOffers"] = []
	var div_clubs := GameData.get_clubs_in_division(int(new_club["nation_id"]), int(new_club["division"]))
	career["leagueTable"] = _init_league_table(div_clubs)
	career["schedule"] = _build_season_schedule(div_clubs, new_cid, int(new_club["nation_id"]), int(new_club["division"]))
	career["clubSquad"] = _build_club_squad(new_cid, career["playerProfile"]["name"], career["playerProfile"]["naturalPosition"], career["playerProfile"]["appearance"])
	_push_news("DUNIA", "%s resmi pindah ke %s dengan nomor punggung #%d!" % [career["playerProfile"]["name"], new_club["name"], chosen_num])
	recalculate_ovr()
	evaluate_achievements()
	save_active_career()
	career_updated.emit()

func _push_news(channel: String, text: String) -> void:
	var item := {"channel": channel, "season": career["careerMeta"]["year"], "text": text}
	career["news"].push_front(item)
	if career["news"].size() > 60:
		career["news"].pop_back()
	news_added.emit(item)

func buy_boot(boot_id: int) -> bool:
	var boot: Dictionary = GameData.boots_catalog[clampi(boot_id, 0, 10)]
	var owned: Array = career["inventory"]["bootsOwned"]
	if owned.has(boot_id):
		career["playerProfile"]["appearance"]["boot_id"] = boot_id
		recalculate_ovr()
		save_active_career()
		career_updated.emit()
		return true
	var price := int(boot["price"])
	if int(career["playerProfile"]["cash"]) < price:
		return false
	career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) - price
	owned.append(boot_id)
	career["playerProfile"]["appearance"]["boot_id"] = boot_id
	recalculate_ovr()
	evaluate_achievements()
	save_active_career()
	career_updated.emit()
	return true

func hire_staff(staff_id: String) -> bool:
	var owned: Array = career["inventory"]["staffHired"]
	if owned.has(staff_id) or owned.size() >= 6:
		return false
	for s in GameData.staff_catalog:
		if s["id"] == staff_id:
			var price := int(s["price"])
			if int(career["playerProfile"]["cash"]) < price:
				return false
			career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) - price
			owned.append(staff_id)
			evaluate_achievements()
			save_active_career()
			career_updated.emit()
			return true
	return false

func buy_lifestyle(item_id: String) -> bool:
	var owned: Array = career["inventory"]["lifestyleOwned"]
	if owned.has(item_id):
		return false
	for item in GameData.lifestyle_catalog:
		if item["id"] == item_id:
			var price := int(item["price"])
			if int(career["playerProfile"]["cash"]) < price:
				return false
			career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) - price
			owned.append(item_id)
			career["stats"]["lifestyleBought"] = int(career["stats"].get("lifestyleBought", 0)) + 1
			evaluate_achievements()
			save_active_career()
			career_updated.emit()
			return true
	return false

func buy_energy_drink() -> bool:
	var price := 1200
	if int(career["playerProfile"]["cash"]) < price:
		return false
	career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) - price
	career["playerProfile"]["energy"] = mini(100, int(career["playerProfile"]["energy"]) + 35)
	save_active_career()
	career_updated.emit()
	return true

func buy_or_equip_cosmetic(cat: String, item_id: String, price: int) -> bool:
	var owned: Array = global_profile["owned_cosmetics"].get(cat, ["default"])
	if not owned.has(item_id):
		if not has_active_career or int(career["playerProfile"]["cash"]) < price:
			return false
		career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) - price
		owned.append(item_id)
		global_profile["owned_cosmetics"][cat] = owned
	var slot_map := {
		"CINCIN": "ringId", "AIM": "aimId", "JEJAK": "trailId",
		"LENCANA": "badgeId", "KARTU": "cardFrameId"
	}
	var slot_key: String = str(slot_map.get(cat, "ringId"))
	if has_active_career:
		career["playerProfile"]["cosmetics"][slot_key] = item_id
		save_active_career()
	save_global_profile()
	career_updated.emit()
	return true

func unlock_perk(perk_id: String, price: int) -> bool:
	var perks: Array = global_profile.get("owned_perks", [])
	if perks.has(perk_id):
		return true
	if has_active_career and int(career["playerProfile"]["cash"]) >= price:
		career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) - price
		perks.append(perk_id)
		global_profile["owned_perks"] = perks
		save_active_career()
		career_updated.emit()
		return true
	# Also allow unlocking in offline sandbox demo mode if user has no active cash
	if not has_active_career:
		return false
	return false

func evaluate_achievements() -> void:
	if not has_active_career:
		return
	var unlocked: Dictionary = global_profile.get("unlocked_achievements", {})
	var st: Dictionary = career["stats"]
	var p: Dictionary = career["playerProfile"]
	var m: Dictionary = career["careerMeta"]

	var metrics := {
		"sponsors_signed": int(st.get("sponsorsSigned", 0)),
		"goals": int(st.get("goals", 0)),
		"assists": int(st.get("assists", 0)),
		"best_match_goals": int(st.get("bestMatchGoals", 0)),
		"penalties_scored": int(st.get("penaltiesScored", 0)),
		"freekicks_scored": int(st.get("freekicksScored", 0)),
		"promotions": int(st.get("promotions", 0)),
		"matches": int(st.get("matches", 0)),
		"wins": int(st.get("wins", 0)),
		"seasons_div3": int(st.get("seasonsDiv3", 0)),
		"motm": int(st.get("motm", 0)),
		"transfers": int(st.get("transfers", 0)),
		"fans_score": int(p["relations"]["fans"]),
		"dribbles_won": int(st.get("dribblesWon", 0)),
		"passes_won": int(st.get("passesWon", 0)),
		"finals_lost": int(st.get("finalsLost", 0)),
		"style_edits": int(st.get("styleEdits", 0)),
		"lifestyle_bought": int(st.get("lifestyleBought", 0)),
		"ovr": int(p["ovr"]),
		"trophies": int(st.get("trophies", 0)),
		"legacy_points": int(m.get("legacyPoints", 0)),
		"followers": int(st.get("followers", 0)),
		"cash": int(p["cash"]),
		"intl_caps": int(st.get("intlCaps", 0)),
		"intl_goals": int(st.get("intlGoals", 0)),
		"positions_learned": p["learnedPositions"].size(),
		"staff_hired": career["inventory"]["staffHired"].size(),
		"boots_owned": career["inventory"]["bootsOwned"].size(),
		"level": int(p["level"]),
		"seasons_played": int(m.get("year", 1)),
	}

	var newly_unlocked := false
	for ach in GameData.achievements:
		var aid: String = ach["id"]
		if unlocked.has(aid):
			continue
		var cur_val := int(metrics.get(ach["metric"], 0))
		if cur_val >= int(ach["target"]):
			unlocked[aid] = Time.get_unix_time_from_system()
			newly_unlocked = true
			AudioSynth.play_achievement()
			achievement_unlocked.emit(ach)
	if newly_unlocked:
		global_profile["unlocked_achievements"] = unlocked
		save_global_profile()

func get_achievement_progress(ach: Dictionary) -> int:
	if not has_active_career:
		return 0
	var st: Dictionary = career["stats"]
	var p: Dictionary = career["playerProfile"]
	var m: Dictionary = career["careerMeta"]
	match str(ach["metric"]):
		"ovr": return int(p["ovr"])
		"goals": return int(st.get("goals", 0))
		"assists": return int(st.get("assists", 0))
		"matches": return int(st.get("matches", 0))
		"wins": return int(st.get("wins", 0))
		"motm": return int(st.get("motm", 0))
		"cash": return int(p["cash"])
		"legacy_points": return int(m.get("legacyPoints", 0))
		"level": return int(p["level"])
		"trophies": return int(st.get("trophies", 0))
		_: return 0
