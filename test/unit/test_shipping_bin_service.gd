extends GutTest

func test_shipping_bin_settlement_adds_gold_and_clears_queue() -> void:
    if not FileAccess.file_exists("res://scripts/economy/shipping_bin_service.gd"):
        fail_test("res://scripts/economy/shipping_bin_service.gd should exist")
        return
    if not FileAccess.file_exists("res://scripts/autoload/session_state.gd"):
        fail_test("res://scripts/autoload/session_state.gd should exist")
        return

    var shipping_script := load("res://scripts/economy/shipping_bin_service.gd")
    var session_script := load("res://scripts/autoload/session_state.gd")
    assert_not_null(shipping_script)
    assert_not_null(session_script)
    if shipping_script == null or session_script == null:
        return

    var shipping = shipping_script.new()
    var session = add_child_autofree(session_script.new())
    session.gold = 10

    shipping.add_item("parsnip", 2)
    var earned = shipping.settle_to_session(session, {"parsnip": 35})

    assert_eq(earned, 70)
    assert_eq(session.gold, 80)
    assert_eq(shipping.pending_count(), 0)
