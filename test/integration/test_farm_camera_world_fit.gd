extends GutTest

const TILE_SIZE := 32
const GRID_WIDTH := 64
const GRID_HEIGHT := 36
const MAP_WIDTH := TILE_SIZE * GRID_WIDTH
const MAP_HEIGHT := TILE_SIZE * GRID_HEIGHT
const EPSILON := 0.0001
const TARGET_RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1536, 960),
	Vector2i(1920, 1080),
	Vector2i(2560, 1080)
]

func test_camera_world_fit_prevents_horizontal_void_for_target_resolutions() -> void:
	var farm_world := _spawn_farm_world()
	var camera := _camera_from_world(farm_world)
	assert_not_null(camera)
	if camera == null:
		return

	for resolution in TARGET_RESOLUTIONS:
		farm_world.call("_configure_camera_limits", camera, resolution)
		_assert_no_horizontal_void(camera, resolution)

func test_camera_world_fit_stays_stable_across_resize_sequence() -> void:
	var farm_world := _spawn_farm_world()
	var camera := _camera_from_world(farm_world)
	assert_not_null(camera)
	if camera == null:
		return

	var resize_sequence := [
		Vector2i(1280, 720),
		Vector2i(2560, 1080),
		Vector2i(1536, 960),
		Vector2i(1920, 1080),
		Vector2i(2560, 1080)
	]

	for resolution in resize_sequence:
		farm_world.call("_configure_camera_limits", camera, resolution)
		_assert_no_horizontal_void(camera, resolution)

		var half_height := int(ceil((float(resolution.y) * 0.5) * camera.zoom.y))
		var offset_allowance_y := int(ceil(absf(camera.offset.y)))
		assert_true(
			camera.limit_top >= half_height - offset_allowance_y,
			"limit_top should stay in vertical fit bounds for %s" % [str(resolution)]
		)
		assert_true(
			camera.limit_bottom <= MAP_HEIGHT - half_height + offset_allowance_y,
			"limit_bottom should stay in vertical fit bounds for %s" % [str(resolution)]
		)
		assert_true(camera.limit_left <= camera.limit_right)
		assert_true(camera.limit_top <= camera.limit_bottom)

func _spawn_farm_world() -> Node2D:
	var packed := load("res://scenes/farm/farm_world.tscn") as PackedScene
	return add_child_autofree(packed.instantiate())

func _camera_from_world(farm_world: Node) -> Camera2D:
	if farm_world == null:
		return null
	var player := farm_world.get_node_or_null("Player")
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as Camera2D

func _assert_no_horizontal_void(camera: Camera2D, resolution: Vector2i) -> void:
	var max_zoom_x := float(MAP_WIDTH) / float(resolution.x)
	assert_true(
		camera.zoom.x <= max_zoom_x + EPSILON,
		"zoom.x (%f) must be <= max width-fit zoom (%f) for %s" % [camera.zoom.x, max_zoom_x, str(resolution)]
	)

	var half_width := int(ceil((float(resolution.x) * 0.5) * camera.zoom.x))
	var offset_allowance_x := int(ceil(absf(camera.offset.x)))
	assert_true(
		camera.limit_left >= half_width - offset_allowance_x,
		"limit_left should stay inside width-fit bounds for %s" % [str(resolution)]
	)
	assert_true(
		camera.limit_right <= MAP_WIDTH - half_width + offset_allowance_x,
		"limit_right should stay inside width-fit bounds for %s" % [str(resolution)]
	)
