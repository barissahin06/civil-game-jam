extends RefCounted
## Presentation-only paths; stable event IDs preserve campaign catalog fingerprints.

const EVENT_IMAGES := {
	"historical-003": "res://assets/events/1952-hasankale-depremi.jpg",
	"historical-005": "res://assets/events/1953-yenice-gonen-depremi.jpg",
	"historical-007": "res://assets/events/1955-soke-balat-depremi.jpg",
	"historical-008": "res://assets/events/1956-eskisehir-depremi.jpg",
	"historical-009": "res://assets/events/1957-fethiye-depremi.jpg",
	"historical-010": "res://assets/events/1957-abant-depremi.jpg",
	"historical-016": "res://assets/events/1966-varto-depremi.jpg",
	"historical-017": "res://assets/events/1967-mudurnu-depremi.jpg",
	"historical-018": "res://assets/events/1968-bartin-depremi.jpg",
	"historical-019": "res://assets/events/1969-alasehir-depremi.jpg",
	"historical-020": "res://assets/events/1970-gediz-depremi.jpg",
	"historical-021": "res://assets/events/1971-burdur-depremi.jpg",
	"historical-022": "res://assets/events/1971-bingol-depremi.jpg",
	"historical-023": "res://assets/events/1975-lice-depremi.jpg",
	"historical-024": "res://assets/events/1976-caldiran-depremi.jpg",
	"historical-030": "res://assets/events/1990-trabzon-seli.jpg",
	"historical-031": "res://assets/events/1992-gormec-cig-faciasi.jpg",
	"historical-032": "res://assets/events/1992-tunekpinar-cig-faciasi.jpg",
	"historical-033": "res://assets/events/1992-erzincan-depremi.jpg",
	"historical-034": "res://assets/events/1995-senirkent-sel-felaketi.jpg",
	"historical-038": "res://assets/events/1998-adana-ceyhan-depremi.jpg",
	"historical-039": "res://assets/events/1998-beskoy-seli.jpg",
	"historical-040": "res://assets/events/1999-marmara-depremi.jpg",
	"historical-041": "res://assets/events/1999-duzce-depremi.jpg",
	"historical-044": "res://assets/events/2002-cay-sultandagi-depremi.jpg",
	"historical-046": "res://assets/events/2003-bingol-depremi.jpg",
	"historical-048": "res://assets/events/2004-dogubayazit-depremi.jpg",
	"historical-051": "res://assets/events/2009-istanbul-seli.jpg",
	"historical-053": "res://assets/events/2010-gundogdu-seli.jpg",
	"historical-055": "res://assets/events/2011-van-depremi.jpg",
	"historical-058": "res://assets/events/2012-samsun-seli.jpg",
	"historical-059": "res://assets/events/2015-hopa-seli.jpg",
	"historical-060": "res://assets/events/2019-akcakoca-seli.jpg",
	"historical-062": "res://assets/events/2020-elazig-depremi.jpg",
	"historical-063": "res://assets/events/2020-van-bahcesaray-ciglari.jpg",
	"historical-066": "res://assets/events/2020-dereli-seli.jpg",
	"historical-067": "res://assets/events/2020-izmir-depremi.jpg",
	"historical-068": "res://assets/events/2021-orman-yanginlari.jpg",
	"historical-069": "res://assets/events/2021-bati-karadeniz-seli.jpg",
	"historical-071": "res://assets/events/2023-kahramanmaras-depremi.jpg",
	"historical-072": "res://assets/events/2023-hatay-depremi.jpg",
	"historical-074": "res://assets/events/2023-sanliurfa-adiyaman-seli.jpg",
	"historical-075": "res://assets/events/2023-istanbul-kirklareli-seli.jpg",
	"historical-078": "res://assets/events/2025-eskisehir-orman-yangini.jpg",
	"historical-079": "res://assets/events/2025-sindirgi-depremi.jpg",
	"historical-081": "res://assets/events/1955-ankara-sel-felaketi.jpg",
	"historical-082": "res://assets/events/1965-ankara-bentderesi-taskini.jpg",
	"historical-084": "res://assets/events/1977-palu-depremi.jpg",
	"historical-085": "res://assets/events/1982-hatay-amik-ovasi-taskini.jpg",
	"historical-087": "res://assets/events/1992-cukurca-yuksekova-ciglari.jpg",
	"historical-088": "res://assets/events/1993-bayburt-uzengili-cig-faciasi.jpg",
	"historical-089": "res://assets/events/2006-guneydogu-anadolu-seli.jpg",
	"historical-090": "res://assets/events/2007-bala-depremi.jpg",
	"historical-091": "res://assets/events/2008-tasagil-manavgat-orman-yangini.jpg",
	"historical-093": "res://assets/events/2019-bozkurt-depremi.jpg",
	"historical-094": "res://assets/events/2020-hatay-orman-yanginlari.jpg",
	"historical-095": "res://assets/events/2021-ayancik-ve-turkeli-seli.jpg",
	"historical-096": "res://assets/events/2022-bati-karadeniz-seli.jpg",
	"historical-098": "res://assets/events/2024-izmir-orman-yangini.jpg"
}
const FALLBACK_IMAGES := {
	"earthquake": "res://assets/events/_fallback_earthquake.jpg",
	"flood": "res://assets/events/_fallback_flood.jpg",
	"fire": "res://assets/events/_fallback_wildfire.jpg",
	"avalanche": "res://assets/events/_fallback_avalanche.jpg",
	"landslide": "res://assets/events/_fallback_landslide.jpg"
}


static func path_for(event: Dictionary) -> String:
	var path: String = EVENT_IMAGES.get(str(event.get("id", "")), "")
	if not path.is_empty() and ResourceLoader.exists(path, "Texture2D"):
		return path
	path = FALLBACK_IMAGES.get(str(event.get("kind", "")), "")
	return path if not path.is_empty() and ResourceLoader.exists(path, "Texture2D") else ""
