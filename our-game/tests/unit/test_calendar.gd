extends GdUnitTestSuite


func test_negative_epoch_and_round_trip() -> void:
	var day := CalendarClock.date_to_day("1950-01-01")
	assert_bool(day < 0).is_true()
	assert_str(CalendarClock.day_to_iso(day)).is_equal("1950-01-01")
	assert_int(CalendarClock.date_to_day("1970-01-01")).is_equal(0)


func test_leap_day_and_month_boundaries() -> void:
	var clock := CalendarClock.new()
	clock.set_day(CalendarClock.date_to_day("2000-02-28"))
	clock.advance_days(1)
	assert_int(clock.day_of_month).is_equal(29)
	assert_int(clock.next_month_day() - clock.day).is_equal(1)
	clock.advance_days(1)
	assert_int(clock.month).is_equal(3)
	assert_int(clock.day_of_month).is_equal(1)
	clock.set_day(CalendarClock.date_to_day("1999-12-31"))
	assert_str(CalendarClock.day_to_iso(clock.next_month_day())).is_equal("2000-01-01")


func test_invalid_date_is_rejected() -> void:
	assert_int(CalendarClock.date_to_day("2023-02-30")).is_equal(CalendarClock.INVALID_DAY)
	assert_int(CalendarClock.date_to_day("2023/02/01")).is_equal(CalendarClock.INVALID_DAY)


func test_trust_is_bounded_and_awareness_slows_decay() -> void:
	var ordinary := TrustState.new()
	var prepared := TrustState.new()
	ordinary.decay_month()
	prepared.decay_month(0.5)
	assert_bool(prepared.value > ordinary.value).is_true()
	prepared.change(-200.0, "Test")
	assert_float(prepared.value).is_equal(0.0)
	prepared.change(200.0, "Test")
	assert_float(prepared.value).is_equal(100.0)
