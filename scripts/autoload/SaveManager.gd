extends Node

const SAVE_PATH := "user://marriage_intrigue_save.json"
const AUTO_SAVE_PATH := "user://marriage_intrigue_autosave.json"
const SLOT_COUNT := 3

signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)

func _ready() -> void:
    TimeManager.week_advanced.connect(_on_week_advanced)

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func has_auto_save() -> bool:
    return FileAccess.file_exists(AUTO_SAVE_PATH)

func slot_count() -> int:
    return SLOT_COUNT

func has_slot_save(slot: int) -> bool:
    return FileAccess.file_exists(_slot_path(slot))

func slot_summary(slot: int) -> String:
    if not has_slot_save(slot):
        return "비어 있음"
    var parsed := _read_json(_slot_path(slot))
    if parsed.is_empty():
        return "손상된 저장"
    var week := int(parsed.get("week", 0))
    var age := int(parsed.get("age_years", 0))
    var player: Dictionary = parsed.get("player", {})
    var stats: Dictionary = player.get("stats", {})
    var risks: Dictionary = player.get("global_risks", {})
    return "%d세 W%03d / 자금 %d / 의심 %d" % [
        age,
        week,
        int(stats.get("cash", 0)),
        int(risks.get("social_suspicion", 0)),
    ]

func save_game() -> bool:
    if not _write_state(SAVE_PATH):
        return false
    var message := "저장 완료: " + ProjectSettings.globalize_path(SAVE_PATH)
    GameState.add_log(message)
    save_completed.emit(true, message)
    return true

func save_slot(slot: int) -> bool:
    if not _valid_slot(slot):
        var invalid_message := "저장 실패: 잘못된 슬롯입니다."
        GameState.add_log(invalid_message)
        save_completed.emit(false, invalid_message)
        return false
    if not _write_state(_slot_path(slot)):
        return false
    var message := "슬롯 %d 저장 완료." % slot
    GameState.add_log(message)
    save_completed.emit(true, message)
    return true

func auto_save_game() -> bool:
    var success := _write_state(AUTO_SAVE_PATH)
    if not success:
        GameState.add_log("자동 저장 실패.")
    return success

func load_game() -> bool:
    return _load_from_path(SAVE_PATH, "불러오기")

func load_auto_save() -> bool:
    return _load_from_path(AUTO_SAVE_PATH, "자동 저장 불러오기")

func load_slot(slot: int) -> bool:
    if not _valid_slot(slot):
        var invalid_message := "불러오기 실패: 잘못된 슬롯입니다."
        GameState.add_log(invalid_message)
        load_completed.emit(false, invalid_message)
        return false
    return _load_from_path(_slot_path(slot), "슬롯 %d 불러오기" % slot)

func _write_state(path: String) -> bool:
    var payload := GameState.export_state()
    payload["saved_at_unix"] = Time.get_unix_time_from_system()
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        var error_message := "저장 실패: 파일을 열 수 없습니다."
        GameState.add_log(error_message)
        save_completed.emit(false, error_message)
        return false
    file.store_string(JSON.stringify(payload, "\t"))
    file.close()
    return true

func _load_from_path(path: String, label: String) -> bool:
    if not FileAccess.file_exists(path):
        var missing_message := "불러오기 실패: 저장 파일이 없습니다."
        GameState.add_log(missing_message)
        load_completed.emit(false, missing_message)
        return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        var open_message := "불러오기 실패: 파일을 열 수 없습니다."
        GameState.add_log(open_message)
        load_completed.emit(false, open_message)
        return false
    var text := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        var parse_message := "불러오기 실패: 저장 데이터 형식이 올바르지 않습니다."
        GameState.add_log(parse_message)
        load_completed.emit(false, parse_message)
        return false
    GameState.import_state(parsed)
    var message := label + " 완료: " + ProjectSettings.globalize_path(path)
    GameState.add_log(message)
    load_completed.emit(true, message)
    return true

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var text := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed

func _valid_slot(slot: int) -> bool:
    return slot >= 1 and slot <= SLOT_COUNT

func _slot_path(slot: int) -> String:
    return "user://marriage_intrigue_slot_%d.json" % slot

func _on_week_advanced(_new_week: int) -> void:
    auto_save_game()
