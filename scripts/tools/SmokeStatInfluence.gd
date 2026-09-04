extends SceneTree

const CALCULATOR := preload("res://scripts/systems/StatInfluenceCalculator.gd")


func _init() -> void:
    var action := {
        "base_success": 60,
        "stat_influence": {
            "stats": {"information": 0.6, "mask": 0.4},
            "reference_stat": 40,
            "chance_per_point": 0.5,
            "fixed_effects": ["cash"]
        }
    }
    var effects := {"information": 4, "social_suspicion": 4, "origin_rumor": -4, "cash": -3}
    var low_stats := {"information": 0, "mask": 0, "fatigue": 0, "stress": 0}
    var high_stats := {"information": 100, "mask": 100, "fatigue": 0, "stress": 0}
    var exhausted_stats := {"information": 100, "mask": 100, "fatigue": 100, "stress": 100}
    var low := CALCULATOR.evaluate(action, low_stats)
    var high := CALCULATOR.evaluate(action, high_stats)
    var exhausted := CALCULATOR.evaluate(action, exhausted_stats)
    assert(int(low["chance"]) < int(high["chance"]))
    assert(int(exhausted["chance"]) < int(high["chance"]))

    var low_effects := CALCULATOR.adjusted_effects(action, effects, low_stats, low)
    var high_effects := CALCULATOR.adjusted_effects(action, effects, high_stats, high)
    assert(int(low_effects["information"]) < int(high_effects["information"]))
    assert(int(low_effects["social_suspicion"]) > int(high_effects["social_suspicion"]))
    assert(abs(int(low_effects["origin_rumor"])) < abs(int(high_effects["origin_rumor"])))
    assert(int(low_effects["cash"]) == -3 and int(high_effects["cash"]) == -3)

    var fixed_action := {"base_success": 70}
    assert(int(CALCULATOR.evaluate(fixed_action, high_stats)["chance"]) == 70)
    assert(CALCULATOR.adjusted_effects(fixed_action, effects, high_stats) == effects)
    var rank_action := {"stat_influence": {"stats": {"status": 1.0}, "reference_stat": 50}}
    assert(roundi(float(CALCULATOR.evaluate(rank_action, {"status": 6})["skill"])) == 100)
    print("STAT_INFLUENCE_SMOKE_OK low=%s high=%s exhausted=%s" % [low, high, exhausted])
    quit()
