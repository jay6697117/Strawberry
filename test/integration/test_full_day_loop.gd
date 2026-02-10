extends GutTest

func test_core_loop_from_seed_to_sell_updates_gold() -> void:
    if not FileAccess.file_exists("res://scripts/economy/shop_service.gd"):
        fail_test("res://scripts/economy/shop_service.gd should exist")
        return
    if not FileAccess.file_exists("res://scripts/inventory/inventory_model.gd"):
        fail_test("res://scripts/inventory/inventory_model.gd should exist")
        return
    if not FileAccess.file_exists("res://scripts/economy/shipping_bin_service.gd"):
        fail_test("res://scripts/economy/shipping_bin_service.gd should exist")
        return
    if not FileAccess.file_exists("res://scripts/autoload/session_state.gd"):
        fail_test("res://scripts/autoload/session_state.gd should exist")
        return

    var shop_script := load("res://scripts/economy/shop_service.gd")
    var inventory_script := load("res://scripts/inventory/inventory_model.gd")
    var shipping_script := load("res://scripts/economy/shipping_bin_service.gd")
    var session_script := load("res://scripts/autoload/session_state.gd")
    assert_not_null(shop_script)
    assert_not_null(inventory_script)
    assert_not_null(shipping_script)
    assert_not_null(session_script)
    if shop_script == null or inventory_script == null or shipping_script == null or session_script == null:
        return

    var shop = shop_script.new()
    var inventory = inventory_script.new(36)
    var shipping = shipping_script.new()
    var session: Node = add_child_autofree(session_script.new())

    session.gold = 500
    var purchased = shop.buy(session, inventory, "parsnip_seed", 20, 1)
    assert_true(purchased)

    inventory.add_item("parsnip", 1)
    shipping.add_item("parsnip", 1)

    var before = session.gold
    var earned = shipping.settle_to_session(session, {"parsnip": 35})
    assert_eq(earned, 35)
    assert_gt(session.gold, before)

func test_ui_files_exist_for_hud_and_shop() -> void:
    assert_true(FileAccess.file_exists("res://scenes/ui/hud.tscn"))
    assert_true(FileAccess.file_exists("res://scenes/ui/shop_panel.tscn"))
    assert_true(FileAccess.file_exists("res://scripts/ui/hud_controller.gd"))
