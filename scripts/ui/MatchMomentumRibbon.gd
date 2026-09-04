extends Control

const GOLD := Color(0.72, 0.50, 0.22, 1.0)
const BAD := Color(0.78, 0.18, 0.20, 1.0)
const AXIS_COLORS := {
    "favor": Color(0.82, 0.28, 0.38, 1.0),
    "interest": Color(0.55, 0.31, 0.72, 1.0),
    "trust": Color(0.20, 0.46, 0.70, 1.0),
    "comfort": Color(0.20, 0.55, 0.36, 1.0),
    "face": Color(0.82, 0.54, 0.16, 1.0),
    "political_value": Color(0.68, 0.48, 0.14, 1.0),
}
const AXES := ["favor", "interest", "trust", "comfort", "face", "political_value"]

var _bias := 0.0
var _pulse := 0.0
var _repeat_drag := 0.0
var _phase := 0.0
var _accent := GOLD
var _reduced_motion := false
var _snapshot: Dictionary = {}


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)


func configure(state: Dictionary, compact_mode: bool, reduced_motion: bool = false) -> void:
    custom_minimum_size.y = 11.0 if compact_mode else 15.0
    _reduced_motion = reduced_motion
    var effects: Dictionary = state.get("last_effects", {})
    var net_effect := 0
    var dominant_axis := ""
    var dominant_strength := -1
    for axis_id in AXES:
        var delta := int(effects.get(axis_id, 0))
        net_effect += delta
        if absi(delta) > dominant_strength:
            dominant_axis = axis_id
            dominant_strength = absi(delta)
    var readiness_state := String(state.get("last_readiness_state", ""))
    var repeat_level := _last_repeat_level(state)
    var target_bias := 0.0
    if readiness_state == "backfire":
        target_bias = -1.0
    elif net_effect > 0:
        target_bias = clampf(0.38 + float(net_effect) / 18.0, 0.38, 1.0)
    elif net_effect < 0:
        target_bias = -clampf(0.42 + float(abs(net_effect)) / 16.0, 0.42, 1.0)
    _accent = AXIS_COLORS.get(dominant_axis, GOLD) if target_bias >= 0.0 else BAD
    _repeat_drag = clampf(float(repeat_level) / 3.0, 0.0, 1.0)
    _snapshot = {
        "net_effect": net_effect,
        "dominant_axis": dominant_axis,
        "repeat_level": repeat_level,
        "target_bias": target_bias,
    }
    if effects.is_empty() or _reduced_motion:
        _bias = target_bias * (0.72 if _reduced_motion else 1.0)
        _pulse = 0.22 if not effects.is_empty() else 0.0
        queue_redraw()
        return
    _bias = 0.0
    _pulse = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "_bias", target_bias, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "_pulse", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.chain().tween_property(self, "_pulse", 0.28, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
    if not visible:
        return
    if not _reduced_motion:
        _phase += delta * (1.4 - _repeat_drag * 0.7)
    queue_redraw()


func state_snapshot() -> Dictionary:
    return _snapshot.duplicate(true)


func _draw() -> void:
    if size.x <= 24.0:
        return
    var left := 10.0
    var right := size.x - 10.0
    var center := size.x * 0.5
    var y := size.y * 0.5
    draw_line(Vector2(left, y), Vector2(right, y), Color(0.25, 0.18, 0.10, 0.32), 2.0)
    draw_circle(Vector2(left, y), 2.5, Color(0.18, 0.34, 0.52, 0.68))
    draw_circle(Vector2(right, y), 2.5, Color(0.48, 0.12, 0.16, 0.68))
    if absf(_bias) < 0.01:
        _draw_diamond(Vector2(center, y), 4.0, Color(GOLD, 0.72))
        return
    var travel := (right - left) * 0.35
    var breathing := sin(_phase) * 1.4 * (1.0 - _repeat_drag * 0.8)
    var knot_x := center + travel * _bias + breathing
    var line_alpha := 0.58 + _pulse * 0.24
    draw_line(Vector2(center, y), Vector2(knot_x, y), Color(_accent, line_alpha), 3.0)
    for glow_step in range(3, 0, -1):
        draw_circle(Vector2(knot_x, y), 3.0 + float(glow_step) * 2.2, Color(_accent, (0.055 + _pulse * 0.035) * float(4 - glow_step)))
    _draw_diamond(Vector2(knot_x, y), 4.2 + _pulse * 1.4, Color(_accent, 0.92 - _repeat_drag * 0.28))


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(0, -radius),
        center + Vector2(radius, 0),
        center + Vector2(0, radius),
        center + Vector2(-radius, 0),
    ]), color)


func _last_repeat_level(state: Dictionary) -> int:
    var history: Array = state.get("choice_history", [])
    if history.is_empty():
        return 0
    var last_choice_id := String(history.back())
    return maxi(0, int(Dictionary(state.get("choice_usage", {})).get(last_choice_id, 1)) - 1)
