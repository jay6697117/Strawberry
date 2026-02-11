extends Node2D

const GROUND_COLOR := Color(0.29, 0.53, 0.30)
const GRID_LINE_COLOR := Color(0.0, 0.0, 0.0, 0.18)
const DRY_SOIL_COLOR := Color(0.53, 0.36, 0.21)
const WET_SOIL_COLOR := Color(0.32, 0.22, 0.14)
const CROP_COLOR_EARLY := Color(0.36, 0.69, 0.28)
const CROP_COLOR_LATE := Color(0.64, 0.86, 0.34)

var _tile_size: int = 32
var _grid_width: int = 32
var _grid_height: int = 18
var _plots: Dictionary = {}

func configure(tile_size: int, grid_width: int, grid_height: int) -> void:
    _tile_size = maxi(tile_size, 8)
    _grid_width = maxi(grid_width, 1)
    _grid_height = maxi(grid_height, 1)
    queue_redraw()

func apply_plot(cell: Vector2i, plot: Dictionary) -> void:
    if plot.is_empty():
        _plots.erase(cell)
    else:
        _plots[cell] = plot.duplicate(true)
    queue_redraw()

func apply_all_plots(plots: Dictionary) -> void:
    _plots.clear()
    for cell in plots.keys():
        _plots[cell] = Dictionary(plots[cell]).duplicate(true)
    queue_redraw()

func _draw() -> void:
    var full_rect := Rect2(Vector2.ZERO, Vector2(_grid_width * _tile_size, _grid_height * _tile_size))
    draw_rect(full_rect, GROUND_COLOR, true)

    for y in _grid_height:
        for x in _grid_width:
            var rect := Rect2(Vector2(x * _tile_size, y * _tile_size), Vector2(_tile_size, _tile_size))
            draw_rect(rect, GRID_LINE_COLOR, false, 1.0)

    for cell in _plots.keys():
        var plot: Dictionary = _plots[cell]
        _draw_plot(cell, plot)

func _draw_plot(cell: Vector2i, plot: Dictionary) -> void:
    var cell_rect := Rect2(Vector2(cell.x * _tile_size, cell.y * _tile_size), Vector2(_tile_size, _tile_size))
    var inset_rect := cell_rect.grow(-1.5)

    var soil_state := String(plot.get("soil_state", "dry"))
    var soil_color := DRY_SOIL_COLOR
    if soil_state == "wet":
        soil_color = WET_SOIL_COLOR
    draw_rect(inset_rect, soil_color, true)

    var crop_id := String(plot.get("crop_id", ""))
    if crop_id.is_empty():
        return

    var stage := maxi(int(plot.get("stage", 0)), 0)
    var ratio := clampf(float(stage) / 4.0, 0.0, 1.0)
    var crop_color := CROP_COLOR_EARLY.lerp(CROP_COLOR_LATE, ratio)
    var crop_rect := inset_rect.grow(-float(_tile_size) * 0.26)
    draw_rect(crop_rect, crop_color, true)

    if stage >= 4:
        var center := crop_rect.get_center()
        draw_circle(center + Vector2(-4.0, -2.0), 2.5, Color(1.0, 0.88, 0.45))
        draw_circle(center + Vector2(0.0, -4.0), 2.5, Color(1.0, 0.83, 0.35))
        draw_circle(center + Vector2(4.0, -2.0), 2.5, Color(1.0, 0.9, 0.5))
