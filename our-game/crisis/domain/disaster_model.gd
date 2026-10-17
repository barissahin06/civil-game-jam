class_name DisasterModel
extends RefCounted
## All human counts are model estimates. Historical casualties never enter these outcomes.


func daily_weight(_elapsed: int, _window: int) -> float:
	return 0.0


func initial_damage(severity: int, protection: float) -> float:
	return severity * 4.0 * (1.0 - protection / 120.0)


func daily_damage(_severity: int, _support: float) -> float:
	return 0.0


func total_damage(severity: int, protection: float, elapsed: int, support_sum: float) -> float:
	var average_support := support_sum / elapsed if elapsed > 0 else 0.0
	return initial_damage(severity, protection) + daily_damage(severity, average_support) * elapsed


func estimate(
	population: int, severity: int, protection: float, support: float, elapsed: int, window: int
) -> Dictionary:
	var exposed := maxi(1, roundi(population * (0.005 + severity * 0.003)))
	var affected := roundi(exposed * (1.0 - protection * 0.006))
	var rescued := mini(affected, roundi(affected * clampf(support, 0.0, 0.95)))
	var losses := roundi(
		maxi(0, affected - rescued) * (0.002 + severity * 0.001) * daily_weight(elapsed, window)
	)
	return {
		"exposed": exposed,
		"affected": affected,
		"rescued": rescued,
		"safe": exposed - affected,
		"losses": losses
	}
