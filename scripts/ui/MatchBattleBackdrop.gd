extends Control

const WALNUT := Color(0.075, 0.045, 0.028, 1.0)
const WOOD := Color(0.16, 0.095, 0.052, 1.0)
const NAVY := Color(0.035, 0.075, 0.13, 1.0)
const WINE := Color(0.20, 0.045, 0.06, 1.0)
const GOLD := Color(0.72, 0.50, 0.22, 1.0)
const WINDOW := Color(0.12, 0.19, 0.28, 1.0)
const AXIS_COLORS := {
    "favor": Color(0.90, 0.43, 0.49, 1.0),
    "interest": Color(0.65, 0.42, 0.84, 1.0),
    "trust": Color(0.34, 0.62, 0.84, 1.0),
    "comfort": Color(0.38, 0.70, 0.52, 1.0),
    "face": Color(0.91, 0.67, 0.27, 1.0),
    "political_value": Color(0.78, 0.60, 0.28, 1.0),
}

var _phase := 0.0
var _mood_bias := 0.0
var _impact := 0.0
var _repeat_drag := 0.0
var _axis_color := GOLD
var _compact_mode := false
var _reduced_motion := false
var _feedback_tween: Tween
var _last_feedback: Dictionary = {}


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
    set_process(true)


func _process(delta: float) -> void:
    if not visible:
        return
    if not _reduced_motion:
        _phase += delta * (0.72 if _compact_mode else 0.92)
    queue_redraw()


func configure_presentation(compact_mode: bool, reduced_motion: bool = false) -> void:
    _compact_mode = compact_mode
    _reduced_motion = reduced_motion
    queue_redraw()


func reset_atmosphere() -> void:
    if _feedback_tween != null and _feedback_tween.is_valid():
        _feedback_tween.kill()
    _last_feedback.clear()
    _mood_bias = 0.0
    _impact = 0.0
    _repeat_drag = 0.0
    _axis_color = GOLD
    queue_redraw()


func play_turn_feedback(event: Dictionary) -> void:
    _last_feedback = event.duplicate(true)
    var net_effect := int(event.get("net_effect", 0))
    var readiness_state := String(event.get("readiness_state", ""))
    var repeat_level := maxi(0, int(event.get("repeat_level", 0)))
    var target_mood := 0.0
    if readiness_state == "backfire":
        target_mood = -1.0
    elif net_effect > 0:
        target_mood = clampf(0.38 + float(net_effect) / 18.0, 0.38, 1.0)
    elif net_effect < 0:
        target_mood = -clampf(0.42 + float(abs(net_effect)) / 16.0, 0.42, 1.0)
    var target_repeat := clampf(float(repeat_level) / 3.0, 0.0, 1.0)
    var target_color: Color = AXIS_COLORS.get(String(event.get("dominant_axis", "")), GOLD)

    if _feedback_tween != null and _feedback_tween.is_valid():
        _feedback_tween.kill()
    if _reduced_motion:
        _mood_bias = target_mood * 0.62
        _impact = 0.22
        _repeat_drag = target_repeat
        _axis_color = target_color
        queue_redraw()
        return

    _impact = 0.0
    _feedback_tween = create_tween()
    _feedback_tween.set_parallel(true)
    _feedback_tween.tween_property(self, "_mood_bias", target_mood, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _feedback_tween.tween_property(self, "_impact", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _feedback_tween.tween_property(self, "_repeat_drag", target_repeat, 0.22)
    _feedback_tween.tween_property(self, "_axis_color", target_color, 0.18)
    _feedback_tween.chain().set_parallel(true)
    _feedback_tween.tween_property(self, "_mood_bias", target_mood * 0.66, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    _feedback_tween.tween_property(self, "_impact", 0.28, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func feedback_snapshot() -> Dictionary:
    var snapshot := _last_feedback.duplicate(true)
    snapshot["mood_bias"] = _mood_bias
    snapshot["impact"] = _impact
    snapshot["repeat_drag"] = _repeat_drag
    return snapshot


func _draw() -> void:
    var breath := sin(_phase) * (0.35 if _compact_mode else 0.55) * (1.0 - _repeat_drag * 0.72)
    var positive := maxf(_mood_bias, 0.0)
    var negative := maxf(-_mood_bias, 0.0)
    draw_rect(Rect2(Vector2.ZERO, size), WALNUT)
    draw_rect(Rect2(0, 0, size.x, size.y * 0.70), Color(0.105, 0.065, 0.040, 1.0))

    var window_rect := Rect2(size.x * 0.08, size.y * 0.08, size.x * 0.25, size.y * 0.54)
    var window_warmth := Color(0.12 + positive * 0.08, 0.19 + positive * 0.045, 0.28 - negative * 0.055, 1.0)
    draw_rect(window_rect, window_warmth)
    draw_rect(window_rect, Color(GOLD, 0.55 + positive * 0.16), false, 4.0)
    for i in range(1, 4):
        var x := window_rect.position.x + window_rect.size.x * float(i) / 4.0
        draw_line(Vector2(x, window_rect.position.y), Vector2(x, window_rect.end.y), Color(GOLD, 0.30), 2.0)
    for i in range(1, 3):
        var y := window_rect.position.y + window_rect.size.y * float(i) / 3.0
        draw_line(Vector2(window_rect.position.x, y), Vector2(window_rect.end.x, y), Color(GOLD, 0.30), 2.0)

    var curtain_closure := negative * 0.045 - positive * 0.018
    var left_drape := PackedVector2Array([
        Vector2(0, 0), Vector2(size.x * 0.12, 0),
        Vector2(size.x * (0.18 + curtain_closure), size.y * 0.65), Vector2(0, size.y * 0.80),
    ])
    draw_colored_polygon(left_drape, NAVY.lerp(Color(0.025, 0.045, 0.075, 1.0), negative * 0.45))
    var right_drape := PackedVector2Array([
        Vector2(size.x * 0.88, 0), Vector2(size.x, 0),
        Vector2(size.x, size.y * 0.80), Vector2(size.x * (0.82 - curtain_closure), size.y * 0.65),
    ])
    draw_colored_polygon(right_drape, WINE.lerp(Color(0.12, 0.025, 0.045, 1.0), negative * 0.45))

    for i in range(7):
        var line_y := size.y * (0.12 + float(i) * 0.085)
        draw_line(Vector2(size.x * 0.36, line_y), Vector2(size.x * 0.86, line_y), Color(GOLD, 0.035 + positive * 0.018), 1.0)

    _draw_atmosphere_flow(breath)

    draw_rect(Rect2(0, size.y * 0.70, size.x, size.y * 0.30), WOOD)
    var table := PackedVector2Array([
        Vector2(size.x * 0.24, size.y * 0.72), Vector2(size.x * 0.76, size.y * 0.72),
        Vector2(size.x * 0.88, size.y), Vector2(size.x * 0.12, size.y),
    ])
    draw_colored_polygon(table, Color(0.10, 0.055, 0.03, 1.0))
    draw_line(Vector2(size.x * 0.24, size.y * 0.72), Vector2(size.x * 0.76, size.y * 0.72), Color(GOLD, 0.28 + positive * 0.20), 3.0)

    var candle_spread := (7.0 * positive - 5.0 * negative) * (1.0 - _repeat_drag * 0.6)
    for candle_index in range(2):
        var candle_x := size.x * (0.42 if candle_index == 0 else 0.58)
        var flame_direction := 1.0 if candle_index == 0 else -1.0
        var flame_x := candle_x + flame_direction * candle_spread + breath
        draw_line(Vector2(candle_x, size.y * 0.63), Vector2(candle_x, size.y * 0.72), Color(0.72, 0.60, 0.38, 0.75), 3.0)
        draw_circle(Vector2(flame_x, size.y * 0.61), 9.0 + positive * 3.0, Color(0.96, 0.63, 0.20, 0.12 + positive * 0.12))
        draw_circle(Vector2(flame_x, size.y * 0.61), 3.0, Color(1.0, 0.77 - negative * 0.18, 0.32, 0.90 - _repeat_drag * 0.35))

    var shade_alpha := 0.24 + negative * 0.12 + _repeat_drag * 0.055 - positive * 0.045
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, shade_alpha))
    if negative > 0.0:
        var edge_alpha := negative * (0.09 + _impact * 0.07)
        draw_rect(Rect2(0, 0, size.x * 0.19, size.y), Color(0.08, 0.01, 0.025, edge_alpha))
        draw_rect(Rect2(size.x * 0.81, 0, size.x * 0.19, size.y), Color(0.08, 0.01, 0.025, edge_alpha))
    draw_line(Vector2(24, 22), Vector2(size.x - 24, 22), Color(GOLD, 0.18 + positive * 0.10), 1.0)
    draw_line(Vector2(24, size.y - 22), Vector2(size.x - 24, size.y - 22), Color(GOLD, 0.18 + positive * 0.10), 1.0)


func _draw_atmosphere_flow(breath: float) -> void:
    if absf(_mood_bias) < 0.01 and _impact < 0.01:
        return
    var direction := 1.0 if _mood_bias >= 0.0 else -1.0
    var center := Vector2(size.x * (0.50 + direction * 0.065 * _impact), size.y * 0.39)
    center.x += breath * 4.0
    var glow_color := _axis_color if _mood_bias >= 0.0 else Color(0.68, 0.12, 0.18, 1.0)
    var strength := clampf(absf(_mood_bias) * 0.10 + _impact * 0.075, 0.0, 0.17)
    var radius_base := minf(size.x, size.y) * (0.16 + maxf(_mood_bias, 0.0) * 0.055)
    for step in range(7, 0, -1):
        var ratio := float(step) / 7.0
        draw_circle(center, radius_base * ratio, Color(glow_color, strength * (1.0 - ratio) * (1.0 - _repeat_drag * 0.45)))
    var sweep_half_width := size.x * (0.055 + _impact * 0.025)
    var sweep_rect := Rect2(center.x - sweep_half_width, size.y * 0.10, sweep_half_width * 2.0, size.y * 0.56)
    draw_rect(sweep_rect, Color(glow_color, strength * 0.32))
    draw_line(Vector2(center.x, size.y * 0.12), Vector2(center.x, size.y * 0.66), Color(glow_color, strength * 1.35), 2.0 + _impact * 2.0)
