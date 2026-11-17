class_name GardenCalendar
extends RefCounted

const START_MINUTE := 6 * 60
const LAST_MINUTE := 23 * 60 + 50
const STEP_MINUTES := 10
const SHOP_OPEN := START_MINUTE
const SHOP_CLOSE := 18 * 60
const MARKET_CLOSE := 16 * 60
const WEEKDAYS := ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
const SEASON_LENGTH := 28

enum Season { SPRING, SUMMER, AUTUMN }


static func season(day: int) -> Season:
	return Season.SPRING if (day - 1) % (SEASON_LENGTH * 2) < SEASON_LENGTH else Season.SUMMER


static func day_in_season(day: int) -> int:
	return (day - 1) % SEASON_LENGTH + 1


static func season_name(day: int) -> String:
	return "Xuân" if season(day) == Season.SPRING else "Hè"


static func is_raining(day: int) -> bool:
	var weekday := weekday_index(day)
	if season(day) == Season.SUMMER:
		return weekday == 1 or weekday == 4
	return weekday == 5


static func weather_name(day: int) -> String:
	return "Mưa" if is_raining(day) else "Nắng"


static func weekday_index(day: int) -> int:
	return (day - 1) % WEEKDAYS.size()


static func week_start(day: int) -> int:
	return day - weekday_index(day)


static func week_number(day: int) -> int:
	return floori((day - 1) / float(WEEKDAYS.size())) + 1


static func format_time(minute_of_day: int) -> String:
	return "%02d:%02d" % [floori(minute_of_day / 60.0), minute_of_day % 60]


static func shop_is_open(minute_of_day: int) -> bool:
	return minute_of_day >= SHOP_OPEN and minute_of_day < SHOP_CLOSE


static func shop_hours() -> String:
	return "%s–%s" % [format_time(SHOP_OPEN), format_time(SHOP_CLOSE)]


static func is_market_day(day: int) -> bool:
	return weekday_index(day) == WEEKDAYS.size() - 1


static func market_is_open(day: int, minute_of_day: int) -> bool:
	return is_market_day(day) and minute_of_day >= START_MINUTE and minute_of_day < MARKET_CLOSE


static func next_market_day(day: int, minute_of_day: int) -> int:
	var sunday := week_start(day) + WEEKDAYS.size() - 1
	return sunday + WEEKDAYS.size() if day == sunday and minute_of_day >= MARKET_CLOSE else sunday


static func market_hours() -> String:
	return "%s–%s" % [format_time(START_MINUTE), format_time(MARKET_CLOSE)]
