extends Control

const NIGHT := Color(0.035, 0.055, 0.105, 1.0)
const DAWN := Color(0.32, 0.18, 0.16, 1.0)
const GOLD := Color(0.96, 0.73, 0.31, 1.0)
const BLUE := Color(0.66, 0.78, 0.94, 1.0)
const DUST_POINTS := [0.08, 0.17, 0.27, 0.39, 0.53, 0.66, 0.78, 0.91]

var _progress := 0.0
var _phase := 0.0
var _weeks := 1
var _crossed_month := false
var _crossed_year := false
var _compact_mode := false
var _reduced_motion := false
var _flow_tween: Tween
var _snapshot: Dictionary = {}


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
    set_process(true)


func configure(event: Dictionary, compact_mode: bool, reduced_motion: bool = false) -> void:
    _weeks = maxi(1, int(event.get("weeks", 1)))
    _crossed_year = bool(event.get("crossed_year", false))
    _crossed_month = bool(event.get("crossed_month", false)) or _crossed_year
    _compact_mode = compact_mode
    _reduced_motion = reduced_motion
    custom_minimum_size.y = 50.0 if compact_mode else 66.0
    _snapshot = {
        "from_week": int(event.get("from_week", 0)),
        "to_week": int(event.get("to_week", 0)),
        "weeks": _weeks,
        "crossed_month": _crossed_month,
        "crossed_year": _crossed_year,
    }
    queue_redraw()


func play() -> void:
    if _flow_tween != null and _flow_tween.is_valid():
        _flow_tween.kill()
    if _reduced_motion:
        _progress = 1.0
        queue_redraw()
        return
    _progress = 0.0
    _flow_tween = create_tween()
    _flow_tween.tween_property(self, "_progress", 1.0, 0.72 if not _crossed_year else 0.92).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func state_snapshot() -> Dictionary:
    var result := _snapshot.duplicate(true)
    result["progress"] = _progress
    return result


func _process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    if not _reduced_motion:
        _phase += delta * 1.15
    queue_redraw()


func _draw() -> void:
    if size.x < 80.0 or size.y < 24.0:
        return
    var accent := GOLD if _crossed_year else BLUE if _crossed_month else Color(0.88, 0.66, 0.34, 1.0)
    var inner := Rect2(4, 2, size.x - 8, size.y - 4)
    draw_rect(inner, NIGHT)
    draw_rect(Rect2(inner.position + Vector2(0, inner.size.y * 0.48), Vector2(inner.size.x, inner.size.y * 0.52)), DAWN)
    draw_rect(inner, Color(0.01, 0.012, 0.025, 0.18), false, 1.0)

    var start := Vector2(inner.position.x + 18.0, inner.end.y - 15.0)
    var finish := Vector2(inner.end.x - 18.0, inner.end.y - 15.0)
    var orb_x := lerpf(start.x, finish.x, _progress)
    var arc_height := inner.size.y * (0.48 if not _compact_mode else 0.40)
    var orb_y := start.y - sin(_progress * PI) * arc_height
    var orb := Vector2(orb_x, orb_y)
    var trail_points := PackedVector2Array()
    var trail_steps := maxi(2, int(18.0 * _progress))
    for step in range(trail_steps + 1):
        var ratio := _progress * float(step) / float(trail_steps)
        trail_points.append(Vector2(lerpf(start.x, finish.x, ratio), start.y - sin(ratio * PI) * arc_height))
    if trail_points.size() >= 2:
        draw_polyline(trail_points, Color(accent, 0.56), 2.0, true)
    for glow_size in range(4, 0, -1):
        draw_circle(orb, 3.0 + float(glow_size) * 2.2, Color(accent, 0.035 * float(5 - glow_size)))
    draw_circle(orb, 3.4 if _compact_mode else 4.2, Color(accent, 0.96))

    for point_index in range(DUST_POINTS.size()):
        var ratio: float = DUST_POINTS[point_index]
        var dust_x := lerpf(start.x, finish.x, ratio)
        var dust_y := inner.position.y + 8.0 + float((point_index * 11) % maxi(12, int(inner.size.y - 20.0)))
        var shimmer := 0.24 + sin(_phase + float(point_index) * 0.8) * 0.10
        draw_circle(Vector2(dust_x, dust_y), 1.0 + float(point_index % 2), Color(accent, shimmer))

    var pip_count := mini(_weeks, 6)
    var pip_spacing := 13.0 if not _compact_mode else 10.0
    var pip_start := size.x * 0.5 - float(pip_count - 1) * pip_spacing * 0.5
    for pip_index in range(pip_count):
        var threshold := float(pip_index + 1) / float(pip_count)
        var pip_color := Color(accent, 0.92) if _progress >= threshold else Color(0.72, 0.70, 0.68, 0.28)
        draw_circle(Vector2(pip_start + float(pip_index) * pip_spacing, inner.end.y - 5.0), 2.1, pip_color)
    if _weeks > 6:
        _draw_diamond(Vector2(pip_start + float(pip_count) * pip_spacing + 4.0, inner.end.y - 5.0), 2.5, Color(accent, 0.88))
    if _crossed_year:
        _draw_diamond(Vector2(inner.end.x - 10.0, inner.position.y + 10.0), 4.0, Color(GOLD, 0.92))


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(0, -radius),
        center + Vector2(radius, 0),
        center + Vector2(0, radius),
        center + Vector2(-radius, 0),
    ]), color)
