class_name SuddenDisasterModel
extends DisasterModel


func daily_weight(elapsed: int, window: int) -> float:
	# The first response days carry more risk after a sudden shock.
	return (2.0 * (window - elapsed) - 1.0) / float(window * window)
