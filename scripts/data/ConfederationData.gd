extends RefCounted

# Real-world FIFA Confederation catalog, tournament cycles, group pots, and national rosters:
# AFC, CAF, CONCACAF, CONMEBOL, OFC, UEFA + FIFA World Cup

const CONFED_ORDER := ["AFC", "CAF", "CONCACAF", "CONMEBOL", "OFC", "UEFA"]

const CONFED_META := {
	"AFC": {
		"id": "AFC",
		"full_name": "Asian Football Confederation",
		"region": "Asia (termasuk Australia)",
		"main_tournament": "PIALA ASIA AFC",
		"secondary_tournament": "KUALIFIKASI PIALA DUNIA AFC",
		"months": "JANUARI - FEBRUARI",
		"accent": Color("#F59E0B"),
		"continental": {"teams": 24, "groups": 6, "group_size": 4, "qualify_top": 2, "knockout_start": "16 BESAR", "pots": 4},
		"wcq": {"group_size": 6, "qualify_direct": 2, "playoff_end": 4, "pots": 6, "round_label": "BABAK 3 • GRUP 6 TIM"},
	},
	"CAF": {
		"id": "CAF",
		"full_name": "Confederation Africaine de Football",
		"region": "Afrika",
		"main_tournament": "PIALA NEGARA AFRIKA (AFCON)",
		"secondary_tournament": "KUALIFIKASI PIALA DUNIA CAF",
		"months": "JANUARI - FEBRUARI",
		"accent": Color("#22C55E"),
		"continental": {"teams": 24, "groups": 6, "group_size": 4, "qualify_top": 2, "knockout_start": "16 BESAR", "pots": 4},
		"wcq": {"group_size": 6, "qualify_direct": 1, "playoff_end": 2, "pots": 6, "round_label": "FASE GRUP • 9 GRUP x 6 TIM"},
	},
	"CONCACAF": {
		"id": "CONCACAF",
		"full_name": "Confederation of North, Central American & Caribbean",
		"region": "Amerika Utara, Tengah & Karibia",
		"main_tournament": "PIALA EMAS CONCACAF",
		"secondary_tournament": "CONCACAF NATIONS LEAGUE",
		"months": "JUNI - JULI (2 TAHUNAN)",
		"accent": Color("#EAB308"),
		"continental": {"teams": 16, "groups": 4, "group_size": 4, "qualify_top": 2, "knockout_start": "8 BESAR", "pots": 4},
		"wcq": {"group_size": 4, "qualify_direct": 1, "playoff_end": 2, "pots": 4, "round_label": "BABAK 3 • 3 GRUP x 4 TIM"},
	},
	"CONMEBOL": {
		"id": "CONMEBOL",
		"full_name": "Confederacion Sudamericana de Futbol",
		"region": "Amerika Selatan",
		"main_tournament": "COPA AMERICA",
		"secondary_tournament": "KUALIFIKASI PIALA DUNIA CONMEBOL",
		"months": "JUNI - JULI",
		"accent": Color("#38BDF8"),
		"continental": {"teams": 16, "groups": 4, "group_size": 4, "qualify_top": 2, "knockout_start": "8 BESAR", "pots": 4},
		"wcq": {"group_size": 10, "qualify_direct": 6, "playoff_end": 7, "pots": 5, "round_label": "LIGA TUNGGAL • 10 TIM"},
	},
	"OFC": {
		"id": "OFC",
		"full_name": "Oceania Football Confederation",
		"region": "Oseania",
		"main_tournament": "PIALA NEGARA OFC",
		"secondary_tournament": "KUALIFIKASI PIALA DUNIA OFC",
		"months": "JUNI",
		"accent": Color("#14B8A6"),
		"continental": {"teams": 8, "groups": 2, "group_size": 4, "qualify_top": 2, "knockout_start": "SEMI FINAL", "pots": 4},
		"wcq": {"group_size": 4, "qualify_direct": 1, "playoff_end": 2, "pots": 4, "round_label": "BABAK 2 • 2 GRUP x 4 TIM"},
	},
	"UEFA": {
		"id": "UEFA",
		"full_name": "Union of European Football Associations",
		"region": "Eropa",
		"main_tournament": "PIALA EROPA (UEFA EURO)",
		"secondary_tournament": "UEFA NATIONS LEAGUE",
		"months": "JUNI - JULI",
		"accent": Color("#6366F1"),
		"continental": {"teams": 24, "groups": 6, "group_size": 4, "qualify_top": 2, "knockout_start": "16 BESAR", "pots": 4},
		"wcq": {"group_size": 5, "qualify_direct": 1, "playoff_end": 2, "pots": 5, "round_label": "FASE GRUP • 12 GRUP x 4-5 TIM"},
	},
}

# Authentic FIFA-ranked national team pools per confederation (ordered by strength for accurate Pot seeding)
const CONFED_TEAMS := {
	"AFC": [
		{"code": "JPN", "name": "Jepang", "ovr": 81, "colors": [Color("#00235D"), Color("#FFFFFF")]},
		{"code": "IRN", "name": "Iran", "ovr": 79, "colors": [Color("#239F40"), Color("#DA0000")]},
		{"code": "KOR", "name": "Korea Selatan", "ovr": 80, "colors": [Color("#FFFFFF"), Color("#CD2E3A")]},
		{"code": "AUS", "name": "Australia", "ovr": 77, "colors": [Color("#00008B"), Color("#FFCD00")]},
		{"code": "QAT", "name": "Qatar", "ovr": 74, "colors": [Color("#8A1538"), Color("#FFFFFF")]},
		{"code": "KSA", "name": "Arab Saudi", "ovr": 75, "colors": [Color("#006C35"), Color("#FFFFFF")]},
		{"code": "UZB", "name": "Uzbekistan", "ovr": 73, "colors": [Color("#0099B5"), Color("#1EB53A")]},
		{"code": "IRQ", "name": "Irak", "ovr": 72, "colors": [Color("#CE1126"), Color("#111111")]},
		{"code": "JOR", "name": "Yordania", "ovr": 71, "colors": [Color("#111111"), Color("#007A3D")]},
		{"code": "UAE", "name": "Uni Emirat Arab", "ovr": 70, "colors": [Color("#00732F"), Color("#FF0000")]},
		{"code": "OMA", "name": "Oman", "ovr": 69, "colors": [Color("#DB161B"), Color("#008000")]},
		{"code": "SYR", "name": "Suriah", "ovr": 67, "colors": [Color("#CE1126"), Color("#111111")]},
		{"code": "BHR", "name": "Bahrain", "ovr": 68, "colors": [Color("#CE1126"), Color("#FFFFFF")]},
		{"code": "CHN", "name": "Tiongkok", "ovr": 68, "colors": [Color("#DE2910"), Color("#FFDE00")]},
		{"code": "THA", "name": "Thailand", "ovr": 66, "colors": [Color("#A51931"), Color("#2D2A4A")]},
		{"code": "VIE", "name": "Vietnam", "ovr": 65, "colors": [Color("#DA251D"), Color("#FFFF00")]},
		{"code": "IDN", "name": "Indonesia", "ovr": 66, "colors": [Color("#CE1126"), Color("#FFFFFF")]},
		{"code": "LBN", "name": "Lebanon", "ovr": 64, "colors": [Color("#ED1C24"), Color("#FFFFFF")]},
		{"code": "MAS", "name": "Malaysia", "ovr": 63, "colors": [Color("#010066"), Color("#CC0001")]},
		{"code": "IND", "name": "India", "ovr": 62, "colors": [Color("#FF9933"), Color("#138808")]},
		{"code": "PRK", "name": "Korea Utara", "ovr": 63, "colors": [Color("#024FA2"), Color("#ED1C27")]},
		{"code": "KUW", "name": "Kuwait", "ovr": 62, "colors": [Color("#007A3D"), Color("#CE1126")]},
		{"code": "PHI", "name": "Filipina", "ovr": 60, "colors": [Color("#0038A8"), Color("#CE1126")]},
		{"code": "SGP", "name": "Singapura", "ovr": 59, "colors": [Color("#EF3340"), Color("#FFFFFF")]},
	],
	"CAF": [
		{"code": "MAR", "name": "Maroko", "ovr": 82, "colors": [Color("#C1272D"), Color("#006233")]},
		{"code": "SEN", "name": "Senegal", "ovr": 80, "colors": [Color("#00853F"), Color("#FDEF42")]},
		{"code": "EGY", "name": "Mesir", "ovr": 78, "colors": [Color("#CE1126"), Color("#111111")]},
		{"code": "NGA", "name": "Nigeria", "ovr": 79, "colors": [Color("#008751"), Color("#FFFFFF")]},
		{"code": "CIV", "name": "Pantai Gading", "ovr": 78, "colors": [Color("#F77F00"), Color("#009E60")]},
		{"code": "ALG", "name": "Aljazair", "ovr": 77, "colors": [Color("#006233"), Color("#FFFFFF")]},
		{"code": "CMR", "name": "Kamerun", "ovr": 76, "colors": [Color("#007A5E"), Color("#CE1126")]},
		{"code": "TUN", "name": "Tunisia", "ovr": 74, "colors": [Color("#E70013"), Color("#FFFFFF")]},
		{"code": "MLI", "name": "Mali", "ovr": 74, "colors": [Color("#14B53A"), Color("#FCD116")]},
		{"code": "GHA", "name": "Ghana", "ovr": 74, "colors": [Color("#CF0921"), Color("#FCD20F")]},
		{"code": "RSA", "name": "Afrika Selatan", "ovr": 72, "colors": [Color("#007749"), Color("#FFB81C")]},
		{"code": "COD", "name": "RD Kongo", "ovr": 73, "colors": [Color("#007FFF"), Color("#F7D618")]},
		{"code": "BFA", "name": "Burkina Faso", "ovr": 71, "colors": [Color("#EF2B2D"), Color("#009E49")]},
		{"code": "GUI", "name": "Guinea", "ovr": 70, "colors": [Color("#CE1126"), Color("#009460")]},
		{"code": "CPV", "name": "Tanjung Verde", "ovr": 69, "colors": [Color("#003893"), Color("#CF2027")]},
		{"code": "ANG", "name": "Angola", "ovr": 68, "colors": [Color("#CC092F"), Color("#111111")]},
		{"code": "GAB", "name": "Gabon", "ovr": 68, "colors": [Color("#009E60"), Color("#FCD116")]},
		{"code": "ZAM", "name": "Zambia", "ovr": 67, "colors": [Color("#198A00"), Color("#DE2010")]},
	],
	"CONCACAF": [
		{"code": "USA", "name": "Amerika Serikat", "ovr": 80, "colors": [Color("#B22234"), Color("#3C3B6E")]},
		{"code": "MEX", "name": "Meksiko", "ovr": 79, "colors": [Color("#006847"), Color("#CE1126")]},
		{"code": "CAN", "name": "Kanada", "ovr": 77, "colors": [Color("#FF0000"), Color("#FFFFFF")]},
		{"code": "PAN", "name": "Panama", "ovr": 73, "colors": [Color("#DA121A"), Color("#072357")]},
		{"code": "CRC", "name": "Kosta Rika", "ovr": 72, "colors": [Color("#002B7F"), Color("#CE1126")]},
		{"code": "JAM", "name": "Jamaika", "ovr": 71, "colors": [Color("#009B3A"), Color("#FED100")]},
		{"code": "HON", "name": "Honduras", "ovr": 69, "colors": [Color("#00BCE4"), Color("#FFFFFF")]},
		{"code": "SLV", "name": "El Salvador", "ovr": 67, "colors": [Color("#0F47AF"), Color("#FFFFFF")]},
		{"code": "GUA", "name": "Guatemala", "ovr": 67, "colors": [Color("#4997D0"), Color("#FFFFFF")]},
		{"code": "HAI", "name": "Haiti", "ovr": 66, "colors": [Color("#00209F"), Color("#D21034")]},
		{"code": "TRI", "name": "Trinidad & Tobago", "ovr": 66, "colors": [Color("#DA1A35"), Color("#111111")]},
		{"code": "CUW", "name": "Curacao", "ovr": 65, "colors": [Color("#002B7F"), Color("#F9E814")]},
		{"code": "SUR", "name": "Suriname", "ovr": 65, "colors": [Color("#377E3F"), Color("#B40A2D")]},
		{"code": "NCA", "name": "Nikaragua", "ovr": 63, "colors": [Color("#0067C6"), Color("#FFFFFF")]},
		{"code": "DOM", "name": "Rep. Dominika", "ovr": 63, "colors": [Color("#002D62"), Color("#CE1126")]},
		{"code": "CUB", "name": "Kuba", "ovr": 62, "colors": [Color("#002A8F"), Color("#CF142B")]},
	],
	"CONMEBOL": [
		{"code": "ARG", "name": "Argentina", "ovr": 87, "colors": [Color("#74ACDF"), Color("#FFFFFF")]},
		{"code": "BRA", "name": "Brasil", "ovr": 86, "colors": [Color("#009C3B"), Color("#FFDF00")]},
		{"code": "URU", "name": "Uruguay", "ovr": 83, "colors": [Color("#5B9BD5"), Color("#FFFFFF")]},
		{"code": "COL", "name": "Kolombia", "ovr": 82, "colors": [Color("#FCD116"), Color("#003893")]},
		{"code": "ECU", "name": "Ekuador", "ovr": 78, "colors": [Color("#FFD100"), Color("#034EA2")]},
		{"code": "CHI", "name": "Chili", "ovr": 76, "colors": [Color("#0039A6"), Color("#D52B1E")]},
		{"code": "PAR", "name": "Paraguay", "ovr": 75, "colors": [Color("#D52B1E"), Color("#0038A8")]},
		{"code": "PER", "name": "Peru", "ovr": 74, "colors": [Color("#D91023"), Color("#FFFFFF")]},
		{"code": "VEN", "name": "Venezuela", "ovr": 74, "colors": [Color("#CF142B"), Color("#FFCC00")]},
		{"code": "BOL", "name": "Bolivia", "ovr": 70, "colors": [Color("#D52B1E"), Color("#007934")]},
	],
	"OFC": [
		{"code": "NZL", "name": "Selandia Baru", "ovr": 71, "colors": [Color("#00247D"), Color("#CC142B")]},
		{"code": "TAH", "name": "Tahiti", "ovr": 62, "colors": [Color("#CE1126"), Color("#FFFFFF")]},
		{"code": "FIJ", "name": "Fiji", "ovr": 61, "colors": [Color("#68BFE5"), Color("#CE1126")]},
		{"code": "NCL", "name": "Kaledonia Baru", "ovr": 61, "colors": [Color("#0035AD"), Color("#009543")]},
		{"code": "PNG", "name": "Papua Nugini", "ovr": 60, "colors": [Color("#CE1126"), Color("#111111")]},
		{"code": "SOL", "name": "Kep. Solomon", "ovr": 59, "colors": [Color("#0051BA"), Color("#215B33")]},
		{"code": "VAN", "name": "Vanuatu", "ovr": 59, "colors": [Color("#D21034"), Color("#009543")]},
		{"code": "SAM", "name": "Samoa", "ovr": 57, "colors": [Color("#CE1126"), Color("#002B7F")]},
	],
	"UEFA": [
		{"code": "ESP", "name": "Spanyol", "ovr": 87, "colors": [Color("#C60B1E"), Color("#FFC400")]},
		{"code": "FRA", "name": "Prancis", "ovr": 87, "colors": [Color("#0055A4"), Color("#EF4135")]},
		{"code": "ENG", "name": "Inggris", "ovr": 86, "colors": [Color("#FFFFFF"), Color("#CE1124")]},
		{"code": "GER", "name": "Jerman", "ovr": 85, "colors": [Color("#111111"), Color("#DD0000")]},
		{"code": "POR", "name": "Portugal", "ovr": 85, "colors": [Color("#006600"), Color("#DA291C")]},
		{"code": "NED", "name": "Belanda", "ovr": 84, "colors": [Color("#AE1C28"), Color("#21468B")]},
		{"code": "ITA", "name": "Italia", "ovr": 83, "colors": [Color("#009246"), Color("#CE2B37")]},
		{"code": "BEL", "name": "Belgia", "ovr": 82, "colors": [Color("#111111"), Color("#FDDA24")]},
		{"code": "CRO", "name": "Kroasia", "ovr": 81, "colors": [Color("#FF0000"), Color("#171796")]},
		{"code": "SUI", "name": "Swiss", "ovr": 79, "colors": [Color("#DA291C"), Color("#FFFFFF")]},
		{"code": "DEN", "name": "Denmark", "ovr": 79, "colors": [Color("#C60C30"), Color("#FFFFFF")]},
		{"code": "AUT", "name": "Austria", "ovr": 78, "colors": [Color("#ED2939"), Color("#FFFFFF")]},
		{"code": "TUR", "name": "Turki", "ovr": 78, "colors": [Color("#E30A17"), Color("#FFFFFF")]},
		{"code": "SWE", "name": "Swedia", "ovr": 77, "colors": [Color("#005293"), Color("#FECB00")]},
		{"code": "NOR", "name": "Norwegia", "ovr": 77, "colors": [Color("#BA0C2F"), Color("#00205B")]},
		{"code": "SRB", "name": "Serbia", "ovr": 77, "colors": [Color("#C6363C"), Color("#0C4076")]},
		{"code": "POL", "name": "Polandia", "ovr": 76, "colors": [Color("#FFFFFF"), Color("#DC143C")]},
		{"code": "UKR", "name": "Ukraina", "ovr": 76, "colors": [Color("#0057B7"), Color("#FFD700")]},
		{"code": "CZE", "name": "Ceko", "ovr": 75, "colors": [Color("#FFFFFF"), Color("#D7141A")]},
		{"code": "SCO", "name": "Skotlandia", "ovr": 75, "colors": [Color("#005EB8"), Color("#FFFFFF")]},
		{"code": "GRE", "name": "Yunani", "ovr": 75, "colors": [Color("#0D5EAF"), Color("#FFFFFF")]},
		{"code": "HUN", "name": "Hungaria", "ovr": 74, "colors": [Color("#CE2939"), Color("#477050")]},
		{"code": "WAL", "name": "Wales", "ovr": 74, "colors": [Color("#FFFFFF"), Color("#00AB39")]},
		{"code": "ROU", "name": "Rumania", "ovr": 73, "colors": [Color("#002B7F"), Color("#FCD116")]},
	],
}

static func get_nation_confederation_by_code(code: String) -> String:
	var c: String = code.to_upper()
	if c in ["IDN", "JPN", "KOR", "AUS", "KSA", "IRN", "QAT", "MAS", "THA", "VIE", "SGP", "PHI", "OMA", "SYR", "LBN", "UZB", "IRQ", "JOR", "UAE", "BHR", "CHN", "IND", "PRK", "KUW"]:
		return "AFC"
	if c in ["EGY", "MAR", "NGA", "SEN", "CIV", "ALG", "CMR", "TUN", "MLI", "GHA", "RSA", "COD", "BFA", "GUI", "CPV", "ANG", "GAB", "ZAM"]:
		return "CAF"
	if c in ["USA", "MEX", "CAN", "PAN", "CRC", "JAM", "HON", "SLV", "GUA", "HAI", "TRI", "CUW", "SUR", "NCA", "DOM", "CUB"]:
		return "CONCACAF"
	if c in ["BRA", "ARG", "COL", "URU", "CHI", "PER", "ECU", "PAR", "VEN", "BOL"]:
		return "CONMEBOL"
	if c in ["NZL", "TAH", "FIJ", "NCL", "PNG", "SOL", "VAN", "SAM"]:
		return "OFC"
	return "UEFA"

static func get_nation_confederation(nat_id: int) -> String:
	var idx: int = clampi(nat_id, 0, GameData.nations.size() - 1)
	var code: String = str(GameData.nations[idx].get("code", "UEFA"))
	return get_nation_confederation_by_code(code)

static func get_confed_teams_with_pots(confed: String, pot_count: int = 4) -> Array[Dictionary]:
	var raw: Array = CONFED_TEAMS.get(confed, CONFED_TEAMS["UEFA"])
	var out: Array[Dictionary] = []
	var n: int = raw.size()
	var per_pot: int = maxi(1, int(ceil(float(n) / float(maxi(1, pot_count)))))
	for i in range(n):
		var item: Dictionary = raw[i]
		var pot_num: int = clampi(int(i / per_pot) + 1, 1, pot_count)
		out.append({
			"code": str(item["code"]),
			"name": str(item["name"]),
			"ovr": int(item["ovr"]),
			"colors": item["colors"],
			"pot": pot_num,
		})
	return out

static func get_season_campaign(confed: String, year: int, wc_qualified: bool = false) -> Dictionary:
	var cyc: int = ((maxi(1, year) - 1) % 4) + 1  # 1, 2, 3, 4
	var meta: Dictionary = CONFED_META.get(confed, CONFED_META["UEFA"])
	var c_fmt: Dictionary = meta["continental"]
	var w_fmt: Dictionary = meta["wcq"]

	# Year 4 (4, 8, 12...): FIFA World Cup if qualified, otherwise Continental Qualifiers!
	if cyc == 4:
		if wc_qualified:
			return {
				"id": "WORLD_CUP",
				"kind": "WORLD_CUP",
				"confed": "FIFA",
				"title": "PIALA DUNIA FIFA",
				"short_title": "PIALA DUNIA",
				"months": "MEI - JUNI",
				"group_size": 4,
				"qualify_top": 2,
				"playoff_end": 2,
				"pot_count": 4,
				"has_knockout": true,
				"knockout_start": "16 BESAR",
				"group_weeks": [36, 38, 40],
				"ko_weeks": [41, 42, 43, 44],
				"format_note": "48 Tim • 4 Pot • Top 2 Lolos ke 16 Besar",
			}
		return {
			"id": "WCQ_PLAYOFF",
			"kind": "WCQ",
			"confed": confed,
			"title": "KUALIFIKASI %s" % str(meta["main_tournament"]),
			"short_title": "KUALIFIKASI",
			"months": "SEP - MAR",
			"group_size": mini(6, int(w_fmt["group_size"])),
			"qualify_top": int(w_fmt["qualify_direct"]),
			"playoff_end": int(w_fmt["playoff_end"]),
			"pot_count": int(w_fmt["pots"]),
			"has_knockout": false,
			"knockout_start": "",
			"group_weeks": [8, 14, 20, 28, 34, 40],
			"ko_weeks": [],
			"format_note": str(w_fmt["round_label"]),
		}

	match confed:
		"AFC":
			if cyc == 1:
				return {
					"id": "AFC_ASIAN_CUP",
					"kind": "CONTINENTAL",
					"confed": "AFC",
					"title": "PIALA ASIA AFC",
					"short_title": "PIALA ASIA",
					"months": "JANUARI - FEBRUARI",
					"group_size": 4,
					"qualify_top": 2,
					"playoff_end": 2,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "16 BESAR",
					"group_weeks": [23, 25, 27],
					"ko_weeks": [29, 31, 33, 35],
					"format_note": "24 Tim • 4 Pot • Top 2 Lolos ke 16 Besar",
				}
			return {
				"id": "AFC_WCQ",
				"kind": "WCQ",
				"confed": "AFC",
				"title": "KUALIFIKASI PIALA DUNIA (AFC)",
				"short_title": "KUALIFIKASI",
				"months": "SEP - JUN (FIFA MATCHDAY)",
				"group_size": 6,
				"qualify_top": 2,
				"playoff_end": 4,
				"pot_count": 6,
				"has_knockout": false,
				"knockout_start": "",
				"group_weeks": [8, 14, 18, 26, 34, 40],
				"ko_weeks": [],
				"format_note": "Babak 3 AFC • 6 Pot • 2 Teratas Lolos Piala Dunia",
			}
		"CAF":
			if cyc == 1:
				return {
					"id": "CAF_AFCON",
					"kind": "CONTINENTAL",
					"confed": "CAF",
					"title": "PIALA NEGARA AFRIKA (AFCON)",
					"short_title": "AFCON",
					"months": "JANUARI - FEBRUARI",
					"group_size": 4,
					"qualify_top": 2,
					"playoff_end": 2,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "16 BESAR",
					"group_weeks": [23, 25, 27],
					"ko_weeks": [29, 31, 33, 35],
					"format_note": "24 Tim • 4 Pot • Top 2 Lolos ke 16 Besar",
				}
			return {
				"id": "CAF_WCQ",
				"kind": "WCQ",
				"confed": "CAF",
				"title": "KUALIFIKASI PIALA DUNIA (CAF)",
				"short_title": "KUALIFIKASI",
				"months": "SEP - MAR (FIFA MATCHDAY)",
				"group_size": 6,
				"qualify_top": 1,
				"playoff_end": 2,
				"pot_count": 6,
				"has_knockout": false,
				"knockout_start": "",
				"group_weeks": [8, 14, 18, 26, 34, 40],
				"ko_weeks": [],
				"format_note": "9 Grup x 6 Tim • 6 Pot • Juara Grup Lolos Piala Dunia",
			}
		"CONCACAF":
			if cyc == 1 or cyc == 3:
				return {
					"id": "CONCACAF_GOLD_CUP",
					"kind": "CONTINENTAL",
					"confed": "CONCACAF",
					"title": "PIALA EMAS CONCACAF",
					"short_title": "GOLD CUP",
					"months": "MEI - JUNI (2 TAHUNAN)",
					"group_size": 4,
					"qualify_top": 2,
					"playoff_end": 2,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "8 BESAR",
					"group_weeks": [36, 38, 40],
					"ko_weeks": [41, 43, 44],
					"format_note": "16 Tim • 4 Pot • Top 2 Lolos ke 8 Besar",
				}
			return {
				"id": "CONCACAF_WCQ",
				"kind": "WCQ",
				"confed": "CONCACAF",
				"title": "KUALIFIKASI PIALA DUNIA (CONCACAF)",
				"short_title": "KUALIFIKASI",
				"months": "SEP - MAR (FIFA MATCHDAY)",
				"group_size": 4,
				"qualify_top": 1,
				"playoff_end": 2,
				"pot_count": 4,
				"has_knockout": false,
				"knockout_start": "",
				"group_weeks": [8, 14, 18, 26, 34, 40],
				"ko_weeks": [],
				"format_note": "Babak 3 CONCACAF • 4 Pot • Juara Grup Lolos",
			}
		"CONMEBOL":
			if cyc == 2:
				return {
					"id": "CONMEBOL_COPA",
					"kind": "CONTINENTAL",
					"confed": "CONMEBOL",
					"title": "COPA AMERICA",
					"short_title": "COPA AMERICA",
					"months": "MEI - JUNI",
					"group_size": 4,
					"qualify_top": 2,
					"playoff_end": 2,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "8 BESAR",
					"group_weeks": [36, 38, 40],
					"ko_weeks": [41, 43, 44],
					"format_note": "16 Tim • 4 Pot • Top 2 Lolos ke 8 Besar",
				}
			return {
				"id": "CONMEBOL_WCQ",
				"kind": "WCQ",
				"confed": "CONMEBOL",
				"title": "KUALIFIKASI PIALA DUNIA (CONMEBOL)",
				"short_title": "KUALIFIKASI",
				"months": "SEP - MAR (FIFA MATCHDAY)",
				"group_size": 10,
				"qualify_top": 6,
				"playoff_end": 7,
				"pot_count": 5,
				"has_knockout": false,
				"knockout_start": "",
				"group_weeks": [8, 14, 18, 26, 34, 40],
				"ko_weeks": [],
				"format_note": "10 Tim Liga Tunggal • Top 6 Lolos Piala Dunia, #7 Playoff",
			}
		"OFC":
			if cyc == 1:
				return {
					"id": "OFC_NATIONS_CUP",
					"kind": "CONTINENTAL",
					"confed": "OFC",
					"title": "PIALA NEGARA OFC",
					"short_title": "OFC CUP",
					"months": "MEI - JUNI",
					"group_size": 4,
					"qualify_top": 2,
					"playoff_end": 2,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "SEMI FINAL",
					"group_weeks": [37, 39, 41],
					"ko_weeks": [43, 44],
					"format_note": "8 Tim • 4 Pot • Top 2 Lolos ke Semi Final",
				}
			return {
				"id": "OFC_WCQ",
				"kind": "WCQ",
				"confed": "OFC",
				"title": "KUALIFIKASI PIALA DUNIA (OFC)",
				"short_title": "KUALIFIKASI",
				"months": "OKT - MAR",
				"group_size": 4,
				"qualify_top": 1,
				"playoff_end": 2,
				"pot_count": 4,
				"has_knockout": false,
				"knockout_start": "",
				"group_weeks": [10, 18, 28, 34],
				"ko_weeks": [],
				"format_note": "2 Grup x 4 Tim • Juara Lolos Langsung ke Piala Dunia",
			}
		_:
			# UEFA
			if cyc == 1:
				return {
					"id": "UEFA_NATIONS_LEAGUE",
					"kind": "NATIONS_LEAGUE",
					"confed": "UEFA",
					"title": "UEFA NATIONS LEAGUE",
					"short_title": "NATIONS LEAGUE",
					"months": "SEP - JUN",
					"group_size": 4,
					"qualify_top": 1,
					"playoff_end": 1,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "SEMI FINAL",
					"group_weeks": [8, 14, 18],
					"ko_weeks": [34, 38],
					"format_note": "Liga A/B • 4 Pot • Juara Grup ke Final Four",
				}
			if cyc == 2:
				return {
					"id": "UEFA_EURO",
					"kind": "CONTINENTAL",
					"confed": "UEFA",
					"title": "PIALA EROPA (UEFA EURO)",
					"short_title": "UEFA EURO",
					"months": "MEI - JUNI",
					"group_size": 4,
					"qualify_top": 2,
					"playoff_end": 2,
					"pot_count": 4,
					"has_knockout": true,
					"knockout_start": "16 BESAR",
					"group_weeks": [36, 38, 40],
					"ko_weeks": [41, 42, 43, 44],
					"format_note": "24 Tim • 4 Pot • Top 2 Lolos ke 16 Besar",
				}
			return {
				"id": "UEFA_WCQ",
				"kind": "WCQ",
				"confed": "UEFA",
				"title": "KUALIFIKASI PIALA DUNIA (UEFA)",
				"short_title": "KUALIFIKASI",
				"months": "SEP - MAR (FIFA MATCHDAY)",
				"group_size": 5,
				"qualify_top": 1,
				"playoff_end": 2,
				"pot_count": 5,
				"has_knockout": false,
				"knockout_start": "",
				"group_weeks": [8, 14, 18, 26, 34, 40],
				"ko_weeks": [],
				"format_note": "12 Grup x 4-5 Tim • 5 Pot • Juara Grup Lolos Piala Dunia",
			}

static func build_world_cup_pool() -> Array[Dictionary]:
	# 16 strongest global teams across all 6 confederations for World Cup draw
	var pool: Array[Dictionary] = []
	var quotas := {"UEFA": 6, "CONMEBOL": 3, "AFC": 3, "CAF": 2, "CONCACAF": 1, "OFC": 1}
	for cid in CONFED_ORDER:
		var q: int = int(quotas.get(cid, 1))
		var list: Array = CONFED_TEAMS.get(cid, [])
		for i in range(mini(q, list.size())):
			var t: Dictionary = list[i]
			pool.append({"code": str(t["code"]), "name": str(t["name"]), "ovr": int(t["ovr"]), "colors": t["colors"], "pot": (i % 4) + 1})
	return pool

static func build_seeded_group(confed: String, campaign: Dictionary, user_code: String, user_name: String, user_colors: Array, seed_val: int) -> Dictionary:
	var g_size: int = int(campaign.get("group_size", 4))
	var pot_cnt: int = int(campaign.get("pot_count", 4))
	var is_wc: bool = (str(campaign.get("kind", "")) == "WORLD_CUP")
	var pool: Array[Dictionary] = build_world_cup_pool() if is_wc else get_confed_teams_with_pots(confed, pot_cnt)

	var user_entry: Dictionary = {}
	for t in pool:
		if str(t["code"]).to_upper() == user_code.to_upper():
			user_entry = t.duplicate(true)
			break
	if user_entry.is_empty():
		user_entry = {"code": user_code.to_upper(), "name": user_name, "ovr": 68, "colors": user_colors, "pot": clampi(pot_cnt, 1, pot_cnt)}

	# CONMEBOL WCQ uses all 10 member nations in a single league table!
	if confed == "CONMEBOL" and g_size >= 10:
		var table10: Array[Dictionary] = []
		var has_u := false
		for t in pool:
			var is_u: bool = (str(t["code"]).to_upper() == user_code.to_upper())
			if is_u:
				has_u = true
			table10.append(_make_group_row(t, is_u))
		if not has_u:
			table10[table10.size() - 1] = _make_group_row(user_entry, true)
		return {"group_name": "KLASEMEN", "user_pot": int(user_entry["pot"]), "rows": table10}

	# Standard Pot-based draw: 1 team from each pot!
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var user_pot: int = clampi(int(user_entry.get("pot", 2)), 1, pot_cnt)
	var picked: Array[Dictionary] = [_make_group_row(user_entry, true)]
	var used_codes: Dictionary = {str(user_entry["code"]): true}

	for p in range(1, pot_cnt + 1):
		if p == user_pot:
			continue
		if picked.size() >= g_size:
			break
		var pot_cands: Array[Dictionary] = []
		for t in pool:
			if int(t["pot"]) == p and not used_codes.has(str(t["code"])):
				pot_cands.append(t)
		if not pot_cands.is_empty():
			var ch: Dictionary = pot_cands[rng.randi_range(0, pot_cands.size() - 1)]
			used_codes[str(ch["code"])] = true
			picked.append(_make_group_row(ch, false))

	# Fill any remaining spots if group_size > pot_count
	for t in pool:
		if picked.size() >= g_size:
			break
		if not used_codes.has(str(t["code"])):
			used_codes[str(t["code"])] = true
			picked.append(_make_group_row(t, false))

	picked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["pot"]) < int(b["pot"])
	)
	var grp_letters := ["GRUP A", "GRUP B", "GRUP C", "GRUP D", "GRUP E", "GRUP F"]
	var gname: String = grp_letters[abs(seed_val) % grp_letters.size()]
	return {"group_name": gname, "user_pot": user_pot, "rows": picked}

static func _make_group_row(t: Dictionary, is_user: bool) -> Dictionary:
	var raw_cols: Array = t.get("colors", [Color("#2563EB"), Color("#FFFFFF")])
	var hex_cols: Array[String] = []
	for rc in raw_cols:
		if rc is Color:
			hex_cols.append("#" + (rc as Color).to_html(false))
		else:
			hex_cols.append(str(rc))
	return {
		"code": str(t["code"]).to_upper(),
		"name": str(t["name"]),
		"ovr": int(t.get("ovr", 68)),
		"pot": int(t.get("pot", 2)),
		"colors": hex_cols,
		"p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0, "form": [],
		"is_user": is_user,
	}
