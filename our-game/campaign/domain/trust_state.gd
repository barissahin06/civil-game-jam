class_name TrustState
extends RefCounted

var value: float = 100.0
var history: Array[Dictionary] = []

const MONTHLY_BASE_DECAY := 0.015
const MONTHLY_DAMAGE_DECAY_PER_POINT := 0.0015


func change(amount: float, reason: String) -> void:
	assert(is_finite(amount))
	var previous := value
	value = clampf(value + amount, 0.0, 100.0)
	if not is_equal_approx(previous, value):
		history.append({"amount": value - previous, "reason": reason})
		if history.size() > 200:
			history.pop_front()


func decay_month(reduction: float = 0.0, unresolved_damage: float = 0.0) -> void:
	change(-MONTHLY_BASE_DECAY * (1.0 - clampf(reduction, 0.0, 0.85)), "Aylık güven aşınması")
	if unresolved_damage > 0.0:
		change(
			-clampf(unresolved_damage, 0.0, 100.0) * MONTHLY_DAMAGE_DECAY_PER_POINT,
			"Onarılmayan altyapının güven etkisi"
		)


func assess_response(
	preparation: float, response: float, teams: float, aid: float, reason: String
) -> float:
	var adjustment := clampf(
		(
			3.0 * (clampf(response, 0.0, 1.0) - 0.65)
			+ 0.8 * (clampf(preparation, 0.0, 1.0) - 0.35)
			- 0.6 * (1.0 - clampf(teams, 0.0, 1.0))
			- 1.2 * (1.0 - clampf(aid, 0.0, 1.0))
		),
		-3.0,
		2.0
	)
	var previous := value
	change(adjustment, reason)
	return value - previous
