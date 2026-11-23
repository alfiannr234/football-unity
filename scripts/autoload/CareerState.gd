extends Node

signal career_updated
signal achievement_unlocked(ach: Dictionary)
signal news_added(item: Dictionary)
signal level_up_triggered(new_level: int, points_added: int)

const SAVES_DIR := "user://saves/"
const META_PATH := "user://saves/slots_meta.json"
const GLOBAL_PATH := "user://global_profile.json"
const TOTAL_WORLD_PLAYERS := 21289
const SEASON_MONTHS: Array[String] = ["AGUSTUS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DESEMBER", "JANUARI", "FEBRUARI", "MARET", "APRIL", "MEI"]
const ConfederationDataScript := preload("res://scripts/data/ConfederationData.gd")

var active_slot: int = -1
var has_active_career: bool = false
var career: Dictionary = {}
var _world_table_cache: Dictionary = {}

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

	# Distribute remaining players across all 2,731 clubs (~7-8 core players per club) + 84 Free Agents (TANPA KLUB)
	var free_agent_start: int = TOTAL_WORLD_PLAYERS - 84
	while idx < TOTAL_WORLD_PLAYERS:
		var is_fa: bool = (idx >= free_agent_start)
		var c_id: int = -1 if is_fa else (idx % clubs_count)
		var nat_id: int = 0
		var p_ovr: int = 62
		var p_age: int = rng.randi_range(17, 35)
		var age_factor: float = 1.45 if p_age <= 23 else (1.0 if p_age <= 29 else 0.48)
		var p_val: int = 1200

		if is_fa:
			nat_id = rng.randi_range(0, GameData.nations.size() - 1)
			p_ovr = clampi(56 + ((idx - free_agent_start) * 7) % 16, 56, 71)
			p_age = rng.randi_range(19, 34)
			age_factor = 1.25 if p_age <= 23 else (1.0 if p_age <= 28 else 0.65)
			p_val = clampi(int(pow(maxf(1.0, float(p_ovr) - 42.0), 1.85) * 4.8 * age_factor), 500, 3800)
		else:
			var c_dict: Dictionary = GameData.clubs[c_id]
			nat_id = int(c_dict["nation_id"])
			if rng.randf() < 0.22:
				nat_id = rng.randi_range(0, GameData.nations.size() - 1)
			p_ovr = clampi(int(c_dict["ovr"]) + rng.randi_range(-6, 7), 44, 89)
			p_val = int(pow(maxf(1.0, float(p_ovr) - 42.0), 2.15) * 14.0 * age_factor)

		var fn: String = GameData.FIRST_NAMES[(idx * 7 + rng.randi_range(0, 11)) % GameData.FIRST_NAMES.size()]
		var ln: String = GameData.LAST_NAMES[(idx * 13 + rng.randi_range(0, 17)) % GameData.LAST_NAMES.size()]

		wp_name[idx] = "%s %s" % [fn, ln]
		wp_club[idx] = c_id
		wp_nat[idx] = nat_id
		wp_pos[idx] = (idx % pos_count)
		wp_age[idx] = p_age
		wp_ovr[idx] = p_ovr
		wp_val[idx] = maxi(250, p_val)
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

func get_world_player_positions(wp_idx: int) -> Array[String]:
	if wp_idx < 0 or wp_idx >= TOTAL_WORLD_PLAYERS:
		return ["ST"]
	var primary: String = GameData.POSITIONS[int(wp_pos[wp_idx]) % GameData.POSITIONS.size()]
	if primary == "GK":
		return ["GK"]
	var alt_map := {
		"CB": ["LB", "RB", "CDM"],
		"LB": ["CB", "RB", "LM"],
		"RB": ["CB", "LB", "RM"],
		"CDM": ["CM", "CB", "CAM"],
		"CM": ["CDM", "CAM", "LM"],
		"LM": ["LW", "CM", "RM"],
		"RM": ["RW", "CM", "LM"],
		"CAM": ["CM", "ST", "RW"],
		"LW": ["RW", "LM", "ST"],
		"RW": ["LW", "RM", "CAM"],
		"ST": ["LW", "RW", "CAM"],
	}
	var out: Array[String] = [primary]
	var seed_v: int = abs(int(wp_seed[wp_idx]))
	var extra_cnt: int = seed_v % 3  # 0, 1, or 2 secondary positions (total 1..3 matching Gambar 2!)
	var alts: Array = alt_map.get(primary, [])
	for k in range(mini(extra_cnt, alts.size())):
		var candidate: String = str(alts[(seed_v + k) % alts.size()])
		if not out.has(candidate):
			out.append(candidate)
	return out

func filter_world_players(filters: Dictionary) -> PackedInt32Array:
	ensure_world_database()
	var pos_list: Array = filters.get("positions", [])
	var has_pos: bool = not pos_list.is_empty()
	var pos_set: Dictionary = {}
	for ps in pos_list:
		pos_set[str(ps)] = true

	var age_f: String = str(filters.get("age", "SEMUA"))
	var val_f: String = str(filters.get("val", "SEMUA"))
	var nat_f: int = int(filters.get("nat_id", -1))
	var league_f: int = int(filters.get("league_nat_id", -1))
	var div_f: int = int(filters.get("division", 0))
	var club_mode: String = str(filters.get("club_mode", "SEMUA"))
	var query: String = str(filters.get("query", "")).strip_edges().to_lower()
	var my_cid: int = int(get_current_club().get("id", -1)) if has_active_career else -1

	if not has_pos and age_f == "SEMUA" and val_f == "SEMUA" and nat_f < 0 and league_f < 0 and div_f == 0 and club_mode == "SEMUA" and query == "":
		return wp_rank_order

	var out := PackedInt32Array()
	var clubs_n: int = GameData.clubs.size()
	for r in range(wp_rank_order.size()):
		var idx: int = wp_rank_order[r]
		var cid: int = int(wp_club[idx])

		# Club filter (SEMUA / FREE = TANPA KLUB / MINE)
		if club_mode == "FREE":
			if cid >= 0:
				continue
		elif club_mode == "MINE":
			if cid != my_cid:
				continue

		# Nation (player nationality) filter
		if nat_f >= 0 and int(wp_nat[idx]) != nat_f:
			continue

		# League & Division filter (ignored for FREE agent mode so free agents stay visible like Gambar 10!)
		if club_mode != "FREE" and (league_f >= 0 or div_f > 0):
			if cid < 0 or cid >= clubs_n:
				continue
			var cd: Dictionary = GameData.clubs[cid]
			if league_f >= 0 and int(cd["nation_id"]) != league_f:
				continue
			if div_f > 0 and int(cd["division"]) != div_f:
				continue

		# Age bucket filter (Gambar 5)
		if age_f != "SEMUA":
			var ag: int = int(wp_age[idx])
			match age_f:
				"U21":
					if ag > 21: continue
				"22_25":
					if ag < 22 or ag > 25: continue
				"26_29":
					if ag < 26 or ag > 29: continue
				"30_33":
					if ag < 30 or ag > 33: continue
				"34P":
					if ag < 34: continue

		# Market value bucket filter (Gambar 6: wp_val stored in thousands -> val_m = wp_val / 1000.0)
		if val_f != "SEMUA":
			var vm: float = float(wp_val[idx]) / 1000.0
			match val_f:
				"LT2":
					if vm >= 2.0: continue
				"2_6":
					if vm < 2.0 or vm >= 6.0: continue
				"6_15":
					if vm < 6.0 or vm >= 15.0: continue
				"15_40":
					if vm < 15.0 or vm >= 40.0: continue
				"40_80":
					if vm < 40.0 or vm >= 80.0: continue
				"80P":
					if vm < 80.0: continue

		# Multi-position filter (Gambar 4)
		if has_pos:
			var p_positions: Array[String] = get_world_player_positions(idx)
			var matched_pos := false
			for pp in p_positions:
				if pos_set.has(pp):
					matched_pos = true
					break
			if not matched_pos:
				continue

		# Search query filter (CARI)
		if query != "" and not wp_name[idx].to_lower().contains(query):
			continue

		out.append(idx)
	return out

func get_world_player_detail(wp_idx: int) -> Dictionary:
	ensure_world_database()
	var idx: int = clampi(wp_idx, 0, TOTAL_WORLD_PLAYERS - 1)
	var full_name: String = wp_name[idx]
	var parts: PackedStringArray = full_name.split(" ")
	var short_name: String = parts[parts.size() - 1] if parts.size() > 0 else full_name
	var ovr: int = int(wp_ovr[idx])
	var age: int = int(wp_age[idx])
	var nat_id: int = clampi(int(wp_nat[idx]), 0, GameData.nations.size() - 1)
	var cid: int = int(wp_club[idx])
	var is_fa: bool = (cid < 0 or cid >= GameData.clubs.size())
	var club_d: Dictionary = {} if is_fa else GameData.clubs[cid]
	var positions: Array[String] = get_world_player_positions(idx)
	var p_pos: String = positions[0]
	var val_k: int = int(wp_val[idx])
	var val_full: int = val_k * 1000
	var seed_v: int = abs(int(wp_seed[idx]))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 37 + idx * 13 + 91

	var contract_yrs: int = 0 if is_fa else rng.randi_range(1, 5)
	var clause_m: float = 0.0 if is_fa else snappedf((float(val_k) / 1000.0) * rng.randf_range(2.2, 3.6), 0.1)

	# 10 attributes scaled realistically to OVR + primary position (Gambar 3)
	var is_fwd: bool = p_pos in ["ST", "LW", "RW"]
	var is_mid: bool = p_pos in ["CAM", "CM", "CDM", "LM", "RM"]
	var is_def: bool = p_pos in ["CB", "LB", "RB"]
	var is_gk: bool = (p_pos == "GK")
	var attrs := {
		"Tendangan": clampi(ovr + (7 if is_fwd else (-12 if is_gk else 1)) + rng.randi_range(-5, 6), 38, 99),
		"Penyelesaian": clampi(ovr + (8 if is_fwd else (-18 if is_gk else (-6 if is_def else 2))) + rng.randi_range(-5, 6), 35, 99),
		"Lengkung": clampi(ovr + (4 if is_mid or is_fwd else -6) + rng.randi_range(-6, 6), 35, 99),
		"Sundulan": clampi(ovr + (6 if p_pos in ["ST", "CB"] else -4) + rng.randi_range(-6, 7), 38, 99),
		"Penalti": clampi(ovr + (5 if is_fwd or p_pos == "CAM" else -5) + rng.randi_range(-5, 7), 35, 99),
		"Bola mati": clampi(ovr + (4 if is_mid else -5) + rng.randi_range(-6, 7), 35, 99),
		"Kecepatan": clampi(ovr + (6 if p_pos in ["LW", "RW", "ST", "LB", "RB"] else (-10 if is_gk else 0)) + rng.randi_range(-5, 6), 40, 99),
		"Akselerasi": clampi(ovr + (5 if p_pos in ["LW", "RW", "CAM", "ST"] else (-9 if is_gk else 0)) + rng.randi_range(-5, 6), 40, 99),
		"Tekel": clampi(ovr + (8 if is_def or p_pos == "CDM" else (-18 if is_fwd else -4)) + rng.randi_range(-6, 6), 30, 99),
		"Visi": clampi(ovr + (7 if is_mid else 0) + rng.randi_range(-5, 6), 38, 99),
	}

	# Deterministic PixelAvatar appearance
	var appearance := {
		"skin": seed_v % 6,
		"hair_style": (seed_v / 7) % 16,
		"hair_color": (seed_v / 13) % 7,
		"tip_color": 0,
		"beard": (age >= 24 and (seed_v % 3 == 0)),
		"beard_style": ((seed_v / 5) % 4) + 1 if (age >= 24 and (seed_v % 3 == 0)) else 0,
		"sleeve": "PANJANG" if (seed_v % 4 == 0) else "PENDEK",
		"shirt_num": (seed_v % 29) + 1,
	}

	# Transfer history + 4 seasons stats (M1..M4 tabs in Gambar 3)
	var cur_yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var prev_cid: int = (abs(cid + 19 + (seed_v % 120)) % GameData.clubs.size()) if not is_fa else (seed_v % GameData.clubs.size())
	var prev_club: Dictionary = GameData.clubs[prev_cid]
	var history_transfers: Array[Dictionary] = []
	if is_fa:
		history_transfers.append({
			"span": "M1-M%d" % maxi(1, cur_yr),
			"club_id": prev_cid,
			"club_name": str(prev_club["name"]),
			"nat_id": int(prev_club["nation_id"]),
			"tag": "KONTRAK HABIS",
		})
		history_transfers.append({
			"span": "SAAT INI",
			"club_id": -1,
			"club_name": "TANPA KLUB (BEBAS)",
			"nat_id": nat_id,
			"tag": "BEBAS",
		})
	else:
		var join_yr: int = maxi(1, cur_yr - rng.randi_range(0, 2))
		if join_yr > 1 or age >= 22:
			history_transfers.append({
				"span": "M1-M%d" % maxi(1, join_yr),
				"club_id": prev_cid,
				"club_name": str(prev_club["name"]),
				"nat_id": int(prev_club["nation_id"]),
				"tag": "TRANSFER",
			})
		history_transfers.append({
			"span": "SEJAK M%d" % join_yr,
			"club_id": cid,
			"club_name": str(club_d["name"]),
			"nat_id": int(club_d["nation_id"]),
			"tag": "AKTIF",
		})

	var season_stats: Array[Dictionary] = []
	for s_i in range(4):
		var mn: int = rng.randi_range(18, 36)
		var g_s: int = rng.randi_range(8, 28) if is_fwd else (rng.randi_range(3, 14) if is_mid else rng.randi_range(0, 4))
		var a_s: int = rng.randi_range(3, 12) if is_fwd else (rng.randi_range(5, 16) if is_mid else rng.randi_range(0, 5))
		var rtg: float = snappedf(clampf(6.2 + float(ovr - 60) * 0.05 + rng.randf_range(-0.3, 0.5), 6.0, 8.8), 0.1)
		season_stats.append({"label": "M%d" % (s_i + 1), "matches": mn, "goals": g_s, "assists": a_s, "rating": rtg})

	# Transfer interest & comparison against User's Club
	var my_club: Dictionary = get_current_club() if has_active_career else GameData.clubs[0]
	var my_club_ovr: int = int(my_club.get("ovr", 65))
	var my_pos_rank: int = get_user_league_position() if has_active_career else 7
	var target_club_ovr: int = 58 if is_fa else int(club_d.get("ovr", 70))
	var ovr_diff: int = my_club_ovr - target_club_ovr
	var interest_pct: int = clampi(62 + ovr_diff * 2 + (18 if is_fa else 0) + (5 if my_pos_rank <= 5 else -4), 12, 96)
	var pos_rival_ovr: int = clampi(my_club_ovr + rng.randi_range(-3, 4), 52, 90)
	var coach_rel: int = int(career.get("playerProfile", {}).get("relations", {}).get("pelatih", 50)) if has_active_career else 50
	var suara_lv: int = int(career.get("careerMeta", {}).get("clubSuaraLevel", 2)) if has_active_career else 2
	var can_suggest: bool = (not is_fa and cid != int(my_club.get("id", -1)) and (coach_rel >= 35 or suara_lv >= 3)) or (is_fa and (coach_rel >= 35 or suara_lv >= 3))

	var report_lines: Array[String] = []
	if is_fa:
		report_lines.append("Status pemain bebas (TANPA KLUB): bisa direkrut gratis tanpa biaya transfer.")
		report_lines.append("Cukup menegosiasikan gaji sesuai kebutuhan skuad inti timmu.")
	elif ovr >= 85:
		report_lines.append("Klubnya tak menjualnya: hanya bisa pergi lewat klausul pelepasan.")
		report_lines.append("Datang dari klub lebih besar: harga +15 %." if target_club_ovr > my_club_ovr else "Tertarik dengan proyek ambisius klubmu.")
	else:
		report_lines.append("Klubnya terbuka mendengar tawaran transfer yang sesuai nilai pasarnya.")
		report_lines.append("Siap bersaing di posisi %s bersama tim intimu." % p_pos)

	if can_suggest:
		report_lines.append("Hubungan pelatih (%d) & pengaruhmu cukup kuat untuk mengusulkannya ke manajemen." % coach_rel)
	else:
		report_lines.append("Klub belum meminta pendapatmu soal transfer. Dengan hubungan 35, kamu naik ke SUARA dan bisa mengusulkannya.")

	return {
		"wp_idx": idx,
		"name": full_name,
		"short_name": short_name,
		"ovr": ovr,
		"age": age,
		"nat_id": nat_id,
		"club_id": cid,
		"club_name": "TANPA KLUB" if is_fa else str(club_d["name"]),
		"club_code": "TAN" if is_fa else str(club_d.get("code", "CLB")).left(3).to_upper(),
		"club_primary": Color("#475569") if is_fa else club_d.get("primary", Color("#1E64D8")),
		"club_secondary": Color("#CBD5E1") if is_fa else club_d.get("secondary", Color("#FFFFFF")),
		"club_pattern": "solid" if is_fa else str(club_d.get("pattern", "solid")),
		"is_free_agent": is_fa,
		"positions": positions,
		"primary_pos": p_pos,
		"val_k": val_k,
		"val_full": val_full,
		"contract_years": contract_yrs,
		"clause_m": clause_m,
		"attributes": attrs,
		"appearance": appearance,
		"history_transfers": history_transfers,
		"season_stats": season_stats,
		"interest_pct": interest_pct,
		"my_club_ovr": my_club_ovr,
		"pos_rival_ovr": pos_rival_ovr,
		"club_diff": ovr_diff,
		"my_pos_rank": my_pos_rank,
		"can_suggest": can_suggest,
		"report_lines": report_lines,
	}

func suggest_world_player_to_club(wp_idx: int) -> bool:
	if not has_active_career or wp_idx < 0 or wp_idx >= TOTAL_WORLD_PLAYERS:
		return false
	var pname: String = wp_name[wp_idx]
	var p_pos: String = GameData.POSITIONS[int(wp_pos[wp_idx]) % GameData.POSITIONS.size()]
	var p_ovr: int = int(wp_ovr[wp_idx])
	_push_news("KLUB", "Kamu mengusulkan perekrutan %s (%s • OVR %d) kepada manajemen klub." % [pname, p_pos, p_ovr])
	var rel: Dictionary = career["playerProfile"]["relations"]
	rel["pelatih"] = clampi(int(rel.get("pelatih", 60)) + 1, 0, 100)
	save_active_career()
	career_updated.emit()
	return true

func get_transfer_window_status() -> Dictionary:
	if not has_active_career:
		return {"is_open": false, "weeks": 4}
	var meta: Dictionary = career["careerMeta"]
	var tw: int = int(meta.get("transferWindowWeeksLeft", 0))
	if tw > 0:
		return {"is_open": true, "weeks": tw}
	var wk: int = int(meta.get("week", 1))
	var max_wks: int = int(meta.get("maxWeeks", 45))
	# Mid-season winter window opens around week 22; summer window opens at end of season (week 46)
	var wks_until: int = (22 - wk) if wk < 22 else maxi(1, (max_wks + 1) - wk)
	return {"is_open": false, "weeks": wks_until}

func get_sponsor_flavor_text(sponsor_id: String) -> String:
	match sponsor_id:
		"roti_lokal":
			return "Mereka kenal kamu dari kampung. Tiap tahun kamu tampil, kontrakmu naik.\nPRAMUSIM: sekarang atau tahun depan. Begitu kamu memainkan pekan pertama, pintunya tutup, dan yang tidak kamu teken tak akan kembali musim ini."
		"kopi_kota":
			return "Kedai favorit suporter kota ini ingin wajahmu di gelas edisi khusus musim ini.\nKontrak berlaku satu musim penuh dengan bonus besar bila target gol tercapai."
		"apparel_nord":
			return "Merek perlengkapan olahraga regional menawarimu lini sepatu dan kampanye poster di seluruh liga.\nTampil konsisten agar sponsor global mulai melirikmu."
		"energy_volt":
			return "Minuman isotonik papan atas mencari ikon muda bertenaga untuk iklan siaran utama.\nTarget gol lebih tinggi, namun bayaran per laga melonjak tajam."
		"global_tech":
			return "Raksasa teknologi internasional menawarkan kontrak bintang utama dengan bonus akhir musim fantastis.\nHanya pemain papan atas dengan reputasi kuat yang mampu memenuhi targetnya."
	return "Sponsor resmi siap mendanai kariermu sepanjang musim dengan bonus performa gol."

func sign_or_break_sponsor(sponsor_id: String, do_sign: bool) -> void:
	if not has_active_career:
		return
	if do_sign:
		career["sponsor"]["activeId"] = sponsor_id
		career["sponsor"]["goalsProgress"] = 0
		career["stats"]["sponsorsSigned"] = int(career["stats"].get("sponsorsSigned", 0)) + 1
	else:
		if str(career["sponsor"].get("activeId", "")) == sponsor_id:
			career["sponsor"]["activeId"] = ""
	evaluate_achievements()
	save_active_career()
	career_updated.emit()

func get_watched_clubs() -> Array[Dictionary]:
	if not has_active_career:
		return []
	var prof: Dictionary = career["playerProfile"]
	var meta: Dictionary = career["careerMeta"]
	var my_cid: int = int(prof.get("clubId", 0))
	var my_ovr: int = int(prof.get("ovr", 62))
	var yr: int = int(meta.get("year", 1))
	var decisions: Dictionary = meta.get("bursaClubDecisions", {})

	var cid_list: Array[int] = []
	var sc_cid: int = int(meta.get("scoutedByClubId", -1))
	if sc_cid >= 0 and sc_cid < GameData.clubs.size() and sc_cid != my_cid:
		cid_list.append(sc_cid)
	for v in meta.get("agentWatchedClubIds", []):
		var acid: int = int(v)
		if acid >= 0 and acid < GameData.clubs.size() and acid != my_cid and not cid_list.has(acid):
			cid_list.append(acid)
	for v in career.get("followedBackClubs", []):
		var fcid: int = int(v)
		if fcid >= 0 and fcid < GameData.clubs.size() and fcid != my_cid and not cid_list.has(fcid):
			cid_list.append(fcid)

	# Ensure at least 4 realistic clubs near player's OVR are actively watching
	var rng := RandomNumberGenerator.new()
	rng.seed = yr * 4129 + my_cid * 73 + my_ovr * 19
	var guard: int = 0
	while cid_list.size() < 4 and guard < 400:
		guard += 1
		var cand_id: int = rng.randi_range(0, GameData.clubs.size() - 1)
		if cand_id == my_cid or cid_list.has(cand_id):
			continue
		var cd: Dictionary = GameData.clubs[cand_id]
		if abs(int(cd.get("ovr", 65)) - my_ovr) <= 10 or guard > 200:
			cid_list.append(cand_id)

	var out: Array[Dictionary] = []
	for cid in cid_list:
		var c: Dictionary = GameData.clubs[cid]
		var nid: int = clampi(int(c.get("nation_id", 0)), 0, GameData.nations.size() - 1)
		var div_n: int = clampi(int(c.get("division", 1)), 1, 3)
		var tbl: Array[Dictionary] = get_live_division_table(nid, div_n)
		var tot_t: int = maxi(1, tbl.size())
		var rk: int = 1
		for i in range(tbl.size()):
			if int(tbl[i]["club_id"]) == cid:
				rk = i + 1
				break
		var dec: String = str(decisions.get(str(cid), ""))
		var status_txt: String = "DEKAT"
		if dec == "GREEN":
			status_txt = "LAMPU HIJAU"
		elif dec == "DECLINED":
			status_txt = "DITOLAK"
		out.append({
			"club_id": cid,
			"name": str(c.get("name", "KLUB")),
			"code": str(c.get("code", "CLB")).left(3).to_upper(),
			"nation_id": nid,
			"nation_name": str(GameData.nations[nid].get("name", "LIGA")),
			"division": div_n,
			"ovr": int(c.get("ovr", 65)),
			"rank": rk,
			"total_teams": tot_t,
			"status": status_txt,
			"decision": dec,
			"pen_pelatih": -6,
			"pen_ruang": -4,
			"pen_fans": -5,
		})
	return out

func decide_watched_club_gossip(club_id: int, green_light: bool) -> Dictionary:
	if not has_active_career or club_id < 0 or club_id >= GameData.clubs.size():
		return {}
	var meta: Dictionary = career["careerMeta"]
	var rel: Dictionary = career["playerProfile"]["relations"]
	var decisions: Dictionary = meta.get("bursaClubDecisions", {})
	var cname: String = str(GameData.clubs[club_id].get("name", "Klub"))
	var pname: String = str(career["playerProfile"].get("name", "Pemain"))

	if green_light:
		decisions[str(club_id)] = "GREEN"
		rel["pelatih"] = clampi(int(rel.get("pelatih", 60)) - 6, 0, 100)
		rel["ruangGanti"] = clampi(int(rel.get("ruangGanti", 60)) - 4, 0, 100)
		rel["fans"] = clampi(int(rel.get("fans", 60)) - 5, 0, 100)
		var fbc: Array = career.get("followedBackClubs", [])
		if not fbc.has(club_id):
			fbc.append(club_id)
			career["followedBackClubs"] = fbc
		_push_news("LIGA", "%s memberi LAMPU HIJAU pada ketertarikan %s." % [pname, cname])
		if int(meta.get("transferWindowWeeksLeft", 0)) > 0:
			career["transferOffers"] = []
			_refresh_transfer_offers()
	else:
		decisions[str(club_id)] = "DECLINED"
		rel["pelatih"] = clampi(int(rel.get("pelatih", 60)) + 2, 0, 100)
		rel["fans"] = clampi(int(rel.get("fans", 60)) + 2, 0, 100)
		_push_news("KLUB", "%s menyatakan TAK TERTARIK pada gosip transfer %s." % [pname, cname])

	meta["bursaClubDecisions"] = decisions
	save_active_career()
	career_updated.emit()
	return {"club_id": club_id, "decision": decisions[str(club_id)]}

func get_agent_pitch_costs() -> Dictionary:
	var mv: int = int(career.get("playerProfile", {}).get("marketValue", 1000000)) if has_active_career else 1000000
	var base_scale: float = clampf(float(mv) / 4000000.0, 1.0, 28.0)
	return {
		"TAWARKAN": int(round(2404.0 * base_scale)),
		"SATU_LIGA": int(round(4207.0 * base_scale)),
		"SATU_KLUB": int(round(7212.0 * base_scale)),
	}

func use_agent_pitch(mode: String) -> Dictionary:
	if not has_active_career:
		return {"ok": false, "msg": "Karier tidak aktif."}
	var prof: Dictionary = career["playerProfile"]
	var meta: Dictionary = career["careerMeta"]
	var left: int = int(meta.get("agentPitchesLeft", 3))
	if left <= 0:
		return {"ok": false, "msg": "Jatah pendekatan agen musim ini habis."}
	var costs: Dictionary = get_agent_pitch_costs()
	var cost: int = int(costs.get(mode, 2404))
	if int(prof.get("cash", 0)) < cost:
		return {"ok": false, "msg": "Uang tidak cukup."}

	prof["cash"] = int(prof["cash"]) - cost
	meta["agentPitchesLeft"] = left - 1
	var rel: Dictionary = prof["relations"]
	rel["agen"] = clampi(int(rel.get("agen", 50)) + 4, 0, 100)

	var my_cid: int = int(prof.get("clubId", 0))
	var my_ovr: int = int(prof.get("ovr", 62))
	var my_nid: int = int(get_current_club().get("nation_id", 0))
	var watched: Array = meta.get("agentWatchedClubIds", [])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var added_name: String = ""
	var add_target: int = 2 if mode == "TAWARKAN" else 1
	var added_cnt: int = 0
	for _try in range(200):
		if added_cnt >= add_target:
			break
		var cid: int = rng.randi_range(0, GameData.clubs.size() - 1)
		if cid == my_cid or watched.has(cid):
			continue
		var c: Dictionary = GameData.clubs[cid]
		if mode == "SATU_LIGA" and int(c["nation_id"]) == my_nid:
			continue
		if abs(int(c["ovr"]) - my_ovr) <= 12:
			watched.push_front(cid)
			added_name = str(c["name"])
			added_cnt += 1
	meta["agentWatchedClubIds"] = watched
	career["transferOffers"] = []
	_refresh_transfer_offers()
	if added_name != "":
		_push_news("LIGA", "Agenmu berhasil menarik minat %s untuk memantau performamu." % added_name)
	save_active_career()
	career_updated.emit()
	return {"ok": true, "club_name": added_name}

func get_world_transfers(filters: Dictionary = {}) -> Array[Dictionary]:
	ensure_world_database()
	var league_mode: String = str(filters.get("league_mode", "MINE"))
	var target_nat: int = int(filters.get("nat_id", -1))
	var pos_list: Array = filters.get("positions", [])
	var has_pos: bool = not pos_list.is_empty()
	var pos_set: Dictionary = {}
	for ps in pos_list:
		pos_set[str(ps)] = true
	var sort_mode: String = str(filters.get("sort", "TERBARU"))

	var yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var wk: int = int(career.get("careerMeta", {}).get("week", 12)) if has_active_career else 12
	var my_club: Dictionary = get_current_club() if has_active_career else GameData.clubs[0]
	var my_nat: int = int(my_club.get("nation_id", 0))
	var my_div: int = int(my_club.get("division", 3))

	var nat_pool: Array[int] = []
	var div_focus: int = 0
	if league_mode == "MINE":
		nat_pool.append(my_nat)
		div_focus = my_div
	elif league_mode == "NAT" and target_nat >= 0 and target_nat < GameData.nations.size():
		nat_pool.append(target_nat)
		div_focus = 1
	else:
		# Worldwide transfers across top leagues + user's nation
		for nid in [my_nat, 1, 2, 3, 4, 5, 6, 7, 16, 0, 18, 19]:
			if nid >= 0 and nid < GameData.nations.size() and not nat_pool.has(nid):
				nat_pool.append(nid)

	var m_short := ["AGU", "SEP", "OKT", "NOV", "DES", "JAN", "FEB", "MAR", "APR", "MEI"]
	var cur_m_idx: int = clampi(int((wk - 1) / 4.5), 0, m_short.size() - 1)
	var out: Array[Dictionary] = []
	var clubs_n: int = GameData.clubs.size()
	var per_nat: int = 19 if nat_pool.size() == 1 else 6

	for nid in nat_pool:
		var dest_clubs: Array[Dictionary] = GameData.get_clubs_in_division(nid, div_focus if div_focus > 0 else 1)
		if dest_clubs.is_empty():
			dest_clubs = GameData.get_clubs_in_division(nid, 1)
		if dest_clubs.is_empty():
			continue

		var rng := RandomNumberGenerator.new()
		rng.seed = yr * 6733 + nid * 257 + div_focus * 43 + 19

		for i in range(per_nat):
			var dest_c: Dictionary = dest_clubs[(i * 3 + rng.randi_range(0, dest_clubs.size() - 1)) % dest_clubs.size()]
			var dest_cid: int = int(dest_c["id"])
			var dest_ovr: int = int(dest_c.get("ovr", 65))

			# Pick a real world player matching this league's OVR neighborhood via deterministic stride
			var wp_idx: int = (dest_cid + (i + 1) * clubs_n) % TOTAL_WORLD_PLAYERS
			if wp_idx < 0 or wp_idx >= TOTAL_WORLD_PLAYERS:
				wp_idx = (i * 197 + nid * 31) % TOTAL_WORLD_PLAYERS
			var p_pos: String = GameData.POSITIONS[int(wp_pos[wp_idx]) % GameData.POSITIONS.size()]
			var p_positions: Array[String] = get_world_player_positions(wp_idx)

			if has_pos:
				var ok_p := false
				for pp in p_positions:
					if pos_set.has(pp):
						ok_p = true
						break
				if not ok_p:
					continue

			# Rich club-to-club REKRUT transfers mixed with PINJAMAN and BOSMAN moves
			var bosman_chance: float = 0.24 if div_focus >= 2 else 0.14
			var roll: float = rng.randf()
			var kind: String = "BOSMAN"
			var from_cid: int = -1
			var from_code: String = "BEBAS"
			var from_name: String = "TANPA KLUB"
			var from_pri: Color = Color("#3A4556")
			var from_sec: Color = Color("#5A687D")
			var from_pat: String = "solid"
			var fee_k: int = 0
			if roll >= bosman_chance:
				kind = "TRANSFER" if rng.randf() < 0.84 else "PINJAMAN"
				# Prefer origin clubs from nearby division/tier with varied kit signatures
				var same_div_pool: Array[Dictionary] = GameData.get_clubs_in_division((nid + rng.randi_range(0, 6)) % GameData.nations.size(), div_focus if div_focus > 0 else 1)
				if not same_div_pool.is_empty():
					var picked_from: Dictionary = same_div_pool[rng.randi_range(0, same_div_pool.size() - 1)]
					from_cid = int(picked_from["id"])
				else:
					from_cid = (dest_cid + rng.randi_range(5, 95)) % clubs_n
				if from_cid == dest_cid:
					from_cid = (dest_cid + 1) % clubs_n
				var from_c: Dictionary = GameData.clubs[from_cid]
				from_code = str(from_c.get("code", "CLB")).left(3).to_upper()
				from_name = str(from_c.get("name", "Klub Asal"))
				from_pri = from_c.get("primary", Color("#2563EB"))
				from_sec = from_c.get("secondary", Color("#F8FAFC"))
				from_pat = str(from_c.get("pattern", "solid"))
				if kind == "TRANSFER":
					var base_val_k: int = maxi(800, int(wp_val[wp_idx]))
					fee_k = maxi(400, int(round(float(base_val_k) * rng.randf_range(0.80, 1.40))))

			var day_offset: int = rng.randi_range(0, 40)
			var m_idx: int = clampi(cur_m_idx - int(day_offset / 28), 0, m_short.size() - 1)
			var day_num: int = clampi(28 - (day_offset % 26), 1, 28)
			var sort_day: int = m_idx * 31 + day_num
			var p_ovr_disp: int = clampi(int(wp_ovr[wp_idx]), maxi(46, dest_ovr - 12), mini(93, dest_ovr + 14))
			var full_nm: String = wp_name[wp_idx]
			var nm_parts: PackedStringArray = full_nm.split(" ")
			var short_nm: String = nm_parts[nm_parts.size() - 1] if nm_parts.size() > 1 else full_nm

			out.append({
				"wp_idx": wp_idx,
				"name": full_nm,
				"short_name": short_nm,
				"ovr": p_ovr_disp,
				"pos": p_pos,
				"positions": p_positions,
				"seed": int(wp_seed[wp_idx]),
				"dest_club_id": dest_cid,
				"dest_code": str(dest_c.get("code", "CLB")).left(3).to_upper(),
				"dest_name": str(dest_c.get("name", "Klub")),
				"dest_nat_id": nid,
				"dest_primary": dest_c.get("primary", Color("#1E64D8")),
				"dest_secondary": dest_c.get("secondary", Color("#F8FAFC")),
				"dest_pattern": str(dest_c.get("pattern", "solid")),
				"from_club_id": from_cid,
				"from_code": from_code,
				"from_name": from_name,
				"from_primary": from_pri,
				"from_secondary": from_sec,
				"from_pattern": from_pat,
				"kind": kind,
				"fee_k": fee_k,
				"date_str": "%02d %s" % [day_num, m_short[m_idx]],
				"sort_day": sort_day,
			})

	match sort_mode:
		"NILAI":
			out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				if int(a["fee_k"]) != int(b["fee_k"]):
					return int(a["fee_k"]) > int(b["fee_k"])
				return int(a["ovr"]) > int(b["ovr"])
			)
		"OVR":
			out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				if int(a["ovr"]) != int(b["ovr"]):
					return int(a["ovr"]) > int(b["ovr"])
				return int(a["sort_day"]) > int(b["sort_day"])
			)
		_:
			out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				if int(a["sort_day"]) != int(b["sort_day"]):
					return int(a["sort_day"]) > int(b["sort_day"])
				return int(a["ovr"]) > int(b["ovr"])
			)
	return out

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
			"albumCards": [],
			"scoutedByClubId": -1,
			"scoutInterest": 0,
			"eventCooldown": 1,
			"preEventCooldown": 0,
			"preMatchDoneWeek": 0,
			"monthMatches": 0,
			"monthGoals": 0,
			"monthAssists": 0,
			"monthTotalRating": 0.0,
			"monthMotm": 0,
			"seasonMatches": 0,
			"seasonGoals": 0,
			"seasonAssists": 0,
			"seasonTotalRating": 0.0,
			"seasonMotm": 0,
			"potmHistory": [],
			"potyHistory": [],
			"lastPotmAward": {},
			"lastPotyAward": {},
			"seasonPendingEnd": false,
			"seasonStarts": 0,
			"seasonConceded": 0,
			"seasonCleanSheets": 0,
			"seasonShots": 0,
			"seasonShotsOnTarget": 0,
			"seasonDribblesWon": 0,
			"seasonFouled": 0,
			"seasonRecordsBroken": [],
			"lastSeasonRecap": {},
			"timnasCalledWeeks": [],
			"finalParadeDoneWeek": 0,
			"clubSuaraLevel": 2,
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
				"pelatih": 45, "ruangGanti": 33, "fans": 27, "pers": 18, "agen": 33, "kekasih": 0,
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
			"isFreeAgent": false,
			"clauseTriggered": false,
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
			"transfers": 0, "freeTransfers": 0, "styleEdits": 0, "sponsorsSigned": 1, "seasonsDiv3": 0,
			"finalsLost": 0, "intlCaps": 0, "intlGoals": 0, "followers": 2600,
			"longestGoalMeters": 0.0, "autographs": 0,
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

	var user_club: Dictionary = GameData.clubs[clampi(user_club_id, 0, GameData.clubs.size() - 1)]
	var club_ovr: int = int(user_club.get("ovr", 60))
	var yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var elite_comp := ""
	var elite_title := ""
	if div_num == 1:
		var qual_comp: String = str(career.get("careerMeta", {}).get("qualifiedComp", "")) if has_active_career else ""
		if qual_comp == "PIALA_ELITE":
			elite_comp = "PIALA_ELITE"
			elite_title = "PIALA ELITE"
		elif qual_comp == "PIALA_EUROPA":
			elite_comp = "PIALA_EUROPA"
			elite_title = "PIALA EUROPA"
		elif qual_comp == "PIALA_CONF":
			elite_comp = "PIALA_CONF"
			elite_title = "PIALA CHALLENGE"
		elif qual_comp == "NONE":
			elite_comp = ""
			elite_title = ""
		else:
			if club_ovr >= 74:
				elite_comp = "PIALA_ELITE"
				elite_title = "PIALA ELITE"
			elif club_ovr >= 65:
				elite_comp = "PIALA_EUROPA"
				elite_title = "PIALA EUROPA"
			else:
				elite_comp = "PIALA_CONF"
				elite_title = "PIALA CHALLENGE"

	var cup_stages := {
		6: "BABAK 1",
		12: "32 BESAR",
		20: "16 BESAR",
		28: "8 BESAR",
		36: "SEMI FINAL",
		42: "FINAL",
	}
	var elite_stages := {
		5: "PLAYOFF (LEG 1)",
		9: "FASE LIGA 2/8",
		14: "FASE LIGA 4/8",
		22: "FASE LIGA 6/8",
		30: "16 BESAR",
		34: "8 BESAR",
		38: "SEMI FINAL",
		40: "FINAL",
	}
	var player_nat_id: int = clampi(int(career.get("playerProfile", {}).get("nationId", nat_id)) if has_active_career else nat_id, 0, GameData.nations.size() - 1)
	var player_confed: String = ConfederationDataScript.get_nation_confederation(player_nat_id)
	var wc_qual: bool = bool(career.get("careerMeta", {}).get("wcQualified", false)) if has_active_career else false
	var intl_camp: Dictionary = ConfederationDataScript.get_season_campaign(player_confed, yr, wc_qual)
	var intl_grp_weeks: Array = intl_camp.get("group_weeks", [])
	var intl_ko_weeks: Array = intl_camp.get("ko_weeks", [])
	var intl_ko_names: Array[String] = _get_ko_round_names(str(intl_camp.get("knockout_start", "")))
	var p_nat_dict: Dictionary = GameData.nations[player_nat_id]
	var seeded_grp: Dictionary = ConfederationDataScript.build_seeded_group(
		player_confed, intl_camp,
		str(p_nat_dict.get("code", "IDN")),
		str(p_nat_dict.get("name", "Indonesia")),
		p_nat_dict.get("colors", [Color("#CE1126"), Color("#FFFFFF")]),
		yr * 733 + player_nat_id * 41
	)
	var intl_rivals: Array[Dictionary] = []
	for gr in seeded_grp.get("rows", []):
		if not bool(gr.get("is_user", false)):
			intl_rivals.append(gr)
	if intl_rivals.is_empty():
		intl_rivals.append({"code": "JPN", "name": "Jepang", "ovr": 78, "colors": [Color("#00235D"), Color("#FFFFFF")]})

	var opp_ptr := 0
	for w in range(1, 46):
		var comp := "LIGA"
		var comp_label := "LIGA ke-%d" % div_num
		var stage := ""
		var is_ko := false
		var opp: Dictionary = opponents[opp_ptr % opponents.size()]
		var grp_w_idx: int = intl_grp_weeks.find(w)
		var ko_w_idx: int = intl_ko_weeks.find(w)

		if grp_w_idx >= 0:
			comp = "TIMNAS"
			stage = "FASE GRUP %d/%d" % [grp_w_idx + 1, intl_grp_weeks.size()] if bool(intl_camp.get("has_knockout", false)) else "KUALIFIKASI P%d" % (grp_w_idx + 1)
			comp_label = "%s • %s" % [str(intl_camp.get("short_title", "TIMNAS")), stage]
			var rv: Dictionary = intl_rivals[grp_w_idx % intl_rivals.size()]
			opp = {
				"id": _find_nation_id_by_code(str(rv["code"])),
				"name": str(rv["name"]),
				"code": str(rv["code"]).left(3).to_upper(),
				"ovr": clampi(int(rv.get("ovr", 72)), 56, 89),
				"nation_id": _find_nation_id_by_code(str(rv["code"])),
				"intl_colors": rv.get("colors", [Color("#2563EB"), Color("#FFFFFF")]),
			}
		elif ko_w_idx >= 0 and ko_w_idx < intl_ko_names.size():
			comp = "TIMNAS"
			stage = intl_ko_names[ko_w_idx]
			comp_label = "%s • %s" % [str(intl_camp.get("short_title", "TIMNAS")), stage]
			is_ko = true
			var rv_k: Dictionary = intl_rivals[(ko_w_idx + 1) % intl_rivals.size()]
			opp = {
				"id": _find_nation_id_by_code(str(rv_k["code"])),
				"name": str(rv_k["name"]),
				"code": str(rv_k["code"]).left(3).to_upper(),
				"ovr": clampi(int(rv_k.get("ovr", 76)), 60, 89),
				"nation_id": _find_nation_id_by_code(str(rv_k["code"])),
				"intl_colors": rv_k.get("colors", [Color("#2563EB"), Color("#FFFFFF")]),
			}
		elif cup_stages.has(w):
			comp = "PIALA"
			stage = str(cup_stages[w])
			comp_label = "PIALA NASIONAL • %s" % stage
			is_ko = true
			var cup_pool := GameData.get_clubs_in_division(nat_id, maxi(1, div_num - (1 if w > 18 else 0)))
			if cup_pool.size() > 1:
				opp = cup_pool[(w * 7 + yr) % cup_pool.size()]
				if int(opp["id"]) == user_club_id:
					opp = opponents[opp_ptr % opponents.size()]
		elif elite_comp != "" and elite_stages.has(w):
			comp = elite_comp
			stage = str(elite_stages[w])
			comp_label = "%s %s" % [elite_title, stage] if stage == "PLAYOFF (LEG 1)" else "%s • %s" % [elite_title, stage]
			is_ko = stage in ["16 BESAR", "8 BESAR", "SEMI FINAL", "FINAL"]
			var intl_clubs := GameData.get_clubs_in_division((nat_id + w) % GameData.nations.size(), 1)
			if not intl_clubs.is_empty():
				opp = intl_clubs[(w * 3 + club_ovr) % intl_clubs.size()]
		elif club_ovr >= 80 and w == 24:
			comp = "PIALA_DUNIA_KLUB"
			stage = "FINAL"
			comp_label = "KEJUARAAN DUNIA KLUB • FINAL"
			is_ko = true
			var top_pool := GameData.get_clubs_in_division((nat_id + 18) % GameData.nations.size(), 1)
			if not top_pool.is_empty():
				opp = top_pool[0]
		else:
			opp_ptr += 1

		var is_home := (w % 2 == 1)
		sched.append({
			"week": w,
			"comp": comp,
			"comp_label": comp_label,
			"stage": stage,
			"is_knockout": is_ko,
			"opp_club_id": int(opp["id"]),
			"opp_name": opp["name"],
			"opp_code": opp["code"],
			"opp_ovr": int(opp["ovr"]),
			"opp_nat_id": int(opp.get("nation_id", nat_id)),
			"is_home": is_home,
			"is_derby": (comp == "LIGA" and is_derby_match(user_club_id, int(opp["id"]))),
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
		"nationId": p["nationId"],
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
		"matches": st["matches"],
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
		["unlockedCoachTraits", ["KORNER_PENALTI"]], ["lastMatchdayResults", []], ["boughtSneakers", []],
		["seasonPendingEnd", false], ["seasonStarts", 0], ["seasonConceded", 0],
		["seasonCleanSheets", 0], ["seasonShots", 0], ["seasonShotsOnTarget", 0],
		["seasonDribblesWon", 0], ["seasonFouled", 0], ["seasonRecordsBroken", []],
		["lastSeasonRecap", {}], ["timnasCalledWeeks", []], ["finalParadeDoneWeek", 0], ["clubSuaraLevel", 2]
	]:
		if not m.has(k[0]):
			m[k[0]] = k[1]
	var rel: Dictionary = career["playerProfile"].get("relations", {})
	if not rel.has("kekasih"):
		rel["kekasih"] = 0
	var con: Dictionary = career.get("contract", {})
	for kc in [["clause", "NONE"], ["isFreeAgent", false], ["clauseTriggered", false]]:
		if not con.has(kc[0]):
			con[kc[0]] = kc[1]
	if not career["stats"].has("freeTransfers"):
		career["stats"]["freeTransfers"] = 0
	var app: Dictionary = career["playerProfile"].get("appearance", {})
	for k2 in [
		["tattoo_face", 0], ["tattoo_arm", 0], ["tattoo_leg", 0],
		["headwear", 0], ["eyewear", 0], ["casual_style", 0]
	]:
		if not app.has(k2[0]):
			app[k2[0]] = k2[1]
	if not career["stats"].has("bestVolleyStreak"):
		career["stats"]["bestVolleyStreak"] = 0
	if not career["stats"].has("longestPassMeters"):
		career["stats"]["longestPassMeters"] = 0.0
	if not career["stats"].has("longestGoalClub"):
		career["stats"]["longestGoalClub"] = ""
	if not career["stats"].has("longestGoalSeason"):
		career["stats"]["longestGoalSeason"] = 1
	if not career["stats"].has("longestPassClub"):
		career["stats"]["longestPassClub"] = ""
	if not career["stats"].has("longestPassSeason"):
		career["stats"]["longestPassSeason"] = 1
	if not career.has("compStats") or typeof(career["compStats"]) != TYPE_DICTIONARY:
		career["compStats"] = {}
	if not career.has("victimGoals") or typeof(career["victimGoals"]) != TYPE_DICTIONARY:
		career["victimGoals"] = {}

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

func is_derby_match(cid_a: int, cid_b: int) -> bool:
	if cid_a < 0 or cid_b < 0 or cid_a == cid_b:
		return false
	if cid_a >= GameData.clubs.size() or cid_b >= GameData.clubs.size():
		return false
	var ca: Dictionary = GameData.clubs[cid_a]
	var cb: Dictionary = GameData.clubs[cid_b]
	if int(ca["nation_id"]) != int(cb["nation_id"]) or int(ca["division"]) != int(cb["division"]):
		return false
	var na := str(ca["name"]).split(" ")
	var nb := str(cb["name"]).split(" ")
	if na.size() > 0 and nb.size() > 0 and na[0].length() >= 4 and na[0] == nb[0]:
		return true
	var div_clubs := GameData.get_clubs_in_division(int(ca["nation_id"]), int(ca["division"]))
	var idx_a := -1
	var idx_b := -1
	for i in range(div_clubs.size()):
		var cid := int(div_clubs[i]["id"])
		if cid == cid_a:
			idx_a = i
		elif cid == cid_b:
			idx_b = i
	if idx_a >= 0 and idx_b >= 0 and (idx_a ^ 1) == idx_b:
		return true
	return false

func is_fixture_derby(fix: Dictionary) -> bool:
	if fix.is_empty():
		return false
	if bool(fix.get("is_derby", false)):
		return true
	if not has_active_career or str(fix.get("comp", "")) != "LIGA":
		return false
	var my_cid := int(career.get("playerProfile", {}).get("clubId", -1))
	return is_derby_match(my_cid, int(fix.get("opp_club_id", -1)))

func get_live_division_table(nat_id: int, div_num: int) -> Array[Dictionary]:
	if has_active_career:
		var user_club := get_current_club()
		if nat_id == int(user_club.get("nation_id", -1)) and div_num == int(user_club.get("division", -1)):
			return get_sorted_league_table()

	var div_clubs := GameData.get_clubs_in_division(nat_id, div_num)
	if div_clubs.is_empty():
		return []
	var yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var wk: int = int(career.get("careerMeta", {}).get("week", 1)) if has_active_career else 1
	# League rounds match actual completed LIGA matchdays across the world (~1 per week minus cup/intl weeks)
	var cur_played: int = 0
	if has_active_career:
		for row in career.get("leagueTable", []):
			cur_played = maxi(cur_played, int(row.get("p", 0)))
	var max_rounds: int = maxi(1, mini(38, div_clubs.size() * 2 - 2))
	var rounds_done: int = clampi(cur_played if cur_played > 0 else maxi(0, wk - 1), 0, max_rounds)
	var cache_key := "%d_%d_%d_%d" % [yr, rounds_done, nat_id, div_num]
	if _world_table_cache.has(cache_key):
		var cached: Array[Dictionary] = []
		for item in _world_table_cache[cache_key]:
			cached.append(item)
		return cached

	var rows := _init_league_table(div_clubs)
	var n := rows.size()
	if n >= 2 and rounds_done > 0:
		var rng := RandomNumberGenerator.new()
		var eff_n: int = n if (n % 2 == 0) else (n + 1)
		for r in range(rounds_done):
			rng.seed = yr * 9187 + (r + 1) * 3571 + nat_id * 173 + div_num * 53
			# Standard circle-method round-robin pairing so every club plays evenly each round
			var shift: int = r % maxi(1, eff_n - 1)
			var order: Array[int] = [0]
			for k in range(1, eff_n):
				order.append(1 + ((k - 1 + shift) % (eff_n - 1)))
			var half: int = int(eff_n / 2)
			for p_i in range(half):
				var idx_a: int = order[p_i]
				var idx_b: int = order[eff_n - 1 - p_i]
				if idx_a >= n or idx_b >= n or idx_a == idx_b:
					continue
				var ra: Dictionary = rows[idx_a]
				var rb: Dictionary = rows[idx_b]
				var diff := int(ra["ovr"]) - int(rb["ovr"])
				var ga := clampi(int(rng.randf_range(0.0, 2.45) + float(diff) * 0.055), 0, 5)
				var gb := clampi(int(rng.randf_range(0.0, 2.25) - float(diff) * 0.055), 0, 5)
				_apply_match_to_table_row(ra, ga, gb)
				_apply_match_to_table_row(rb, gb, ga)

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["pts"]) != int(b["pts"]):
			return int(a["pts"]) > int(b["pts"])
		var gd_a := int(a["gf"]) - int(a["ga"])
		var gd_b := int(b["gf"]) - int(b["ga"])
		if gd_a != gd_b:
			return gd_a > gd_b
		return int(a["gf"]) > int(b["gf"])
	)
	_world_table_cache[cache_key] = rows
	return rows

func get_league_zone_rules(nat_id: int, div_num: int, total_teams: int) -> Dictionary:
	var n_idx: int = clampi(nat_id, 0, GameData.nations.size() - 1)
	var nat: Dictionary = GameData.nations[n_idx]
	var code: String = str(nat.get("code", ""))
	var w_rank: int = int(nat.get("world_rank", 20))
	var accent := Color("#60A5FA")
	match code:
		"ENG": accent = Color("#9370FF")
		"ITA": accent = Color("#4EA8FF")
		"GER": accent = Color("#EE4B4B")
		"ESP": accent = Color("#F5B82E")
		"FRA": accent = Color("#5B8CFF")
		"IDN": accent = Color("#F87171")
		"SWE": accent = Color("#FACC15")
		"POR": accent = Color("#34D399")
		"NED": accent = Color("#FB923C")
		"BRA": accent = Color("#4ADE80")
		"ARG": accent = Color("#7DD3FC")
		_:
			var cols: Array = nat.get("colors", [Color("#60A5FA")])
			var c0: Color = cols[0] if not cols.is_empty() else Color("#60A5FA")
			accent = c0.lightened(0.28)

	var elite_end: int = 0
	var europa_start: int = 0
	var europa_end: int = 0
	var challenge_start: int = 0
	var challenge_end: int = 0
	var promo_end: int = 0
	var releg_start: int = 0

	if div_num == 1:
		match code:
			"ESP":
				elite_end = 5
				europa_start = 6
				europa_end = 6
				challenge_start = 7
				challenge_end = 7
			"ENG", "ITA":
				elite_end = 5
				europa_start = 6
				europa_end = 7
				challenge_start = 8
				challenge_end = 8
			"GER":
				elite_end = 4
				europa_start = 5
				europa_end = 6
				challenge_start = 7
				challenge_end = 7
			"FRA":
				elite_end = 4
				europa_start = 5
				europa_end = 5
				challenge_start = 6
				challenge_end = 6
			_:
				if w_rank <= 10:
					elite_end = 3
					europa_start = 4
					europa_end = 4
					challenge_start = 5
					challenge_end = 5
				else:
					elite_end = 2
					europa_start = 3
					europa_end = 3
					challenge_start = 4
					challenge_end = 4
		if total_teams >= 6:
			releg_start = total_teams - 2
	elif div_num == 2:
		promo_end = mini(3, total_teams)
		if total_teams >= 6:
			releg_start = total_teams - 2
	else:
		promo_end = mini(3, total_teams)
		releg_start = 0

	return {
		"elite_end": elite_end,
		"europa_start": europa_start,
		"europa_end": europa_end,
		"challenge_start": challenge_start,
		"challenge_end": challenge_end,
		"promo_end": promo_end,
		"releg_start": releg_start,
		"accent_color": accent,
	}

func get_zone_for_rank(nat_id: int, div_num: int, rank_1based: int, total_teams: int) -> String:
	var rules: Dictionary = get_league_zone_rules(nat_id, div_num, total_teams)
	var releg_start: int = int(rules["releg_start"])
	if releg_start > 0 and rank_1based >= releg_start:
		return "RELEG"
	var promo_end: int = int(rules["promo_end"])
	if promo_end > 0 and rank_1based <= promo_end:
		return "PROMO"
	var elite_end: int = int(rules["elite_end"])
	if elite_end > 0 and rank_1based <= elite_end:
		return "ELITE"
	var eu_s: int = int(rules["europa_start"])
	var eu_e: int = int(rules["europa_end"])
	if eu_s > 0 and rank_1based >= eu_s and rank_1based <= eu_e:
		return "EUROPA"
	var ch_s: int = int(rules["challenge_start"])
	var ch_e: int = int(rules["challenge_end"])
	if ch_s > 0 and rank_1based >= ch_s and rank_1based <= ch_e:
		return "CHALLENGE"
	return ""

func get_division_top_stats(nat_id: int, div_num: int) -> Dictionary:
	ensure_world_database()
	var table: Array[Dictionary] = get_live_division_table(nat_id, div_num)
	var club_played: Dictionary = {}
	var div_cids: Array[int] = []
	for r in table:
		var cid: int = int(r["club_id"])
		div_cids.append(cid)
		club_played[cid] = int(r.get("p", 0))
	if div_cids.is_empty():
		return {"goals": [], "assists": [], "rating": []}

	var yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var clubs_count: int = GameData.clubs.size()
	var candidates: Array[Dictionary] = []

	var is_user_div := false
	var user_cid: int = -1
	if has_active_career:
		var u_club: Dictionary = get_current_club()
		user_cid = int(u_club.get("id", -1))
		if int(u_club.get("nation_id", -1)) == nat_id and int(u_club.get("division", -1)) == div_num:
			is_user_div = true

	# Collect world players belonging to clubs in this (nat_id, div_num)
	var seeded_limit: int = mini(GameData.TOP_SEEDED_PLAYERS.size(), TOTAL_WORLD_PLAYERS)
	var seen_idx: Dictionary = {}
	for cid in div_cids:
		var club_p: int = int(club_played.get(cid, 0))
		# Check famous seeded players first
		for si in range(seeded_limit):
			if wp_club[si] == cid and not seen_idx.has(si):
				seen_idx[si] = true
				candidates.append(_build_div_stat_entry(si, cid, club_p, yr, nat_id, div_num))
		# Fast O(8) stride over wp_club (since idx % clubs_count == c_id for idx >= seeded_limit)
		var start_k: int = cid
		while start_k < seeded_limit:
			start_k += clubs_count
		var k: int = start_k
		while k < TOTAL_WORLD_PLAYERS:
			if wp_club[k] == cid and not seen_idx.has(k):
				seen_idx[k] = true
				candidates.append(_build_div_stat_entry(k, cid, club_p, yr, nat_id, div_num))
			k += clubs_count

	# Guarantee at least 12 candidates even for tiny edge-case divisions
	if candidates.size() < 12:
		for i in range(12 - candidates.size()):
			var cid: int = div_cids[i % div_cids.size()]
			var club_p: int = int(club_played.get(cid, 0))
			var fn: String = GameData.FIRST_NAMES[(cid * 5 + i * 7 + nat_id) % GameData.FIRST_NAMES.size()]
			var ln: String = GameData.LAST_NAMES[(cid * 3 + i * 11 + div_num) % GameData.LAST_NAMES.size()]
			var mn: int = maxi(1, club_p) if club_p > 0 else 1
			candidates.append({
				"name": "%s %s" % [fn, ln],
				"club_id": cid,
				"matches": mn,
				"goals": maxi(0, int(float(mn) * 0.25) + (i % 3)),
				"assists": maxi(0, int(float(mn) * 0.16) + ((i + 1) % 2)),
				"rating": snappedf(6.6 + float(i % 9) * 0.1, 0.1),
				"is_user": false,
			})

	# Inject real User player when inspecting user's own league & division
	if is_user_div and has_active_career:
		var prof: Dictionary = career["playerProfile"]
		var meta: Dictionary = career["careerMeta"]
		var st: Dictionary = career["stats"]
		var u_mn: int = int(meta.get("seasonMatches", 0))
		var u_g: int = int(meta.get("seasonGoals", 0))
		var u_a: int = int(meta.get("seasonAssists", 0))
		var u_rt_sum: float = float(meta.get("seasonTotalRating", 0.0))
		if u_mn == 0 and int(st.get("matches", 0)) > 0:
			u_mn = int(st.get("matches", 0))
			u_g = int(st.get("goals", 0))
			u_a = int(st.get("assists", 0))
			u_rt_sum = float(st.get("totalRating", 0.0))
		var u_avg: float = snappedf(u_rt_sum / float(maxi(1, u_mn)), 0.1) if u_mn > 0 else 6.5
		candidates.append({
			"name": str(prof.get("name", "PEMAIN")),
			"club_id": user_cid,
			"matches": u_mn,
			"goals": u_g,
			"assists": u_a,
			"rating": u_avg,
			"is_user": true,
		})

	var g_sorted: Array[Dictionary] = candidates.duplicate()
	g_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["goals"]) != int(b["goals"]):
			return int(a["goals"]) > int(b["goals"])
		if bool(a["is_user"]) != bool(b["is_user"]):
			return bool(a["is_user"])
		return int(a["matches"]) < int(b["matches"])
	)
	var a_sorted: Array[Dictionary] = candidates.duplicate()
	a_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["assists"]) != int(b["assists"]):
			return int(a["assists"]) > int(b["assists"])
		if bool(a["is_user"]) != bool(b["is_user"]):
			return bool(a["is_user"])
		return int(a["matches"]) < int(b["matches"])
	)
	var r_sorted: Array[Dictionary] = candidates.duplicate()
	r_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra: float = float(a["rating"])
		var rb: float = float(b["rating"])
		if not is_equal_approx(ra, rb):
			return ra > rb
		if bool(a["is_user"]) != bool(b["is_user"]):
			return bool(a["is_user"])
		return int(a["matches"]) > int(b["matches"])
	)

	var top_g: Array[Dictionary] = []
	var top_a: Array[Dictionary] = []
	var top_r: Array[Dictionary] = []
	for i in range(mini(10, g_sorted.size())):
		var g_item: Dictionary = g_sorted[i]
		top_g.append({"rank": i + 1, "name": str(g_item["name"]), "club_id": int(g_item["club_id"]), "matches": int(g_item["matches"]), "value": int(g_item["goals"]), "is_user": bool(g_item["is_user"])})
	for i in range(mini(10, a_sorted.size())):
		var a_item: Dictionary = a_sorted[i]
		top_a.append({"rank": i + 1, "name": str(a_item["name"]), "club_id": int(a_item["club_id"]), "matches": int(a_item["matches"]), "value": int(a_item["assists"]), "is_user": bool(a_item["is_user"])})
	for i in range(mini(10, r_sorted.size())):
		var r_item: Dictionary = r_sorted[i]
		top_r.append({"rank": i + 1, "name": str(r_item["name"]), "club_id": int(r_item["club_id"]), "matches": int(r_item["matches"]), "value": float(r_item["rating"]), "is_user": bool(r_item["is_user"])})

	return {"goals": top_g, "assists": top_a, "rating": top_r}

func _build_div_stat_entry(wp_idx: int, cid: int, club_p: int, yr: int, nat_id: int, div_num: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(wp_seed[wp_idx]) * 17 + yr * 1009 + nat_id * 131 + div_num * 37
	var pos_str: String = GameData.POSITIONS[int(wp_pos[wp_idx]) % GameData.POSITIONS.size()]
	var ovr: int = int(wp_ovr[wp_idx])
	var mn: int = 0
	if club_p > 0:
		mn = clampi(club_p - rng.randi_range(0, mini(3, club_p)), 1, club_p)
	var ovr_factor: float = clampf((float(ovr) - 52.0) / 38.0, 0.15, 1.15)
	var g_rate: float = 0.08
	var a_rate: float = 0.07
	if pos_str in ["ST"]:
		g_rate = 0.42 + ovr_factor * 0.28
		a_rate = 0.12 + ovr_factor * 0.10
	elif pos_str in ["LW", "RW", "CAM"]:
		g_rate = 0.28 + ovr_factor * 0.22
		a_rate = 0.24 + ovr_factor * 0.18
	elif pos_str in ["LM", "RM", "CM"]:
		g_rate = 0.12 + ovr_factor * 0.14
		a_rate = 0.20 + ovr_factor * 0.16
	elif pos_str in ["CDM", "LB", "RB", "CB"]:
		g_rate = 0.04 + ovr_factor * 0.06
		a_rate = 0.09 + ovr_factor * 0.10
	else:
		g_rate = 0.0
		a_rate = 0.02

	var goals: int = int(round(float(mn) * g_rate * rng.randf_range(0.65, 1.38))) if mn > 0 else 0
	var assists: int = int(round(float(mn) * a_rate * rng.randf_range(0.60, 1.40))) if mn > 0 else 0
	var rating: float = snappedf(clampf(6.35 + ovr_factor * 0.95 + rng.randf_range(-0.35, 0.55), 6.0, 8.6), 0.1) if mn > 0 else 6.0
	return {
		"name": wp_name[wp_idx],
		"club_id": cid,
		"matches": mn,
		"goals": goals,
		"assists": assists,
		"rating": rating,
		"is_user": false,
	}

func get_continental_table(comp_key: String, focus_nat_id: int = 0) -> Array[Dictionary]:
	var yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var wk: int = int(career.get("careerMeta", {}).get("week", 1)) if has_active_career else 1
	var rounds: int = clampi(int(wk / 4), 1, 8)
	var pool: Array[Dictionary] = []

	if comp_key == "PIALA":
		# Domestic national cup for focus_nat_id (top clubs from Div 1 + Div 2 + Div 3)
		for d in [1, 2, 3]:
			var dc: Array[Dictionary] = GameData.get_clubs_in_division(focus_nat_id, d)
			for i in range(mini(6 if d == 1 else 5, dc.size())):
				pool.append(dc[i])
	elif comp_key == "KLUB":
		# Club World Cup: champions from top 16 global nations
		for nid in range(mini(16, GameData.nations.size())):
			var dc: Array[Dictionary] = GameData.get_clubs_in_division(nid, 1)
			if not dc.is_empty():
				pool.append(dc[0])
	else:
		# ELITE, EUROPA, CONF.: qualify clubs from top nations according to exact zone rules!
		var top_nats: Array[int] = [1, 2, 3, 4, 5, 6, 7, 17, 8, 9, 0, 16]
		for nid in top_nats:
			if nid >= GameData.nations.size():
				continue
			var tbl: Array[Dictionary] = get_live_division_table(nid, 1)
			var rules: Dictionary = get_league_zone_rules(nid, 1, tbl.size())
			var lo: int = 1
			var hi: int = 0
			if comp_key == "ELITE":
				lo = 1
				hi = mini(2, int(rules["elite_end"]))
			elif comp_key == "EUROPA":
				lo = int(rules["europa_start"])
				hi = int(rules["europa_end"])
			else:
				lo = int(rules["challenge_start"])
				hi = int(rules["challenge_end"])
			if lo <= 0 or hi < lo:
				continue
			for rk in range(lo, mini(hi, tbl.size()) + 1):
				var cid: int = int(tbl[rk - 1]["club_id"])
				if cid >= 0 and cid < GameData.clubs.size():
					pool.append(GameData.clubs[cid])
				if pool.size() >= 16:
					break
			if pool.size() >= 16:
				break

	if pool.is_empty():
		return []
	var rows: Array[Dictionary] = _init_league_table(pool)
	var n: int = rows.size()
	var rng := RandomNumberGenerator.new()
	var comp_salt: int = comp_key.hash() % 997
	for r in range(rounds):
		rng.seed = yr * 5309 + (r + 1) * 719 + comp_salt + focus_nat_id * 31
		var eff_n: int = n if (n % 2 == 0) else (n + 1)
		var shift: int = r % maxi(1, eff_n - 1)
		var order: Array[int] = [0]
		for k in range(1, eff_n):
			order.append(1 + ((k - 1 + shift) % (eff_n - 1)))
		for p_i in range(int(eff_n / 2)):
			var ia: int = order[p_i]
			var ib: int = order[eff_n - 1 - p_i]
			if ia >= n or ib >= n or ia == ib:
				continue
			var ra: Dictionary = rows[ia]
			var rb: Dictionary = rows[ib]
			var diff: int = int(ra["ovr"]) - int(rb["ovr"])
			var ga: int = clampi(int(rng.randf_range(0.0, 2.5) + float(diff) * 0.05), 0, 5)
			var gb: int = clampi(int(rng.randf_range(0.0, 2.3) - float(diff) * 0.05), 0, 5)
			_apply_match_to_table_row(ra, ga, gb)
			_apply_match_to_table_row(rb, gb, ga)

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["pts"]) != int(b["pts"]):
			return int(a["pts"]) > int(b["pts"])
		var gd_a: int = int(a["gf"]) - int(a["ga"])
		var gd_b: int = int(b["gf"]) - int(b["ga"])
		if gd_a != gd_b:
			return gd_a > gd_b
		return int(a["gf"]) > int(b["gf"])
	)
	return rows

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

func get_ovr_progress() -> Dictionary:
	if not has_active_career:
		return {"ovr": 60, "progress": 0.0, "points_to_next": 5, "will_level_up": false}
	var attrs: Dictionary = career["playerProfile"]["attributes"]
	var total := 0.0
	for k in GameData.ATTRIBUTE_KEYS:
		total += float(attrs.get(k, 60))
	var cnt: float = float(maxi(1, GameData.ATTRIBUTE_KEYS.size()))
	var boot_id := int(career["playerProfile"]["appearance"].get("boot_id", 0))
	var boot_bonus := int(GameData.boots_catalog[clampi(boot_id, 0, 10)]["bonus_val"])
	var boot_eff: int = int(boot_bonus * 0.4)
	var exact_ovr: float = (total / cnt) + float(boot_eff)
	var cur_ovr: int = clampi(int(round(exact_ovr)), 45, 99)
	if cur_ovr >= 99:
		return {"ovr": 99, "progress": 1.0, "points_to_next": 0, "will_level_up": false}
	var progress: float = clampf(exact_ovr - (float(cur_ovr) - 0.5), 0.0, 1.0)
	var cur_sum: int = int(round(total))
	var needed_pts: int = 1
	while clampi(int(round(float(cur_sum + needed_pts) / cnt)) + boot_eff, 45, 99) <= cur_ovr and needed_pts < 25:
		needed_pts += 1
	var sp: int = int(career["playerProfile"].get("skillPoints", 0))
	return {"ovr": cur_ovr, "progress": progress, "points_to_next": needed_pts, "will_level_up": (sp >= needed_pts)}

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

static func get_attribute_upgrade_cost(cur_val: int) -> int:
	return 2 if cur_val >= 80 else 1

func upgrade_attribute(attr_key: String) -> bool:
	if not has_active_career:
		return false
	var sp := int(career["playerProfile"]["skillPoints"])
	var cur := int(career["playerProfile"]["attributes"].get(attr_key, 60))
	var cost := get_attribute_upgrade_cost(cur)
	if sp < cost or cur >= 99:
		return false
	career["playerProfile"]["skillPoints"] = sp - cost
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
	var attrs: Dictionary = career["playerProfile"]["attributes"]
	for k in pending.keys():
		var steps: int = maxi(0, int(pending[k]))
		var cur_v: int = int(attrs.get(k, 60))
		for _s in range(steps):
			if cur_v >= 99:
				break
			total_cost += get_attribute_upgrade_cost(cur_v)
			cur_v += 1
	var sp: int = int(career["playerProfile"]["skillPoints"])
	if total_cost <= 0 or total_cost > sp:
		return false
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
	apply_dilemma_choice_with_result(choice_dict)

func apply_dilemma_choice_with_result(choice_dict: Dictionary) -> Dictionary:
	if not has_active_career:
		return {"success": true, "deltas": {}, "outcome_text": ""}
	var week := int(career["careerMeta"]["week"])
	if int(career["careerMeta"].get("dilemmaDoneWeek", 0)) == week:
		return {"success": true, "deltas": {}, "outcome_text": ""}
	var success := true
	if choice_dict.has("chance"):
		success = randf() <= float(choice_dict["chance"])
	var eff: Dictionary = choice_dict.get("effects", {}) if success else choice_dict.get("fail_effects", choice_dict.get("effects", {}))
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
	if eff.has("scoutInterest"):
		career["careerMeta"]["scoutInterest"] = clampi(int(career["careerMeta"].get("scoutInterest", 0)) + int(eff["scoutInterest"]), 0, 100)
	career["careerMeta"]["dilemmaDoneWeek"] = week
	save_active_career()
	career_updated.emit()
	var out_txt := str(choice_dict.get("win_text", "")) if success else str(choice_dict.get("fail_text", ""))
	return {"success": success, "deltas": eff.duplicate(true), "outcome_text": out_txt}

func unlock_album_card(card_id: String) -> Dictionary:
	var card_def: Dictionary = {}
	for c in GameData.album_cards_catalog:
		if str(c["id"]) == card_id:
			card_def = c
			break
	if card_def.is_empty():
		return {"newly_unlocked": false, "card": {}, "owned_count": 0, "total": GameData.album_cards_catalog.size()}
	var newly := false
	var owned: Array = []
	if has_active_career:
		if not career["careerMeta"].has("albumCards"):
			career["careerMeta"]["albumCards"] = []
		owned = career["careerMeta"]["albumCards"]
		if not owned.has(card_id):
			owned.append(card_id)
			newly = true
			save_active_career()
			career_updated.emit()
	return {"newly_unlocked": newly, "card": card_def, "owned_count": owned.size(), "total": GameData.album_cards_catalog.size()}

func increment_autographs() -> int:
	if not has_active_career:
		return 1
	var cur := int(career["stats"].get("autographs", 0)) + 1
	career["stats"]["autographs"] = cur
	save_active_career()
	career_updated.emit()
	return cur

func consume_event_cooldown() -> bool:
	# Returns true only when cooldown reaches 0, then resets to 1-3 matches so events don't spam!
	if not has_active_career:
		return false
	var meta: Dictionary = career["careerMeta"]
	var cd: int = int(meta.get("eventCooldown", 0))
	if cd > 0:
		return false
	meta["eventCooldown"] = randi_range(1, 3)
	save_active_career()
	return true

func consume_prematch_event_cooldown() -> bool:
	if not has_active_career:
		return false
	var meta: Dictionary = career["careerMeta"]
	var cd: int = int(meta.get("preEventCooldown", 0))
	if cd > 0:
		return false
	meta["preEventCooldown"] = randi_range(1, 3)
	save_active_career()
	return true

func pick_contextual_dilemma(timing: String, report: Dictionary = {}) -> Dictionary:
	if not has_active_career:
		return GameData.dilemmas_catalog[0]
	var meta: Dictionary = career["careerMeta"]
	var prof: Dictionary = career["playerProfile"]
	var wk: int = int(meta.get("week", 1))
	var pool: Array[Dictionary] = []
	for d in GameData.dilemmas_catalog:
		var t_s: String = str(d.get("timing", "POST"))
		if t_s != timing and t_s != "ANY":
			continue
		var did: String = str(d.get("id", ""))
		# Only show transfer rumors when scouting interest or higher OVR justifies it
		if did == "rumor_transfer_pers" and int(meta.get("scoutedByClubId", -1)) < 0 and int(meta.get("scoutInterest", 0)) < 5 and int(prof.get("ovr", 60)) < 62:
			continue
		pool.append(d)
	if pool.is_empty():
		pool = [GameData.dilemmas_catalog[0]]

	var picked: Dictionary = pool[wk % pool.size()]
	if timing == "POST":
		var eng: int = int(prof.get("energy", 80))
		var my_g: int = int(report.get("my_goals", 0))
		var rep_fix: Dictionary = report.get("fixture", {})
		var rep_comp: String = str(rep_fix.get("comp", "LIGA"))
		if rep_comp == "TIMNAS":
			var nat_nm := str(GameData.nations[clampi(int(prof.get("nationId", 16)), 0, GameData.nations.size() - 1)]["name"]).to_upper()
			return {
				"id": "jeda_internasional",
				"timing": "POST",
				"tag": "JEDA INTERNASIONAL",
				"scene": "TUNNEL",
				"title": "JEDA INTERNASIONAL • %s" % nat_nm,
				"desc": "Kamu pulang bersama timnas dan mikrofon sudah menunggu. Untuk siapa selebrasimu malam ini?",
				"choices": [
					{"label": "UNTUK NEGARA KELAHIRAN", "effects": {"fans": 8, "pers": 5}, "win_text": "Suporter satu negeri tersentuh oleh ucapanmu!"},
					{"label": "UNTUK PELATIH YANG MEMANGGIL", "effects": {"pelatih": 8, "agen": 4}, "win_text": "Pelatih timnas dan klub sama-sama senang mendengar kerendahan hatimu."},
					{"label": "UNTUK KLUB YANG MENGGAJI", "effects": {"ruangGanti": 6, "fans": 4}, "win_text": "Rekan setim dan fans klub mengapresiasi loyalitasmu."},
				],
			}
		if int(prof.get("relations", {}).get("kekasih", 0)) <= 0 and wk >= 5 and randf() < 0.40:
			return {
				"id": "wulan_kekasih",
				"timing": "POST",
				"tag": "KEHIDUPAN PRIBADI",
				"scene": "HOLIDAY",
				"title": "PERTEMUAN DENGAN WULAN",
				"desc": "Wulan mengajakmu keluar setelah laga berakhir. Bagaimana kamu menanggapi malam ini?",
				"choices": [
					{"label": "MAKAN MALAM ROMANTIS", "effects": {"kekasih": 35, "pers": 2, "energy": -4}, "win_text": "Hubungan kalian makin dekat! Wulan kini mendampingimu sebagai KEKASIH."},
					{"label": "KOPI SINGKAT & NGOBROL", "effects": {"kekasih": 25, "energy": 4}, "win_text": "Pertemuan hangat yang membuat pikiranmu jauh lebih segar."},
					{"label": "FOKUS PEMULIHAN SAJA", "effects": {"pelatih": 4, "energy": 8}, "win_text": "Kamu memilih pulang lebih awal untuk menjaga kebugaran."},
				],
			}
		if bool(report.get("won_derby", false)):
			for d in pool:
				if str(d.get("id", "")) == "menang_derby":
					picked = d
					break
		elif eng < 66 and randf() < 0.45:
			for d in pool:
				if str(d.get("id", "")) == "hari_libur_aktivitas":
					picked = d
					break
		elif my_g >= 1 and randf() < 0.45:
			for d in pool:
				if str(d.get("id", "")) == "adu_penalti_kiper":
					picked = d
					break
	elif timing == "PRE":
		var rel_coach: int = int(prof.get("relations", {}).get("pelatih", 60))
		if int(meta.get("scoutedByClubId", -1)) >= 0 and randf() < 0.45:
			for d in pool:
				if str(d.get("id", "")) == "rumor_transfer_pers":
					picked = d
					break
		elif rel_coach < 55 and randf() < 0.45:
			for d in pool:
				if str(d.get("id", "")) == "latihan_ekstra":
					picked = d
					break

	meta["currentDilemma"] = picked
	save_active_career()
	return picked

func get_season_month_index(wk: int) -> int:
	return clampi(int(floor(float(wk - 1) / 4.5)), 0, SEASON_MONTHS.size() - 1)

func get_season_month_name(wk: int) -> String:
	return SEASON_MONTHS[get_season_month_index(wk)]

func ensure_scout_target_club() -> int:
	if not has_active_career or GameData.clubs.is_empty():
		return -1
	var meta: Dictionary = career["careerMeta"]
	var existing_id: int = int(meta.get("scoutedByClubId", -1))
	var my_cid: int = int(career["playerProfile"].get("clubId", 0))
	if existing_id >= 0 and existing_id < GameData.clubs.size() and existing_id != my_cid:
		return existing_id
	var my_club: Dictionary = get_current_club()
	var target_ovr: int = maxi(62, int(career["playerProfile"].get("ovr", 60)) + 4)
	var picked_id: int = (my_cid + 17) % GameData.clubs.size()
	var best_diff: int = 999
	for c in GameData.clubs:
		var cid: int = int(c["id"])
		if cid == my_cid:
			continue
		var c_div: int = int(c.get("division", 3))
		var c_ovr: int = int(c.get("ovr", 60))
		if c_div > int(my_club.get("division", 3)):
			continue
		var d: int = abs(c_ovr - target_ovr)
		if d < best_diff:
			best_diff = d
			picked_id = cid
			if d <= 2 and cid != (my_cid + 1):
				break
	meta["scoutedByClubId"] = picked_id
	save_active_career()
	return picked_id

func evaluate_player_of_the_month(month_idx: int) -> Dictionary:
	if not has_active_career:
		return {}
	var meta: Dictionary = career["careerMeta"]
	var prof: Dictionary = career["playerProfile"]
	var st: Dictionary = career["stats"]
	var m_matches: int = maxi(1, int(meta.get("monthMatches", 1)))
	var m_goals: int = int(meta.get("monthGoals", 0))
	var m_assists: int = int(meta.get("monthAssists", 0))
	var m_motm: int = int(meta.get("monthMotm", 0))
	var m_avg_r: float = snappedf(float(meta.get("monthTotalRating", 6.5)) / float(m_matches), 0.1)
	var m_name: String = SEASON_MONTHS[clampi(month_idx, 0, SEASON_MONTHS.size() - 1)]
	var yr: int = int(meta.get("year", 1))
	var club: Dictionary = get_current_club()
	var user_score: float = m_avg_r * 10.0 + float(m_goals) * 8.0 + float(m_assists) * 5.0 + float(m_motm) * 4.5

	var div_clubs := GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	var candidates: Array[Dictionary] = [{
		"name": str(prof.get("name", "PEMAIN")).to_upper(),
		"club_id": int(club["id"]),
		"club_code": str(club["code"]),
		"goals": m_goals,
		"assists": m_assists,
		"avg_rating": m_avg_r,
		"score": user_score,
		"seed": 999,
		"is_user": true,
	}]

	var rival_names := ["Viktor Lindqvist", "Mateo Alvarez", "Emil Holm", "Lukas Svensson", "Rafael Costa", "Sora Takahashi"]
	for i in range(2):
		var rc: Dictionary = div_clubs[(i * 7 + month_idx * 3 + 1) % div_clubs.size()] if div_clubs.size() > 1 else GameData.clubs[(int(club["id"]) + i + 1) % GameData.clubs.size()]
		if int(rc["id"]) == int(club["id"]) and GameData.clubs.size() > 2:
			rc = GameData.clubs[(int(club["id"]) + i + 2) % GameData.clubs.size()]
		var h: int = abs((yr * 37 + month_idx * 19 + i * 29) % 100)
		var r_g: int = 1 + (h % 3)
		var r_a: int = (h / 5) % 3
		var r_rtg: float = snappedf(6.8 + float(h % 9) * 0.1, 0.1)
		var r_score: float = r_rtg * 10.0 + float(r_g) * 8.0 + float(r_a) * 5.0
		candidates.append({
			"name": rival_names[(month_idx + i) % rival_names.size()].to_upper(),
			"club_id": int(rc["id"]),
			"club_code": str(rc["code"]),
			"goals": r_g,
			"assists": r_a,
			"avg_rating": r_rtg,
			"score": r_score,
			"seed": 400 + month_idx * 13 + i * 31,
			"is_user": false,
		})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["score"]), float(b["score"])):
			return float(a["score"]) > float(b["score"])
		return bool(a["is_user"])
	)
	var u_rank: int = 1
	for idx in range(candidates.size()):
		if bool(candidates[idx]["is_user"]):
			u_rank = idx + 1
			break
	var won: bool = (u_rank == 1)
	if won:
		prof["cash"] = int(prof["cash"]) + 3500
		prof["skillPoints"] = int(prof.get("skillPoints", 0)) + 1
		meta["legacyPoints"] = int(meta["legacyPoints"]) + 6
		st["potmCount"] = int(st.get("potmCount", 0)) + 1
		var rel: Dictionary = prof["relations"]
		rel["fans"] = clampi(int(rel["fans"]) + 5, 0, 100)
		rel["pers"] = clampi(int(rel["pers"]) + 5, 0, 100)
		_push_news("LIGA", "%s terpilih sebagai PEMAIN TERBAIK BULAN %s (+1 Poin Atribut, Musim %d)!" % [prof["name"], m_name, yr])
	else:
		meta["legacyPoints"] = int(meta["legacyPoints"]) + 2
		_push_news("LIGA", "%s masuk nominasi Top 3 Pemain Terbaik Bulan %s." % [prof["name"], m_name])

	var award := {
		"kind": "POTM",
		"month": m_name,
		"year": yr,
		"won": won,
		"user_rank": u_rank,
		"winner_name": str(candidates[0]["name"]),
		"candidates": candidates,
		"user_stats": {"matches": m_matches, "goals": m_goals, "assists": m_assists, "avg_rating": m_avg_r},
	}
	meta["lastPotmAward"] = award
	var hist: Array = meta.get("potmHistory", [])
	hist.append({"month": m_name, "year": yr, "won": won, "rank": u_rank})
	meta["potmHistory"] = hist
	meta["monthMatches"] = 0
	meta["monthGoals"] = 0
	meta["monthAssists"] = 0
	meta["monthTotalRating"] = 0.0
	meta["monthMotm"] = 0
	_update_legacy_tier()
	return award

func evaluate_player_of_the_year(finished_year: int, league_pos: int) -> Dictionary:
	if not has_active_career:
		return {}
	var meta: Dictionary = career["careerMeta"]
	var prof: Dictionary = career["playerProfile"]
	var st: Dictionary = career["stats"]
	var s_matches: int = maxi(1, int(meta.get("seasonMatches", st.get("matches", 1))))
	var s_goals: int = int(meta.get("seasonGoals", 0))
	var s_assists: int = int(meta.get("seasonAssists", 0))
	var s_motm: int = int(meta.get("seasonMotm", 0))
	var s_avg_r: float = snappedf(float(meta.get("seasonTotalRating", 6.5 * float(s_matches))) / float(s_matches), 0.1)
	var club: Dictionary = get_current_club()
	var team_bonus: float = 14.0 if league_pos == 1 else (7.0 if league_pos <= 3 else 0.0)
	var user_score: float = s_avg_r * 12.0 + float(s_goals) * 2.6 + float(s_assists) * 1.8 + float(s_motm) * 3.2 + team_bonus

	var div_clubs := GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	var candidates: Array[Dictionary] = [{
		"name": str(prof.get("name", "PEMAIN")).to_upper(),
		"club_id": int(club["id"]),
		"club_code": str(club["code"]),
		"goals": s_goals,
		"assists": s_assists,
		"avg_rating": s_avg_r,
		"score": user_score,
		"seed": 999,
		"is_user": true,
	}]

	var stars := ["Corentin Zimmer", "Charlie Irving", "Pedro Resende", "Max Torres", "Ana Ruiz"]
	for i in range(2):
		var rc: Dictionary = div_clubs[(i * 9 + finished_year * 5 + 2) % div_clubs.size()] if div_clubs.size() > 1 else GameData.clubs[(int(club["id"]) + i + 3) % GameData.clubs.size()]
		if int(rc["id"]) == int(club["id"]) and GameData.clubs.size() > 2:
			rc = GameData.clubs[(int(club["id"]) + i + 4) % GameData.clubs.size()]
		var h: int = abs((finished_year * 53 + i * 41 + int(club["division"]) * 17) % 100)
		var r_g: int = maxi(8, 12 + (h % 14))
		var r_a: int = maxi(4, 6 + ((h / 3) % 9))
		var r_rtg: float = snappedf(7.1 + float(h % 9) * 0.1, 0.1)
		var r_score: float = r_rtg * 12.0 + float(r_g) * 2.6 + float(r_a) * 1.8 + 8.0
		candidates.append({
			"name": stars[(finished_year + i) % stars.size()].to_upper(),
			"club_id": int(rc["id"]),
			"club_code": str(rc["code"]),
			"goals": r_g,
			"assists": r_a,
			"avg_rating": r_rtg,
			"score": r_score,
			"seed": 700 + finished_year * 23 + i * 47,
			"is_user": false,
		})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["score"]), float(b["score"])):
			return float(a["score"]) > float(b["score"])
		return bool(a["is_user"])
	)
	var u_rank: int = 1
	for idx in range(candidates.size()):
		if bool(candidates[idx]["is_user"]):
			u_rank = idx + 1
			break
	var won: bool = (u_rank == 1)
	if won:
		var t_name := "PEMAIN TERBAIK TAHUN INI (MUSIM %d)" % finished_year
		career["trophiesList"].append({"name": t_name, "season": finished_year, "type": "INDIVIDU"})
		st["trophies"] = int(st["trophies"]) + 1
		st["potyCount"] = int(st.get("potyCount", 0)) + 1
		prof["cash"] = int(prof["cash"]) + 15000
		meta["legacyPoints"] = int(meta["legacyPoints"]) + 25
		_push_news("DUNIA", "GALA MUSIM %d: %s dinobatkan PEMAIN TERBAIK TAHUN INI!" % [finished_year, prof["name"]])
	else:
		meta["legacyPoints"] = int(meta["legacyPoints"]) + 8
		_push_news("DUNIA", "GALA MUSIM %d: %s finis # %d dalam penghargaan Pemain Terbaik Tahun Ini." % [finished_year, prof["name"], u_rank])

	var award := {
		"kind": "POTY",
		"year": finished_year,
		"won": won,
		"user_rank": u_rank,
		"winner_name": str(candidates[0]["name"]),
		"candidates": candidates,
		"user_stats": {"matches": s_matches, "goals": s_goals, "assists": s_assists, "avg_rating": s_avg_r, "league_pos": league_pos},
	}
	meta["lastPotyAward"] = award
	var yhist: Array = meta.get("potyHistory", [])
	yhist.append({"year": finished_year, "won": won, "rank": u_rank})
	meta["potyHistory"] = yhist
	meta["seasonMatches"] = 0
	meta["seasonGoals"] = 0
	meta["seasonAssists"] = 0
	meta["seasonTotalRating"] = 0.0
	meta["seasonMotm"] = 0
	_update_legacy_tier()
	return award

func get_division_leaders() -> Dictionary:
	if not has_active_career:
		return {"goals": [], "assists": [], "rating": [], "user_goal_rank": 1, "top_goals": 1}
	var prof: Dictionary = career["playerProfile"]
	var st: Dictionary = career["stats"]
	var u_name: String = str(prof.get("name", "PEMAIN"))
	var u_goals: int = int(st.get("goals", 0))
	var u_assists: int = int(st.get("assists", 0))
	var matches_n: int = maxi(1, int(st.get("matches", 0)))
	var u_avg_r: float = snappedf(float(st.get("totalRating", 6.5)) / float(matches_n), 0.1) if int(st.get("matches", 0)) > 0 else 6.5
	var wk: int = maxi(1, int(career["careerMeta"].get("week", 1)))
	var seed_base: int = int(prof.get("clubId", 1)) * 31 + int(career["careerMeta"].get("year", 1)) * 97

	var rival_names := [
		"Satrio Setiawan", "Agus Junaidi", "Aji Maulana", "Krisna Purnomo", "Ridwan Hermansyah",
		"Wawan Maulana", "Irfan Silalahi", "Satrio Susanto", "Ferdi Wijaya", "Rizal Prasetyo",
		"Fadil Hutapea", "Dani Ginting", "Aldi Sitompul", "Budi Santoso", "Rangga Rahman",
	]
	var g_list: Array[Dictionary] = [{"name": u_name, "val": u_goals, "is_user": true, "delta": 1}]
	var a_list: Array[Dictionary] = [{"name": u_name, "val": u_assists, "is_user": true, "delta": 2}]
	var r_list: Array[Dictionary] = [{"name": u_name, "val": u_avg_r, "is_user": true, "delta": 3}]

	for i in range(rival_names.size()):
		var h: int = abs((seed_base + i * 73 + wk * 13) % 100)
		var rg: int = maxi(0, int(round(float(wk) * (0.14 + float(h % 25) * 0.018))))
		var ra: int = maxi(0, int(round(float(wk) * (0.10 + float((h + 11) % 22) * 0.015))))
		var rr: float = snappedf(clampf(6.3 + float((h + 17) % 14) * 0.1, 6.1, 8.4), 0.1)
		var d_arr: int = (h % 5) - 2
		g_list.append({"name": rival_names[i], "val": rg, "is_user": false, "delta": d_arr})
		a_list.append({"name": rival_names[(i + 3) % rival_names.size()], "val": ra, "is_user": false, "delta": -d_arr})
		r_list.append({"name": rival_names[(i + 7) % rival_names.size()], "val": rr, "is_user": false, "delta": d_arr})

	g_list.sort_custom(func(a, b): return int(a["val"]) > int(b["val"]) if int(a["val"]) != int(b["val"]) else bool(a["is_user"]))
	a_list.sort_custom(func(a, b): return int(a["val"]) > int(b["val"]) if int(a["val"]) != int(b["val"]) else bool(a["is_user"]))
	r_list.sort_custom(func(a, b): return float(a["val"]) > float(b["val"]) if not is_equal_approx(float(a["val"]), float(b["val"])) else bool(a["is_user"]))

	var u_goal_rank: int = 1
	for idx in range(g_list.size()):
		if bool(g_list[idx]["is_user"]):
			u_goal_rank = idx + 1
			break
	var top_goals: int = int(g_list[0]["val"]) if not g_list.is_empty() else maxi(1, u_goals)
	return {
		"goals": g_list,
		"assists": a_list,
		"rating": r_list,
		"user_goal_rank": u_goal_rank,
		"top_goals": maxi(1, top_goals),
	}

func _award_xp(amount: int) -> void:
	var mult := 2.0 if _has_perk("xp_ganda") or _has_perk("paket_legenda") else 1.0
	if career["inventory"]["staffHired"].has("pelatih_pribadi"):
		mult += 0.15
	var gained := int(round(float(amount) * mult))
	var p: Dictionary = career["playerProfile"]
	p["xp"] = int(p["xp"]) + gained
	var xp_guard: int = 0
	while int(p["xp"]) >= maxi(10, int(p.get("xpToNext", 100))) and xp_guard < 50:
		var req_xp: int = maxi(10, int(p.get("xpToNext", 100)))
		p["xp"] = int(p["xp"]) - req_xp
		p["level"] = int(p["level"]) + 1
		p["skillPoints"] = int(p["skillPoints"]) + 3
		p["xpToNext"] = maxi(10, int(round(float(req_xp) * 1.18)))
		level_up_triggered.emit(int(p["level"]), 3)
		xp_guard += 1

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
	var timnas_trophy_won: Dictionary = {}
	if fix["comp"] == "TIMNAS":
		st["intlCaps"] = int(st["intlCaps"]) + 1
		st["intlGoals"] = int(st["intlGoals"]) + my_g
		timnas_trophy_won = _advance_intl_after_match(fix, us, them, int(result.get("pen_us", -1)), int(result.get("pen_them", -1)))

	# Update season history row
	var sh: Array = career["seasonHistory"]
	if not sh.is_empty():
		var cur_sh: Dictionary = sh[sh.size() - 1]
		cur_sh["matches"] = int(cur_sh["matches"]) + 1
		cur_sh["goals"] = int(cur_sh["goals"]) + my_g
		cur_sh["assists"] = int(cur_sh["assists"]) + my_a
		cur_sh["avgRating"] = snappedf(float(st["totalRating"]) / maxf(1.0, float(st["matches"])), 0.1)

	# Telemetry & Moviola + Competition & Victim Goal Tracking
	var comp_key_raw: String = str(fix.get("comp", "LIGA")).to_upper()
	var comp_bucket: String = "LIGA"
	if comp_key_raw == "PIALA_ELITE":
		comp_bucket = "PIALA_ELITE"
	elif comp_key_raw in ["PIALA_EUROPA", "PIALA_CONF", "PIALA_DUNIA_KLUB", "PIALA"]:
		comp_bucket = "KONTINENTAL"
	elif comp_key_raw in ["TIMNAS", "TURNAMEN_ASIA"]:
		comp_bucket = "KUALIFIKASI"
	if not career.has("compStats") or typeof(career["compStats"]) != TYPE_DICTIONARY:
		career["compStats"] = {}
	var cstats: Dictionary = career["compStats"]
	if not cstats.has(comp_bucket):
		cstats[comp_bucket] = {"season_g": 0, "season_a": 0, "career_g": 0, "career_a": 0}
	var cb: Dictionary = cstats[comp_bucket]
	cb["season_g"] = int(cb.get("season_g", 0)) + my_g
	cb["season_a"] = int(cb.get("season_a", 0)) + my_a
	cb["career_g"] = int(cb.get("career_g", 0)) + my_g
	cb["career_a"] = int(cb.get("career_a", 0)) + my_a

	if my_g > 0:
		if not career.has("victimGoals") or typeof(career["victimGoals"]) != TYPE_DICTIONARY:
			career["victimGoals"] = {}
		var vmap: Dictionary = career["victimGoals"]
		var opp_cd: String = str(fix.get("opp_code", "LWN")).left(3).to_upper()
		if not vmap.has(opp_cd):
			vmap[opp_cd] = {"club_id": int(fix.get("opp_club_id", 0)), "code": opp_cd, "name": str(fix.get("opp_name", opp_cd)), "goals": 0}
		vmap[opp_cd]["goals"] = int(vmap[opp_cd].get("goals", 0)) + my_g

	var shots: Array = result.get("shots", [])
	var cur_club_nm: String = str(get_current_club().get("name", "Klub"))
	for s_entry in shots:
		s_entry["season"] = career["careerMeta"]["year"]
		s_entry["matchId"] = "W%02d_%s" % [week, fix["opp_code"]]
		career["shotTelemetry"].append(s_entry)
		var dist_m: float = float(s_entry.get("distanceMeters", 0.0))
		if s_entry.get("outcome") == "GOAL" and dist_m > float(st.get("longestGoalMeters", 0.0)):
			st["longestGoalMeters"] = dist_m
			st["longestGoalClub"] = cur_club_nm
			st["longestGoalSeason"] = int(career["careerMeta"]["year"])
		elif str(s_entry.get("type", "")) == "PASS" and dist_m > float(st.get("longestPassMeters", 0.0)):
			st["longestPassMeters"] = dist_m
			st["longestPassClub"] = cur_club_nm
			st["longestPassSeason"] = int(career["careerMeta"]["year"])

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

	# Energy drain (+20% more demanding) & weekly recovery
	var fisik := get_effective_attribute("fisik")
	var base_drain := lerpf(18.0, 9.0, float(fisik) / 99.0) * 1.20
	var drain := int(round(base_drain)) + int(result.get("extra_energy_drain", 0))
	if career["inventory"]["staffHired"].has("kebugaran"):
		drain = int(round(float(drain) * 0.8))
	var rec := 8
	if career["inventory"]["staffHired"].has("fisioterapis"):
		rec += 8
	for l_id in career["inventory"]["lifestyleOwned"]:
		if l_id == "apartemen":
			rec += 5
		elif l_id == "rumah_kota":
			rec += 10
		elif l_id == "vila_mewah":
			rec += 18
	career["playerProfile"]["energy"] = clampi(int(career["playerProfile"]["energy"]) - drain + rec, 12, 100)
	# Decrement event cooldown counters (events appear only every 1-3 matches)
	var cur_cd: int = int(career["careerMeta"].get("eventCooldown", 1))
	career["careerMeta"]["eventCooldown"] = maxi(0, cur_cd - 1)
	var cur_pre_cd: int = int(career["careerMeta"].get("preEventCooldown", 0))
	career["careerMeta"]["preEventCooldown"] = maxi(0, cur_pre_cd - 1)

	# Accumulate monthly & seasonal stats for Player of the Month / Player of the Year awards
	career["careerMeta"]["monthMatches"] = int(career["careerMeta"].get("monthMatches", 0)) + 1
	career["careerMeta"]["monthGoals"] = int(career["careerMeta"].get("monthGoals", 0)) + my_g
	career["careerMeta"]["monthAssists"] = int(career["careerMeta"].get("monthAssists", 0)) + my_a
	career["careerMeta"]["monthTotalRating"] = float(career["careerMeta"].get("monthTotalRating", 0.0)) + rating
	if is_motm:
		career["careerMeta"]["monthMotm"] = int(career["careerMeta"].get("monthMotm", 0)) + 1
	var prev_season_goals: int = int(career["careerMeta"].get("seasonGoals", 0))
	career["careerMeta"]["seasonMatches"] = int(career["careerMeta"].get("seasonMatches", 0)) + 1
	career["careerMeta"]["seasonStarts"] = int(career["careerMeta"].get("seasonStarts", 0)) + (1 if get_player_role_status() == "PEMAIN INTI" or int(result.get("starts_inc", 1)) > 0 else 0)
	career["careerMeta"]["seasonGoals"] = prev_season_goals + my_g
	career["careerMeta"]["seasonAssists"] = int(career["careerMeta"].get("seasonAssists", 0)) + my_a
	career["careerMeta"]["seasonTotalRating"] = float(career["careerMeta"].get("seasonTotalRating", 0.0)) + rating
	career["careerMeta"]["seasonConceded"] = int(career["careerMeta"].get("seasonConceded", 0)) + them
	if them == 0:
		career["careerMeta"]["seasonCleanSheets"] = int(career["careerMeta"].get("seasonCleanSheets", 0)) + 1
	var shots_arr: Array = result.get("shots", [])
	career["careerMeta"]["seasonShots"] = int(career["careerMeta"].get("seasonShots", 0)) + maxi(my_g + 1, shots_arr.size())
	var sog_cnt := my_g
	for s_item in shots_arr:
		if typeof(s_item) == TYPE_DICTIONARY and bool(s_item.get("on_target", false)):
			sog_cnt += 1
	career["careerMeta"]["seasonShotsOnTarget"] = int(career["careerMeta"].get("seasonShotsOnTarget", 0)) + maxi(my_g, sog_cnt)
	career["careerMeta"]["seasonDribblesWon"] = int(career["careerMeta"].get("seasonDribblesWon", 0)) + int(result.get("dribbles_won", 0))
	if is_motm:
		career["careerMeta"]["seasonMotm"] = int(career["careerMeta"].get("seasonMotm", 0)) + 1
	# Per-club cumulative goals & assists tracker (feeds LEGENDA PER KLUB -> GOL & ASSIST and Club All-Time Record!)
	var my_cid_now: int = int(career["playerProfile"]["clubId"])
	var cid_key: String = str(my_cid_now)
	if not st.has("clubStats"):
		st["clubStats"] = {}
	var cstats_map: Dictionary = st["clubStats"]
	var prev_club_entry: Dictionary = cstats_map.get(cid_key, {"goals": 0, "assists": 0})
	var prev_club_g: int = int(prev_club_entry.get("goals", 0))
	var prev_club_a: int = int(prev_club_entry.get("assists", 0))
	var is_timnas_fx: bool = (str(fix.get("comp", "")) == "TIMNAS")
	if not is_timnas_fx:
		cstats_map[cid_key] = {"goals": prev_club_g + my_g, "assists": prev_club_a + my_a}
	var cur_club_g: int = int(cstats_map.get(cid_key, {}).get("goals", prev_club_g))

	var broke_club_record := false
	var record_event: Dictionary = {}
	var rec_broken: Array = career["careerMeta"].get("seasonRecordsBroken", [])
	var alltime_broken: Array = career["careerMeta"].get("alltimeRecordsBroken", [])
	var club_rec: int = get_club_season_goal_record(my_cid_now)
	var cur_club_d: Dictionary = get_current_club()
	var u_nat_now: int = clampi(int(career["playerProfile"].get("nationality", 16)), 0, GameData.nations.size() - 1)
	if my_g > 0 and is_timnas_fx:
		var tn_rec: Dictionary = get_timnas_alltime_goal_record(u_nat_now)
		var tn_rec_g: int = int(tn_rec.get("goals", 40))
		var cur_intl_g: int = int(st.get("intlGoals", 0))
		var prev_intl_g: int = maxi(0, cur_intl_g - my_g)
		var tn_key: String = "TIMNAS_%d" % u_nat_now
		if prev_intl_g <= tn_rec_g and cur_intl_g > tn_rec_g and not alltime_broken.has(tn_key):
			broke_club_record = true
			alltime_broken.append(tn_key)
			career["careerMeta"]["alltimeRecordsBroken"] = alltime_broken
			var nat_nm: String = str(GameData.nations[u_nat_now].get("name", "Indonesia"))
			record_event = {
				"kind": "TIMNAS_ALLTIME",
				"title": "REKOR GOL TERBANYAK TIMNAS",
				"new_val": cur_intl_g,
				"old_val": tn_rec_g,
				"old_holder": str(tn_rec.get("holder", "Legenda Timnas")),
				"since": int(tn_rec.get("since", 1998)),
				"org_name": "TIMNAS " + nat_nm.to_upper(),
				"org_role": "TIMNAS",
				"is_timnas": true,
				"nat_id": u_nat_now,
			}
			_push_news("TIMNAS", "REKOR TIMNAS! %s menjadi pencetak gol terbanyak sepanjang masa %s (%d gol)!" % [career["playerProfile"]["name"], nat_nm, cur_intl_g])
	elif my_g > 0:
		var club_at_rec: Dictionary = get_club_alltime_goal_record(my_cid_now)
		var club_at_g: int = int(club_at_rec.get("goals", 120))
		var at_key: String = "CLUB_AT_%d" % my_cid_now
		if prev_club_g <= club_at_g and cur_club_g > club_at_g and not alltime_broken.has(at_key):
			broke_club_record = true
			alltime_broken.append(at_key)
			career["careerMeta"]["alltimeRecordsBroken"] = alltime_broken
			record_event = {
				"kind": "CLUB_ALLTIME",
				"title": "REKOR GOL TERBANYAK SEPANJANG MASA KLUB",
				"new_val": cur_club_g,
				"old_val": club_at_g,
				"old_holder": str(club_at_rec.get("holder", "Legenda Klub")),
				"since": int(club_at_rec.get("since", 1987)),
				"org_name": str(cur_club_d.get("name", "KLUB")).to_upper(),
				"org_role": "KLUB",
				"is_timnas": false,
				"club_id": my_cid_now,
			}
			_push_news("KLUB", "REKOR SEPANJANG MASA! %s jadi top skor abadi %s dengan %d gol!" % [career["playerProfile"]["name"], cur_club_d["name"], cur_club_g])
		elif prev_season_goals <= club_rec and int(career["careerMeta"]["seasonGoals"]) > club_rec and not rec_broken.has("GOALS"):
			broke_club_record = true
			rec_broken.append("GOALS")
			career["careerMeta"]["seasonRecordsBroken"] = rec_broken
			var season_holder: String = _det_legend_name(my_cid_now * 47 + 9, int(cur_club_d.get("nation_id", 1)))
			var season_since: int = 1978 + (my_cid_now * 7) % 38
			record_event = {
				"kind": "CLUB_SEASON",
				"title": "GOL DALAM SATU MUSIM UNTUK KLUB",
				"new_val": int(career["careerMeta"]["seasonGoals"]),
				"old_val": club_rec,
				"old_holder": season_holder,
				"since": season_since,
				"org_name": str(cur_club_d.get("name", "KLUB")).to_upper(),
				"org_role": "KLUB",
				"is_timnas": false,
				"club_id": my_cid_now,
			}
			_push_news("KLUB", "REKOR KLUB! %s pecahkan rekor %d gol semusim milik %s!" % [career["playerProfile"]["name"], int(career["careerMeta"]["seasonGoals"]), cur_club_d["name"]])

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

	# XP & Level Up (2x bonus EXP on winning a Derby match!)
	var is_derby: bool = is_fixture_derby(fix)
	var won_derby: bool = is_derby and (us > them)
	var prev_level := int(career["playerProfile"]["level"])
	var xp_gain := 45 + my_g * 25 + my_a * 15 + (25 if is_motm else 0) + (20 if us > them else 5)
	if won_derby:
		xp_gain *= 2
		_push_news("KLUB", "MENANG DERBY! %s membawa pulang kemenangan bergengsi kontra %s (Bonus EXP 2x)!" % [career["playerProfile"]["name"], fix["opp_name"]])
	_award_xp(xp_gain)

	# News feed + Post-match Social & Inbox messages (Teammate Assist / Supporter / Club Follow)
	if is_motm:
		_push_news("LIGA", "%s menjadi Pemain Terbaik Laga saat %s vs %s (%d-%d)." % [career["playerProfile"]["name"], get_current_club()["code"], fix["opp_code"], us, them])
	elif my_g > 0:
		_push_news("KLUB", "%s mencetak %d gol kontra %s." % [career["playerProfile"]["name"], my_g, fix["opp_name"]])
	generate_post_match_social_and_messages(fix, us, them, my_g, my_a, rating, result.get("goal_timeline", []))

	# Advance week & transfer window
	var tw := int(career["careerMeta"].get("transferWindowWeeksLeft", 0))
	if tw > 0:
		career["careerMeta"]["transferWindowWeeksLeft"] = tw - 1
		_refresh_transfer_offers()
	else:
		career["transferOffers"] = []

	career["contract"]["clubPoints"] = clampi(int(career["contract"]["clubPoints"]) + 1 + (1 if us > them else 0), 0, 200)
	career["contract"]["clubRequestsLevel"] = clampi(1 + int(int(career["contract"]["clubPoints"]) / 35), 1, 6)

	# Track rolling 1-year Ballon d'Or stats window (since previous October Gala)
	if not career["careerMeta"].has("ballonWindow"):
		career["careerMeta"]["ballonWindow"] = {
			"matches": maxi(0, int(st.get("matches", 1)) - 1),
			"goals": maxi(0, int(st.get("goals", my_g)) - my_g),
			"assists": maxi(0, int(st.get("assists", my_a)) - my_a),
			"trophy_baseline_idx": 0,
		}
	var bw_map: Dictionary = career["careerMeta"]["ballonWindow"]
	bw_map["matches"] = int(bw_map.get("matches", 0)) + 1
	bw_map["goals"] = int(bw_map.get("goals", 0)) + my_g
	bw_map["assists"] = int(bw_map.get("assists", 0)) + my_a
	career["careerMeta"]["ballonWindow"] = bw_map

	var max_wks: int = int(career["careerMeta"].get("maxWeeks", 45))
	var cur_m_idx: int = get_season_month_index(week)
	var next_m_idx: int = get_season_month_index(week + 1) if week < max_wks else -1
	var potm_award: Dictionary = {}
	if next_m_idx != cur_m_idx and int(career["careerMeta"].get("monthMatches", 0)) >= 2:
		potm_award = evaluate_player_of_the_month(cur_m_idx)

	# Ballon d'Or & Pemain Muda Terbaik (U-21) Gala: executed on the LAST WEEK OF OCTOBER (month 2 -> 3)!
	var ballon_gala: Dictionary = {}
	var yr_for_gala: int = int(career["careerMeta"].get("year", 1))
	if cur_m_idx == 2 and next_m_idx == 3 and int(career["careerMeta"].get("ballonGalaDoneYear", 0)) != yr_for_gala:
		ballon_gala = evaluate_october_ballon_gala(true)

	var poty_award: Dictionary = {}
	var season_ended := false
	var season_summary := {}
	if week >= max_wks:
		# Defer full season rollover until user holds TAHAN UNTUK AKHIRI MUSIM on KiniTab
		career["careerMeta"]["seasonPendingEnd"] = true
		career["careerMeta"]["week"] = max_wks + 1
		season_ended = false
	else:
		career["careerMeta"]["week"] = week + 1
		career["careerMeta"]["currentDilemma"] = GameData.dilemmas_catalog[week % GameData.dilemmas_catalog.size()]

	if int(st["matches"]) == 1:
		unlock_album_card("debut_pro")
	if int(st["goals"]) >= 1:
		unlock_album_card("gol_perdana")
	if is_motm:
		unlock_album_card("bintang_laga")

	evaluate_achievements()
	save_active_career()

	last_match_report = {
		"fixture": fix,
		"score_us": us,
		"score_them": them,
		"pen_us": int(result.get("pen_us", -1)),
		"pen_them": int(result.get("pen_them", -1)),
		"my_goals": my_g,
		"my_assists": my_a,
		"rating": snappedf(rating, 0.1),
		"motm": is_motm,
		"is_derby": is_derby,
		"won_derby": won_derby,
		"broke_club_record": broke_club_record,
		"record_event": record_event,
		"club_goal_record": club_rec,
		"season_goals_now": int(career["careerMeta"].get("seasonGoals", my_g)),
		"motm_player": result.get("motm_player", {}),
		"xp_gained": xp_gain,
		"leveled_up": int(career["playerProfile"]["level"]) > prev_level,
		"new_level": int(career["playerProfile"]["level"]),
		"cash_earned": total_cash_earned,
		"legacy_add": legacy_add,
		"follower_gain": follower_gain,
		"season_ended": season_ended,
		"season_pending_end": bool(career["careerMeta"].get("seasonPendingEnd", false)),
		"season_summary": season_summary,
		"potm_award": potm_award,
		"poty_award": poty_award,
		"ballon_gala": ballon_gala,
		"timnas_trophy_won": timnas_trophy_won,
		"goal_timeline": result.get("goal_timeline", []),
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
	if not row.has("form"):
		row["form"] = []
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

func get_club_season_goal_record(club_id: int) -> int:
	if club_id < 0 or club_id >= GameData.clubs.size():
		return 18
	var c: Dictionary = GameData.clubs[club_id]
	return clampi(int(round(float(c.get("ovr", 60)) * 0.34)), 14, 34)

func set_contract_clause(clause_id: String) -> bool:
	if not has_active_career:
		return false
	var valid := ["NONE", "ANTI_DEGRADASI", "JANJI_INTI", "TOLAK_RIVAL"]
	if not valid.has(clause_id):
		return false
	career["contract"]["clause"] = clause_id
	save_active_career()
	career_updated.emit()
	return true

func evaluate_timnas_callup(wk: int = -1) -> Dictionary:
	if not has_active_career:
		return {"called_up": false, "score": 50, "threshold": 70, "role": "TIDAK DIPANGGIL", "nation_name": "INDONESIA", "nation_id": 16, "shortfall": 20, "opp_name": "VIETNAM"}
	var target_wk: int = wk if wk > 0 else int(career["careerMeta"].get("week", 1))
	var prof: Dictionary = career["playerProfile"]
	var club: Dictionary = get_current_club()
	var nat_id: int = clampi(int(prof.get("nationId", 16)), 0, GameData.nations.size() - 1)
	var nat: Dictionary = GameData.nations[nat_id]
	var nat_ovr: int = int(nat.get("ovr", 70))
	var ovr: int = int(prof.get("ovr", 60))
	var div_num: int = int(club.get("division", 3))
	var div_bonus: int = 10 if div_num == 1 else (4 if div_num == 2 else 0)
	var sm: int = maxi(1, int(career["careerMeta"].get("seasonMatches", 1)))
	var avg_rtg: float = float(career["careerMeta"].get("seasonTotalRating", 6.5 * float(sm))) / float(sm)
	var rtg_bonus: int = clampi(int(round((avg_rtg - 5.5) * 3.5)), 0, 12)
	var score: int = clampi(ovr + div_bonus + rtg_bonus - 5, 38, 99)
	var threshold: int = clampi(int(round(float(nat_ovr) * 0.88)), 56, 78)
	var called := (score >= threshold)
	var fix: Dictionary = get_current_fixture()
	var called_weeks: Array = career["careerMeta"].get("timnasCalledWeeks", [])
	if not called_weeks.has(target_wk):
		called_weeks.append(target_wk)
		career["careerMeta"]["timnasCalledWeeks"] = called_weeks
		save_active_career()
	return {
		"week": target_wk,
		"called_up": called,
		"score": score,
		"threshold": threshold,
		"shortfall": maxi(0, threshold - score),
		"div_bonus": div_bonus,
		"avg_rating": snappedf(avg_rtg, 0.1),
		"role": "INTI DI TIMNASMU" if score >= threshold + 6 else "CADANGAN TIMNAS",
		"nation_id": nat_id,
		"nation_name": str(nat.get("name", "TIMNAS")).to_upper(),
		"opp_name": str(fix.get("opp_name", "VIETNAM")).to_upper(),
	}

func skip_timnas_week() -> void:
	if not has_active_career:
		return
	var wk: int = int(career["careerMeta"].get("week", 1))
	var max_wks: int = int(career["careerMeta"].get("maxWeeks", 45))
	career["playerProfile"]["energy"] = clampi(int(career["playerProfile"].get("energy", 80)) + 10, 0, 100)
	if wk < max_wks:
		career["careerMeta"]["week"] = wk + 1
	save_active_career()
	career_updated.emit()

# ==============================================================================
# TIMNAS & 6-CONFEDERATION INTERNATIONAL TOURNAMENT ENGINE
# ==============================================================================
func _find_nation_id_by_code(code: String) -> int:
	var c: String = code.to_upper()
	for nat in GameData.nations:
		if str(nat.get("code", "")).to_upper() == c:
			return int(nat["id"])
	return 0

func _get_ko_round_names(start_stage: String) -> Array[String]:
	match start_stage:
		"16 BESAR": return ["16 BESAR", "8 BESAR", "SEMI FINAL", "FINAL"]
		"8 BESAR": return ["8 BESAR", "SEMI FINAL", "FINAL"]
		"SEMI FINAL": return ["SEMI FINAL", "FINAL"]
	return []

func ensure_intl_state(force_rebuild: bool = false) -> Dictionary:
	if not has_active_career:
		return {}
	var prof: Dictionary = career["playerProfile"]
	var meta: Dictionary = career["careerMeta"]
	var nat_id: int = clampi(int(prof.get("nationId", 16)), 0, GameData.nations.size() - 1)
	var yr: int = int(meta.get("year", 1))
	if not force_rebuild and career.has("intlState"):
		var existing: Dictionary = career["intlState"]
		if int(existing.get("year", -1)) == yr and int(existing.get("nation_id", -1)) == nat_id and not existing.get("group_table", []).is_empty():
			return existing

	var nat: Dictionary = GameData.nations[nat_id]
	var u_code: String = str(nat.get("code", "IDN")).to_upper()
	var u_name: String = str(nat.get("name", "Indonesia"))
	var u_cols: Array = nat.get("colors", [Color("#CE1126"), Color("#FFFFFF")])
	var confed: String = ConfederationDataScript.get_nation_confederation(nat_id)
	var wc_qual: bool = bool(meta.get("wcQualified", false))
	var campaign: Dictionary = ConfederationDataScript.get_season_campaign(confed, yr, wc_qual)
	var grp_data: Dictionary = ConfederationDataScript.build_seeded_group(confed, campaign, u_code, u_name, u_cols, yr * 733 + nat_id * 41)

	var state := {
		"year": yr,
		"nation_id": nat_id,
		"nation_code": u_code,
		"nation_name": u_name,
		"confed": confed,
		"campaign": campaign,
		"phase": "GROUP",
		"group_name": str(grp_data.get("group_name", "GRUP A")),
		"user_pot": int(grp_data.get("user_pot", 2)),
		"group_played": 0,
		"group_table": grp_data.get("rows", []),
		"knockout": {},
	}
	career["intlState"] = state
	return state

func get_timnas_overview() -> Dictionary:
	if not has_active_career:
		return {}
	ensure_world_database()
	var intl: Dictionary = ensure_intl_state()
	var prof: Dictionary = career["playerProfile"]
	var meta: Dictionary = career["careerMeta"]
	var club: Dictionary = get_current_club()
	var nat_id: int = int(intl["nation_id"])
	var nat: Dictionary = GameData.nations[clampi(nat_id, 0, GameData.nations.size() - 1)]
	var w_rank: int = int(nat.get("world_rank", 25))
	var ovr: int = int(prof.get("ovr", 60))
	var div_you: int = clampi(int(club.get("division", 3)), 1, 3)

	# Requirements scale realistically with nation world rank
	var div_req: int = 1 if w_rank <= 8 else (2 if w_rank <= 22 else 3)
	var rtg_req: float = 7.4 if w_rank <= 8 else (6.8 if w_rank <= 22 else 6.4)
	var level_req: int = 76 if w_rank <= 6 else (68 if w_rank <= 15 else (60 if w_rank <= 30 else 53))

	var sm: int = int(meta.get("seasonMatches", 0))
	var rt_sum: float = float(meta.get("seasonTotalRating", 0.0))
	if sm == 0:
		sm = int(career["stats"].get("matches", 0))
		rt_sum = float(career["stats"].get("totalRating", 0.0))
	var rtg_you: float = snappedf(rt_sum / float(maxi(1, sm)), 0.1) if sm > 0 else 6.5
	var div_bonus: float = 5.5 if div_you == 1 else (2.4 if div_you == 2 else 0.0)
	var rtg_bonus: float = clampf((rtg_you - 6.0) * 2.2, -3.0, 8.0)
	var level_you: float = snappedf(clampf(float(ovr) + div_bonus + rtg_bonus - 2.1, 40.0, 99.0), 0.1)

	var div_ok: bool = (div_you <= div_req)
	var rtg_ok: bool = (rtg_you >= rtg_req)
	var level_ok: bool = (level_you >= float(level_req))
	var status: String = "TIDAK DIPANGGIL"
	if level_you >= float(level_req) + 5.0 and div_ok:
		status = "INTI"
	elif level_ok:
		status = "CADANGAN"

	var won_list: Array = meta.get("intlTrophiesWon", [])
	var camp: Dictionary = intl.get("campaign", {})
	var confed: String = str(intl.get("confed", "AFC"))
	var c_meta: Dictionary = ConfederationDataScript.CONFED_META.get(confed, ConfederationDataScript.CONFED_META["AFC"])
	var cont_ok: bool = (not won_list.is_empty()) or (str(camp.get("kind", "")) in ["CONTINENTAL", "WORLD_CUP", "WCQ"] and level_ok)

	# Build 25-man national team squad & replaced rival at user's position (Gambar 1!)
	var squad_res: Dictionary = _build_national_squad_25(nat_id, level_req, status != "TIDAK DIPANGGIL")
	return {
		"nation_id": nat_id,
		"nation_code": str(intl["nation_code"]),
		"nation_name": str(intl["nation_name"]).to_upper(),
		"confed": confed,
		"confed_full": str(c_meta.get("full_name", confed)),
		"status": status,
		"div_you": div_you,
		"div_req": div_req,
		"div_ok": div_ok,
		"rtg_you": rtg_you,
		"rtg_req": rtg_req,
		"rtg_ok": rtg_ok,
		"level_you": level_you,
		"level_req": level_req,
		"level_ok": level_ok,
		"continental_ok": cont_ok,
		"continental_title": str(c_meta.get("main_tournament", "PIALA BENUA")),
		"squad_25": squad_res["squad"],
		"replaced_player": squad_res["replaced"],
		"intl": intl,
	}

func _build_national_squad_25(nat_id: int, base_ovr: int, user_called: bool) -> Dictionary:
	var prof: Dictionary = career["playerProfile"]
	var u_name: String = str(prof.get("name", "PEMAIN"))
	var u_pos: String = str(prof.get("favoritePosition", "ST"))
	var u_ovr: int = int(prof.get("ovr", 65))
	var u_club: Dictionary = get_current_club()
	var pos_slots: Array[String] = [
		"GK", "CB", "CB", "LB", "RB", "CDM", "CM", "CAM", "LW", "RW", "ST",
		"GK", "GK", "CB", "CB", "LB", "RB", "CDM", "CM", "CM", "LM", "RM", "CAM", "LW", "ST"
	]
	var nat_players: Array[Dictionary] = []
	for i in range(0, TOTAL_WORLD_PLAYERS, 5):
		if int(wp_nat[i]) == nat_id:
			var raw_cid: int = int(wp_club[i])
			var has_clb: bool = (raw_cid >= 0 and raw_cid < GameData.clubs.size())
			nat_players.append({
				"name": wp_name[i],
				"pos": GameData.POSITIONS[int(wp_pos[i]) % GameData.POSITIONS.size()],
				"ovr": clampi(int(wp_ovr[i]), base_ovr - 6, base_ovr + 14),
				"club_code": str(GameData.clubs[raw_cid].get("code", "CLB")).left(3).to_upper() if has_clb else "TAN",
				"club_name": str(GameData.clubs[raw_cid].get("name", "Klub")) if has_clb else "Tanpa Klub",
				"is_user": false,
			})
			if nat_players.size() >= 36:
				break
	var rng := RandomNumberGenerator.new()
	rng.seed = nat_id * 991 + 42
	while nat_players.size() < 28:
		var fn: String = GameData.FIRST_NAMES[rng.randi_range(0, GameData.FIRST_NAMES.size() - 1)]
		var ln: String = GameData.LAST_NAMES[rng.randi_range(0, GameData.LAST_NAMES.size() - 1)]
		var rc: Dictionary = GameData.clubs[rng.randi_range(0, GameData.clubs.size() - 1)]
		nat_players.append({
			"name": "%s %s" % [fn, ln],
			"pos": pos_slots[nat_players.size() % pos_slots.size()],
			"ovr": clampi(base_ovr + rng.randi_range(-3, 9), 50, 90),
			"club_code": str(rc.get("code", "CLB")).left(3).to_upper(),
			"club_name": str(rc.get("name", "Klub")),
			"is_user": false,
		})
	nat_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["ovr"]) > int(b["ovr"])
	)

	var squad: Array[Dictionary] = []
	var replaced: Dictionary = {}
	var user_inserted := false
	for idx in range(25):
		var slot_pos: String = pos_slots[idx]
		var entry: Dictionary = nat_players[idx].duplicate(true)
		entry["pos"] = slot_pos
		entry["is_starter"] = (idx < 11)
		if not user_inserted and slot_pos == u_pos:
			replaced = entry.duplicate(true)
			if user_called:
				entry = {
					"name": u_name,
					"pos": u_pos,
					"ovr": u_ovr,
					"club_code": str(u_club.get("code", "CLB")).left(3).to_upper(),
					"club_name": str(u_club.get("name", "Klub")),
					"is_user": true,
					"is_starter": (idx < 11),
				}
				user_inserted = true
		squad.append(entry)
	if replaced.is_empty():
		replaced = nat_players[10].duplicate(true)
		replaced["pos"] = u_pos
	if user_called and not user_inserted:
		squad[10] = {
			"name": u_name,
			"pos": u_pos,
			"ovr": u_ovr,
			"club_code": str(u_club.get("code", "CLB")).left(3).to_upper(),
			"club_name": str(u_club.get("name", "Klub")),
			"is_user": true,
			"is_starter": true,
		}
	return {"squad": squad, "replaced": replaced}

func _advance_intl_after_match(fix: Dictionary, us: int, them: int, pen_us: int, pen_them: int) -> Dictionary:
	var intl: Dictionary = ensure_intl_state()
	if intl.is_empty():
		return {}
	var camp: Dictionary = intl.get("campaign", {})
	var phase: String = str(intl.get("phase", "GROUP"))
	var u_code: String = str(intl.get("nation_code", "IDN")).to_upper()
	var opp_code: String = str(fix.get("opp_code", "")).to_upper()
	var yr: int = int(intl.get("year", 1))
	var wk: int = int(fix.get("week", 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = yr * 8123 + wk * 419 + us * 31 + them * 17

	if phase == "GROUP":
		var rows: Array = intl.get("group_table", [])
		var u_row: Dictionary = {}
		var o_row: Dictionary = {}
		var others: Array[Dictionary] = []
		for r in rows:
			var rc: String = str(r.get("code", "")).to_upper()
			if bool(r.get("is_user", false)):
				u_row = r
			elif rc == opp_code and o_row.is_empty():
				o_row = r
			else:
				others.append(r)
		if o_row.is_empty() and not others.is_empty():
			o_row = others.pop_front()
		if not u_row.is_empty():
			_apply_match_to_table_row(u_row, us, them)
		if not o_row.is_empty():
			_apply_match_to_table_row(o_row, them, us)
		# Simulate remaining group pairs evenly
		others.shuffle()
		var p_i: int = 0
		while p_i + 1 < others.size():
			var ra: Dictionary = others[p_i]
			var rb: Dictionary = others[p_i + 1]
			var diff: int = int(ra.get("ovr", 70)) - int(rb.get("ovr", 70))
			var ga: int = clampi(int(rng.randf_range(0.0, 2.5) + float(diff) * 0.05), 0, 5)
			var gb: int = clampi(int(rng.randf_range(0.0, 2.3) - float(diff) * 0.05), 0, 5)
			_apply_match_to_table_row(ra, ga, gb)
			_apply_match_to_table_row(rb, gb, ga)
			p_i += 2

		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["pts"]) != int(b["pts"]):
				return int(a["pts"]) > int(b["pts"])
			var gda: int = int(a["gf"]) - int(a["ga"])
			var gdb: int = int(b["gf"]) - int(b["ga"])
			if gda != gdb:
				return gda > gdb
			return int(a["gf"]) > int(b["gf"])
		)
		intl["group_table"] = rows
		intl["group_played"] = int(intl.get("group_played", 0)) + 1

		var grp_weeks: Array = camp.get("group_weeks", [])
		if int(intl["group_played"]) >= grp_weeks.size():
			var u_rank: int = rows.size()
			for i in range(rows.size()):
				if bool(rows[i].get("is_user", false)):
					u_rank = i + 1
					break
			var qual_top: int = int(camp.get("qualify_top", 2))
			var qualified: bool = (u_rank <= qual_top)
			if bool(camp.get("has_knockout", false)):
				intl["knockout"] = _build_intl_knockout_bracket(intl, qualified, rng)
				intl["phase"] = "KNOCKOUT"
				if qualified:
					_push_news("DUNIA", "%s lolos ke babak %s %s!" % [intl["nation_name"], str(camp.get("knockout_start", "16 BESAR")), str(camp.get("title", "TURNAMEN"))])
					_sync_next_timnas_ko_fixture(intl)
				else:
					_push_news("DUNIA", "%s tersingkir di fase grup %s (peringkat %d)." % [intl["nation_name"], str(camp.get("title", "TURNAMEN")), u_rank])
					_clear_remaining_timnas_ko_fixtures(wk)
			else:
				intl["phase"] = "FINISHED"
				if str(camp.get("kind", "")) == "WCQ":
					career["careerMeta"]["wcQualified"] = qualified
					if qualified:
						_push_news("DUNIA", "SEJARAH! %s LOLOS ke PIALA DUNIA FIFA dari %s!" % [intl["nation_name"], str(camp.get("title", "KUALIFIKASI"))])
					else:
						_push_news("DUNIA", "%s gagal lolos langsung Piala Dunia (peringkat %d grup)." % [intl["nation_name"], u_rank])
		return {}

	elif phase == "KNOCKOUT":
		var ko: Dictionary = intl.get("knockout", {})
		if ko.is_empty() or str(ko.get("user_status", "")) != "ACTIVE":
			return {}
		var r_idx: int = int(ko.get("active_round_idx", 0))
		var rounds: Array = ko.get("rounds", [])
		if r_idx < 0 or r_idx >= rounds.size():
			return {}
		var cur_round: Dictionary = rounds[r_idx]
		var matches: Array = cur_round.get("matches", [])
		var user_won: bool = (us > them)
		if us == them:
			if pen_us >= 0 and pen_them >= 0 and pen_us != pen_them:
				user_won = (pen_us > pen_them)
			else:
				user_won = true  # Extra-time / shootout victory fallback

		var winners: Array[Dictionary] = []
		for m in matches:
			var is_um: bool = bool(m.get("is_user_match", false))
			if is_um:
				var u_is_a: bool = (str(m["a_code"]).to_upper() == u_code)
				m["score_a"] = us if u_is_a else them
				m["score_b"] = them if u_is_a else us
				if int(m["score_a"]) == int(m["score_b"]):
					if user_won:
						if u_is_a: m["score_a"] = int(m["score_a"]) + 1
						else: m["score_b"] = int(m["score_b"]) + 1
					else:
						if u_is_a: m["score_b"] = int(m["score_b"]) + 1
						else: m["score_a"] = int(m["score_a"]) + 1
				m["played"] = true
				m["user_passed"] = user_won
				m["user_failed"] = not user_won
				if user_won:
					m["winner_code"] = u_code
					winners.append(_team_from_match_side(m, u_is_a))
				else:
					m["winner_code"] = str(m["b_code"]) if u_is_a else str(m["a_code"])
					winners.append(_team_from_match_side(m, not u_is_a))
			else:
				var diff: int = int(m.get("a_ovr", 72)) - int(m.get("b_ovr", 72))
				var sa: int = clampi(int(rng.randf_range(0.0, 2.7) + float(diff) * 0.05), 0, 5)
				var sb: int = clampi(int(rng.randf_range(0.0, 2.5) - float(diff) * 0.05), 0, 5)
				if sa == sb:
					if diff >= 0: sa += 1
					else: sb += 1
				m["score_a"] = sa
				m["score_b"] = sb
				m["played"] = true
				var a_won: bool = (sa > sb)
				m["winner_code"] = str(m["a_code"]) if a_won else str(m["b_code"])
				winners.append(_team_from_match_side(m, a_won))

		# Populate next round or finalize tournament
		if r_idx + 1 < rounds.size():
			var next_round: Dictionary = rounds[r_idx + 1]
			var next_matches: Array = next_round.get("matches", [])
			for ni in range(next_matches.size()):
				var wa: Dictionary = winners[mini(ni * 2, winners.size() - 1)]
				var wb: Dictionary = winners[mini(ni * 2 + 1, winners.size() - 1)]
				var nm: Dictionary = next_matches[ni]
				nm["a_code"] = str(wa["code"])
				nm["a_name"] = str(wa["name"])
				nm["a_ovr"] = int(wa["ovr"])
				nm["a_colors"] = wa["colors"]
				nm["b_code"] = str(wb["code"])
				nm["b_name"] = str(wb["name"])
				nm["b_ovr"] = int(wb["ovr"])
				nm["b_colors"] = wb["colors"]
				nm["is_user_match"] = (str(wa["code"]).to_upper() == u_code or str(wb["code"]).to_upper() == u_code)

			ko["active_round_idx"] = r_idx + 1
			ko["active_round"] = str(next_round["name"])
			if user_won:
				_push_news("DUNIA", "%s melaju ke %s %s!" % [intl["nation_name"], str(next_round["name"]), str(camp.get("title", "TURNAMEN"))])
				_sync_next_timnas_ko_fixture(intl)
			else:
				ko["user_status"] = "ELIMINATED"
				_simulate_remaining_ko_rounds(ko, r_idx + 1, rng)
				intl["phase"] = "KNOCKOUT"
				_push_news("DUNIA", "%s terhenti di %s %s." % [intl["nation_name"], str(cur_round["name"]), str(camp.get("title", "TURNAMEN"))])
				_clear_remaining_timnas_ko_fixtures(wk)
			return {}
		else:
			# FINAL completed!
			var champ_t: Dictionary = winners[0] if not winners.is_empty() else {"code": u_code, "name": intl["nation_name"]}
			ko["champion_code"] = str(champ_t["code"])
			ko["champion_name"] = str(champ_t["name"])
			if user_won:
				ko["user_status"] = "CHAMPION"
				ko["active_round"] = "JUARA"
				var t_title: String = str(camp.get("title", "PIALA BENUA"))
				var trophy_name: String = "JUARA %s (%s)" % [t_title, str(intl["nation_name"])]
				career["trophiesList"].append({"name": trophy_name, "season": yr, "type": "TIMNAS"})
				career["stats"]["trophies"] = int(career["stats"]["trophies"]) + 1
				career["careerMeta"]["legacyPoints"] = int(career["careerMeta"]["legacyPoints"]) + 60
				career["stats"]["followers"] = int(career["stats"]["followers"]) + 25000
				var won_ids: Array = career["careerMeta"].get("intlTrophiesWon", [])
				if not won_ids.has(str(camp.get("id", "INTL"))):
					won_ids.append(str(camp.get("id", "INTL")))
				career["careerMeta"]["intlTrophiesWon"] = won_ids
				_push_news("DUNIA", "JUARA! %s MENJADI KAMPION %s!" % [str(intl["nation_name"]).to_upper(), t_title])
				return {
					"title": t_title,
					"trophy_name": trophy_name,
					"confed": str(intl["confed"]),
					"nation_id": int(intl["nation_id"]),
					"nation_code": u_code,
					"nation_name": str(intl["nation_name"]).to_upper(),
					"year": yr,
					"score_us": us,
					"score_them": them,
					"opp_name": str(fix.get("opp_name", "LAWAN")).to_upper(),
				}
			else:
				ko["user_status"] = "ELIMINATED"
				ko["active_round"] = "FINAL"
				_push_news("DUNIA", "%s harus puas jadi runner-up %s setelah kalah di Final." % [intl["nation_name"], str(camp.get("title", "TURNAMEN"))])
	return {}

func _team_from_match_side(m: Dictionary, is_a: bool) -> Dictionary:
	if is_a:
		return {"code": str(m["a_code"]), "name": str(m["a_name"]), "ovr": int(m.get("a_ovr", 72)), "colors": m.get("a_colors", [Color.BLUE, Color.WHITE])}
	return {"code": str(m["b_code"]), "name": str(m["b_name"]), "ovr": int(m.get("b_ovr", 72)), "colors": m.get("b_colors", [Color.RED, Color.WHITE])}

func _build_intl_knockout_bracket(intl: Dictionary, user_qualified: bool, rng: RandomNumberGenerator) -> Dictionary:
	var camp: Dictionary = intl.get("campaign", {})
	var start_stage: String = str(camp.get("knockout_start", "16 BESAR"))
	var r_names: Array[String] = _get_ko_round_names(start_stage)
	var team_count: int = 16 if start_stage == "16 BESAR" else (8 if start_stage == "8 BESAR" else 4)
	var confed: String = str(intl.get("confed", "AFC"))
	var u_code: String = str(intl.get("nation_code", "IDN")).to_upper()
	var is_wc: bool = (str(camp.get("kind", "")) == "WORLD_CUP")
	var pool: Array[Dictionary] = ConfederationDataScript.build_world_cup_pool() if is_wc else ConfederationDataScript.get_confed_teams_with_pots(confed, 4)

	var seeds: Array[Dictionary] = []
	var used: Dictionary = {}
	# Place user at top slot (index 0) if qualified!
	if user_qualified:
		for r in intl.get("group_table", []):
			if bool(r.get("is_user", false)):
				seeds.append({"code": str(r["code"]), "name": str(r["name"]), "ovr": int(r.get("ovr", 70)), "colors": r.get("colors", [Color.RED, Color.WHITE])})
				used[str(r["code"]).to_upper()] = true
				break
	else:
		used[u_code] = true

	# Add other group qualifier(s) + top pool teams
	for r in intl.get("group_table", []):
		if seeds.size() >= team_count:
			break
		var rc: String = str(r["code"]).to_upper()
		if not used.has(rc):
			used[rc] = true
			seeds.append({"code": rc, "name": str(r["name"]), "ovr": int(r.get("ovr", 70)), "colors": r.get("colors", [Color.BLUE, Color.WHITE])})
	for t in pool:
		if seeds.size() >= team_count:
			break
		var tc: String = str(t["code"]).to_upper()
		if not used.has(tc):
			used[tc] = true
			seeds.append({"code": tc, "name": str(t["name"]), "ovr": int(t.get("ovr", 70)), "colors": t.get("colors", [Color.BLUE, Color.WHITE])})
	while seeds.size() < team_count:
		var idx: int = seeds.size()
		seeds.append({"code": "T%02d" % idx, "name": "Timnas %d" % idx, "ovr": 66, "colors": [Color("#3B82F6"), Color("#FFFFFF")]})

	var rounds: Array[Dictionary] = []
	var match_cnt: int = int(team_count / 2)
	for ri in range(r_names.size()):
		var m_list: Array[Dictionary] = []
		for mi in range(match_cnt):
			if ri == 0:
				var ta: Dictionary = seeds[mi * 2]
				var tb: Dictionary = seeds[mi * 2 + 1]
				m_list.append({
					"a_code": str(ta["code"]), "a_name": str(ta["name"]), "a_ovr": int(ta["ovr"]), "a_colors": ta["colors"],
					"b_code": str(tb["code"]), "b_name": str(tb["name"]), "b_ovr": int(tb["ovr"]), "b_colors": tb["colors"],
					"score_a": -1, "score_b": -1, "played": false, "winner_code": "",
					"is_user_match": (str(ta["code"]).to_upper() == u_code or str(tb["code"]).to_upper() == u_code),
					"user_passed": false, "user_failed": false,
				})
			else:
				m_list.append({
					"a_code": "TBD", "a_name": "Menunggu", "a_ovr": 72, "a_colors": [Color("#334155"), Color("#64748B")],
					"b_code": "TBD", "b_name": "Menunggu", "b_ovr": 72, "b_colors": [Color("#334155"), Color("#64748B")],
					"score_a": -1, "score_b": -1, "played": false, "winner_code": "",
					"is_user_match": false, "user_passed": false, "user_failed": false,
				})
		rounds.append({"name": r_names[ri], "matches": m_list})
		match_cnt = maxi(1, int(match_cnt / 2))

	var ko := {
		"start_stage": start_stage,
		"active_round_idx": 0,
		"active_round": r_names[0] if not r_names.is_empty() else "FINAL",
		"user_status": "ACTIVE" if user_qualified else "ELIMINATED",
		"champion_code": "",
		"champion_name": "",
		"rounds": rounds,
	}
	if not user_qualified:
		_simulate_remaining_ko_rounds(ko, 0, rng)
	return ko

func _simulate_remaining_ko_rounds(ko: Dictionary, start_r_idx: int, rng: RandomNumberGenerator) -> void:
	var rounds: Array = ko.get("rounds", [])
	for r_idx in range(start_r_idx, rounds.size()):
		var cur_r: Dictionary = rounds[r_idx]
		var winners: Array[Dictionary] = []
		for m in cur_r.get("matches", []):
			if not bool(m.get("played", false)):
				var diff: int = int(m.get("a_ovr", 72)) - int(m.get("b_ovr", 72))
				var sa: int = clampi(int(rng.randf_range(0.0, 2.7) + float(diff) * 0.05), 0, 5)
				var sb: int = clampi(int(rng.randf_range(0.0, 2.5) - float(diff) * 0.05), 0, 5)
				if sa == sb:
					if diff >= 0: sa += 1
					else: sb += 1
				m["score_a"] = sa
				m["score_b"] = sb
				m["played"] = true
				m["winner_code"] = str(m["a_code"]) if sa > sb else str(m["b_code"])
			var a_won: bool = (str(m["winner_code"]) == str(m["a_code"]))
			winners.append(_team_from_match_side(m, a_won))
		if r_idx + 1 < rounds.size():
			var next_m: Array = rounds[r_idx + 1].get("matches", [])
			for ni in range(next_m.size()):
				var wa: Dictionary = winners[mini(ni * 2, winners.size() - 1)]
				var wb: Dictionary = winners[mini(ni * 2 + 1, winners.size() - 1)]
				next_m[ni]["a_code"] = str(wa["code"])
				next_m[ni]["a_name"] = str(wa["name"])
				next_m[ni]["a_ovr"] = int(wa["ovr"])
				next_m[ni]["a_colors"] = wa["colors"]
				next_m[ni]["b_code"] = str(wb["code"])
				next_m[ni]["b_name"] = str(wb["name"])
				next_m[ni]["b_ovr"] = int(wb["ovr"])
				next_m[ni]["b_colors"] = wb["colors"]
		elif not winners.is_empty():
			ko["champion_code"] = str(winners[0]["code"])
			ko["champion_name"] = str(winners[0]["name"])

func _sync_next_timnas_ko_fixture(intl: Dictionary) -> void:
	var ko: Dictionary = intl.get("knockout", {})
	var r_idx: int = int(ko.get("active_round_idx", 0))
	var rounds: Array = ko.get("rounds", [])
	if r_idx < 0 or r_idx >= rounds.size():
		return
	var r_name: String = str(rounds[r_idx]["name"])
	var u_code: String = str(intl.get("nation_code", "")).to_upper()
	var opp_info: Dictionary = {}
	for m in rounds[r_idx].get("matches", []):
		if bool(m.get("is_user_match", false)):
			var u_is_a: bool = (str(m["a_code"]).to_upper() == u_code)
			opp_info = _team_from_match_side(m, not u_is_a)
			break
	if opp_info.is_empty():
		return
	for fx in career.get("schedule", []):
		if str(fx.get("comp", "")) == "TIMNAS" and str(fx.get("stage", "")) == r_name and not bool(fx.get("played", false)):
			fx["opp_name"] = str(opp_info["name"])
			fx["opp_code"] = str(opp_info["code"]).left(3).to_upper()
			fx["opp_ovr"] = int(opp_info["ovr"])
			fx["opp_club_id"] = _find_nation_id_by_code(str(opp_info["code"]))
			break

func _clear_remaining_timnas_ko_fixtures(after_week: int) -> void:
	var club: Dictionary = get_current_club()
	var div_clubs: Array[Dictionary] = GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	var fallback_opp: Dictionary = div_clubs[0] if not div_clubs.is_empty() else GameData.clubs[0]
	for c in div_clubs:
		if int(c["id"]) != int(club["id"]):
			fallback_opp = c
			break
	for fx in career.get("schedule", []):
		if int(fx.get("week", 0)) > after_week and str(fx.get("comp", "")) == "TIMNAS" and bool(fx.get("is_knockout", false)) and not bool(fx.get("played", false)):
			fx["comp"] = "LIGA"
			fx["stage"] = ""
			fx["comp_label"] = "LIGA ke-%d" % int(club["division"])
			fx["is_knockout"] = false
			fx["opp_club_id"] = int(fallback_opp["id"])
			fx["opp_name"] = str(fallback_opp["name"])
			fx["opp_code"] = str(fallback_opp["code"])
			fx["opp_ovr"] = int(fallback_opp["ovr"])

func build_confed_explorer_data(confed_id: String) -> Dictionary:
	var cid: String = confed_id if ConfederationDataScript.CONFED_META.has(confed_id) else "AFC"
	var meta: Dictionary = ConfederationDataScript.CONFED_META[cid]
	var yr: int = int(career.get("careerMeta", {}).get("year", 1)) if has_active_career else 1
	var my_intl: Dictionary = ensure_intl_state() if has_active_career else {}
	var is_my_confed: bool = (not my_intl.is_empty() and str(my_intl.get("confed", "")) == cid)
	var camp: Dictionary = my_intl.get("campaign", {}) if is_my_confed else ConfederationDataScript.get_season_campaign(cid, yr, false)
	var pot_cnt: int = int(camp.get("pot_count", 4))
	var all_teams: Array[Dictionary] = ConfederationDataScript.get_confed_teams_with_pots(cid, pot_cnt)
	var pots: Array = []
	for p in range(1, pot_cnt + 1):
		var p_list: Array[Dictionary] = []
		for t in all_teams:
			if int(t["pot"]) == p:
				p_list.append(t)
		pots.append({"pot": p, "teams": p_list})

	var group_rows: Array = []
	var group_name: String = "GRUP A"
	var ko_data: Dictionary = {}
	if is_my_confed:
		group_rows = my_intl.get("group_table", [])
		group_name = str(my_intl.get("group_name", "GRUP A"))
		ko_data = my_intl.get("knockout", {})
	else:
		var sample_first: Dictionary = all_teams[0] if not all_teams.is_empty() else {"code": "ESP", "name": "Spanyol", "colors": [Color.RED, Color.YELLOW]}
		var sg: Dictionary = ConfederationDataScript.build_seeded_group(cid, camp, str(sample_first["code"]), str(sample_first["name"]), sample_first["colors"], yr * 409 + cid.hash())
		group_rows = sg.get("rows", [])
		for r in group_rows:
			r["is_user"] = false
		group_name = str(sg.get("group_name", "GRUP A"))

	return {
		"meta": meta,
		"campaign": camp,
		"pots": pots,
		"group_name": group_name,
		"group_rows": group_rows,
		"knockout": ko_data,
		"is_my_confed": is_my_confed,
	}

func finalize_season_rollover() -> Dictionary:
	if not has_active_career:
		return {}
	var poty_award := evaluate_player_of_the_year(int(career["careerMeta"]["year"]), get_user_league_position())
	var summary := _rollover_season()
	summary["poty_award"] = poty_award
	career["careerMeta"]["seasonPendingEnd"] = false
	save_active_career()
	career_updated.emit()
	return summary

func _rollover_season() -> Dictionary:
	var finished_yr: int = int(career["careerMeta"]["year"])
	var pos := get_user_league_position()
	var table_size: int = maxi(1, career["leagueTable"].size())
	var club := get_current_club()
	var div_num := int(club["division"])
	var nat_id := int(club["nation_id"])
	var st: Dictionary = career["stats"]
	var trophies_won: Array[String] = []
	var old_table := get_sorted_league_table()

	if div_num == 3:
		st["seasonsDiv3"] = int(st["seasonsDiv3"]) + 1

	# Champion, Continental Qualification, Promotion (Top 3 of Div 2/3) & Relegation (Bottom 3 of Div 1/2)
	var promoted := false
	var relegated := false
	var final_zone: String = get_zone_for_rank(nat_id, div_num, pos, table_size)
	if pos == 1:
		var t_name := "JUARA LIGA ke-%d (%s)" % [div_num, GameData.nations[nat_id]["name"]]
		trophies_won.append(t_name)
		career["trophiesList"].append({"name": t_name, "season": finished_yr, "type": "LIGA"})
		st["trophies"] = int(st["trophies"]) + 1
		career["careerMeta"]["legacyPoints"] = int(career["careerMeta"]["legacyPoints"]) + 40

	# Snapshot all 3 divisions in user's nation before applying 3-up / 3-down swaps
	var t_d1: Array[Dictionary] = old_table if div_num == 1 else get_live_division_table(nat_id, 1)
	var t_d2: Array[Dictionary] = old_table if div_num == 2 else get_live_division_table(nat_id, 2)
	var t_d3: Array[Dictionary] = old_table if div_num == 3 else get_live_division_table(nat_id, 3)

	var d1_drop: Array[int] = []
	var d2_rise: Array[int] = []
	var d2_drop: Array[int] = []
	var d3_rise: Array[int] = []
	for k in range(3):
		if t_d1.size() >= 6 and (t_d1.size() - 1 - k) >= 0:
			d1_drop.append(int(t_d1[t_d1.size() - 1 - k]["club_id"]))
		if t_d2.size() >= 6 and k < t_d2.size():
			d2_rise.append(int(t_d2[k]["club_id"]))
		if t_d2.size() >= 6 and (t_d2.size() - 1 - k) >= 0:
			d2_drop.append(int(t_d2[t_d2.size() - 1 - k]["club_id"]))
		if t_d3.size() >= 6 and k < t_d3.size():
			d3_rise.append(int(t_d3[k]["club_id"]))

	for cid in d1_drop:
		if cid >= 0 and cid < GameData.clubs.size():
			GameData.clubs[cid]["division"] = 2
	for cid in d2_rise:
		if cid >= 0 and cid < GameData.clubs.size():
			GameData.clubs[cid]["division"] = 1
	for cid in d2_drop:
		if cid >= 0 and cid < GameData.clubs.size():
			GameData.clubs[cid]["division"] = 3
	for cid in d3_rise:
		if cid >= 0 and cid < GameData.clubs.size():
			GameData.clubs[cid]["division"] = 2

	if final_zone == "PROMO" and div_num > 1:
		promoted = true
		st["promotions"] = int(st["promotions"]) + 1
		club["division"] = div_num - 1
		career["careerMeta"]["qualifiedComp"] = "NONE"
		_push_news("LIGA", "%s PROMOSI ke Divisi ke-%d!" % [club["name"], div_num - 1])
	elif final_zone == "RELEG" and div_num < 3:
		relegated = true
		club["division"] = div_num + 1
		career["careerMeta"]["qualifiedComp"] = "NONE"
		_push_news("LIGA", "%s DEGRADASI ke Divisi ke-%d!" % [club["name"], div_num + 1])
	elif div_num == 1:
		if final_zone == "ELITE":
			career["careerMeta"]["qualifiedComp"] = "PIALA_ELITE"
			_push_news("LIGA", "%s lolos ke KOMPETISI ELITE musim depan (peringkat ke-%d)!" % [club["name"], pos])
		elif final_zone == "EUROPA":
			career["careerMeta"]["qualifiedComp"] = "PIALA_EUROPA"
			_push_news("LIGA", "%s lolos ke PIALA EUROPA musim depan (peringkat ke-%d)!" % [club["name"], pos])
		elif final_zone == "CHALLENGE":
			career["careerMeta"]["qualifiedComp"] = "PIALA_CONF"
			_push_news("LIGA", "%s lolos ke PIALA CHALLENGE musim depan (peringkat ke-%d)!" % [club["name"], pos])
		else:
			career["careerMeta"]["qualifiedComp"] = "NONE"
	else:
		career["careerMeta"]["qualifiedComp"] = "NONE"
	_world_table_cache.clear()

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

	# Personal Clause evaluation (ANTI_DEGRADASI & JANJI_INTI)
	var clause_id := str(career["contract"].get("clause", "NONE"))
	var season_starts := int(career["careerMeta"].get("seasonStarts", 0))
	var season_matches := int(career["careerMeta"].get("seasonMatches", 0))
	var season_goals := int(career["careerMeta"].get("seasonGoals", 0))
	var season_assists := int(career["careerMeta"].get("seasonAssists", 0))
	var season_motm := int(career["careerMeta"].get("seasonMotm", 0))
	var season_avg := snappedf(float(career["careerMeta"].get("seasonTotalRating", 0.0)) / float(maxi(1, season_matches)), 0.1)
	var clause_freed := false
	var clause_reason := ""
	if clause_id == "ANTI_DEGRADASI" and relegated:
		clause_freed = true
		clause_reason = "KLAUSUL ANTI-DEGRADASI AKTIF: Klub terdegradasi!"
	elif clause_id == "JANJI_INTI" and season_starts < 12 and season_matches < 15:
		clause_freed = true
		clause_reason = "KLAUSUL JANJI INTI AKTIF: Kamu jarang menjadi pemain inti!"

	career["contract"]["goalsScoredThisSeason"] = 0
	if clause_freed:
		career["contract"]["isFreeAgent"] = true
		career["contract"]["clauseTriggered"] = true
		career["contract"]["yearsLeft"] = 0
		_push_news("BURSA", "%s menjadi PEMAIN BEBAS (%s)" % [career["playerProfile"]["name"], clause_reason])
	else:
		career["contract"]["yearsLeft"] = maxi(1, int(career["contract"]["yearsLeft"]) - 1)
		if int(career["contract"]["yearsLeft"]) == 0:
			career["contract"]["isFreeAgent"] = true

	var top_other_champs: Array[Dictionary] = []
	for nat_idx in [16, 0, 2, 4, 3]:
		if nat_idx >= GameData.nations.size():
			continue
		var d_tbl := get_live_division_table(nat_idx, 1)
		if not d_tbl.is_empty():
			top_other_champs.append({
				"nation": str(GameData.nations[nat_idx]["name"]),
				"club_name": str(d_tbl[0].get("name", "JUARA")),
				"pts": int(d_tbl[0].get("pts", 70)),
			})

	var world_best_name := str(GameData.TOP_SEEDED_PLAYERS[finished_yr % GameData.TOP_SEEDED_PLAYERS.size()]["name"])
	var in_best_xi := (season_avg >= 7.1 and season_matches >= 14)

	var recap := {
		"season": finished_yr,
		"calendar_year": int(career["careerMeta"]["seasonCalendarYear"]),
		"club_id": int(club["id"]),
		"club_name": str(club["name"]),
		"club_code": str(club["code"]),
		"division": div_num,
		"league_pos": pos,
		"promoted": promoted,
		"relegated": relegated,
		"matches": season_matches,
		"starts": season_starts,
		"goals": season_goals,
		"assists": season_assists,
		"motm": season_motm,
		"avg_rating": season_avg,
		"shots": int(career["careerMeta"].get("seasonShots", 0)),
		"shots_on_target": int(career["careerMeta"].get("seasonShotsOnTarget", 0)),
		"dribbles_won": int(career["careerMeta"].get("seasonDribblesWon", 0)),
		"clean_sheets": int(career["careerMeta"].get("seasonCleanSheets", 0)),
		"trophies": trophies_won,
		"sponsor_bonus": sp_payout,
		"gala_club_won": (pos <= 4 or season_motm >= 4),
		"gala_liga_won": (season_avg >= 7.2 and season_goals >= 14),
		"world_best": world_best_name,
		"in_best_xi": in_best_xi,
		"clause_freed": clause_freed,
		"clause_reason": clause_reason,
		"is_free_agent": bool(career["contract"].get("isFreeAgent", false)),
		"standings": old_table.slice(0, mini(6, old_table.size())),
		"other_champions": top_other_champs,
		"market_value": int(career["playerProfile"].get("marketValue", 1000000)),
		"cash": int(career["playerProfile"].get("cash", 0)),
	}

	# Reset seasonal counters & advance year/week
	for sk in ["seasonMatches", "seasonStarts", "seasonGoals", "seasonAssists", "seasonMotm", "seasonConceded", "seasonCleanSheets", "seasonShots", "seasonShotsOnTarget", "seasonDribblesWon"]:
		career["careerMeta"][sk] = 0
	career["careerMeta"]["seasonTotalRating"] = 0.0
	career["careerMeta"]["seasonRecordsBroken"] = []
	career["careerMeta"]["timnasCalledWeeks"] = []
	career["careerMeta"]["lastSeasonRecap"] = recap
	career["careerMeta"]["year"] = finished_yr + 1
	career["careerMeta"]["seasonCalendarYear"] = int(career["careerMeta"]["seasonCalendarYear"]) + 1
	career["careerMeta"]["week"] = 1
	career["careerMeta"]["seasonPendingEnd"] = false
	career["careerMeta"]["agentPitchesLeft"] = 3
	career["careerMeta"]["bursaClubDecisions"] = {}
	career["careerMeta"]["agentWatchedClubIds"] = []
	open_transfer_window()
	if bool(career["contract"].get("isFreeAgent", false)):
		career["careerMeta"]["transferWindowWeeksLeft"] = 6
	career["playerProfile"]["age"] = int(career["playerProfile"]["age"]) + 1

	var new_div_clubs := GameData.get_clubs_in_division(int(club["nation_id"]), int(club["division"]))
	career["leagueTable"] = _init_league_table(new_div_clubs)
	ensure_intl_state(true)
	career["schedule"] = _build_season_schedule(new_div_clubs, int(club["id"]), int(club["nation_id"]), int(club["division"]))
	career["seasonHistory"].append({
		"season": career["careerMeta"]["year"],
		"clubId": int(club["id"]),
		"clubCode": club["code"],
		"matches": 0, "goals": 0, "assists": 0, "avgRating": 0.0,
	})
	_update_legacy_tier()
	return recap

func _refresh_transfer_offers() -> void:
	if not career.get("transferOffers", []).is_empty():
		return
	var ovr := int(career["playerProfile"]["ovr"])
	var my_cid := int(career["playerProfile"]["clubId"])
	var is_free := bool(career["contract"].get("isFreeAgent", false))
	var reject_rival := (str(career["contract"].get("clause", "NONE")) == "TOLAK_RIVAL")
	var mv := int(career["playerProfile"].get("marketValue", 1000000))
	var pool: Array[Dictionary] = []
	for c in GameData.clubs:
		var cid := int(c["id"])
		if cid == my_cid:
			continue
		if reject_rival and is_derby_match(my_cid, cid):
			continue
		if abs(int(c["ovr"]) - ovr) <= 12:
			pool.append(c)
	if pool.size() < 5:
		for c in GameData.clubs:
			var cid := int(c["id"])
			if cid == my_cid or (reject_rival and is_derby_match(my_cid, cid)):
				continue
			if not pool.has(c) and abs(int(c["ovr"]) - ovr) <= 20:
				pool.append(c)
			if pool.size() >= 40:
				break
	pool.shuffle()
	# Guarantee clubs that player followed back on SOSMED appear first in next transfer window!
	var followed_cids: Array = career.get("followedBackClubs", [])
	for fcid_v in followed_cids:
		var fcid := int(fcid_v)
		if fcid >= 0 and fcid < GameData.clubs.size() and fcid != my_cid:
			var fc: Dictionary = GameData.clubs[fcid]
			if pool.has(fc):
				pool.erase(fc)
			pool.push_front(fc)
	var offers: Array[Dictionary] = []
	var used_nations: Array[int] = []
	for pass_idx in range(2):
		for c in pool:
			if offers.size() >= 5:
				break
			var cid := int(c["id"])
			var nid := int(c["nation_id"])
			var already := false
			for o in offers:
				if int(o["club_id"]) == cid:
					already = true
					break
			if already or (pass_idx == 0 and used_nations.has(nid)):
				continue
			used_nations.append(nid)
			var covr := int(c["ovr"])
			var tags: Array = ["BEBAS" if is_free else ("PELAPIS" if covr - ovr >= 5 else "INTI")]
			if int(c["division"]) == 1:
				tags.append("LIGA TOP")
			offers.append({
				"club_id": cid,
				"club_name": c["name"],
				"nation": GameData.nations[nid]["name"],
				"nation_id": nid,
				"division": int(c["division"]),
				"ovr": covr,
				"fee": 0 if is_free else int(float(mv) * (0.85 + 0.15 * float(covr % 4))),
				"salary": int(covr * 18 + randi_range(80, 320)),
				"years": randi_range(3, 5),
				"tags": tags,
			})
	career["transferOffers"] = offers

func get_club_taken_numbers(club_id: int) -> Array[int]:
	var sq: Dictionary = _build_club_squad(club_id, "X", "ST", {"shirt_num": 0})
	var nums: Array[int] = []
	for grp in ["starters", "bench"]:
		for pl in sq[grp]:
			if not bool(pl.get("is_user", false)):
				nums.append(int(pl["number"]))
	return nums

func open_transfer_window() -> void:
	career["careerMeta"]["transferWindowWeeksLeft"] = 4
	career["careerMeta"]["transferWindowAnimPending"] = true
	career["transferOffers"] = []
	_refresh_transfer_offers()

func reset_relations_for_new_club() -> void:
	var rel: Dictionary = career["playerProfile"]["relations"]
	var keep: Array = ["agen", "kekasih", "pacar", "pasangan", "partner"]
	for rk in rel.keys():
		if not keep.has(str(rk)):
			rel[rk] = 20

func accept_transfer(offer: Dictionary, chosen_num: int = 9) -> void:
	if not has_active_career:
		return
	var was_free_agent := bool(career["contract"].get("isFreeAgent", false)) or int(offer.get("fee", 1)) == 0
	var new_cid := int(offer["club_id"])
	var new_club := GameData.clubs[new_cid]
	career["playerProfile"]["clubId"] = new_cid
	career["playerProfile"]["appearance"]["shirt_num"] = chosen_num
	career["contract"]["salaryPerMatch"] = int(offer["salary"])
	career["contract"]["yearsLeft"] = int(offer["years"])
	career["contract"]["clubPoints"] = 20
	career["contract"]["clubRequestsLevel"] = 1
	career["contract"]["isFreeAgent"] = false
	career["contract"]["clauseTriggered"] = false
	career["contract"]["clause"] = "NONE"
	reset_relations_for_new_club()
	career["stats"]["transfers"] = int(career["stats"]["transfers"]) + 1
	if was_free_agent:
		career["stats"]["freeTransfers"] = int(career["stats"].get("freeTransfers", 0)) + 1
	career["transferOffers"] = []
	career["careerMeta"]["seasonPendingEnd"] = false
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
		"free_transfers": int(st.get("freeTransfers", 0)),
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

func get_club_league_position(club_id: int) -> int:
	if not has_active_career:
		return 1
	var tbl: Array = career.get("leagueTable", [])
	for i in range(tbl.size()):
		if int(tbl[i].get("club_id", -1)) == club_id:
			return i + 1
	return clampi(1 + (club_id % maxi(1, tbl.size())), 1, maxi(1, tbl.size()))

func get_club_kits(club: Dictionary) -> Array[Dictionary]:
	var pri: Color = club.get("primary", Color("#1A66D2"))
	var sec: Color = club.get("secondary", Color("#F4F8FF"))
	var pat: String = str(club.get("pattern", "stripes"))
	var cid: int = int(club.get("id", 0))

	var home_shorts: Color = sec if pri.get_luminance() < 0.65 else Color("#18202E")
	var kit0 := {
		"name": "KANDANG",
		"primary": pri,
		"secondary": sec,
		"shorts": home_shorts,
		"pattern": pat,
	}

	var is_pri_light: bool = pri.get_luminance() > 0.62
	var away_pri: Color = Color("#182234") if is_pri_light else Color("#ECEFF4")
	var away_sec: Color = pri if not is_pri_light else sec
	var away_shorts: Color = Color("#182234") if not is_pri_light else Color("#E5E9F0")
	var away_pats := ["chest_band", "gradient", "hoops", "sash"]
	var kit1 := {
		"name": "TANDANG",
		"primary": away_pri,
		"secondary": away_sec,
		"shorts": away_shorts,
		"pattern": away_pats[cid % away_pats.size()],
	}

	var third_palettes := [
		[Color("#1D8A6B"), Color("#0F2D27"), Color("#0F2D27"), "chest_band"],
		[Color("#B59738"), Color("#181C26"), Color("#181C26"), "checkered"],
		[Color("#7C2238"), Color("#F2E6D8"), Color("#22141C"), "checkered"],
		[Color("#20345A"), Color("#38BDF8"), Color("#101D34"), "gradient"],
		[Color("#252B36"), Color("#EAB308"), Color("#141820"), "sash"],
		[Color("#246E8C"), Color("#E2F1F8"), Color("#122634"), "hoops"],
	]
	var tp: Array = third_palettes[cid % third_palettes.size()]
	var kit2 := {
		"name": "KETIGA",
		"primary": tp[0],
		"secondary": tp[1],
		"shorts": tp[2],
		"pattern": tp[3],
	}
	return [kit0, kit1, kit2]

func _kit_color_dist(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

func get_selected_match_kit_idx(is_home_side: bool, home_club: Dictionary, away_club: Dictionary) -> int:
	var meta: Dictionary = career.get("careerMeta", {}) if has_active_career else {}
	var wk: int = int(meta.get("week", 1))
	if int(meta.get("kitMatchWeek", -1)) != wk:
		meta["kitMatchWeek"] = wk
		meta["selectedHomeKit"] = 0
		var hk: Array[Dictionary] = get_club_kits(home_club)
		var ak: Array[Dictionary] = get_club_kits(away_club)
		meta["selectedAwayKit"] = 1 if _kit_color_dist(hk[0]["primary"], ak[0]["primary"]) < 0.72 else 0
	return clampi(int(meta.get("selectedHomeKit" if is_home_side else "selectedAwayKit", 0)), 0, 2)

func set_selected_match_kit(is_home_side: bool, kit_idx: int) -> void:
	if not has_active_career:
		return
	var meta: Dictionary = career["careerMeta"]
	meta["kitMatchWeek"] = int(meta.get("week", 1))
	meta["selectedHomeKit" if is_home_side else "selectedAwayKit"] = clampi(kit_idx, 0, 2)

func get_selected_match_kit(is_home_side: bool, home_club: Dictionary, away_club: Dictionary) -> Dictionary:
	var club: Dictionary = home_club if is_home_side else away_club
	var kits: Array[Dictionary] = get_club_kits(club)
	var idx: int = get_selected_match_kit_idx(is_home_side, home_club, away_club)
	return kits[idx]

func ensure_berita_data() -> void:
	if not has_active_career:
		return
	if not career.has("followedBackClubs") or typeof(career["followedBackClubs"]) != TYPE_ARRAY:
		career["followedBackClubs"] = []
	if not career.has("watchingClubIds") or typeof(career["watchingClubIds"]) != TYPE_ARRAY:
		career["watchingClubIds"] = []
	if not career.has("socialFeed") or typeof(career["socialFeed"]) != TYPE_ARRAY:
		career["socialFeed"] = []
	if not career.has("inboxMessages") or typeof(career["inboxMessages"]) != TYPE_ARRAY:
		career["inboxMessages"] = []

	var p: Dictionary = career["playerProfile"]
	var uname: String = str(p.get("name", "ALFIAN"))
	var wk: int = int(career["careerMeta"].get("week", 1))
	var ovr: int = int(p.get("ovr", 62))
	var my_cid: int = int(p.get("clubId", 0))

	if (career["watchingClubIds"] as Array).is_empty():
		var wids: Array = []
		for c in GameData.clubs:
			var cid: int = int(c["id"])
			if cid != my_cid and abs(int(c["ovr"]) - ovr) <= 10:
				wids.append(cid)
				if wids.size() >= 4:
					break
		if wids.is_empty() and GameData.clubs.size() > 1:
			wids.append((my_cid + 1) % GameData.clubs.size())
		career["watchingClubIds"] = wids

	var sfeed: Array = career["socialFeed"]
	if sfeed.is_empty():
		var wids: Array = career["watchingClubIds"]
		var follow_cid: int = int(wids[0]) if not wids.is_empty() else ((my_cid + 1) % maxi(1, GameData.clubs.size()))
		var fclub: Dictionary = GameData.clubs[clampi(follow_cid, 0, GameData.clubs.size() - 1)]
		var fhandle := "@" + str(fclub["name"]).to_upper().replace(" ", "_")
		var payout := maxi(6500, ovr * 380 + int(career["stats"].get("followers", 1000)) / 8)
		sfeed.append({
			"id": "cf_init_%d" % follow_cid,
			"kind": "CLUB_FOLLOW",
			"category": "LAWAN",
			"author": str(fclub["name"]).to_upper(),
			"handle": fhandle,
			"club_id": follow_cid,
			"text": "mulai mengikutimu",
			"likes": 0,
			"week": wk,
			"handled": false,
			"followed_back": false,
		})
		sfeed.append({
			"id": "ad_init_%d" % wk,
			"kind": "BRAND_AD",
			"category": "MEREK",
			"brand": "VOLT COLA",
			"handle": "@VOLTCOLA",
			"author": "VOLT COLA",
			"text": "\"Fotomu dengan produk kami setelah latihan. Itu saja.\"",
			"payout": payout,
			"likes": 22100,
			"week": wk,
			"posted": false,
		})
		var tm_name: String = str(_pick_non_user_starter().get("name", "Wallin"))
		sfeed.append({
			"id": "tm_init_%d" % wk,
			"kind": "TEAMMATE",
			"category": "RUANG GANTI",
			"author": "RUANG GANTI",
			"handle": "@%s" % str(tm_name).to_upper().replace(" ", ""),
			"text": "Terima kasih %s atas umpan hari ini." % uname.capitalize(),
			"likes": 1240 + int(career["stats"].get("followers", 1000)) / 5,
			"week": wk,
			"liked": false,
		})
		if wids.size() > 1:
			var sc2: Dictionary = GameData.clubs[int(wids[1])]
			sfeed.append({
				"id": "cf_sec_%d" % int(wids[1]),
				"kind": "CLUB_FOLLOW",
				"category": "LAWAN",
				"author": str(sc2["name"]).to_upper(),
				"handle": "@" + str(sc2["name"]).to_upper().replace(" ", "_"),
				"club_id": int(wids[1]),
				"text": "mulai mengikutimu",
				"likes": 0,
				"week": maxi(1, wk - 1),
				"handled": false,
				"followed_back": false,
			})
		career["socialFeed"] = sfeed

	var inbox: Array = career["inboxMessages"]
	if inbox.is_empty():
		var tm: Dictionary = _pick_non_user_starter()
		inbox.append({
			"id": "msg_tm_init_%d" % wk,
			"sender_type": "TEAMMATE",
			"sender_name": str(tm.get("name", "Wallin")),
			"sender_ovr": int(tm.get("ovr", 61)),
			"sender_pos": str(tm.get("pos", "ST")),
			"preview": "Umpan mantap, bro!",
			"body": "Umpan mantap, bro! Gol itu separuh milikmu.",
			"context_tag": "ASISTMU • P%d 3 - 2" % maxi(1, wk - 1),
			"replied": false,
			"reply_text": "",
			"expires_in": 2,
			"week": wk,
			"replies": [
				{"text": "Berikutnya giliranku kasih umpan.", "rg": 3, "pelatih": 1, "fans": 0, "fol": 200},
				{"text": "Kerja tim yang hebat, bro!", "rg": 4, "pelatih": 0, "fans": 1, "fol": 350},
				{"text": "Yang penting kita bawa pulang 3 poin.", "rg": 2, "pelatih": 2, "fans": 1, "fol": 250},
			],
		})
		inbox.append({
			"id": "msg_fan_init_%d" % wk,
			"sender_type": "SUPPORTER",
			"sender_name": "Raka_Ultras",
			"sender_ovr": 0,
			"sender_pos": "FAN",
			"preview": "Aksimu di lapangan gila banget, kak!",
			"body": "Halo %s! Satu tribun bersorak lihat aksimu pekan kemarin. Boleh kasih semangat buat kami suporter di stadion nanti?" % uname.capitalize(),
			"context_tag": "SUPORTER • TRIBUN UTARA",
			"replied": false,
			"reply_text": "",
			"expires_in": 3,
			"week": wk,
			"replies": [
				{"text": "Terima kasih dukungannya! Aku beri 100% di laga berikutnya!", "rg": 0, "pelatih": 0, "fans": 4, "fol": 1500},
				{"text": "Sampai jumpa di tribun! Terus bernyanyi untuk tim kita!", "rg": 1, "pelatih": 0, "fans": 3, "fol": 1100},
				{"text": "Aku fokus latihan keras biar kita bisa juara musim ini.", "rg": 0, "pelatih": 2, "fans": 2, "fol": 700},
			],
		})
		career["inboxMessages"] = inbox

func _pick_non_user_starter(preferred_name: String = "") -> Dictionary:
	var starters: Array = career.get("clubSquad", {}).get("starters", [])
	if not preferred_name.is_empty():
		var pref_up := preferred_name.to_upper()
		for s in starters:
			if not bool(s.get("is_user", false)) and str(s.get("name", "")).to_upper() == pref_up:
				return s
	for s in starters:
		if not bool(s.get("is_user", false)) and str(s.get("pos", "")) != "GK":
			return s
	return {"name": "Wallin", "ovr": 62, "pos": "ST"}

func generate_post_match_social_and_messages(fix: Dictionary, us: int, them: int, my_g: int, my_a: int, rating: float, goal_timeline: Array) -> void:
	ensure_berita_data()
	var p: Dictionary = career["playerProfile"]
	var uname: String = str(p.get("name", "ALFIAN"))
	var wk: int = int(career["careerMeta"].get("week", 1))
	var ovr: int = int(p.get("ovr", 62))
	var my_cid: int = int(p.get("clubId", 0))
	var inbox: Array = career["inboxMessages"]
	var sfeed: Array = career["socialFeed"]

	# 1. Teammate Assist Message + Social Shoutout whenever user gave an assist!
	if my_a > 0:
		var assisted_nm := ""
		for g_ev in goal_timeline:
			if bool(g_ev.get("is_us", false)) and str(g_ev.get("assist", "")).to_upper() == uname.to_upper():
				assisted_nm = str(g_ev.get("scorer", ""))
				break
		var tm: Dictionary = _pick_non_user_starter(assisted_nm)
		var tm_name := str(tm.get("name", "Rekan"))
		inbox.push_front({
			"id": "msg_ast_%d_%d" % [wk, inbox.size()],
			"sender_type": "TEAMMATE",
			"sender_name": tm_name,
			"sender_ovr": int(tm.get("ovr", 62)),
			"sender_pos": str(tm.get("pos", "ST")),
			"preview": "Umpan mantap, bro!",
			"body": "Umpan mantap, bro! Gol ke gawang %s itu separuh milikmu." % str(fix.get("opp_name", "lawan")),
			"context_tag": "ASISTMU • P%d %d - %d" % [wk, us, them],
			"replied": false,
			"reply_text": "",
			"expires_in": 2,
			"week": wk,
			"replies": [
				{"text": "Berikutnya giliranku kasih umpan lagi.", "rg": 3, "pelatih": 1, "fans": 0, "fol": 250},
				{"text": "Finishing kamu yang kelas dunia, bro!", "rg": 4, "pelatih": 0, "fans": 1, "fol": 400},
				{"text": "Fokus ke laga berikutnya, jaga momentum!", "rg": 2, "pelatih": 2, "fans": 1, "fol": 200},
			],
		})
		sfeed.push_front({
			"id": "soc_ast_%d_%d" % [wk, sfeed.size()],
			"kind": "TEAMMATE",
			"category": "RUANG GANTI",
			"author": "RUANG GANTI",
			"handle": "@%s" % tm_name.to_upper().replace(" ", ""),
			"text": "Terima kasih %s atas umpan hari ini." % uname.capitalize(),
			"likes": 1800 + int(career["stats"].get("followers", 1000)) / 4,
			"week": wk,
			"liked": false,
		})

	# 2. Supporter Fan Message after goals/wins/strong rating!
	if my_g > 0 or us > them or rating >= 7.0:
		var fan_names := ["Dinda_Curva", "Raka_Ultras", "Bima_Tribun", "Salsa_1928", "Fajar_Suporter", "Nadia_FanClub"]
		var fn: String = fan_names[(wk + my_g) % fan_names.size()]
		var fan_body: String = (
			"Golmu melawan %s bikin satu stadion bergetar, kak %s! Kami semua bangga banget!" % [str(fix.get("opp_name", "lawan")), uname.capitalize()]
			if my_g > 0 else
			"Permainanmu hari ini luar biasa %s! Tetap jaga semangat buat bawa pulang trofi musim ini!" % uname.capitalize()
		)
		inbox.push_front({
			"id": "msg_fan_%d_%d" % [wk, inbox.size()],
			"sender_type": "SUPPORTER",
			"sender_name": fn,
			"sender_ovr": 0,
			"sender_pos": "FAN",
			"preview": "Keren banget aksimu hari ini!",
			"body": fan_body,
			"context_tag": "SUPORTER • P%d %d - %d" % [wk, us, them],
			"replied": false,
			"reply_text": "",
			"expires_in": 3,
			"week": wk,
			"replies": [
				{"text": "Terima kasih banyak! Dukungan kalian tenaga utama kami!", "rg": 0, "pelatih": 0, "fans": 4, "fol": 1600},
				{"text": "Gol dan kemenangan ini khusus buat kalian di tribun!", "rg": 1, "pelatih": 0, "fans": 3, "fol": 1200},
				{"text": "Belum puas! Kami akan kerja lebih keras lagi pekan depan.", "rg": 0, "pelatih": 2, "fans": 2, "fol": 800},
			],
		})

	# 3. External Club Starts Following Player on SOSMED (Gambar 6!)
	if rating >= 7.0 or my_g >= 1 or (wk % 3 == 0):
		var picked_cid := -1
		var watching: Array = career["watchingClubIds"]
		for c in GameData.clubs:
			var cid := int(c["id"])
			if cid != my_cid and not watching.has(cid) and abs(int(c["ovr"]) - ovr) <= 12:
				picked_cid = cid
				break
		if picked_cid >= 0:
			watching.push_front(picked_cid)
			if watching.size() > 6:
				watching.resize(6)
			career["watchingClubIds"] = watching
			var fclub: Dictionary = GameData.clubs[picked_cid]
			sfeed.push_front({
				"id": "cf_%d_%d" % [wk, picked_cid],
				"kind": "CLUB_FOLLOW",
				"category": "LAWAN",
				"author": str(fclub["name"]).to_upper(),
				"handle": "@" + str(fclub["name"]).to_upper().replace(" ", "_"),
				"club_id": picked_cid,
				"text": "mulai mengikutimu",
				"likes": 0,
				"week": wk,
				"handled": false,
				"followed_back": false,
			})

	# 4. Periodic Brand #IKLAN sponsorship post (Gambar 5!)
	if wk % 4 == 0:
		var brands := [
			["VOLT COLA", "@VOLTCOLA", "\"Fotomu dengan produk kami setelah latihan. Itu saja.\""],
			["TURBO KICK", "@TURBOKICK", "\"Pamerkan sepatu barumu di lapangan latihan.\""],
			["HYDRA PRO", "@HYDRAPRO", "\"Satu unggahan botol minuman elektrolit usai laga.\""],
		]
		var br: Array = brands[(wk / 4) % brands.size()]
		var payout := maxi(7500, ovr * 420 + int(career["stats"].get("followers", 1000)) / 7)
		sfeed.push_front({
			"id": "ad_%d" % wk,
			"kind": "BRAND_AD",
			"category": "MEREK",
			"brand": br[0],
			"handle": br[1],
			"author": br[0],
			"text": br[2],
			"payout": payout,
			"likes": 15000 + ovr * 120,
			"week": wk,
			"posted": false,
		})

	while inbox.size() > 14:
		inbox.pop_back()
	while sfeed.size() > 24:
		sfeed.pop_back()
	career["inboxMessages"] = inbox
	career["socialFeed"] = sfeed

func reply_inbox_message(msg_id: String, reply_idx: int) -> Dictionary:
	if not has_active_career:
		return {}
	ensure_berita_data()
	var inbox: Array = career["inboxMessages"]
	for m in inbox:
		if str(m.get("id", "")) == msg_id:
			if bool(m.get("replied", false)):
				return m
			var reps: Array = m.get("replies", [])
			if reply_idx < 0 or reply_idx >= reps.size():
				return m
			var chosen: Dictionary = reps[reply_idx]
			m["replied"] = true
			m["reply_text"] = str(chosen.get("text", "Terima kasih!"))
			var rel: Dictionary = career["playerProfile"]["relations"]
			rel["ruangGanti"] = clampi(int(rel["ruangGanti"]) + int(chosen.get("rg", 0)), 0, 100)
			rel["pelatih"] = clampi(int(rel["pelatih"]) + int(chosen.get("pelatih", 0)), 0, 100)
			rel["fans"] = clampi(int(rel["fans"]) + int(chosen.get("fans", 0)), 0, 100)
			career["stats"]["followers"] = int(career["stats"]["followers"]) + int(chosen.get("fol", 0))
			save_active_career()
			career_updated.emit()
			return m
	return {}

func follow_back_club_social(post_id: String) -> bool:
	if not has_active_career:
		return false
	ensure_berita_data()
	var sfeed: Array = career["socialFeed"]
	for post in sfeed:
		if str(post.get("id", "")) == post_id and not bool(post.get("handled", false)):
			post["handled"] = true
			post["followed_back"] = true
			var cid := int(post.get("club_id", -1))
			var followed: Array = career["followedBackClubs"]
			if cid >= 0 and not followed.has(cid):
				followed.append(cid)
				career["followedBackClubs"] = followed
			# Transparent relation cost shown on Gambar 6 (-6 Pelatih, -4 Ruang Ganti, -5 Fans)
			var rel: Dictionary = career["playerProfile"]["relations"]
			rel["pelatih"] = clampi(int(rel["pelatih"]) - 6, 0, 100)
			rel["ruangGanti"] = clampi(int(rel["ruangGanti"]) - 4, 0, 100)
			rel["fans"] = clampi(int(rel["fans"]) - 5, 0, 100)
			_push_news("KLUB", "RUMOR TRANSFER! %s mengikuti balik akun resmi %s di media sosial." % [career["playerProfile"]["name"], str(post.get("author", "klub"))])
			save_active_career()
			career_updated.emit()
			return true
	return false

func ignore_club_social(post_id: String) -> bool:
	if not has_active_career:
		return false
	ensure_berita_data()
	for post in career["socialFeed"]:
		if str(post.get("id", "")) == post_id and not bool(post.get("handled", false)):
			post["handled"] = true
			post["followed_back"] = false
			save_active_career()
			career_updated.emit()
			return true
	return false

func accept_brand_ad_social(post_id: String) -> bool:
	if not has_active_career:
		return false
	ensure_berita_data()
	var sfeed: Array = career["socialFeed"]
	for post in sfeed:
		if str(post.get("id", "")) == post_id and not bool(post.get("posted", false)):
			post["posted"] = true
			var pay := int(post.get("payout", 10000))
			career["playerProfile"]["cash"] = int(career["playerProfile"]["cash"]) + pay
			career["stats"]["followers"] = int(career["stats"]["followers"]) + 1800
			var uname := str(career["playerProfile"].get("name", "ALFIAN"))
			sfeed.push_front({
				"id": "usr_ad_%d" % sfeed.size(),
				"kind": "PLAYER",
				"category": "KAU",
				"author": uname.to_upper(),
				"handle": "@%s" % uname.to_upper().replace(" ", ""),
				"text": "Yang terbaik setelah latihan. %s" % str(post.get("handle", "@SPONSOR")).to_lower(),
				"likes": 12000 + int(career["stats"].get("followers", 1000)) / 3,
				"week": int(career["careerMeta"].get("week", 1)),
			})
			save_active_career()
			career_updated.emit()
			return true
	return false

func get_unread_berita_counts() -> Dictionary:
	if not has_active_career:
		return {"sosmed": 0, "pesan": 0, "total": 0}
	ensure_berita_data()
	var s_cnt := 0
	for post in career.get("socialFeed", []):
		if str(post.get("kind", "")) == "CLUB_FOLLOW" and not bool(post.get("handled", false)):
			s_cnt += 1
		elif str(post.get("kind", "")) == "BRAND_AD" and not bool(post.get("posted", false)):
			s_cnt += 1
	var p_cnt := 0
	for msg in career.get("inboxMessages", []):
		if not bool(msg.get("replied", false)):
			p_cnt += 1
	return {"sosmed": s_cnt, "pesan": p_cnt, "total": s_cnt + p_cnt}

# ==============================================================================
# WARISAN (LEGACY) ANALYTICS, TELEMETRY MAPS & DECORATED CLUBS RANKING
# ==============================================================================
func get_warisan_karier_summary() -> Dictionary:
	if not has_active_career:
		return {}
	ensure_career_fields()
	var m: Dictionary = career["careerMeta"]
	var p: Dictionary = career["playerProfile"]
	var st: Dictionary = career["stats"]
	var club: Dictionary = get_current_club()
	var yr: int = maxi(1, int(m.get("year", 1)))

	var c_matches: int = int(st.get("matches", 0))
	var c_wins: int = int(st.get("wins", 0))
	var c_draws: int = int(st.get("draws", 0))
	var c_losses: int = int(st.get("losses", 0))
	var c_goals: int = int(st.get("goals", 0))
	var c_assists: int = int(st.get("assists", 0))
	var c_avg_r: float = snappedf(float(st.get("totalRating", 0.0)) / maxf(1.0, float(c_matches)), 0.1) if c_matches > 0 else 0.0
	var c_best_r: float = snappedf(float(st.get("bestRating", 0.0)), 0.1)

	var s_matches: int = int(m.get("seasonMatches", 0))
	var s_goals: int = int(m.get("seasonGoals", 0))
	var s_assists: int = int(m.get("seasonAssists", 0))
	var s_avg_r: float = snappedf(float(m.get("seasonTotalRating", 0.0)) / maxf(1.0, float(s_matches)), 0.1) if s_matches > 0 else c_avg_r
	if s_matches == 0 and c_matches > 0:
		s_matches = c_matches
		s_goals = c_goals
		s_assists = c_assists

	var g_per_m: float = snappedf(float(c_goals) / maxf(1.0, float(c_matches)), 0.01) if c_matches > 0 else 0.0
	var sg_per_m: float = snappedf(float(s_goals) / maxf(1.0, float(s_matches)), 0.01) if s_matches > 0 else 0.0
	var a_per_m: float = snappedf(float(c_assists) / maxf(1.0, float(c_matches)), 0.01) if c_matches > 0 else 0.0
	var sa_per_m: float = snappedf(float(s_assists) / maxf(1.0, float(s_matches)), 0.01) if s_matches > 0 else 0.0
	var win_pct: int = int(round(float(c_wins) * 100.0 / maxf(1.0, float(c_matches)))) if c_matches > 0 else 0

	# Accuracy percentages (combining recorded shots/seasonShots cleanly)
	var tot_shots: int = maxi(int(m.get("seasonShots", 0)), c_goals * 2 + (3 if c_matches > 0 else 0))
	var on_t_shots: int = maxi(int(m.get("seasonShotsOnTarget", 0)), int(round(float(tot_shots) * 0.78)))
	if tot_shots == 0:
		tot_shots = 0
		on_t_shots = 0
	var ke_gawang_pct: int = clampi(int(round(float(on_t_shots) * 100.0 / maxf(1.0, float(tot_shots)))), 0, 100) if tot_shots > 0 else 0
	var konversi_pct: int = clampi(int(round(float(c_goals) * 100.0 / maxf(1.0, float(tot_shots)))), 0, 100) if tot_shots > 0 else 0
	var passes_won: int = int(st.get("passesWon", 0))
	var umpan_tembak_pct: int = clampi(82 + mini(16, passes_won % 17), 55, 98) if (passes_won > 0 or c_matches > 0) else 0
	var s_ke_gawang_pct: int = clampi(ke_gawang_pct + (5 if s_goals > 0 else 0), 0, 100) if s_matches > 0 else 0
	var s_konversi_pct: int = clampi(konversi_pct + (6 if s_goals > 0 else 0), 0, 100) if s_matches > 0 else 0
	var s_umpan_tembak_pct: int = clampi(umpan_tembak_pct + 4, 0, 100) if s_matches > 0 else 0

	# Legacy tier & points to next tier
	var pts: int = int(m.get("legacyPoints", 0))
	var tier: String = str(m.get("legacyTier", "PROSPEK"))
	var next_tier: String = "PROFESIONAL"
	var tier_floor: int = 0
	var tier_ceil: int = 100
	if pts >= 650:
		next_tier = "LEGENDA"
		tier_floor = 650
		tier_ceil = 1000
	elif pts >= 300:
		next_tier = "BINTANG DUNIA"
		tier_floor = 300
		tier_ceil = 650
	elif pts >= 100:
		next_tier = "ANDALAN"
		tier_floor = 100
		tier_ceil = 300
	var pts_to_next: int = maxi(0, tier_ceil - pts)
	var tier_prog: float = clampf(float(pts - tier_floor) / maxf(1.0, float(tier_ceil - tier_floor)), 0.0, 1.0)

	# Hall of Fame Top 30 Rank
	var u_trophies: int = int(st.get("trophies", 0))
	var legend_rank: int = 0
	var leg_totals: Array[int] = []
	for lg in GameData.world_legends:
		leg_totals.append(int(lg.get("indiv", 0)) + int(lg.get("team", 0)))
	leg_totals.sort()
	leg_totals.reverse()
	for li in range(mini(30, leg_totals.size())):
		if u_trophies >= leg_totals[li] and u_trophies > 0:
			legend_rank = li + 1
			break

	# Season rows & Best Season
	var sh_list: Array = career.get("seasonHistory", [])
	var season_rows: Array[Dictionary] = []
	var best_season: int = yr
	var best_score: float = -1.0
	if sh_list.is_empty():
		season_rows.append({
			"season": yr,
			"club_id": int(club["id"]),
			"club_name": str(club["name"]),
			"club_code": str(club["code"]),
			"matches": s_matches,
			"goals": s_goals,
			"assists": s_assists,
			"avg_rating": s_avg_r,
			"has_star": s_avg_r >= 7.5 or int(st.get("motm", 0)) > 0,
			"has_trophy": u_trophies > 0,
			"is_current": true,
		})
	else:
		for si in range(sh_list.size() - 1, -1, -1):
			var sh: Dictionary = sh_list[si]
			var s_num: int = int(sh.get("season", 1))
			var cid: int = clampi(int(sh.get("clubId", int(club["id"]))), 0, GameData.clubs.size() - 1)
			var sc_d: Dictionary = GameData.clubs[cid]
			var mn: int = int(sh.get("matches", 0))
			var g_v: int = int(sh.get("goals", 0))
			var a_v: int = int(sh.get("assists", 0))
			var rt_v: float = float(sh.get("avgRating", 0.0))
			if si == sh_list.size() - 1 and mn == 0 and s_matches > 0:
				mn = s_matches
				g_v = s_goals
				a_v = s_assists
				rt_v = s_avg_r
			var sc_val: float = rt_v * 10.0 + float(g_v) * 1.5 + float(a_v)
			if sc_val > best_score:
				best_score = sc_val
				best_season = s_num
			var has_tr: bool = false
			for tr_i in career.get("trophiesList", []):
				if int(tr_i.get("season", 0)) == s_num:
					has_tr = true
					break
			season_rows.append({
				"season": s_num,
				"club_id": cid,
				"club_name": str(sc_d.get("name", str(sh.get("clubCode", "Klub")))),
				"club_code": str(sh.get("clubCode", sc_d.get("code", "CLB"))),
				"matches": mn,
				"goals": g_v,
				"assists": a_v,
				"avg_rating": snappedf(rt_v, 0.1),
				"has_star": rt_v >= 7.5 or (si == sh_list.size() - 1 and int(st.get("motm", 0)) > 0),
				"has_trophy": has_tr,
				"is_current": (si == sh_list.size() - 1),
			})

	# Competition breakdown (LIGA, PIALA ELITE, KONTINENTAL, KUALIFIKASI)
	var cstats: Dictionary = career.get("compStats", {})
	var comp_rows: Array[Dictionary] = []
	var has_recorded_comp: bool = not cstats.is_empty()
	if has_recorded_comp:
		for cd in [
			["LIGA", "LIGA"],
			["PIALA_ELITE", "PIALA ELITE"],
			["KONTINENTAL", "KONTINENTAL"],
			["KUALIFIKASI", "KUALIFIKASI"],
		]:
			var ck: String = str(cd[0])
			var d: Dictionary = cstats.get(ck, {})
			comp_rows.append({
				"label": str(cd[1]),
				"season_g": int(d.get("season_g", 0)),
				"season_a": int(d.get("season_a", 0)),
				"career_g": int(d.get("career_g", 0)),
				"career_a": int(d.get("career_a", 0)),
			})
	else:
		# Graceful breakdown for existing saves prior to compStats tracking
		var intl_g: int = int(st.get("intlGoals", 0))
		var liga_g: int = maxi(0, c_goals - intl_g)
		var s_liga_g: int = maxi(0, s_goals - intl_g)
		comp_rows = [
			{"label": "LIGA", "season_g": s_liga_g, "season_a": s_assists, "career_g": liga_g, "career_a": c_assists},
			{"label": "PIALA ELITE", "season_g": 0, "season_a": 0, "career_g": 0, "career_a": 0},
			{"label": "KONTINENTAL", "season_g": 0, "season_a": 0, "career_g": 0, "career_a": 0},
			{"label": "KUALIFIKASI", "season_g": intl_g, "season_a": 0, "career_g": intl_g, "career_a": 0},
		]

	# Longest goal, longest pass & favorite victim club
	var long_g: float = float(st.get("longestGoalMeters", 0.0))
	if long_g <= 0.1 and c_goals > 0:
		long_g = snappedf(18.4 + float((c_goals * 7 + int(p.get("ovr", 60))) % 22) + 0.2, 0.1)
	var long_p: float = float(st.get("longestPassMeters", 0.0))
	if long_p <= 0.1 and (c_assists > 0 or passes_won > 0 or c_matches > 0):
		long_p = snappedf(26.0 + float((c_matches * 5 + int(p.get("ovr", 60))) % 24) + 0.5, 0.1)

	var victim: Dictionary = {"club_id": (int(club["id"]) + 1) % GameData.clubs.size(), "code": "---", "name": "Belum Ada", "goals": 0}
	var vmap: Dictionary = career.get("victimGoals", {})
	for vk in vmap.keys():
		var vd: Dictionary = vmap[vk]
		if int(vd.get("goals", 0)) > int(victim["goals"]):
			victim = vd
	if int(victim["goals"]) == 0 and c_goals > 0:
		# Pick a played opponent from schedule as top victim fallback
		var best_fx_g: int = 0
		for fx in career.get("schedule", []):
			if bool(fx.get("played", false)) and int(fx.get("score_us", 0)) > best_fx_g:
				best_fx_g = int(fx.get("score_us", 0))
				victim = {
					"club_id": int(fx.get("opp_club_id", 0)),
					"code": str(fx.get("opp_code", "LWN")).left(3).to_upper(),
					"name": str(fx.get("opp_name", "Lawan")),
					"goals": maxi(1, mini(c_goals, best_fx_g)),
				}
		if int(victim["goals"]) == 0:
			var fc_id: int = (int(club["id"]) + 2) % GameData.clubs.size()
			var fc_d: Dictionary = GameData.clubs[fc_id]
			victim = {"club_id": fc_id, "code": str(fc_d["code"]).left(3).to_upper(), "name": str(fc_d["name"]), "goals": mini(c_goals, maxi(1, int(c_goals / 4)))}

	# Journey club history
	var journey_clubs: Array[Dictionary] = []
	var seen_cids: Dictionary = {}
	for sr in season_rows:
		var cid: int = int(sr["club_id"])
		if not seen_cids.has(cid):
			seen_cids[cid] = true
			journey_clubs.append({
				"club_id": cid,
				"code": str(sr["club_code"]),
				"name": str(sr["club_name"]),
				"season_span": "M%d" % int(sr["season"]),
				"matches": int(sr["matches"]),
				"goals": int(sr["goals"]),
				"assists": int(sr["assists"]),
			})

	return {
		"year": yr,
		"goals": c_goals,
		"assists": c_assists,
		"matches": c_matches,
		"wins": c_wins,
		"draws": c_draws,
		"losses": c_losses,
		"win_pct": win_pct,
		"g_per_m": g_per_m,
		"sg_per_m": sg_per_m,
		"a_per_m": a_per_m,
		"sa_per_m": sa_per_m,
		"avg_rating": c_avg_r,
		"season_avg_rating": s_avg_r,
		"best_rating": c_best_r,
		"ke_gawang_pct": ke_gawang_pct,
		"konversi_pct": konversi_pct,
		"umpan_tembak_pct": umpan_tembak_pct,
		"s_ke_gawang_pct": s_ke_gawang_pct,
		"s_konversi_pct": s_konversi_pct,
		"s_umpan_tembak_pct": s_umpan_tembak_pct,
		"total_shots": tot_shots,
		"best_season": best_season,
		"legacy_points": pts,
		"legacy_tier": tier,
		"next_tier": next_tier,
		"pts_to_next": pts_to_next,
		"tier_prog": tier_prog,
		"trophies": u_trophies,
		"legend_rank": legend_rank,
		"season_rows": season_rows,
		"comp_rows": comp_rows,
		"longest_goal_m": long_g,
		"longest_goal_club": str(st.get("longestGoalClub", "")) if str(st.get("longestGoalClub", "")) != "" else str(club["name"]),
		"longest_goal_season": int(st.get("longestGoalSeason", yr)),
		"longest_pass_m": long_p,
		"longest_pass_club": str(st.get("longestPassClub", "")) if str(st.get("longestPassClub", "")) != "" else str(club["name"]),
		"longest_pass_season": int(st.get("longestPassSeason", yr)),
		"victim": victim,
		"market_value": int(p.get("marketValue", 1000000)),
		"journey_clubs": journey_clubs,
		"other_journey_count": maxi(0, journey_clubs.size() - 1),
	}

func get_peta_season_data(mode: String, season_num: int) -> Dictionary:
	if not has_active_career:
		return {}
	var sum: Dictionary = get_warisan_karier_summary()
	var max_yr: int = maxi(1, int(sum.get("year", 1)))
	var sel_yr: int = clampi(season_num, 1, max_yr)
	var shots_all: Array = career.get("shotTelemetry", [])
	var st: Dictionary = career.get("stats", {})
	var club: Dictionary = get_current_club()

	var season_pts: Array[Dictionary] = []
	var career_count: int = 0
	var career_goals_or_ast: int = 0
	var career_on_t: int = 0

	for raw_s in shots_all:
		var s: Dictionary = raw_s
		var t: String = str(s.get("type", "OPEN_PLAY"))
		var is_mode: bool = (mode == "UMPAN" and t == "PASS") or (mode == "DRIBEL" and t == "DRIBBLE") or (mode == "SHOT" and t != "PASS" and t != "DRIBBLE")
		if not is_mode:
			continue
		career_count += 1
		var out_s: String = str(s.get("outcome", "ON_TARGET"))
		if out_s == "GOAL" or out_s == "ASSIST":
			career_goals_or_ast += 1
			career_on_t += 1
		elif out_s == "ON_TARGET" or out_s == "SHOT":
			career_on_t += 1
		if int(s.get("season", 1)) == sel_yr:
			season_pts.append(s)

	# When matches were quick-simmed or early save has few telemetry rows, generate deterministic matched points from real season stats
	var rng := RandomNumberGenerator.new()
	rng.seed = sel_yr * 4391 + int(club["id"]) * 137 + mode.hash() % 997
	var s_row: Dictionary = {}
	for sr in sum.get("season_rows", []):
		if int(sr["season"]) == sel_yr:
			s_row = sr
			break
	var s_m: int = int(s_row.get("matches", int(sum.get("matches", 0))))
	var s_g: int = int(s_row.get("goals", int(sum.get("goals", 0))))
	var s_a: int = int(s_row.get("assists", int(sum.get("assists", 0))))

	if mode == "SHOT":
		if season_pts.is_empty() and (s_m > 0 or s_g > 0):
			var sample_n: int = clampi(maxi(s_g + 4, s_m * 2), 6, 36)
			var g_rem: int = mini(sample_n, maxi(1, s_g))
			for i in range(sample_n):
				var out_c: String = "GOAL" if i < g_rem else ("ON_TARGET" if i < int(float(sample_n) * 0.80) else "WIDE")
				season_pts.append({
					"season": sel_yr,
					"type": "FREEKICK" if i % 9 == 0 else "OPEN_PLAY",
					"outcome": out_c,
					"pitchCoord": {"x": clampf(rng.randf_range(0.16, 0.84), 0.12, 0.88), "y": clampf(rng.randf_range(0.46, 0.90), 0.35, 0.94)},
					"goalCoord": {"x": rng.randf_range(0.12, 0.88), "y": rng.randf_range(0.14, 0.86)},
					"distanceMeters": snappedf(rng.randf_range(9.5, 34.0), 0.1),
				})
		var s_tot: int = season_pts.size()
		var s_on: int = 0
		var s_gl: int = 0
		var s_wide: int = 0
		var s_max_d: float = 0.0
		for pt in season_pts:
			var o: String = str(pt.get("outcome", "ON_TARGET"))
			if o == "GOAL":
				s_gl += 1
				s_on += 1
				s_max_d = maxf(s_max_d, float(pt.get("distanceMeters", 16.0)))
			elif o == "ON_TARGET":
				s_on += 1
			else:
				s_wide += 1
		var c_tot_eff: int = maxi(career_count, maxi(s_tot, int(sum.get("total_shots", s_tot))))
		return {
			"mode": "SHOT",
			"season": sel_yr,
			"max_season": max_yr,
			"points": season_pts,
			"season_total": s_tot,
			"season_on_pct": int(round(float(s_on) * 100.0 / maxf(1.0, float(s_tot)))) if s_tot > 0 else 0,
			"season_wide_pct": int(round(float(s_wide) * 100.0 / maxf(1.0, float(s_tot)))) if s_tot > 0 else 0,
			"season_goal_pct": int(round(float(s_gl) * 100.0 / maxf(1.0, float(s_tot)))) if s_tot > 0 else 0,
			"season_max_m": s_max_d if s_max_d > 0.1 else snappedf(float(sum.get("longest_goal_m", 0.0)) * 0.68, 0.1),
			"career_max_m": float(sum.get("longest_goal_m", 0.0)),
			"career_max_club": str(sum.get("longest_goal_club", club["name"])),
			"career_max_season": int(sum.get("longest_goal_season", sel_yr)),
			"career_on_pct": int(sum.get("ke_gawang_pct", 0)),
			"career_wide_pct": maxi(0, 100 - int(sum.get("ke_gawang_pct", 0))) if c_tot_eff > 0 else 0,
			"career_goal_pct": int(sum.get("konversi_pct", 0)),
			"career_total": c_tot_eff,
		}

	elif mode == "UMPAN":
		if season_pts.is_empty() and (s_m > 0 or s_a > 0):
			var p_cnt: int = clampi(maxi(s_a * 3 + 8, s_m * 2), 10, 42)
			var a_rem: int = mini(p_cnt, maxi(1, s_a) if s_a > 0 else 2)
			for i in range(p_cnt):
				var is_corner: bool = (i == p_cnt - 1 and p_cnt >= 8)
				var sx: float = 0.94 if is_corner else rng.randf_range(0.14, 0.86)
				var sy: float = 0.94 if is_corner else rng.randf_range(0.32, 0.78)
				var tx: float = rng.randf_range(0.30, 0.72)
				var ty: float = rng.randf_range(0.68, 0.90)
				var out_c: String = "ASSIST" if i < a_rem else ("SHOT" if i < int(float(p_cnt) * 0.90) else "NO_SHOT")
				season_pts.append({
					"season": sel_yr,
					"type": "PASS",
					"action": "KORNER" if is_corner else "OPEN",
					"outcome": out_c,
					"fromCoord": {"x": sx, "y": sy},
					"pitchCoord": {"x": tx, "y": ty},
					"distanceMeters": snappedf(Vector2(sx - tx, sy - ty).length() * 68.0, 0.1),
				})
		var open_tot: int = 0
		var open_ast: int = 0
		var open_shot: int = 0
		var cor_tot: int = 0
		var cor_ast: int = 0
		var cor_shot: int = 0
		var d_short: Array[int] = [0, 0]
		var d_med: Array[int] = [0, 0]
		var d_long: Array[int] = [0, 0]
		var right_ast: int = 0
		var tot_ast: int = 0
		var s_max_p: float = 0.0
		for pt in season_pts:
			var is_c: bool = (str(pt.get("action", "OPEN")) == "KORNER")
			var o: String = str(pt.get("outcome", "SHOT"))
			var dm: float = float(pt.get("distanceMeters", 16.0))
			s_max_p = maxf(s_max_p, dm)
			var is_a: bool = (o == "ASSIST")
			var is_sh: bool = (o == "ASSIST" or o == "SHOT")
			if is_c:
				cor_tot += 1
				if is_a: cor_ast += 1
				if is_sh: cor_shot += 1
			else:
				open_tot += 1
				if is_a: open_ast += 1
				if is_sh: open_shot += 1
			if dm < 18.0:
				d_short[0] += 1
				if is_a: d_short[1] += 1
			elif dm < 32.0:
				d_med[0] += 1
				if is_a: d_med[1] += 1
			else:
				d_long[0] += 1
				if is_a: d_long[1] += 1
			if is_a:
				tot_ast += 1
				var fc: Dictionary = pt.get("fromCoord", {"x": 0.6})
				if float(fc.get("x", 0.6)) >= 0.5:
					right_ast += 1

		var s_tot_p: int = maxi(0, open_tot + cor_tot)
		var shot_p_pct: int = int(round(float(open_shot + cor_shot) * 100.0 / maxf(1.0, float(s_tot_p)))) if s_tot_p > 0 else 0
		var ast_p_pct: int = int(round(float(tot_ast) * 100.0 / maxf(1.0, float(s_tot_p)))) if s_tot_p > 0 else 0
		var c_pass_tot: int = maxi(s_tot_p, int(st.get("passesWon", 0)) * 2 + s_tot_p)
		return {
			"mode": "UMPAN",
			"season": sel_yr,
			"max_season": max_yr,
			"points": season_pts,
			"open_ast": open_ast,
			"open_tot": open_tot,
			"open_shot_pct": int(round(float(open_shot) * 100.0 / maxf(1.0, float(open_tot)))) if open_tot > 0 else 0,
			"open_ast_pct": int(round(float(open_ast) * 100.0 / maxf(1.0, float(open_tot)))) if open_tot > 0 else 0,
			"cor_ast": cor_ast,
			"cor_tot": cor_tot,
			"cor_shot_pct": int(round(float(cor_shot) * 100.0 / maxf(1.0, float(cor_tot)))) if cor_tot > 0 else 0,
			"cor_ast_pct": int(round(float(cor_ast) * 100.0 / maxf(1.0, float(cor_tot)))) if cor_tot > 0 else 0,
			"jadi_shot_pct": shot_p_pct,
			"tanpa_shot_pct": maxi(0, 100 - shot_p_pct) if s_tot_p > 0 else 0,
			"assist_pct": ast_p_pct,
			"key_passes": maxi(tot_ast, int(round(float(s_tot_p) * 0.44))),
			"side_note": "Assistmu kebanyakan datang KE SISI KANAN: %d dari %d" % [right_ast, maxi(1, tot_ast)] if right_ast * 2 >= tot_ast else "Assistmu kebanyakan datang KE SISI KIRI: %d dari %d" % [tot_ast - right_ast, maxi(1, tot_ast)],
			"dist_short": d_short,
			"dist_med": d_med,
			"dist_long": d_long,
			"season_max_m": snappedf(maxf(s_max_p, float(sum.get("longest_pass_m", 0.0))), 0.1),
			"career_max_m": float(sum.get("longest_pass_m", 0.0)),
			"career_max_club": str(sum.get("longest_pass_club", club["name"])),
			"career_max_season": int(sum.get("longest_pass_season", sel_yr)),
			"career_shot_pct": int(sum.get("umpan_tembak_pct", shot_p_pct)),
			"career_no_shot_pct": maxi(0, 100 - int(sum.get("umpan_tembak_pct", shot_p_pct))) if c_pass_tot > 0 else 0,
			"career_ast_pct": clampi(ast_p_pct + 4, 0, 100) if c_pass_tot > 0 else 0,
			"career_total": c_pass_tot,
			"career_key_passes": maxi(int(st.get("assists", 0)), int(round(float(c_pass_tot) * 0.48))),
		}

	else:
		# DRIBEL Heatmap + Red Dispossession Markers (Gambar 10 & 11 unified inline!)
		var grid_w: int = 16
		var grid_h: int = 10
		var heat: Array = []
		for _gy in range(grid_h):
			var row_a: Array[float] = []
			for _gx in range(grid_w):
				row_a.append(0.0)
			heat.append(row_a)

		var lost_pts: Array[Vector2] = []
		var s_dr_won: int = maxi(int(career.get("careerMeta", {}).get("seasonDribblesWon", 0)), int(round(float(s_m) * 1.4)))
		var s_lost: int = maxi(2 if s_m > 0 else 0, int(round(float(s_m) * 0.45)))
		var s_fouled: int = int(career.get("careerMeta", {}).get("seasonFouled", 0))
		var s_pen: int = int(st.get("penaltiesScored", 0)) if sel_yr == max_yr else 0

		# Populate realistic attacking-right heatmap weighted toward opponent half & box
		var touch_n: int = clampi(s_dr_won * 5 + s_m * 4, 0, 180)
		for _t in range(touch_n):
			var hx: float = clampf(rng.randfn(0.70, 0.17), 0.15, 0.96)
			var hy: float = clampf(rng.randfn(0.48, 0.24), 0.04, 0.96)
			var gx: int = clampi(int(hx * float(grid_w)), 0, grid_w - 1)
			var gy: int = clampi(int(hy * float(grid_h)), 0, grid_h - 1)
			heat[gy][gx] = float(heat[gy][gx]) + 1.0
		for _l in range(mini(14, s_lost)):
			var lx: float = clampf(rng.randf_range(0.56, 0.92), 0.50, 0.94)
			var ly: float = clampf(rng.randf_range(0.16, 0.86), 0.12, 0.88)
			lost_pts.append(Vector2(lx, ly))

		var c_dr_won: int = maxi(s_dr_won, int(st.get("dribblesWon", 0)))
		var c_lost: int = maxi(s_lost, int(round(float(sum.get("matches", 0)) * 0.48)))
		var c_fouled: int = maxi(s_fouled, int(round(float(sum.get("matches", 0)) * 0.12)))
		var c_pen: int = int(st.get("penaltiesScored", 0))

		return {
			"mode": "DRIBEL",
			"season": sel_yr,
			"max_season": max_yr,
			"heat": heat,
			"grid_w": grid_w,
			"grid_h": grid_h,
			"lost_pts": lost_pts,
			"season_lost": s_lost,
			"season_fouled": s_fouled,
			"season_pen": s_pen,
			"season_won": s_dr_won,
			"career_lost": c_lost,
			"career_fouled": c_fouled,
			"career_pen": c_pen,
			"career_won": c_dr_won,
			"insight": "Paling sering bolamu direbut: LEWAT KANAN, di lini tengah." if (sel_yr % 2 == 1) else "Paling sering bolamu direbut: DI DEPAN KOTAK PENALTI.",
		}

func get_decorated_clubs_ranking(scope: String = "DUNIA", sort_key: String = "tot") -> Dictionary:
	var my_club: Dictionary = get_current_club() if has_active_career else GameData.clubs[0]
	var my_cid: int = int(my_club.get("id", 0))
	var my_name: String = str(my_club.get("name", "Klub"))
	var my_nat: int = clampi(int(my_club.get("nation_id", 0)), 0, GameData.nations.size() - 1)
	var my_conf: String = ConfederationDataScript.get_nation_confederation(my_nat)

	# Count any extra trophies won by user at current club during career
	var won_liga: int = 0
	var won_piala: int = 0
	var won_kont: int = 0
	if has_active_career:
		for tr in career.get("trophiesList", []):
			var ttype: String = str(tr.get("type", "")).to_upper()
			if ttype == "LIGA":
				won_liga += 1
			elif ttype == "PIALA":
				won_piala += 1
			elif ttype in ["ELITE", "EUROPA", "KONTINENTAL"]:
				won_kont += 1

	var entries: Array[Dictionary] = []
	var user_in_list: bool = false
	for dc in GameData.decorated_clubs:
		var cname: String = str(dc.get("name", "Klub"))
		var nat_i: int = clampi(int(dc.get("nat", 0)), 0, GameData.nations.size() - 1)
		var is_me: bool = (cname.to_lower() == my_name.to_lower())
		var l_v: int = int(dc.get("liga", 0)) + (won_liga if is_me else 0)
		var p_v: int = int(dc.get("piala", 0)) + (won_piala if is_me else 0)
		var k_v: int = int(dc.get("kont", 0)) + (won_kont if is_me else 0)
		var d_v: int = int(dc.get("dunia", 0))
		if is_me:
			user_in_list = true
		var cid_match: int = my_cid if is_me else -1
		if cid_match < 0:
			for c in GameData.clubs:
				if str(c["name"]).to_lower() == cname.to_lower():
					cid_match = int(c["id"])
					break
		entries.append({
			"name": cname,
			"nat": nat_i,
			"club_id": cid_match,
			"pri": dc.get("pri", Color("#2563EB")),
			"sec": dc.get("sec", Color("#FFFFFF")),
			"pat": str(dc.get("pat", "solid")),
			"liga": l_v,
			"piala": p_v,
			"kont": k_v,
			"dunia": d_v,
			"tot": l_v + p_v + k_v + d_v,
			"is_user_club": is_me,
		})

	# Compute realistic historical trophies for user's club if not in top 24 decorated list
	var my_entry: Dictionary = {}
	if not user_in_list:
		var covr: int = int(my_club.get("ovr", 62))
		var cdiv: int = int(my_club.get("division", 3))
		var h_l: int = maxi(0, int((covr - 56) / 3) * (2 if cdiv == 1 else 1)) + won_liga
		var h_p: int = maxi(0, int((covr - 54) / 2) * (1 if cdiv >= 2 else 2)) + won_piala
		var h_k: int = (maxi(0, int((covr - 78) / 3)) if cdiv == 1 else 0) + won_kont
		if my_name == "Bilbao Leones":
			h_l = 8 + won_liga
			h_p = 24 + won_piala
			h_k = won_kont
		my_entry = {
			"name": my_name,
			"nat": my_nat,
			"club_id": my_cid,
			"pri": my_club.get("primary", Color("#2563EB")),
			"sec": my_club.get("secondary", Color("#FFFFFF")),
			"pat": str(my_club.get("pattern", "solid")),
			"liga": h_l,
			"piala": h_p,
			"kont": h_k,
			"dunia": 0,
			"tot": h_l + h_p + h_k,
			"is_user_club": true,
		}
		entries.append(my_entry)
	else:
		for e in entries:
			if bool(e["is_user_club"]):
				my_entry = e
				break

	# Scope filter (DUNIA / BENUA / NEGARAMU)
	var filtered: Array[Dictionary] = []
	for e in entries:
		var enat: int = int(e["nat"])
		if scope == "NEGARAMU":
			if enat != my_nat and not bool(e["is_user_club"]):
				continue
		elif scope == "BENUA":
			if ConfederationDataScript.get_nation_confederation(enat) != my_conf and not bool(e["is_user_club"]):
				continue
		filtered.append(e)

	# Ensure NEGARAMU scope always has at least top Div 1 clubs of user's nation
	if scope == "NEGARAMU" and filtered.size() < 8:
		var d1_clubs: Array[Dictionary] = GameData.get_clubs_in_division(my_nat, 1)
		for dc_i in range(mini(12, d1_clubs.size())):
			var dc_c: Dictionary = d1_clubs[dc_i]
			var already := false
			for fe in filtered:
				if str(fe["name"]).to_lower() == str(dc_c["name"]).to_lower():
					already = true
					break
			if already:
				continue
			var ov: int = int(dc_c.get("ovr", 70))
			var lv: int = maxi(1, int((ov - 58) * 0.7))
			var pv: int = maxi(1, int((ov - 56) * 0.6))
			var kv: int = maxi(0, int((ov - 78) * 0.4))
			filtered.append({
				"name": str(dc_c["name"]),
				"nat": my_nat,
				"club_id": int(dc_c["id"]),
				"pri": dc_c.get("primary", Color("#2563EB")),
				"sec": dc_c.get("secondary", Color("#FFFFFF")),
				"pat": str(dc_c.get("pattern", "solid")),
				"liga": lv, "piala": pv, "kont": kv, "dunia": 0,
				"tot": lv + pv + kv, "is_user_club": false,
			})

	var sk: String = sort_key
	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var va: int = int(a.get(sk, 0))
		var vb: int = int(b.get(sk, 0))
		if va != vb:
			return va > vb
		if int(a["tot"]) != int(b["tot"]):
			return int(a["tot"]) > int(b["tot"])
		return str(a["name"]) < str(b["name"])
	)

	var my_rank: int = filtered.size()
	var my_val: int = int(my_entry.get(sk, 0))
	for i in range(filtered.size()):
		if bool(filtered[i]["is_user_club"]):
			my_rank = i + 1
			break
	# Realistic global world rank estimate when outside curated top 24 in DUNIA scope
	if scope == "DUNIA" and not user_in_list:
		var floor_val: int = int(filtered[mini(15, filtered.size() - 1)].get(sk, 20))
		if my_val < floor_val:
			my_rank = maxi(my_rank, 18 + (floor_val - my_val) * (2 if sk == "tot" else 3))

	var gap_to_next: int = 1
	var next_rank: int = maxi(1, my_rank - 1)
	if my_rank > 1 and my_rank <= filtered.size():
		gap_to_next = maxi(1, int(filtered[my_rank - 2].get(sk, my_val)) - my_val)

	# Compute category leaders (LIGA, PIALA, KONTINENTAL) + user rank in each!
	var leaders: Dictionary = {}
	for lcat in ["liga", "piala", "kont"]:
		var copy_a: Array[Dictionary] = filtered.duplicate()
		copy_a.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var va: int = int(a.get(lcat, 0))
			var vb: int = int(b.get(lcat, 0))
			if va != vb:
				return va > vb
			return int(a["tot"]) > int(b["tot"])
		)
		var l_rk: int = copy_a.size()
		for i in range(copy_a.size()):
			if bool(copy_a[i]["is_user_club"]):
				l_rk = i + 1
				break
		if scope == "DUNIA" and not user_in_list:
			var top10_v: int = int(copy_a[mini(9, copy_a.size() - 1)].get(lcat, 10))
			var mv_c: int = int(my_entry.get(lcat, 0))
			if mv_c < top10_v:
				l_rk = maxi(l_rk, 12 + (top10_v - mv_c) * 4)
		leaders[lcat] = {
			"top": copy_a[0] if not copy_a.is_empty() else my_entry,
			"list": copy_a,
			"my_rank": l_rk,
			"my_val": int(my_entry.get(lcat, 0)),
		}

	return {
		"scope": scope,
		"sort_key": sk,
		"list": filtered,
		"my_entry": my_entry,
		"my_rank": my_rank,
		"next_rank": next_rank,
		"gap_to_next": gap_to_next,
		"leaders": leaders,
	}

# ==============================================================================
# WARISAN -> LEGENDA HUB, LEGENDA TIMNAS & HUD KETENARAN HELPERS
# ==============================================================================
func _det_legend_name(seed_val: int, nat_id: int) -> String:
	var first_esp := ["Sergio", "Alvaro", "Lucas", "Arnau", "Raul", "Pablo", "Aitor", "Ivan", "Iker", "Diego", "Mateo", "Marcos"]
	var last_esp := ["Landazuri", "Echeverria", "Salazar", "Aranguren", "Serrano", "Navarro", "Mendoza", "Delgado", "Prieto", "Blanco", "Vega", "Molina"]
	var first_idn := ["Bambang", "Rizky", "Hendra", "Bagus", "Dimas", "Pratama", "Egi", "Witan", "Fajar", "Bayu", "Ilham", "Saddil"]
	var last_idn := ["Prasetyo", "Darmawan", "Gunawan", "Saputra", "Santoso", "Mahendra", "Nugroho", "Wibowo", "Kurniawan", "Setiawan", "Hidayat", "Permana"]
	var first_gen := ["Lucas", "Marco", "Lukas", "Oliver", "Hugo", "Mateo", "Sander", "Emil", "Tomas", "Viktor", "Henrik", "Kenji"]
	var last_gen := ["Morel", "Silva", "Keller", "Berger", "Novak", "Lindholm", "Richter", "Ferrari", "Costa", "Vargas", "Sato", "Jansen"]
	var f_pool: Array = first_gen
	var l_pool: Array = last_gen
	if nat_id == 1 or nat_id == 19 or nat_id == 29 or nat_id == 30 or nat_id == 31 or nat_id == 32:
		f_pool = first_esp
		l_pool = last_esp
	elif nat_id == 16:
		f_pool = first_idn
		l_pool = last_idn
	var f_idx: int = absi(seed_val * 17 + nat_id * 7) % f_pool.size()
	var l_idx: int = absi(seed_val * 31 + nat_id * 13 + 5) % l_pool.size()
	return "%s %s" % [str(f_pool[f_idx]), str(l_pool[l_idx])]

func get_user_elite_production() -> Dictionary:
	var p: Dictionary = career.get("playerProfile", {})
	var st: Dictionary = career.get("stats", {})
	var club: Dictionary = get_current_club()
	var cur_div: int = clampi(int(club.get("division", 3)), 1, 3)

	var tot_g: int = int(st.get("goals", 0))
	var tot_a: int = int(st.get("assists", 0))
	var intl_g: int = int(st.get("intlGoals", 0))
	var intl_a: int = int(st.get("intlAssists", 0))

	# Split career production into Elite (Div 1 + Timnas) vs Div 2/3
	var elite_g: int = intl_g
	var elite_a: int = intl_a
	var hist: Array = st.get("seasonHistory", [])
	var hist_g: int = 0
	var hist_a: int = 0
	for h_item in hist:
		var hd: Dictionary = h_item
		var hg: int = int(hd.get("goals", 0))
		var ha: int = int(hd.get("assists", 0))
		hist_g += hg
		hist_a += ha
		var hdiv: int = int(hd.get("division", 3))
		if hdiv == 1:
			elite_g += hg
			elite_a += ha
	var cur_s_g: int = maxi(0, tot_g - hist_g - intl_g)
	var cur_s_a: int = maxi(0, tot_a - hist_a - intl_a)
	if cur_div == 1:
		elite_g += cur_s_g
		elite_a += cur_s_a
	elite_g = mini(elite_g, tot_g)
	elite_a = mini(elite_a, tot_a)

	# User's elite trophy breakdown
	var ballon_n: int = 0
	var boot_n: int = 0
	var liga_n: int = 0
	var piala_n: int = 0
	var kont_n: int = 0
	var wc_n: int = 0
	var cont_nt_n: int = 0
	for tr_item in career.get("trophiesList", []):
		var tr_s: String = (str((tr_item as Dictionary).get("name", "")) if tr_item is Dictionary else str(tr_item)).to_upper()
		if tr_s.contains("BALLON") or tr_s.contains("BOLA EMAS") or (tr_s.contains("PEMAIN TERBAIK") and not tr_s.contains("MUDA")):
			ballon_n += 1
		elif tr_s.contains("SEPATU EMAS") or tr_s.contains("TOP SKOR"):
			boot_n += 1
		elif tr_s.contains("PIALA DUNIA") and not tr_s.contains("KLUB"):
			wc_n += 1
		elif tr_s.contains("PIALA ASIA") or tr_s.contains("EURO") or tr_s.contains("COPA") or tr_s.contains("AFRIKA") or tr_s.contains("GOLD CUP") or tr_s.contains("OFC"):
			cont_nt_n += 1
		elif tr_s.contains("ELITE") or tr_s.contains("EUROPA") or tr_s.contains("CONF") or tr_s.contains("KONTINENTAL") or tr_s.contains("CHAMPIONS"):
			kont_n += 1
		elif tr_s.contains("LIGA") or tr_s.contains("DIVISI 1"):
			liga_n += 1
		elif tr_s.contains("PIALA") or tr_s.contains("CUP"):
			piala_n += 1

	var indiv_n: int = ballon_n + boot_n
	var team_n: int = liga_n + piala_n + kont_n + wc_n
	return {
		"name": str(p.get("name", "Pemain")),
		"nat": clampi(int(p.get("nationality", 16)), 0, GameData.nations.size() - 1),
		"elite_g": elite_g,
		"elite_a": elite_a,
		"elite_ga": elite_g + elite_a,
		"total_g": tot_g,
		"total_a": tot_a,
		"total_ga": tot_g + tot_a,
		"diff_g": maxi(0, tot_g - elite_g),
		"diff_a": maxi(0, tot_a - elite_a),
		"ballon": ballon_n,
		"boot": boot_n,
		"liga": liga_n,
		"piala": piala_n,
		"kont": kont_n,
		"wc": wc_n,
		"cont_nt": cont_nt_n,
		"indiv": indiv_n,
		"team": team_n,
		"tot_trophies": indiv_n + team_n,
		"intl_caps": int(st.get("intlCaps", 0)),
		"intl_g": intl_g,
		"intl_a": intl_a,
		"retired": false,
		"is_user": true,
	}

func get_world_legends_list(sort_mode: String = "INDIV") -> Dictionary:
	var u: Dictionary = get_user_elite_production()
	var list: Array[Dictionary] = []
	for lg_item in GameData.world_legends:
		var lg: Dictionary = lg_item.duplicate()
		lg["is_user"] = false
		lg["ga"] = int(lg.get("goals", 0)) + int(lg.get("assists", 0))
		lg["tot"] = int(lg.get("indiv", 0)) + int(lg.get("team", 0))
		list.append(lg)

	var u_row: Dictionary = {
		"name": str(u["name"]),
		"nat": int(u["nat"]),
		"indiv": int(u["indiv"]),
		"team": int(u["team"]),
		"tot": int(u["tot_trophies"]),
		"goals": int(u["elite_g"]),
		"assists": int(u["elite_a"]),
		"ga": int(u["elite_ga"]),
		"ballon": int(u["ballon"]),
		"boot": int(u["boot"]),
		"liga": int(u["liga"]),
		"piala": int(u["piala"]),
		"kont": int(u["kont"]),
		"wc": int(u["wc"]),
		"retired": false,
		"is_user": true,
	}

	var mode_u: String = sort_mode.to_upper()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if mode_u == "TIM":
			if int(a["team"]) != int(b["team"]):
				return int(a["team"]) > int(b["team"])
			if int(a["indiv"]) != int(b["indiv"]):
				return int(a["indiv"]) > int(b["indiv"])
			return int(a["goals"]) > int(b["goals"])
		elif mode_u == "TOTAL":
			if int(a["tot"]) != int(b["tot"]):
				return int(a["tot"]) > int(b["tot"])
			if int(a["indiv"]) != int(b["indiv"]):
				return int(a["indiv"]) > int(b["indiv"])
			return int(a["goals"]) > int(b["goals"])
		elif mode_u == "GA":
			if int(a["ga"]) != int(b["ga"]):
				return int(a["ga"]) > int(b["ga"])
			return int(a["goals"]) > int(b["goals"])
		else:
			if int(a["indiv"]) != int(b["indiv"]):
				return int(a["indiv"]) > int(b["indiv"])
			if int(a["team"]) != int(b["team"]):
				return int(a["team"]) > int(b["team"])
			return int(a["goals"]) > int(b["goals"])
	)

	var top10: Array[Dictionary] = []
	for i in range(mini(10, list.size())):
		top10.append(list[i])

	# Determine whether user ranks inside Top 10 or below
	var u_in_top10: bool = false
	var u_rank: int = 11
	var u_val: int = int(u_row["ga"]) if mode_u == "GA" else (int(u_row["team"]) if mode_u == "TIM" else (int(u_row["tot"]) if mode_u == "TOTAL" else int(u_row["indiv"])))
	for i in range(top10.size()):
		var tv: int = int(top10[i]["ga"]) if mode_u == "GA" else (int(top10[i]["team"]) if mode_u == "TIM" else (int(top10[i]["tot"]) if mode_u == "TOTAL" else int(top10[i]["indiv"])))
		if u_val > tv:
			top10.insert(i, u_row)
			if top10.size() > 10:
				top10.resize(10)
			u_in_top10 = true
			u_rank = i + 1
			break
	if not u_in_top10:
		if mode_u == "GA":
			u_rank = 11
		else:
			var floor_v: int = int(top10[top10.size() - 1]["indiv"]) if mode_u == "INDIV" else (int(top10[top10.size() - 1]["team"]) if mode_u == "TIM" else int(top10[top10.size() - 1]["tot"]))
			u_rank = 975 if u_val == 0 else clampi(12 + (floor_v - u_val) * 38, 11, 950)

	return {
		"mode": mode_u,
		"top10": top10,
		"user_row": u_row,
		"user_rank": u_rank,
		"user_in_top10": u_in_top10,
	}

func get_legends_by_league(nat_id: int) -> Dictionary:
	var nid: int = clampi(nat_id, 0, GameData.nations.size() - 1)
	var nd: Dictionary = GameData.nations[nid]
	var n_name: String = str(nd.get("name", "Spanyol"))
	var target_league: String = "Liga " + n_name

	var rows: Array[Dictionary] = []
	for lg_item in GameData.world_legends:
		if str(lg_item.get("league", "")).to_lower() == target_league.to_lower():
			var d: Dictionary = lg_item.duplicate()
			d["disp_goals"] = int(d.get("league_goals", int(float(d.get("goals", 200)) * 0.55)))
			rows.append(d)

	# Fill up to 5 deterministic legends for nations with fewer curated legends
	var extra_i: int = 0
	while rows.size() < 5:
		var seed_v: int = nid * 101 + extra_i * 29 + 7
		var indiv_v: int = maxi(0, 4 - extra_i)
		var ballon_v: int = 1 if (indiv_v >= 3 and nid <= 7) else 0
		var boot_v: int = maxi(0, indiv_v - ballon_v)
		var liga_v: int = maxi(2, 8 - extra_i)
		var piala_v: int = maxi(1, 4 - (extra_i % 3))
		var kont_v: int = maxi(0, (3 - extra_i) if nid <= 8 else (1 if extra_i == 0 else 0))
		var wc_v: int = 1 if (extra_i == 0 and nid in [1, 2, 3, 4, 5, 18, 19]) else 0
		var team_v: int = liga_v + piala_v + kont_v + wc_v
		var lg_goals: int = maxi(95, 290 - extra_i * 34 - (nid % 7) * 8)
		var p_nat: int = nid if (extra_i % 3 != 1) else ((nid + extra_i + 3) % mini(20, GameData.nations.size()))
		rows.append({
			"name": _det_legend_name(seed_v, p_nat),
			"nat": p_nat,
			"indiv": indiv_v,
			"team": team_v,
			"goals": lg_goals + 85,
			"assists": 75 + (seed_v % 90),
			"disp_goals": lg_goals,
			"ballon": ballon_v,
			"boot": boot_v,
			"liga": liga_v,
			"piala": piala_v,
			"kont": kont_v,
			"wc": wc_v,
			"retired": extra_i != 1,
			"league": target_league,
		})
		extra_i += 1

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = int(a["indiv"]) * 3 + int(a["team"])
		var sb: int = int(b["indiv"]) * 3 + int(b["team"])
		if sa != sb:
			return sa > sb
		return int(a["disp_goals"]) > int(b["disp_goals"])
	)
	if rows.size() > 5:
		rows.resize(5)

	return {
		"nat_id": nid,
		"nat_name": n_name,
		"league_name": "LIGA " + n_name.to_upper(),
		"legends": rows,
	}

func get_legends_by_club(club_id: int, sort_mode: String = "GELAR") -> Dictionary:
	var cid: int = clampi(club_id, 0, GameData.clubs.size() - 1)
	var club: Dictionary = GameData.clubs[cid]
	var c_name: String = str(club.get("name", "Klub"))
	var nid: int = clampi(int(club.get("nation_id", 1)), 0, GameData.nations.size() - 1)
	var covr: int = int(club.get("ovr", 65))
	var cdiv: int = clampi(int(club.get("division", 3)), 1, 3)

	var rows: Array[Dictionary] = []
	if c_name == "Bilbao Leones":
		rows = [
			{"name": "Sergio Landazuri", "nat": 1, "indiv": 6, "team": 6, "ballon": 0, "boot": 6, "liga": 1, "piala": 5, "kont": 0, "wc": 0, "goals": 335, "assists": 84, "since": 1955, "retired": true, "is_user": false},
			{"name": "Alvaro Echeverria", "nat": 1, "indiv": 0, "team": 3, "ballon": 0, "boot": 0, "liga": 2, "piala": 1, "kont": 0, "wc": 0, "goals": 212, "assists": 96, "since": 1984, "retired": true, "is_user": false},
			{"name": "Lucas Salazar", "nat": 1, "indiv": 0, "team": 2, "ballon": 0, "boot": 0, "liga": 0, "piala": 2, "kont": 0, "wc": 0, "goals": 186, "assists": 72, "since": 1991, "retired": true, "is_user": false},
			{"name": "Arnau Aranguren", "nat": 1, "indiv": 0, "team": 0, "ballon": 0, "boot": 0, "liga": 0, "piala": 0, "kont": 0, "wc": 0, "goals": 148, "assists": 91, "since": 2004, "retired": true, "is_user": false},
			{"name": "Raul Serrano", "nat": 1, "indiv": 0, "team": 0, "ballon": 0, "boot": 0, "liga": 0, "piala": 0, "kont": 0, "wc": 0, "goals": 124, "assists": 68, "since": 2012, "retired": true, "is_user": false},
		]
	else:
		var scale: float = clampf(float(covr - 56) / 30.0, 0.15, 1.0)
		var g_base: int = clampi(int(round(68.0 + scale * 190.0)), 62, 275)
		for i in range(5):
			var seed_v: int = cid * 73 + i * 41 + 11
			var indiv_v: int = int(round(scale * maxf(0.0, 5.5 - float(i) * 1.8))) if cdiv == 1 else (1 if (i == 0 and covr >= 66) else 0)
			var ballon_v: int = int(indiv_v / 3) if covr >= 80 else 0
			var boot_v: int = maxi(0, indiv_v - ballon_v)
			var liga_v: int = int(round(scale * maxf(0.0, 7.0 - float(i) * 1.6))) if cdiv == 1 else maxi(0, 2 - i)
			var piala_v: int = int(round(scale * maxf(0.0, 4.0 - float(i) * 0.9)))
			var kont_v: int = int(round(scale * maxf(0.0, 3.0 - float(i) * 1.0))) if covr >= 78 else 0
			var wc_v: int = 1 if (i == 0 and covr >= 84) else 0
			var p_nat: int = nid if (i != 2 or covr < 75) else ((nid + cid + i) % mini(20, GameData.nations.size()))
			var lg_g: int = maxi(26, g_base - i * (22 + (seed_v % 9)))
			var lg_a: int = maxi(14, int(float(lg_g) * 0.42) + ((seed_v / 5) % 19))
			rows.append({
				"name": _det_legend_name(seed_v, p_nat),
				"nat": p_nat,
				"indiv": indiv_v,
				"team": liga_v + piala_v + kont_v + wc_v,
				"ballon": ballon_v,
				"boot": boot_v,
				"liga": liga_v,
				"piala": piala_v,
				"kont": kont_v,
				"wc": wc_v,
				"goals": lg_g,
				"assists": lg_a,
				"since": 1974 + (seed_v % 44),
				"retired": i != 1,
				"is_user": false,
			})

	for r_item in rows:
		r_item["ga"] = int(r_item.get("goals", 0)) + int(r_item.get("assists", 0))
		r_item["tot"] = int(r_item.get("indiv", 0)) + int(r_item.get("team", 0))

	# Check user's stats for this club (active club or recorded in clubStats)
	var u_row: Dictionary = {}
	var user_played_here: bool = false
	var user_in_top5: bool = false
	var user_rank: int = 6
	if has_active_career:
		var u_cid: int = int(career.get("playerProfile", {}).get("clubId", -1))
		var st_d: Dictionary = career.get("stats", {})
		var cstats_map: Dictionary = st_d.get("clubStats", {})
		var has_hist: bool = cstats_map.has(str(cid))
		if cid == u_cid or has_hist:
			user_played_here = true
			var u_prod: Dictionary = get_user_elite_production()
			var ug: int = int(cstats_map.get(str(cid), {}).get("goals", int(st_d.get("goals", 0)) if cid == u_cid else 0))
			var ua: int = int(cstats_map.get(str(cid), {}).get("assists", int(st_d.get("assists", 0)) if cid == u_cid else 0))
			if cid == u_cid and ug == 0 and int(st_d.get("goals", 0)) > 0:
				ug = int(st_d.get("goals", 0))
				ua = int(st_d.get("assists", 0))
			u_row = {
				"name": str(u_prod["name"]),
				"nat": int(u_prod["nat"]),
				"indiv": int(u_prod["indiv"]),
				"team": int(u_prod["team"]),
				"tot": int(u_prod["tot_trophies"]),
				"ballon": int(u_prod["ballon"]),
				"boot": int(u_prod["boot"]),
				"liga": int(u_prod["liga"]),
				"piala": int(u_prod["piala"]),
				"kont": int(u_prod["kont"]),
				"wc": int(u_prod["wc"]),
				"goals": ug,
				"assists": ua,
				"ga": ug + ua,
				"retired": false,
				"is_user": true,
			}

	var mode_u: String = sort_mode.to_upper()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if mode_u == "GA":
			if int(a["ga"]) != int(b["ga"]):
				return int(a["ga"]) > int(b["ga"])
			return int(a["goals"]) > int(b["goals"])
		else:
			if int(a["tot"]) != int(b["tot"]):
				return int(a["tot"]) > int(b["tot"])
			if int(a["indiv"]) != int(b["indiv"]):
				return int(a["indiv"]) > int(b["indiv"])
			return int(a["goals"]) > int(b["goals"])
	)

	if user_played_here and not u_row.is_empty():
		var u_key_v: int = int(u_row["ga"]) if mode_u == "GA" else int(u_row["tot"])
		for i in range(rows.size()):
			var rv: int = int(rows[i]["ga"]) if mode_u == "GA" else int(rows[i]["tot"])
			if u_key_v > rv:
				rows.insert(i, u_row)
				if rows.size() > 5:
					rows.resize(5)
				user_in_top5 = true
				user_rank = i + 1
				break

	return {
		"club": club,
		"club_id": cid,
		"nat_id": nid,
		"sort_mode": mode_u,
		"legends": rows,
		"user_row": u_row,
		"user_played_here": user_played_here,
		"user_in_top5": user_in_top5,
		"user_rank": user_rank,
	}

func get_club_alltime_goal_record(club_id: int) -> Dictionary:
	var cdata: Dictionary = get_legends_by_club(club_id, "GA")
	var best_g: int = 85
	var holder: String = "Legenda Klub"
	var since_y: int = 1987
	for lg_item in cdata.get("legends", []):
		var lg: Dictionary = lg_item
		if bool(lg.get("is_user", false)):
			continue
		if int(lg.get("goals", 0)) >= best_g or holder == "Legenda Klub":
			best_g = int(lg.get("goals", 85))
			holder = str(lg.get("name", "Legenda Klub"))
			since_y = int(lg.get("since", 1987))
			break
	return {"holder": holder, "goals": best_g, "since": since_y}

func get_timnas_alltime_goal_record(nat_id: int) -> Dictionary:
	var tdata: Dictionary = get_timnas_legends(nat_id, "GA")
	var best_g: int = 45
	var holder: String = "Legenda Timnas"
	var since_y: int = 1998
	for lg_item in tdata.get("top10", []):
		var lg: Dictionary = lg_item
		if bool(lg.get("is_user", false)):
			continue
		best_g = int(lg.get("goals", 45))
		holder = str(lg.get("name", "Legenda Timnas"))
		since_y = 1986 + (clampi(nat_id, 0, 50) * 3) % 32
		break
	return {"holder": holder, "goals": best_g, "since": since_y}

func get_club_andalan_stalwarts(club_id: int) -> Array[Dictionary]:
	var cid: int = clampi(club_id, 0, GameData.clubs.size() - 1)
	var club: Dictionary = GameData.clubs[cid]
	var nid: int = clampi(int(club.get("nation_id", 1)), 0, GameData.nations.size() - 1)
	var out: Array[Dictionary] = []
	var seasons_list: Array[int] = [14, 12, 10]
	var sq: Array = career.get("squad", []) if cid == int(career.get("playerProfile", {}).get("clubId", -1)) else []
	var used_names: Dictionary = {}
	for i in range(3):
		var nm: String = ""
		var pnat: int = nid
		if i < sq.size():
			var s_item: Dictionary = sq[mini(i * 3, sq.size() - 1)]
			nm = str(s_item.get("name", ""))
			pnat = clampi(int(s_item.get("nat", nid)), 0, GameData.nations.size() - 1)
		if nm.is_empty() or used_names.has(nm):
			pnat = nid if i > 0 else ((nid + 33) % mini(37, GameData.nations.size()))
			nm = _det_legend_name(cid * 59 + i * 19 + 3, pnat)
		used_names[nm] = true
		out.append({
			"name": nm,
			"nat": pnat,
			"since": "SEJAK M1",
			"seasons": seasons_list[i],
		})
	return out

func get_timnas_legends(nat_id: int, sort_mode: String = "PIALA") -> Dictionary:
	var nid: int = clampi(nat_id, 0, GameData.nations.size() - 1)
	var nd: Dictionary = GameData.nations[nid]
	var n_name: String = str(nd.get("name", "Indonesia"))
	var conf: String = ConfederationDataScript.get_nation_confederation(nid)
	var cont_map: Dictionary = {
		"AFC": "PIALA ASIA",
		"UEFA": "EURO",
		"CONMEBOL": "COPA AMERICA",
		"CAF": "PIALA AFRIKA",
		"CONCACAF": "GOLD CUP",
		"OFC": "PIALA OFC",
	}
	var cont_lbl: String = str(cont_map.get(conf, "PIALA BENUA"))
	var is_wc_power: bool = nid in [1, 2, 3, 4, 5, 18, 19, 31]
	var is_cont_power: bool = is_wc_power or nid in [6, 7, 16, 17, 26, 27, 29, 33, 34, 35, 36, 37, 38, 39, 43]

	var rows: Array[Dictionary] = []
	var seen: Dictionary = {}
	# Pull curated world_legends matching this nationality first
	for lg_item in GameData.world_legends:
		if int(lg_item.get("nat", -1)) == nid:
			var nm: String = str(lg_item["name"])
			if seen.has(nm):
				continue
			seen[nm] = true
			var wc_v: int = int(lg_item.get("wc", 0))
			var cont_v: int = maxi(1 if is_cont_power else 0, mini(3, int(lg_item.get("kont", 1) / 2) + (1 if wc_v > 0 else 0)))
			var ig: int = maxi(18, int(float(lg_item.get("goals", 300)) * 0.13))
			var ia: int = maxi(8, int(float(lg_item.get("assists", 140)) * 0.14))
			var caps: int = clampi(62 + ig / 2 + ia / 2, 48, 185)
			rows.append({
				"name": nm,
				"nat": nid,
				"wc": wc_v,
				"cont": cont_v,
				"tot_cups": wc_v + cont_v,
				"caps": caps,
				"goals": ig,
				"assists": ia,
				"ga": ig + ia,
				"retired": bool(lg_item.get("retired", true)),
				"is_user": false,
			})

	# Deterministic national team icons up to 10
	var idx_g: int = 0
	while rows.size() < 10 and idx_g < 200:
		var seed_v: int = nid * 137 + idx_g * 37 + 9
		var nm: String = _det_legend_name(seed_v, nid)
		if seen.has(nm):
			idx_g += 1
			continue
		seen[nm] = true
		var rank_f: float = maxf(0.0, 1.0 - float(rows.size()) * 0.10)
		var wc_v: int = 0
		if is_wc_power:
			wc_v = 2 if (nid == 18 and rows.size() == 0) else (1 if rows.size() < 4 else 0)
		var cont_v: int = 0
		if is_cont_power:
			cont_v = clampi(int(round(rank_f * (3.0 if nid in [18, 19, 31, 33, 29, 26] else 2.2))), 0, 3)
		else:
			cont_v = 1 if rows.size() < 2 else 0
		var ig: int = clampi(int(round(14.0 + rank_f * (72.0 if is_wc_power else 52.0))) + (seed_v % 9), 10, 118)
		var ia: int = clampi(int(round(8.0 + rank_f * 36.0)) + ((seed_v / 3) % 7), 5, 58)
		var caps: int = clampi(52 + int(rank_f * 92.0) + (seed_v % 15), 40, 175)
		rows.append({
			"name": nm,
			"nat": nid,
			"wc": wc_v,
			"cont": cont_v,
			"tot_cups": wc_v + cont_v,
			"caps": caps,
			"goals": ig,
			"assists": ia,
			"ga": ig + ia,
			"retired": rows.size() != 2,
			"is_user": false,
		})
		idx_g += 1

	var mode_u: String = sort_mode.to_upper()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if mode_u == "GA":
			if int(a["ga"]) != int(b["ga"]):
				return int(a["ga"]) > int(b["ga"])
			return int(a["goals"]) > int(b["goals"])
		else:
			if int(a["tot_cups"]) != int(b["tot_cups"]):
				return int(a["tot_cups"]) > int(b["tot_cups"])
			if int(a["wc"]) != int(b["wc"]):
				return int(a["wc"]) > int(b["wc"])
			return int(a["caps"]) > int(b["caps"])
	)
	if rows.size() > 10:
		rows.resize(10)

	# User national team row (only inserted into this nation if nationality matches)
	var u: Dictionary = get_user_elite_production()
	var user_matches_nat: bool = (int(u["nat"]) == nid)
	var u_row: Dictionary = {
		"name": str(u["name"]),
		"nat": int(u["nat"]),
		"wc": int(u["wc"]),
		"cont": int(u["cont_nt"]),
		"tot_cups": int(u["wc"]) + int(u["cont_nt"]),
		"caps": int(u["intl_caps"]),
		"goals": int(u["intl_g"]),
		"assists": int(u["intl_a"]),
		"ga": int(u["intl_g"]) + int(u["intl_a"]),
		"retired": false,
		"is_user": true,
	}
	var u_in_top10: bool = false
	var u_rank: int = 11
	if user_matches_nat:
		var u_key_v: int = int(u_row["ga"]) if mode_u == "GA" else int(u_row["tot_cups"])
		for i in range(rows.size()):
			var rv: int = int(rows[i]["ga"]) if mode_u == "GA" else int(rows[i]["tot_cups"])
			if u_key_v > rv or (mode_u == "PIALA" and u_key_v == rv and u_key_v > 0 and int(u_row["caps"]) > int(rows[i]["caps"])):
				rows.insert(i, u_row)
				if rows.size() > 10:
					rows.resize(10)
				u_in_top10 = true
				u_rank = i + 1
				break

	return {
		"nat_id": nid,
		"nat_name": n_name,
		"conf": conf,
		"cont_cup_label": cont_lbl,
		"sort_mode": mode_u,
		"top10": rows,
		"user_row": u_row,
		"user_matches_nat": user_matches_nat,
		"user_in_top10": u_in_top10,
		"user_rank": u_rank,
	}

func get_fame_overview() -> Dictionary:
	var p: Dictionary = career.get("playerProfile", {})
	var rels: Dictionary = p.get("relations", {})
	var score: int = clampi(int(rels.get("fans", 50)), 0, 100)
	var club: Dictionary = get_current_club()
	var covr: int = int(club.get("ovr", 62))
	var cdiv: int = clampi(int(club.get("division", 3)), 1, 3)

	var tiers: Array[Dictionary] = [
		{"key": "BINTANG", "label": "BINTANG", "min": 85, "max": 100, "stars": 5, "color": Color("#C5D3E6"), "text_col": Color("#1E293B"), "icon": "crown"},
		{"key": "TERKENAL", "label": "TERKENAL", "min": 65, "max": 85, "stars": 4, "color": Color("#D9639A"), "text_col": Color("#240A19"), "icon": "medal"},
		{"key": "DIKENAL", "label": "DIKENAL", "min": 45, "max": 65, "stars": 3, "color": Color("#8A68E6"), "text_col": Color("#FFFFFF"), "icon": "cal_star"},
		{"key": "LOKAL", "label": "LOKAL", "min": 20, "max": 45, "stars": 2, "color": Color("#5A8BE8"), "text_col": Color("#FFFFFF"), "icon": "star"},
		{"key": "TAK_DIKENAL", "label": "TAK DIKENAL", "min": 0, "max": 20, "stars": 1, "color": Color("#5D6B7E"), "text_col": Color("#CBD5E1"), "icon": "shield"},
	]

	var cur_idx: int = 4
	for i in range(tiers.size()):
		if score >= int(tiers[i]["min"]):
			cur_idx = i
			break
	var cur_tier: Dictionary = tiers[cur_idx]
	var next_label: String = ""
	var pts_to_next: int = 0
	var tier_prog: float = 1.0
	if cur_idx > 0:
		var nxt: Dictionary = tiers[cur_idx - 1]
		next_label = str(nxt["label"])
		var t_min: int = int(cur_tier["min"])
		var t_max: int = int(nxt["min"])
		pts_to_next = maxi(0, t_max - score)
		tier_prog = clampf(float(score - t_min) / maxf(1.0, float(t_max - t_min)), 0.0, 1.0)

	var club_dots: int = clampi(1 + int((covr - 50) / 9) + (1 if cdiv == 1 else 0), 1, 5)
	var mult_table: Array[float] = [0.95, 1.00, 1.02, 1.05, 1.15]
	var club_mult: float = mult_table[club_dots - 1]

	return {
		"score": score,
		"stars": int(cur_tier["stars"]),
		"tier_idx": cur_idx,
		"tier_label": str(cur_tier["label"]),
		"tiers": tiers,
		"next_label": next_label,
		"pts_to_next": pts_to_next,
		"tier_prog": tier_prog,
		"club_dots": club_dots,
		"club_mult": club_mult,
		"bonus_nilai": score >= 20,
		"bonus_merek": score >= 45,
		"bonus_jersey": score >= 65,
	}

# ==============================================================================
# OCTOBER LAST-WEEK BALLON D'OR & PEMAIN MUDA TERBAIK (U-21) GALA ENGINE
# ==============================================================================
func _build_gala_candidate_from_wp(wp_idx: int, cal_year: int, is_u21: bool) -> Dictionary:
	var cid: int = int(wp_club[wp_idx])
	var c_dict: Dictionary = GameData.clubs[cid] if (cid >= 0 and cid < GameData.clubs.size()) else GameData.clubs[0]
	var cname: String = str(c_dict.get("name", "Klub Elite"))
	var nid: int = clampi(int(wp_nat[wp_idx]), 0, GameData.nations.size() - 1)
	var pos_i: int = clampi(int(wp_pos[wp_idx]), 0, GameData.POSITIONS.size() - 1)
	var pos_s: String = str(GameData.POSITIONS[pos_i])
	var ovr_v: int = int(wp_ovr[wp_idx])
	var age_v: int = int(wp_age[wp_idx])
	var seed_v: int = absi(wp_idx * 37 + cal_year * 97 + (13 if is_u21 else 3))

	var is_fwd: bool = pos_s in ["ST", "LW", "RW", "CF"]
	var is_mid: bool = pos_s in ["CAM", "CM", "LM", "RM"]
	var m_cnt: int = 38 + (seed_v % 17)
	var g_cnt: int = 0
	var a_cnt: int = 0
	if is_fwd:
		g_cnt = clampi(int(round(float(ovr_v - 54) * 1.05)) + (seed_v % 13) - 4, 14, 58)
		a_cnt = clampi(int(round(float(ovr_v - 60) * 0.45)) + ((seed_v / 3) % 9), 5, 24)
	elif is_mid:
		g_cnt = clampi(int(round(float(ovr_v - 62) * 0.65)) + (seed_v % 9), 7, 29)
		a_cnt = clampi(int(round(float(ovr_v - 55) * 0.72)) + ((seed_v / 5) % 11), 10, 32)
	else:
		g_cnt = clampi(2 + (seed_v % 7), 0, 12)
		a_cnt = clampi(3 + ((seed_v / 7) % 10), 1, 14)

	# Assign realistic 1-year trophies won since previous October Ballon d'Or
	var trophies_arr: Array[String] = []
	var c_nat_id: int = clampi(int(c_dict.get("nation_id", 1)), 0, GameData.nations.size() - 1)
	var l_name: String = "LIGA " + str(GameData.nations[c_nat_id].get("name", "ELITE")).to_upper()
	var c_ovr: int = int(c_dict.get("ovr", 76))
	if c_ovr >= 82 or (seed_v % 3 == 0):
		trophies_arr.append(l_name)
	if (seed_v % 4 == 0 and ovr_v >= 84) or (c_ovr >= 85 and seed_v % 2 == 0):
		trophies_arr.append("PIALA ELITE")
	if seed_v % 5 == 1 and c_ovr >= 78:
		trophies_arr.append("PIALA DOMESTIK")
	if seed_v % 9 == 2 and nid in [1, 2, 3, 4, 5, 6, 18, 19]:
		trophies_arr.append("PIALA BENUA")
	if trophies_arr.is_empty() and ovr_v >= 86:
		trophies_arr.append(l_name)

	var pts: int = int(round(float(ovr_v) * 2.2 + float(g_cnt) * 1.45 + float(a_cnt) * 1.05 + float(trophies_arr.size()) * 14.0))
	return {
		"name": str(wp_name[wp_idx]),
		"club_id": cid,
		"club_name": cname,
		"nat": nid,
		"pos": pos_s,
		"age": age_v,
		"ovr": ovr_v,
		"seed": seed_v,
		"matches": m_cnt,
		"goals": g_cnt,
		"assists": a_cnt,
		"trophies": trophies_arr,
		"points": pts,
		"is_user": false,
	}

func _build_user_gala_candidate() -> Dictionary:
	var p: Dictionary = career.get("playerProfile", {})
	var st: Dictionary = career.get("stats", {})
	var meta: Dictionary = career.get("careerMeta", {})
	var club: Dictionary = get_current_club()
	var bw: Dictionary = meta.get("ballonWindow", {})

	var u_m: int = int(bw.get("matches", int(st.get("matches", 0))))
	var u_g: int = int(bw.get("goals", int(st.get("goals", 0))))
	var u_a: int = int(bw.get("assists", int(st.get("assists", 0))))
	var base_idx: int = int(bw.get("trophy_baseline_idx", 0))
	var t_list: Array = career.get("trophiesList", [])
	var u_trophies: Array[String] = []
	for ti in range(clampi(base_idx, 0, t_list.size()), t_list.size()):
		var tr_item: Dictionary = t_list[ti]
		var tr_nm: String = str(tr_item.get("name", "")).to_upper()
		if not tr_nm.is_empty() and not tr_nm.contains("BALLON") and not tr_nm.contains("ANAK EMAS") and not tr_nm.contains("PEMAIN MUDA"):
			u_trophies.append(tr_nm)

	var u_ovr: int = int(p.get("ovr", 64))
	var div_num: int = clampi(int(club.get("division", 3)), 1, 3)
	var div_mult: float = 1.0 if div_num == 1 else (0.76 if div_num == 2 else 0.58)
	var pts: int = int(round((float(u_ovr) * 2.2 + float(u_g) * 1.45 + float(u_a) * 1.05 + float(u_trophies.size()) * 16.0) * div_mult))
	return {
		"name": str(p.get("name", "Pemain")),
		"club_id": int(club.get("id", 0)),
		"club_name": str(club.get("name", "Klub")),
		"nat": clampi(int(p.get("nationality", 16)), 0, GameData.nations.size() - 1),
		"pos": str(p.get("favoritePosition", "ST")),
		"age": int(p.get("age", 18)),
		"ovr": u_ovr,
		"seed": 777,
		"matches": maxi(1, u_m),
		"goals": u_g,
		"assists": u_a,
		"trophies": u_trophies,
		"points": pts,
		"is_user": true,
	}

func evaluate_october_ballon_gala(commit_rewards: bool = true) -> Dictionary:
	if not has_active_career:
		return {}
	ensure_world_database()
	var meta: Dictionary = career["careerMeta"]
	var p: Dictionary = career["playerProfile"]
	var st: Dictionary = career["stats"]
	var yr: int = int(meta.get("year", 1))
	var cal_year: int = 2025 + yr
	var u_cand: Dictionary = _build_user_gala_candidate()
	var u_age: int = int(u_cand["age"])

	# 1. Gather top Ballon d'Or candidates from world players (top OVR stars)
	var bd_pool: Array[Dictionary] = []
	var u21_pool: Array[Dictionary] = []
	var seen_bd: Dictionary = {}
	var seen_u21: Dictionary = {}
	var total_wp: int = wp_name.size()
	for i in range(total_wp):
		var ov: int = int(wp_ovr[i])
		var ag: int = int(wp_age[i])
		if ov >= 84 and bd_pool.size() < 48:
			seen_bd[i] = true
			bd_pool.append(_build_gala_candidate_from_wp(i, cal_year, false))
		if ag < 21 and ov >= 74 and u21_pool.size() < 48:
			seen_u21[i] = true
			u21_pool.append(_build_gala_candidate_from_wp(i, cal_year, true))
		if bd_pool.size() >= 48 and u21_pool.size() >= 48:
			break

	# Safe deduplicated fallback scans if either pool is tight
	if bd_pool.size() < 12:
		for i in range(total_wp):
			if not seen_bd.has(i) and int(wp_ovr[i]) >= 75:
				seen_bd[i] = true
				bd_pool.append(_build_gala_candidate_from_wp(i, cal_year, false))
				if bd_pool.size() >= 20:
					break
	if u21_pool.size() < 12:
		for i in range(total_wp):
			if not seen_u21.has(i) and int(wp_age[i]) < 21 and int(wp_ovr[i]) >= 66:
				seen_u21[i] = true
				u21_pool.append(_build_gala_candidate_from_wp(i, cal_year, true))
				if u21_pool.size() >= 20:
					break

	# Insert user candidate into Ballon d'Or pool, and into U-21 pool if age < 21
	bd_pool.append(u_cand.duplicate(true))
	if u_age < 21:
		u21_pool.append(u_cand.duplicate(true))

	bd_pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["points"]) != int(b["points"]):
			return int(a["points"]) > int(b["points"])
		return int(a["goals"]) > int(b["goals"])
	)
	u21_pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["points"]) != int(b["points"]):
			return int(a["points"]) > int(b["points"])
		return int(a["goals"]) > int(b["goals"])
	)

	var ballon_top10: Array[Dictionary] = []
	var user_bd_rank: int = -1
	for i in range(mini(10, bd_pool.size())):
		var entry: Dictionary = bd_pool[i].duplicate(true)
		entry["rank"] = i + 1
		if bool(entry.get("is_user", false)):
			user_bd_rank = i + 1
		ballon_top10.append(entry)

	var youth_top10: Array[Dictionary] = []
	var user_u21_rank: int = -1
	for i in range(mini(10, u21_pool.size())):
		var entry: Dictionary = u21_pool[i].duplicate(true)
		entry["rank"] = i + 1
		if bool(entry.get("is_user", false)):
			user_u21_rank = i + 1
		youth_top10.append(entry)

	var gala_data: Dictionary = {
		"year": cal_year,
		"season": yr,
		"month_label": "OKTOBER %d • MINGGU TERAKHIR" % cal_year,
		"ballon_top10": ballon_top10,
		"youth_top10": youth_top10,
		"user_ballon_rank": user_bd_rank,
		"user_youth_rank": user_u21_rank,
	}

	if commit_rewards:
		meta["ballonGalaDoneYear"] = yr
		meta["lastBallonGala"] = gala_data
		var ghist: Array = meta.get("ballonGalaHistory", [])
		ghist.append({
			"year": cal_year,
			"ballon_winner": str(ballon_top10[0]["name"]) if not ballon_top10.is_empty() else "---",
			"youth_winner": str(youth_top10[0]["name"]) if not youth_top10.is_empty() else "---",
			"user_bd_rank": user_bd_rank,
			"user_u21_rank": user_u21_rank,
		})
		meta["ballonGalaHistory"] = ghist

		var rel: Dictionary = p.get("relations", {})
		if user_bd_rank == 1:
			var bd_title: String = "BALLON D'OR %d" % cal_year
			career["trophiesList"].append({"name": bd_title, "season": yr, "type": "INDIVIDU"})
			st["trophies"] = int(st.get("trophies", 0)) + 1
			st["potyCount"] = int(st.get("potyCount", 0)) + 1
			rel["fans"] = clampi(int(rel.get("fans", 50)) + 15, 0, 100)
			rel["pers"] = clampi(int(rel.get("pers", 50)) + 12, 0, 100)
			meta["legacyPoints"] = int(meta.get("legacyPoints", 0)) + 60
			_push_news("DUNIA", "SEJARAH! %s meraih BALLON D'OR %d di Malam Gala Oktober!" % [str(p["name"]), cal_year])
		elif user_bd_rank > 0:
			rel["fans"] = clampi(int(rel.get("fans", 50)) + 5, 0, 100)
			meta["legacyPoints"] = int(meta.get("legacyPoints", 0)) + 15
			_push_news("DUNIA", "NOMINASI BALLON D'OR %d: %s finis peringkat ke-%d dunia!" % [cal_year, str(p["name"]), user_bd_rank])
		elif not ballon_top10.is_empty():
			_push_news("DUNIA", "GALA BALLON D'OR %d: %s (%s) resmi dinobatkan sebagai peraih Ballon d'Or!" % [cal_year, str(ballon_top10[0]["name"]), str(ballon_top10[0]["club_name"])])

		if user_u21_rank == 1:
			var y_title: String = "PEMAIN MUDA TERBAIK U-21 %d" % cal_year
			career["trophiesList"].append({"name": y_title, "season": yr, "type": "INDIVIDU"})
			st["trophies"] = int(st.get("trophies", 0)) + 1
			rel["fans"] = clampi(int(rel.get("fans", 50)) + 10, 0, 100)
			rel["pers"] = clampi(int(rel.get("pers", 50)) + 8, 0, 100)
			meta["legacyPoints"] = int(meta.get("legacyPoints", 0)) + 35
			_push_news("DUNIA", "WONDERKID DUNIA! %s dinobatkan sebagai Pemain Muda Terbaik (U-21) %d!" % [str(p["name"]), cal_year])
		elif user_u21_rank > 0:
			rel["fans"] = clampi(int(rel.get("fans", 50)) + 4, 0, 100)
			_push_news("DUNIA", "NOMINASI U-21 %d: %s masuk 10 besar Pemain Muda Terbaik di posisi ke-%d!" % [cal_year, str(p["name"]), user_u21_rank])

		# Reset 1-year rolling Ballon d'Or stats window for NEXT year's October ceremony!
		meta["ballonWindow"] = {
			"matches": 0,
			"goals": 0,
			"assists": 0,
			"trophy_baseline_idx": career.get("trophiesList", []).size(),
		}
		_update_legacy_tier()

	return gala_data

func get_ballon_gala_preview_data() -> Dictionary:
	if not has_active_career:
		return {}
	var last_g: Dictionary = career.get("careerMeta", {}).get("lastBallonGala", {})
	if not last_g.is_empty() and not last_g.get("ballon_top10", []).is_empty():
		return last_g
	return evaluate_october_ballon_gala(false)
