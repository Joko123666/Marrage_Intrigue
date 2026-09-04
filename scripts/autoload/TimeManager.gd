extends Node

signal week_advanced(new_week: int)
signal age_changed(new_age: int)
signal calendar_advanced(from_year: int, from_month: int, to_year: int, to_month: int, elapsed_weeks: int, crossed_year: bool)

const WEEKS_PER_YEAR := 52
const MONTHS_PER_YEAR := 12

func calendar_year(for_week: int = GameState.week) -> int:
    return int((maxi(1, for_week) - 1) / WEEKS_PER_YEAR) + 1

func calendar_month(for_week: int = GameState.week) -> int:
    var week_in_year := (maxi(1, for_week) - 1) % WEEKS_PER_YEAR
    return mini(MONTHS_PER_YEAR, int(floor(float(week_in_year) * MONTHS_PER_YEAR / WEEKS_PER_YEAR)) + 1)

func calendar_text(for_week: int = GameState.week) -> String:
    return "제%d년 %d월" % [calendar_year(for_week), calendar_month(for_week)]

func advance_weeks(weeks: int) -> void:
    if weeks <= 0:
        return
    var from_week := GameState.week
    var from_year := calendar_year(GameState.week)
    var from_month := calendar_month(GameState.week)
    for i in range(weeks):
        GameState.week += 1
        if GameState.week % WEEKS_PER_YEAR == 1 and GameState.week > 1:
            GameState.age_years += 1
            emit_signal("age_changed", GameState.age_years)
        GameState.on_week_elapsed()
        emit_signal("week_advanced", GameState.week)
    var to_year := calendar_year(GameState.week)
    var to_month := calendar_month(GameState.week)
    var crossed_year := from_year != to_year
    var crossed_month := crossed_year or from_month != to_month
    if crossed_month:
        emit_signal("calendar_advanced", from_year, from_month, to_year, to_month, weeks, crossed_year)
    GameState.request_feedback({
        "type": "time_passage",
        "from_week": from_week,
        "to_week": GameState.week,
        "from_year": from_year,
        "from_month": from_month,
        "year": to_year,
        "month": to_month,
        "weeks": weeks,
        "age": GameState.age_years,
        "crossed_month": crossed_month,
        "crossed_year": crossed_year,
    })
