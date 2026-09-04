extends RefCounted

func show(main: Control) -> void:
    main.current_screen = "shop"
    main._prepare_screen("상점")
    var items: Array = DataManager.get_table("items").get("items", [])
    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var item_dict: Dictionary = item
        var item_id := String(item_dict.get("id", ""))
        var slot := String(item_dict.get("slot", "misc"))
        var is_equipped: bool = String(GameState.equipped.get(slot, "")) == item_id
        var box: VBoxContainer = main._add_card()
        box.add_child(main._make_label("%s%s  /  %s  /  가격 %d" % [item_dict.get("name_ko", item_id), "  [장착 중]" if is_equipped else "", main._slot_name(slot), int(item_dict.get("price", 0))], 16))
        box.add_child(main._make_label(item_dict.get("summary_ko", ""), 13))
        main._add_chip_row(box, "효과", item_dict.get("effects", {}), "effect")
        var row := HFlowContainer.new()
        row.add_theme_constant_override("h_separation", 6)
        row.add_theme_constant_override("v_separation", 6)
        box.add_child(row)

        var buy := Button.new()
        main._style_button(buy)
        buy.text = "구매" if not GameState.inventory.has(item_id) else "보유 중"
        buy.disabled = GameState.inventory.has(item_id) or GameState.get_stat("cash") < int(item_dict.get("price", 0))
        var item_copy: Dictionary = item_dict
        buy.pressed.connect(func():
            GameState.change_stat("cash", -int(item_copy.get("price", 0)))
            GameState.add_item(String(item_copy.get("id", "")))
            main._show_shop()
        )
        row.add_child(buy)

        var equip := Button.new()
        main._style_button(equip)
        equip.text = "해제" if is_equipped else "장착"
        equip.disabled = not GameState.inventory.has(item_id)
        equip.pressed.connect(func():
            if GameState.equipped.get(String(item_copy.get("slot", "misc")), "") == String(item_copy.get("id", "")):
                GameState.unequip_slot(String(item_copy.get("slot", "misc")))
            else:
                GameState.equip_item(item_copy)
            main._show_shop()
        )
        row.add_child(equip)
