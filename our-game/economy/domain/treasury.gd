class_name Treasury
extends RefCounted

var money: int = 20000000
var awareness_points: int = 10
var maintenance_ratio: float = 1.0
var last_income: int = 6000000
var last_upkeep: int = 1000000
var last_net: int = 5000000


func refresh_forecast(areas: Dictionary, projects: ProjectSystem) -> void:
	last_income = 0
	for area: ServiceArea in areas.values():
		last_income += area.income()
	last_upkeep = projects.calculate_upkeep()
	last_net = last_income - last_upkeep


func spend(amount: int) -> bool:
	if amount < 0 or amount > money:
		return false
	money -= amount
	return true


func spend_awareness(amount: int) -> bool:
	if amount < 0 or amount > awareness_points:
		return false
	awareness_points -= amount
	return true


func collect_and_maintain(areas: Dictionary, projects: ProjectSystem) -> Dictionary:
	refresh_forecast(areas, projects)
	money += last_income
	var paid_upkeep := mini(money, last_upkeep)
	money -= paid_upkeep
	maintenance_ratio = 1.0 if last_upkeep == 0 else float(paid_upkeep) / last_upkeep
	last_net = last_income - last_upkeep
	return {
		"income": last_income,
		"upkeep": last_upkeep,
		"paid_upkeep": paid_upkeep,
		"maintenance_ratio": maintenance_ratio,
		"net": last_net,
		"can_pay_budget": paid_upkeep == last_upkeep,
	}
