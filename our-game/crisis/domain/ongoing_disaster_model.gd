class_name OngoingDisasterModel
extends DisasterModel


func daily_weight(_elapsed: int, window: int) -> float:
	return 1.0 / window


func daily_damage(severity: int, support: float) -> float:
	return severity * 0.1 * (1.0 - support)
