extends Control

const AXIS_ORDER := ["favor", "interest", "trust", "comfort", "face", "political_value"]
const AXIS_LABELS := {
    "favor": "호감",
    "interest": "흥미",
    "trust": "신뢰",
    "comfort": "안심",
    "face": "체면",
    "political_value": "정략",
}

var axes: Dictionary = {}

func set_axes(value: Dictionary) -> void:
    axes = value.duplicate(true)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    center.y += 6.0
    var radius := minf(size.x, size.y) * 0.34
    if radius <= 0.0:
        return

    var stroke := Color(0.68, 0.48, 0.22, 0.55)
    var grid := Color(0.74, 0.52, 0.22, 0.22)
    var fill := Color(0.62, 0.13, 0.13, 0.42)
    var line := Color(0.94, 0.70, 0.32, 0.95)
    var text := Color(0.92, 0.88, 0.80, 1.0)
    var muted := Color(0.68, 0.63, 0.56, 1.0)

    for ring in [0.25, 0.5, 0.75, 1.0]:
        _draw_closed_poly(_points_for_radius(center, radius * float(ring)), grid, 1.0)

    for axis_index in range(AXIS_ORDER.size()):
        var outer := _axis_point(center, radius, axis_index)
        draw_line(center, outer, grid, 1.0, true)

    var value_points := PackedVector2Array()
    for axis_index in range(AXIS_ORDER.size()):
        var axis_id := String(AXIS_ORDER[axis_index])
        var value := clampf(float(axes.get(axis_id, 0)) / 100.0, 0.0, 1.0)
        value_points.append(_axis_point(center, radius * value, axis_index))
    draw_colored_polygon(value_points, fill)
    _draw_closed_poly(value_points, line, 2.0)

    for point in value_points:
        draw_circle(point, 3.5, line)

    var font := get_theme_font("font", "Label")
    var font_size := get_theme_font_size("font_size", "Label")
    if font_size <= 0:
        font_size = 13
    for axis_index in range(AXIS_ORDER.size()):
        var axis_id := String(AXIS_ORDER[axis_index])
        var label := String(AXIS_LABELS.get(axis_id, axis_id))
        var label_pos := _axis_point(center, radius + 30.0, axis_index)
        var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
        draw_string(font, label_pos - label_size * 0.5, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text)

    var guide_label := "25 / 50 / 75 / 100"
    draw_string(font, Vector2(10, size.y - 10), guide_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size - 1, muted)
    _draw_closed_poly(_points_for_radius(center, radius), stroke, 2.0)

func _points_for_radius(center: Vector2, radius: float) -> PackedVector2Array:
    var points := PackedVector2Array()
    for axis_index in range(AXIS_ORDER.size()):
        points.append(_axis_point(center, radius, axis_index))
    return points

func _axis_point(center: Vector2, radius: float, axis_index: int) -> Vector2:
    var angle := -PI * 0.5 + TAU * float(axis_index) / float(AXIS_ORDER.size())
    return center + Vector2(cos(angle), sin(angle)) * radius

func _draw_closed_poly(points: PackedVector2Array, color: Color, width: float) -> void:
    if points.size() < 2:
        return
    var closed := PackedVector2Array(points)
    closed.append(points[0])
    draw_polyline(closed, color, width, true)
