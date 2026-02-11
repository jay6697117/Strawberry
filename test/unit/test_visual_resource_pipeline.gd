extends GutTest

func _assert_kenney_provenance(data: Dictionary) -> void:
    var provenance_variant: Variant = data.get("provenance", {})
    assert_true(typeof(provenance_variant) == TYPE_DICTIONARY)
    if typeof(provenance_variant) != TYPE_DICTIONARY:
        return

    var provenance := provenance_variant as Dictionary
    assert_eq(String(provenance.get("active_runtime_source", "")), "kenney")

    var forbidden_variant: Variant = provenance.get("forbidden_sources", [])
    assert_true(typeof(forbidden_variant) == TYPE_ARRAY)
    if typeof(forbidden_variant) != TYPE_ARRAY:
        return

    var forbidden_sources := forbidden_variant as Array
    assert_true(forbidden_sources.has("external_oga"))

func test_tileset_theme_declares_external_texture_paths() -> void:
    var path := "res://data/visual/tileset_theme.json"
    assert_true(FileAccess.file_exists(path))
    if not FileAccess.file_exists(path):
        return

    var file := FileAccess.open(path, FileAccess.READ)
    assert_not_null(file)
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    assert_true(typeof(parsed) == TYPE_DICTIONARY)
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var data := parsed as Dictionary
    _assert_kenney_provenance(data)

    var textures: Variant = data.get("textures", {})
    assert_true(typeof(textures) == TYPE_DICTIONARY)
    if typeof(textures) != TYPE_DICTIONARY:
        return

    var tex_dict := textures as Dictionary
    var backdrop_path := String(tex_dict.get("backdrop", ""))
    assert_false(backdrop_path.contains("external_oga"))
    assert_true(FileAccess.file_exists(backdrop_path))

    var ground_path := String(tex_dict.get("ground", ""))
    assert_false(ground_path.contains("external_oga"))
    assert_true(FileAccess.file_exists(ground_path))

    var soil_dry_path := String(tex_dict.get("soil_dry", ""))
    assert_false(soil_dry_path.contains("external_oga"))
    assert_true(FileAccess.file_exists(soil_dry_path))

    var soil_wet_path := String(tex_dict.get("soil_wet", ""))
    assert_false(soil_wet_path.contains("external_oga"))
    assert_true(FileAccess.file_exists(soil_wet_path))

    var crop_stages: Variant = tex_dict.get("crop_parsnip_stages", [])
    assert_true(typeof(crop_stages) == TYPE_ARRAY)
    if typeof(crop_stages) != TYPE_ARRAY:
        return
    var stages := crop_stages as Array
    assert_eq(stages.size(), 5)
    for stage_path in stages:
        var stage_path_str := String(stage_path)
        assert_false(stage_path_str.contains("external_oga"))
        assert_true(FileAccess.file_exists(stage_path_str))

func test_player_style_declares_external_sprite_frames() -> void:
    var path := "res://data/visual/player_style.json"
    assert_true(FileAccess.file_exists(path))
    if not FileAccess.file_exists(path):
        return

    var file := FileAccess.open(path, FileAccess.READ)
    assert_not_null(file)
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    assert_true(typeof(parsed) == TYPE_DICTIONARY)
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var data := parsed as Dictionary
    _assert_kenney_provenance(data)

    var frames: Variant = data.get("frames", {})
    assert_true(typeof(frames) == TYPE_DICTIONARY)
    if typeof(frames) != TYPE_DICTIONARY:
        return

    for dir_name in ["up", "down", "left", "right"]:
        var dir_data: Variant = (frames as Dictionary).get(dir_name, {})
        assert_true(typeof(dir_data) == TYPE_DICTIONARY)
        if typeof(dir_data) != TYPE_DICTIONARY:
            continue
        var idle_path := String((dir_data as Dictionary).get("idle", ""))
        assert_false(idle_path.contains("external_oga"))
        assert_true(FileAccess.file_exists(idle_path))

        var walk_frames: Variant = (dir_data as Dictionary).get("walk", [])
        assert_true(typeof(walk_frames) == TYPE_ARRAY)
        if typeof(walk_frames) != TYPE_ARRAY:
            continue
        var walk_array := walk_frames as Array
        assert_true(walk_array.size() >= 2)
        for frame_path in walk_array:
            var frame_path_str := String(frame_path)
            assert_false(frame_path_str.contains("external_oga"))
            assert_true(FileAccess.file_exists(frame_path_str))
