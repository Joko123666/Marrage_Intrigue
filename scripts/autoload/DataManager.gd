extends Node

# Codex target: Godot 4.x / GDScript 2.0
# 역할: res://data/**/*.json 파일을 로드하고 id 기반 조회 API를 제공한다.

var data: Dictionary = {}

const DATA_FILES := {
    "game_config": "res://data/meta/game_config.json",
    "player_initial_state": "res://data/player/player_initial_state.json",
    "dialogue_stages": "res://data/player/dialogue_stages.json",
    "personas": "res://data/player/personas.json",
    "choice_tags": "res://data/player/choice_tags.json",
    "dialogue_templates": "res://data/player/dialogue_templates.json",
    "free_actions": "res://data/time/free_actions.json",
    "npcs": "res://data/characters/npcs.json",
    "candidate_profiles": "res://data/characters/candidate_profiles.json",
    "relationship_axes": "res://data/characters/relationship_axes.json",
    "items": "res://data/shop/items.json",
    "rumors": "res://data/rumors/rumor_actions.json",
    "match_config": "res://data/match/match_config.json",
    "marriage_config": "res://data/marriage/marriage_config.json",
    "removal_methods": "res://data/removal/removal_methods.json",
    "coverup_actions": "res://data/coverup/coverup_actions.json",
    "nobility_ranks": "res://data/nobility/ranks.json",
    "rank_events": "res://data/nobility/rank_events.json",
    "tutorial_flow": "res://data/tutorial/tutorial_flow.json"
}

func _ready() -> void:
    load_all()

func load_all() -> void:
    data.clear()
    for key in DATA_FILES.keys():
        data[key] = _load_json(DATA_FILES[key])

func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("JSON not found: " + path)
        return {}
    var text := FileAccess.get_file_as_string(path)
    var parsed = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Invalid JSON dictionary: " + path)
        return {}
    return parsed

func get_table(table_name: String) -> Dictionary:
    return data.get(table_name, {})

func find_by_id(table_name: String, list_key: String, id_value: String) -> Dictionary:
    var table := get_table(table_name)
    var arr: Array = table.get(list_key, [])
    for item in arr:
        if typeof(item) == TYPE_DICTIONARY and item.get("id", "") == id_value:
            return item
    return {}
