local GuiUtils = {}

function GuiUtils.createFrame(event, name, anchor, informatron)
    local player = game.get_player(event.player_index)
    local frame = player.gui.relative.add(
            {type = "frame", name = name, direction="vertical", anchor = anchor})
    frame.style.minimal_width = 300
    frame.style.vertically_stretchable = "stretch_and_expand"

    local title_div = frame.add({type = "flow", direction = "horizontal"})
    title_div.add({
        type = "label",
        style = "frame_title",
        caption = {"spidertron-etc.settings-frame-title"},
        ignored_by_interaction = true
    })
    local title_empty = title_div.add({
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true
    })
    title_empty.style.horizontally_stretchable = "on"
    title_empty.style.left_margin = 4
    title_empty.style.right_margin = 0
    title_empty.style.height = 24
    if informatron and game.active_mods["informatron"] then
        local title_informatron = title_div.add({
            type="sprite-button",
            name="open-informatron",
            sprite = "virtual-signal/informatron",
            style="informatron_close_button",
            tooltip={"spidertron-etc.help_spidertron-etc"}
        })
        title_informatron.style.width = 28
        title_informatron.style.height = 28
        title_informatron.style.left_margin = 4
    end
    return frame
end

function GuiUtils.createSlot(parent, name, item)
    local slot = parent.add({type = "button", name = name, style = "inventory_slot"})
    GuiUtils.updateSlot(slot, item)
    return slot
end

function GuiUtils.updateSlot(slot, item)
    if item and item.valid_for_read and item.count > 0 then
        if not slot["item"] then
            local icon = slot.add({type = "sprite", name = "item", resize_to_sprite = false,
                                   ignored_by_interaction = true})
            icon.style.width = 32
            icon.style.height = 32

            local count = icon.add({type = "label", name = "count", caption = "",
                                    ignored_by_interaction = true})
            count.style.top_padding = 16
            count.style.font = "count-font"
        end
        slot["item"].sprite = "item/" .. item.name
        slot["item"]["count"].caption = item.count
        slot["item"]["count"].style.left_padding = 30 + (#tostring(item.count) * -6)
    elseif slot["item"] then
        slot.clear()
    end
end

function GuiUtils.clickSlot(event, item)
    local player = game.get_player(event.player_index)
    local cursor = player.cursor_stack
    if cursor and cursor.valid_for_read and cursor.count > 0 then
        if item.valid_for_read and item.count > 0 and cursor.name == item.name then
            if item.count == item.prototype.stack_size then return end
            if event.button == defines.mouse_button_type.left then
                local count = math.min(item.prototype.stack_size - item.count, cursor.count)
                item.count = item.count + count
                cursor.count = cursor.count - count
                player.play_sound({path = "utility/inventory_click"})
            elseif event.button == defines.mouse_button_type.right then
                item.count = item.count + 1
                cursor.count = cursor.count - 1
                player.play_sound({path = "utility/inventory_click"})
            end
        elseif event.button == defines.mouse_button_type.left then
            cursor.swap_stack(item)
            player.play_sound({path = "utility/inventory_click"})
        elseif event.button == defines.mouse_button_type.right and
                (not item.valid_for_read or item.count == 0) then
            item.set_stack({name = cursor.name, count = 1})
            cursor.count = cursor.count - 1
            player.play_sound({path = "utility/inventory_click"})
        end
    else
        if not item.valid_for_read or item.count == 0 then return end
        if event.button == defines.mouse_button_type.left then
            if event.shift then
                local player_inventory = player.get_inventory(defines.inventory.character_main)
                item.count = item.count - player_inventory.insert(item)
                player.play_sound({path = "utility/inventory_move"})
            else
                cursor.set_stack(item)
                item.clear()
                player.play_sound({path = "utility/inventory_click"})
            end
        elseif event.button == defines.mouse_button_type.right then
            if event.shift then
                local player_inventory = player.get_inventory(defines.inventory.character_main)
                local count = player_inventory.insert({name = item.name, count = item.count / 2})
                item.count = item.count - count
                player.play_sound({path = "utility/inventory_move"})
            else
                cursor.set_stack(item)
                cursor.count = (item.count + 1) / 2
                item.count = item.count - cursor.count
                player.play_sound({path = "utility/inventory_click"})
            end
        end
    end
end

return GuiUtils
