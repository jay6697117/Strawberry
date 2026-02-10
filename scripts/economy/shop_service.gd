extends RefCounted
class_name ShopService

func buy(session_state: Node, inventory, item_id: String, price: int, amount: int) -> bool:
    var total := price * amount
    if int(session_state.gold) < total:
        return false

    session_state.gold -= total
    inventory.add_item(item_id, amount)
    return true
