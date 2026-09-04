extends PanelContainer

const COLOR_TEXT := Color(0.20, 0.15, 0.10, 1.0)
const COLOR_MUTED := Color(0.42, 0.32, 0.22, 1.0)
const COLOR_GOOD := Color(0.34, 0.84, 0.53, 1.0)
const COLOR_BAD := Color(0.96, 0.34, 0.30, 1.0)

var resource_id: String
var base_accent: Color
var title_label: Label
var value_label: Label
var delta_label: Label
var status_label: Label
var meter: ProgressBar
var marker: ColorRect
var current_value: int = 0
var initialized: bool = false
var change_tween: Tween


func setup(id: String, title: String, accent: Color, show_meter: bool) -> void:
    resource_id = id
    base_accent = accent
    name = "%sResourceHud" % id.capitalize()
    custom_minimum_size = Vector2(160, 70)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_stylebox_override("panel", _card_style(base_accent, 1))

    var root_box := VBoxContainer.new()
    root_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root_box.add_theme_constant_override("separation", 2)
    add_child(root_box)

    var top_row := HBoxContainer.new()
    top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_theme_constant_override("separation", 7)
    root_box.add_child(top_row)

    marker = ColorRect.new()
    marker.color = accent
    marker.custom_minimum_size = Vector2(5, 0)
    marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(marker)

    title_label = _label(title, 14, accent)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_row.add_child(title_label)

    delta_label = _label("", 16, COLOR_GOOD)
    delta_label.custom_minimum_size = Vector2(48, 0)
    delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top_row.add_child(delta_label)

    value_label = _label("0", 27, COLOR_TEXT)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top_row.add_child(value_label)

    status_label = _label("", 11, COLOR_MUTED)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    root_box.add_child(status_label)

    meter = ProgressBar.new()
    meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    meter.min_value = 0
    meter.max_value = 100
    meter.show_percentage = false
    meter.custom_minimum_size = Vector2(0, 7)
    meter.add_theme_stylebox_override("background", _meter_style(Color(0.25, 0.19, 0.12, 0.42)))
    meter.add_theme_stylebox_override("fill", _meter_style(accent))
    meter.visible = show_meter
    root_box.add_child(meter)


func update_value(value: int, status: String, accent: Color, suffix: String = "") -> void:
    base_accent = accent
    marker.color = accent
    title_label.add_theme_color_override("font_color", accent)
    meter.add_theme_stylebox_override("fill", _meter_style(accent))
    meter.value = clampi(value, 0, 100)
    status_label.text = status
    value_label.text = "%d%s" % [value, suffix]
    if not initialized:
        current_value = value
        initialized = true
        add_theme_stylebox_override("panel", _card_style(base_accent, 1))
        return
    var delta := value - current_value
    current_value = value
    if delta == 0:
        add_theme_stylebox_override("panel", _card_style(base_accent, 1))
        return
    _animate_change(delta)


func _animate_change(delta: int) -> void:
    if change_tween != null and change_tween.is_valid():
        change_tween.kill()
    var change_color := COLOR_GOOD if delta > 0 else COLOR_BAD
    delta_label.text = "%s%d" % ["+" if delta > 0 else "", delta]
    delta_label.add_theme_color_override("font_color", change_color)
    delta_label.modulate.a = 1.0
    value_label.modulate = change_color
    value_label.scale = Vector2(1.18, 1.18)
    value_label.pivot_offset = value_label.size * 0.5
    add_theme_stylebox_override("panel", _card_style(change_color, 3))
    change_tween = create_tween()
    change_tween.set_parallel(true)
    change_tween.tween_property(value_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    change_tween.tween_property(value_label, "modulate", COLOR_TEXT, 0.34)
    change_tween.chain().tween_interval(0.72)
    change_tween.chain().tween_property(delta_label, "modulate:a", 0.0, 0.30)
    change_tween.chain().tween_callback(_finish_change)


func _finish_change() -> void:
    delta_label.text = ""
    delta_label.modulate.a = 1.0
    add_theme_stylebox_override("panel", _card_style(base_accent, 1))


func _label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _card_style(border: Color, border_width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.89, 0.80, 0.62, 0.98)
    style.border_color = Color(border, 0.82)
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(6)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style


func _meter_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(3)
    return style
