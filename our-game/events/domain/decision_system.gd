class_name DecisionSystem
extends RefCounted
## The choice survives project cancellation; project rules still belong to ProjectSystem.

const DECLINE_TITLE := "İki projeyi de reddet"
const DECLINE_DESCRIPTION := "Bu iki projeyi bu oyunda bir daha başlatamazsın."
const PROMISE_WARNING_MONTHS := 6
const PROMISE_PENALTY_MONTHS := 12
const PROMISE_MONTHLY_PENALTY := 0.1
# Display wording stays outside the fingerprinted gameplay catalog.
const FULL_TITLES := {
	"gediz_relocation": "Yerleşimi güvenli alana taşı",
	"samsun_flood": "Riskli evleri taşı, dereyi düzenle",
	"construction_inspection": "Yapı denetimini yaygınlaştır",
	"kursunlu_relocation": "İki köyü güvenli alana taşı",
	"hazard_zoning": "Yapılaşmayı denetle ve düzenle",
	"catak_relocation": "Yerleşimi güvenli konutlara taşı",
	"senirkent_flood": "Sel ve moloz için bentler kur",
	"medical_rescue": "Tıbbi kurtarmayı geliştir",
	"national_coordination": "Görev ve iletişimi düzenle",
	"istanbul_streambeds": "Riskleri belirle, dereyi düzenle",
	"silivri_school_safety": "Güvenli okullara taşı ve eğit",
	"dereli_flood": "Dere yatağını ve köprüleri düzenle",
	"izmir_risk_planning": "Ortak risk planı hazırla",
	"bozkurt_flood": "Dere, duvar ve köprüleri düzenle",
	"urban_transformation": "Riskli binaları yenile",
	"yesilyurt_training": "Uyar ve tahliye tatbikatı yap",
	"sanliurfa_flood": "Üç dereye sel koruma yapıları kur",
	"silivri_awareness": "Okul ve mahalle tatbikatları yap",
	"uzengili_relocation": "Köyü çığ riski düşük yere taşı",
	"tasagil_firebreaks": "Yangın koruma şeritleri aç",
	"hatay_fire_response": "Ekipleri eğit ve tanker hazırla"
}
const FOCUSED_COPY := {
	"gediz_relocation":
	[
		"En riskli yerleşimleri taşı",
		"En riskli yerleşimleri güvenli alanlara taşı. Bu proje daha sınırlı deprem koruması sağlar."
	],
	"samsun_flood":
	[
		"Bir arama kurtarma ekibi kur",
		"Başka afetlere de gönderebileceğin bir ekip kur. Bu proje sel hazırlığını artırmaz."
	],
	"construction_inspection":
	[
		"En riskli yapıları denetle",
		"Yapı denetimini yüksek riskli binalarla sınırla. Bu proje ülke genelinde daha sınırlı koruma sağlar."
	],
	"kursunlu_relocation":
	[
		"Yalnızca en riskli konutları taşı",
		"En riskli konutları güvenli alanlara taşı. Bu proje daha sınırlı deprem koruması sağlar."
	],
	"hazard_zoning":
	[
		"En riskli alanları denetle",
		"Denetimi en tehlikeli alanlarla sınırla. Bu proje ülke genelinde daha sınırlı koruma sağlar."
	],
	"catak_relocation":
	[
		"Yalnızca en riskli konutları taşı",
		"En riskli konutları güvenli alanlara taşı. Bu proje daha sınırlı heyelan koruması sağlar."
	],
	"senirkent_flood":
	[
		"Yalnızca kritik bentleri kur",
		"Yerleşime yakın kritik noktalara sel suyunu ve molozu tutan bentler kur. Koruma kapsamı daha sınırlıdır."
	],
	"medical_rescue":
	[
		"Tıbbi kurtarma eğitimi ver",
		"Mevcut ekiplerin eğitimini ve görev paylaşımını düzenle. Bu proje yeni ekip kurmaz."
	],
	"national_coordination":
	[
		"Ortak müdahale planı hazırla",
		"Kurumların afet sırasında nasıl görev paylaşacağını ve haberleşeceğini belirle."
	],
	"istanbul_streambeds":
	[
		"Yalnızca risk tespiti yap",
		"Dere yatağındaki riskli yapıları ve alanları belirle. Bu proje dere yatağını düzenlemez."
	],
	"silivri_school_safety":
	[
		"En riskli okulları incele",
		"Yüksek riskli okulları incele ve öğrencilerin güvenli okullara geçici taşınmasını düzenle."
	],
	"dereli_flood":
	[
		"Yalnızca kritik köprüleri düzenle",
		"Sel suyunun akışını engelleyen kritik köprü geçişlerini düzenle. Koruma kapsamı daha sınırlıdır."
	],
	"izmir_risk_planning":
	[
		"En riskli yapıları incele",
		"İncelemeyi yüksek riskli yapılar ve zeminlerle sınırla. Bu proje ortak risk planını kapsamaz."
	],
	"bozkurt_flood":
	[
		"Kritik dere geçişlerini düzenle",
		"Dere akışını daraltan kritik kesimleri ve geçişleri düzenle. Koruma kapsamı daha sınırlıdır."
	],
	"urban_transformation":
	[
		"En riskli binaları yenile",
		"Yapı dönüşümünü yüksek riskli bina gruplarıyla sınırla. Bu proje daha sınırlı koruma sağlar."
	],
	"yesilyurt_training":
	[
		"Hasarlı binalara girme diye uyar",
		"Hasarlı binalara girmenin tehlikelerini anlat. Bu proje daha geniş tatbikat programını kapsamaz."
	],
	"sanliurfa_flood":
	[
		"En riskli dere kesimlerini düzenle",
		"Dere koruma çalışmalarını en riskli kesimlerle sınırla. Koruma kapsamı daha sınırlıdır."
	],
	"silivri_awareness":
	[
		"Yalnızca afet eğitimi ver",
		"Öğrencilere temel korunma ve güvenli tahliye eğitimi ver. Bu proje mahalle tatbikatlarını kapsamaz."
	],
	"uzengili_relocation":
	[
		"Yalnızca en riskli evleri taşı",
		"En yüksek risk altındaki evleri güvenli alanlara taşı. Bu proje daha sınırlı çığ koruması sağlar."
	],
	"tasagil_firebreaks":
	[
		"Yerleşim çevresine yangın şeridi aç",
		"Yerleşim çevresinde yangının yayılmasını yavaşlatan şeritler aç. Koruma kapsamı daha sınırlıdır."
	],
	"hatay_fire_response":
	[
		"Ekiplere araç ve ekipman hazırla",
		"Mevcut ekiplere su taşıma araçları ve yangın ekipmanı hazırla. Bu proje yeni ekip kurmaz."
	]
}

var catalog: DecisionCatalog
var projects: ProjectSystem
var records: Dictionary = {}
var since_day: int = 0


func setup(content: DecisionCatalog, project_system: ProjectSystem, first_day: int) -> void:
	catalog = content
	projects = project_system
	since_day = first_day
	records.clear()


func card_for(id: String) -> Dictionary:
	for card: Dictionary in catalog.cards:
		if card.id == id:
			return card
	return {}


func offer(event_id: String, day: int) -> Array[String]:
	var offered: Array[String] = []
	if day < since_day:
		return offered
	for card: Dictionary in catalog.cards:
		if event_id in card.event_ids and not records.has(card.id):
			records[card.id] = {
				"event_id": event_id,
				"offered_day": day,
				"choice_id": "",
				"chosen_day": 0,
				"project_uid": 0,
				"last_progress_day": 0,
				"last_review_month": 0
			}
			offered.append(card.id)
	return offered


func preview(id: String) -> Dictionary:
	var card := card_for(id)
	if card.is_empty() or not records.has(id):
		return {}
	var result: Dictionary = card.duplicate(true)
	result.record = records[id].duplicate(true)
	result.scope = "ULUSAL" if int(card.area_id) == 0 else projects.areas[int(card.area_id)].name
	for option: Dictionary in result.options:
		option.title = _option_title(id, option)
		if option.id == "decline":
			option.description = DECLINE_DESCRIPTION
		elif option.id == "focused" and FOCUSED_COPY.has(id):
			option.description = FOCUSED_COPY[id][1]
		option.trust_change = 0.0
		option.cost_budget = 0
		option.months = 0
		option.installment = 0
		option.upkeep = 0
		option.queued = false
		option.effects = {"rows": []}
		if not String(option.project_id).is_empty():
			var definition := projects.definition_for(option.project_id)
			option.cost_budget = definition.cost_budget
			option.months = definition.months
			option.installment = projects.monthly_cost_for(definition.id, int(card.area_id))
			option.upkeep = definition.upkeep
			option.queued = not projects._slot_available(definition, int(card.area_id))
			for pending: ActiveProject in projects.projects:
				if pending.area_id == int(card.area_id) and pending.status == "queued":
					option.queued = true
			option.effects = projects.effect_preview(definition.id, int(card.area_id))
	return result


func choose(id: String, option_id: String, day: int, year: int) -> Dictionary:
	var card := card_for(id)
	if card.is_empty() or not records.has(id) or not String(records[id].choice_id).is_empty():
		return {"ok": false, "message": "Bu karar verilemez veya daha önce kesinleşti."}
	var selected: Dictionary = {}
	for option: Dictionary in card.options:
		if option.id == option_id:
			selected = option
	if selected.is_empty():
		return {"ok": false, "message": "Geçersiz karar seçeneği."}
	var uid := 0
	if not String(selected.project_id).is_empty():
		var order := projects.enqueue_decision(selected.project_id, int(card.area_id), year)
		if not order.ok:
			return order
		uid = int(order.uid)
	var title := _option_title(id, selected)
	records[id].choice_id = option_id
	records[id].chosen_day = day
	records[id].project_uid = uid
	records[id].last_progress_day = day if uid > 0 else 0
	records[id].last_review_month = TrustState.month_index(day) if uid > 0 else 0
	var message := (
		"İki proje de reddedildi. " + DECLINE_DESCRIPTION
		if option_id == "decline"
		else "Kalıcı karar: " + title
	)
	return {"ok": true, "message": message, "uid": uid}


func review_month(day: int, previous_progress: Dictionary) -> Array[String]:
	var notices: Array[String] = []
	var month := TrustState.month_index(day)
	for id: String in records:
		var record: Dictionary = records[id]
		if int(record.project_uid) == 0:
			continue
		var project := projects.get_project(int(record.project_uid))
		if project == null or project.status == "cancelled":
			continue
		if (
			project.progress_months
			> int(previous_progress.get(project.uid, project.progress_months))
		):
			record.last_progress_day = day
		if int(record.last_review_month) >= month:
			continue
		var previous_month := int(record.last_review_month)
		record.last_review_month = month
		if project.status == "completed":
			continue
		var previous_day := CalendarClock.date_to_day(
			"%04d-%02d-01" % [int(previous_month / 12), previous_month % 12 + 1]
		)
		var age := TrustState.elapsed_months(int(record.last_progress_day), day)
		var title := projects.definition_for(project.definition_id).title
		if (
			age >= PROMISE_WARNING_MONTHS
			and (
				TrustState.elapsed_months(int(record.last_progress_day), previous_day)
				< PROMISE_WARNING_MONTHS
			)
		):
			notices.append("Taahhüt uyarısı: %s için 6 aydır gerçek ilerleme yok." % title)
		if age >= PROMISE_PENALTY_MONTHS:
			projects.trust.change(-PROMISE_MONTHLY_PENALTY, "İlerlemeyen taahhüt: " + title)
			notices.append("İlerlemeyen taahhüt güveni azaltıyor: " + title)
	return notices


func commitment_status(uid: int, day: int) -> Dictionary:
	var result := {
		"committed": false, "idle_months": 0, "warned": false, "overdue": false, "description": ""
	}
	var project := projects.get_project(uid)
	if project == null:
		return result
	for record: Dictionary in records.values():
		if int(record.project_uid) != uid or int(record.chosen_day) > day:
			continue
		result.committed = true
		if project.status in ["cancelled", "completed"]:
			result.description = (
				"Taahhüt tamamlandı; takip kapandı."
				if project.status == "completed"
				else "Taahhüt iptal edildi; takip kapandı."
			)
			return result
		var age := TrustState.elapsed_months(int(record.last_progress_day), day)
		result.idle_months = age
		result.warned = age >= PROMISE_WARNING_MONTHS
		result.overdue = age >= PROMISE_PENALTY_MONTHS
		result.description = (
			"Açık taahhüt: %d aydır gerçek ilerleme yok. %d ayda uyarı, %d aydan itibaren aylık güven kaybı."
			% [age, PROMISE_WARNING_MONTHS, PROMISE_PENALTY_MONTHS]
		)
		return result
	return result


func _option_title(card_id: String, option: Dictionary) -> String:
	if option.id == "decline":
		return DECLINE_TITLE
	if option.id == "full" and FULL_TITLES.has(card_id):
		return FULL_TITLES[card_id]
	if option.id == "focused" and FOCUSED_COPY.has(card_id):
		return FOCUSED_COPY[card_id][0]
	return String(option.title)


func to_dict() -> Dictionary:
	return {"since_day": since_day, "records": records.duplicate(true)}


func restore(data: Variant, sim: Simulation) -> bool:
	if not data is Dictionary or not ServiceArea._integer(data.get("since_day")):
		return false
	if (
		int(data.since_day) < CalendarClock.date_to_day("%d-01-01" % sim.start_year)
		or int(data.since_day) > sim.clock.day + 1
	):
		return false
	if not data.get("records") is Dictionary or data.records.size() > catalog.cards.size():
		return false
	var restored: Dictionary = {}
	var linked: Array[int] = []
	for id: Variant in data.records:
		if not id is String:
			return false
		var card := card_for(id)
		var record: Variant = data.records[id]
		if card.is_empty() or not record is Dictionary:
			return false
		if not record.get("event_id") in card.event_ids or not record.get("choice_id") is String:
			return false
		for key: String in [
			"offered_day", "chosen_day", "project_uid", "last_progress_day", "last_review_month"
		]:
			if not ServiceArea._integer(record.get(key)):
				return false
		var report_day := _finished_day(sim, record.event_id)
		if report_day == CalendarClock.INVALID_DAY or _report_pending(sim, record.event_id):
			return false
		if (
			record.offered_day != report_day
			or record.offered_day < data.since_day
			or record.offered_day > sim.clock.day
		):
			return false
		if String(record.choice_id).is_empty():
			if (
				record.chosen_day != 0
				or record.project_uid != 0
				or record.last_progress_day != 0
				or record.last_review_month != 0
				or record.offered_day != sim.clock.day
			):
				return false
		else:
			var option: Dictionary = {}
			for candidate: Dictionary in card.options:
				if candidate.id == record.choice_id:
					option = candidate
			if (
				option.is_empty()
				or record.chosen_day != record.offered_day
				or record.chosen_day > sim.clock.day
			):
				return false
			if String(option.project_id).is_empty():
				if (
					record.project_uid != 0
					or record.last_progress_day != 0
					or record.last_review_month != 0
				):
					return false
			else:
				var project := projects.get_project(int(record.project_uid))
				if (
					project == null
					or project.definition_id != option.project_id
					or project.area_id != int(card.area_id)
					or project.uid in linked
				):
					return false
				linked.append(project.uid)
				if (
					int(record.last_progress_day) < int(record.chosen_day)
					or int(record.last_progress_day) > sim.clock.day
					or (
						int(record.last_review_month)
						< TrustState.month_index(int(record.last_progress_day))
					)
					or int(record.last_review_month) > TrustState.month_index(sim.clock.day)
					or (
						project.progress_months == 0
						and record.last_progress_day != record.chosen_day
					)
				):
					return false
				if (
					project.status == "completed"
					and not projects.is_completed(project.definition_id, project.area_id)
				):
					return false
		restored[id] = record.duplicate(true)
	for project: ActiveProject in projects.projects:
		if project.definition_id.begins_with("decision_") and not project.uid in linked:
			return false
	for area: ServiceArea in projects.areas.values():
		for id: String in area.completed_measures:
			if id.begins_with("decision_") and not _completed_project(id, area.id, linked):
				return false
	for id: String in projects.global_completed:
		if id.begins_with("decision_") and not _completed_project(id, 0, linked):
			return false
	var pending: Array[String] = []
	for item: Dictionary in sim.news_queue:
		if item.kind == "decision":
			if (
				not restored.has(item.id)
				or not String(restored[item.id].choice_id).is_empty()
				or item.id in pending
			):
				return false
			pending.append(item.id)
	for id: String in restored:
		if String(restored[id].choice_id).is_empty() != (id in pending):
			return false
	for card: Dictionary in catalog.cards:
		for event_id: String in card.event_ids:
			var finished := _finished_day(sim, event_id)
			if (
				finished >= int(data.since_day)
				and finished != CalendarClock.INVALID_DAY
				and not _report_pending(sim, event_id)
				and not restored.has(card.id)
			):
				return false
	records = restored
	since_day = int(data.since_day)
	return true


func _completed_project(id: String, area_id: int, linked: Array[int]) -> bool:
	for uid: int in linked:
		var project := projects.get_project(uid)
		if (
			project.definition_id == id
			and project.area_id == area_id
			and project.status == "completed"
		):
			return true
	return false


func _finished_day(sim: Simulation, event_id: String) -> int:
	for active: Dictionary in sim.crises.active:
		if active.event_id == event_id:
			return CalendarClock.INVALID_DAY
	var day := CalendarClock.INVALID_DAY
	for report: Dictionary in sim.crises.reports:
		if sim.report_event_id(report) == event_id:
			day = maxi(day, int(report.day))
	return day


func _report_pending(sim: Simulation, event_id: String) -> bool:
	for item: Dictionary in sim.news_queue:
		if item.kind == "report" and sim.report_event_id(sim.report_for(item.id)) == event_id:
			return true
	return false
