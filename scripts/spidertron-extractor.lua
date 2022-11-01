local SpidertronExtractor = {}
SpidertronExtractor.name = "spidertron-extractor"
SpidertronExtractor.output_name = "spidertron-extractor-output"
SpidertronExtractor.signal_name = "spidertron-extractor-signal"
SpidertronExtractor.window_name = "spidertron-extractor-frame"
SpidertronExtractor.slot_name = "spidertron-extractor-slot"
SpidertronExtractor.docked_signal = "spidertron-docked"
SpidertronExtractor.transfer_complete_signal = "spidertron-transfer-complete"

local createTransferConfig, createItemIcon, fillTransferConfigGui
local MIN_DISTANCE = 8
local CATCH_RADIUS = 3
local DOCKED_RADIUS = 0.3
local NUMBER_CONFIG_SLOTS = 20

function SpidertronExtractor.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= SpidertronExtractor.name then return end

    -- Enforce minimum distance.
    for _,extractor in pairs(global.spidertron_extractors or {}) do
        if not extractor.entity.valid or extractor.entity.surface.index ~= entity.surface.index then
            goto continue
        end
        local dist = v_sub(extractor.entity.position, entity.position)
        if math.abs(dist.x) <= MIN_DISTANCE and math.abs(dist.y) <= MIN_DISTANCE then
            local player = event.player_index and game.get_player(event.player_index) or nil
            local inventory = player and player.get_inventory(defines.inventory.character_main)
            entity.mine({ inventory = inventory.entity_owner and inventory or nil,
                          force = true, ignore_mineable = true, })
            rendering.draw_rectangle({
                left_top = translate(extractor.entity.position, -MIN_DISTANCE, -MIN_DISTANCE),
                right_bottom = translate(extractor.entity.position, MIN_DISTANCE, MIN_DISTANCE),
                surface = extractor.entity.surface,
                color = {r = 0.2, g = 0, b = 0, a = 0.01},
                filled = true,
                players = player and { player } or nil,
                draw_on_ground = true,
                time_to_live = 90,
            })
            return
        end
        ::continue::
    end

    -- Create output chest.
    local output = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronExtractor.output_name,
        position = entity.position,
        raise_built = false,
        create_build_effect_smoke = false,
    })
    output.destructible = false

    -- Create signal constant combinator
    local signal = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronExtractor.signal_name,
        position = translate(entity.position, 0.5, -0.5),
        raise_built = false,
        create_build_effect_smoke = false,
    })
    signal.destructible = false

    -- Store processor.
    global.spidertron_extractors = global.spidertron_extractors or {}
    global.spidertron_extractors[entity.unit_number] = {
        entity = entity,
        output = output,
        signal = signal,
        spidertron = nil,
        -- The current state of the transfer.
        transfer = nil,
        -- The starting state of the transfer (for when it changes mid-transfer).
        transfer_config = nil,
    }

    entity.rotatable = false
end
Events.addListener(defines.events.on_built_entity, SpidertronExtractor.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronExtractor.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronExtractor.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronExtractor.on_create)

function SpidertronExtractor.delete(extractor, unit_number)
    if extractor.output.valid then
        extractor.output.destroy()
    end
    if extractor.signal.valid then
        extractor.signal.destroy()
    end
    global.spidertron_extractors[unit_number] = nil
end

function SpidertronExtractor.on_delete(event)
    if not event.entity or not event.entity.valid or event.entity.name ~= SpidertronExtractor.name then return end
    if not global.spidertron_extractors or not global.spidertron_extractors[event.entity.unit_number] then return end

    SpidertronExtractor.delete(global.spidertron_extractors[event.entity.unit_number], event.entity.unit_number)
end
Events.addListener(defines.events.on_entity_died, SpidertronExtractor.on_delete)
Events.addListener(defines.events.on_robot_mined_entity, SpidertronExtractor.on_delete)
Events.addListener(defines.events.on_player_mined_entity, SpidertronExtractor.on_delete)
Events.addListener(defines.events.script_raised_destroy, SpidertronExtractor.on_delete)

function SpidertronExtractor.update(tick)
    for unit_number, extractor in pairs(global.spidertron_extractors or {}) do
        if not extractor.entity.valid or not extractor.output.valid or not extractor.signal.valid then
            SpidertronExtractor.delete(extractor, unit_number)
            goto continue
        end
        local target = translate(extractor.entity.position, 0, 0.15)

        -- connect with spidertron
        if not extractor.spidertron then
            -- check if there is a spidertron near.
            local spiders = extractor.entity.surface.find_entities_filtered({
                position = target,
                radius = CATCH_RADIUS,
                type = "spider-vehicle",
            })
            for _, spider in pairs(spiders) do
                -- if there is, check if it has waypoints
                -- if it has more than one, ignore
                if #spider.autopilot_destinations > 1 then
                    goto continue2
                end
                -- if it has one that is far away, ignore
                if spider.autopilot_destination and
                        v_length(v_sub(spider.autopilot_destination, target)) > CATCH_RADIUS then
                    goto continue2
                end
                local distance = v_length(v_sub(spider.position, target))
                -- if the spidertron is at the target, set the spidertron as connected
                if distance < DOCKED_RADIUS and spider.speed == 0 then
                    spider.teleport(target)
                    extractor.spidertron = spider
                    extractor.transfer = createTransferConfig(extractor.entity)
                    extractor.transfer_config = createTransferConfig(extractor.entity)
                    SpidertronExtractor.on_gui_update(extractor)
                    break
                end

                if spider.speed == 0 then
                    local dir = v_sub(target, spider.position)
                    local length = 2.05 + math.min((distance - DOCKED_RADIUS) / 1.9, 0.7)
                    if spider.name ~= "spidertron" then length = 2.05 end
                    spider.autopilot_destination =
                            v_add(spider.position, v_scale(dir, length / distance))
                elseif spider.speed > 0.15 and distance < DOCKED_RADIUS / 1.2 then
                    spider.autopilot_destination = null
                    spider.stop_spider()
                end

                ::continue2::
            end
        else
            -- if the spidertron is not at the center anymore, disconnect
            if not extractor.spidertron.valid or
                    v_length(v_sub(extractor.spidertron.position, target)) > DOCKED_RADIUS then
                extractor.spidertron = nil
                extractor.transfer = nil
                extractor.transfer_config = nil
                SpidertronExtractor.on_gui_update(extractor)
            end
        end

        if not extractor.spidertron then
            local ctrl = extractor.signal.get_or_create_control_behavior()
            for i = 1, ctrl.signals_count do
                ctrl.set_signal(i, nil)
            end
            goto continue
        end

        SpidertronExtractor.on_transfer_update(extractor)

        -- transfer items
        local trunk = extractor.spidertron.get_inventory(defines.inventory.spider_trunk)
        local trash = extractor.spidertron.get_inventory(defines.inventory.spider_trash)
        local output = extractor.output.get_inventory(defines.inventory.chest)
        for i, item in ipairs(extractor.transfer) do
            local insertable_count = output.get_insertable_count(item.name)
            if insertable_count == 0 then goto continue3 end
            local item_stack = trash.find_item_stack(item.name)
            local inventory = item_stack and trash or trunk
            item_stack = item_stack or trunk.find_item_stack(item.name)
            if item_stack then
                local amount = math.min(2, item.count, insertable_count, item_stack.count)
                inventory.remove({name = item.name, count = amount})
                output.insert({name = item.name, count = amount})
                if item.count == amount then
                    table.remove(extractor.transfer, i)
                else
                    item.count = item.count - amount
                end
                SpidertronExtractor.on_gui_update(extractor)
                break
            end
            ::continue3::
        end

        -- set signal
        local ammo = extractor.spidertron.get_inventory(defines.inventory.spider_ammo)
        local item_signals = trunk.get_contents()
        for name, count in pairs(trash.get_contents()) do
            item_signals[name] = (item_signals[name] or 0) + count
        end
        for name, count in pairs(ammo.get_contents()) do
            item_signals[name] = (item_signals[name] or 0) + count
        end
        local ctrl = extractor.signal.get_or_create_control_behavior()
        ctrl.set_signal(1,
                {signal = {type = "virtual", name = SpidertronExtractor.docked_signal}, count = 1})
        local slot = 2
        if #extractor.transfer == 0 then
            local signal = {type = "virtual", name = SpidertronExtractor.transfer_complete_signal}
            ctrl.set_signal(2, {signal = signal, count = 1})
            slot = 3
        end
        for name, count in pairs(item_signals) do
            ctrl.set_signal(slot, {signal = {type = "item", name = name}, count = count})
            slot = slot + 1
        end
        for i = slot, ctrl.signals_count do
            ctrl.set_signal(i, nil)
        end

        ::continue::
    end
end
Events.repeatingTask(30, 3, SpidertronExtractor.update)

function SpidertronExtractor.on_open_gui(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity then return end
    if event.entity.name == SpidertronExtractor.signal_name then
        game.get_player(event.player_index).opened = nil
        return
    end
    if event.entity.name ~= SpidertronExtractor.name then return end
    local extractor = global.spidertron_extractors[event.entity.unit_number]
    if not extractor or not extractor.entity.valid then return end

    local anchor = { gui = defines.relative_gui_type.container_gui,
                     position = defines.relative_gui_position.right }
    local frame = GuiUtils.createFrame(event, SpidertronExtractor.window_name, anchor)

    local div1 = frame.add({type = "flow", direction = "horizontal", name = "div1"})
    local output = extractor.output.get_inventory(defines.inventory.chest)
    local slot = GuiUtils.createSlot(div1, SpidertronExtractor.slot_name, output[1])
    slot.style.top_margin = 8
    slot.style.bottom_margin = 8

    frame.add({type = "line"}).style.bottom_margin = 8

    local div2 = frame.add({type = "flow", direction = "horizontal", name = "div2"})
    div2.add({type = "label", caption = {"spidertron-etc.spidertron-extractor-spidertron"}})
            .style.bottom_margin = 4
    local caption = extractor.spidertron and {"spidertron-etc.spidertron-extractor-connected"} or
            {"spidertron-etc.spidertron-extractor-none"}
    div2.add({type = "label", caption = caption, name = "state_label"}).style.font_color =
        extractor.spidertron and {g = 1} or {r = 1}

    local div3 = frame.add({type = "flow", direction = "horizontal", name = "div3"})
    div3.style.height = 24
    div3.style.bottom_margin = 8
    if extractor.transfer then
        div3.add({type = "label", caption = {"spidertron-etc.spidertron-extractor-transfer"}})
        local transfer_config = div3.add({type = "flow", direction = "horizontal",
                                          name = "transfer_config"})
        fillTransferConfigGui(transfer_config, extractor.transfer)
    end

    frame.add({type = "line"}).style.bottom_margin = 8
    frame.add({type = "label", caption = {"spidertron-etc.spidertron-extractor-help-1"}})
    frame.add({type = "label", caption = {"spidertron-etc.spidertron-extractor-help-2"}})
            .style.top_margin = -4
    frame.add({type = "label", caption = {"spidertron-etc.spidertron-extractor-help-3"}})
            .style.top_margin = -4

end
Events.addListener(defines.events.on_gui_opened, SpidertronExtractor.on_open_gui)

function SpidertronExtractor.on_close_gui(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity then
        return
    end

    if event.entity.name == SpidertronExtractor.name then
        local player = game.get_player(event.player_index)
        if player.gui.relative[SpidertronExtractor.window_name] then
            player.gui.relative[SpidertronExtractor.window_name].destroy()
        end
        return
    end
end
Events.addListener(defines.events.on_gui_closed, SpidertronExtractor.on_close_gui)

function SpidertronExtractor.on_gui_click(event)
    if not event.element or not event.element.valid or
            event.element.name ~= SpidertronExtractor.slot_name then
        return
    end
    local player = game.get_player(event.player_index)
    local extractor = global.spidertron_extractors[player.opened.unit_number]
    if not extractor then return end

    local output = extractor.output.get_inventory(defines.inventory.chest)
    GuiUtils.clickSlot(event, output[1])
end
Events.addListener(defines.events.on_gui_click, SpidertronExtractor.on_gui_click)

function SpidertronExtractor.on_gui_update(extractor)
    for _,player in pairs(game.players) do
        local frame = player.gui.relative[SpidertronExtractor.window_name]
        if not frame or player.opened.unit_number ~= extractor.entity.unit_number then goto continue end

        local slot = frame["div1"][SpidertronExtractor.slot_name]
        local output = extractor.output.get_inventory(defines.inventory.chest)
        GuiUtils.updateSlot(slot, output[1])

        local state_label = frame["div2"]["state_label"]
        state_label.caption = extractor.spidertron and
                {"spidertron-etc.spidertron-extractor-connected"} or
                {"spidertron-etc.spidertron-extractor-none"}
        state_label.style.font_color = extractor.spidertron and {g = 1} or {r = 1}

        if extractor.transfer then
            if not frame["div3"]["transfer_config"] then
                frame["div3"].add({type = "label",
                                   caption = {"spidertron-etc.spidertron-extractor-transfer"}})
                frame["div3"].add({type = "flow", direction = "horizontal", name = "transfer_config"})
            end
            local transfer_config = frame["div3"]["transfer_config"]
            transfer_config.clear()
            fillTransferConfigGui(transfer_config, extractor.transfer)
        elseif frame["div3"]["transfer_config"] then
            frame["div3"].clear()
        end

        ::continue::
    end
end

function SpidertronExtractor.on_transfer_update(extractor)
    local new_config = createTransferConfig(extractor.entity)
    local needs_gui_update = false
    for _, item in pairs(new_config) do
        local old
        for _, old_item in pairs(extractor.transfer_config or {}) do
            if old_item.name == item.name then
                old = old_item
                break
            end
        end
        if old then
            if item.count > old.count then
                local done = false
                for _, current_item in pairs(extractor.transfer or {}) do
                    if current_item.name == item.name then
                        current_item.count = current_item.count + item.count - old.count
                        done = true
                        break
                    end
                end
                if not done and extractor.transfer then
                    extractor.transfer[#extractor.transfer + 1] =
                        {name = item.name, count = item.count - old.count}
                end
                needs_gui_update = true
            end
        elseif extractor.transfer then
            extractor.transfer[#extractor.transfer + 1] = {name = item.name, count = item.count}
            needs_gui_update = true
        end
    end
    for _, item in pairs(extractor.transfer_config) do
        local present = false
        for _, new_item in pairs(new_config) do
            if new_item.name == item.name then
                present = true
                break
            end
        end
        if not present then
            for i, current_item in ipairs(extractor.transfer or {}) do
                if current_item.name == item.name then
                    table.remove(extractor.transfer, i)
                    break
                end
            end
            needs_gui_update = true
        end
    end

    extractor.transfer_config = new_config
    if needs_gui_update then
        SpidertronExtractor.on_gui_update(extractor)
    end
end

function createTransferConfig(entity)
    local transferConfig = {}
    for i=1, NUMBER_CONFIG_SLOTS do
        local item = entity.get_request_slot(i)
        if item then
            transferConfig[#transferConfig + 1] = { name = item.name, count = item.count }
        end
    end
    return transferConfig
end

function createItemIcon(parent, item)
    local style = parent.add({type = "sprite", sprite = "item/" .. item.name,
                              resize_to_sprite = false}).style
    style.width = 20
    style.height = 20
    if item.count then
        style = parent.add({type = "label", caption = item.count}).style
        style.top_margin = 4
        style.left_margin = #tostring(item.count) * -6 - 6
        style.font = "count-font"
    end
end

function fillTransferConfigGui(transfer_config, transfer)
    if #transfer == 0 then
        transfer_config.add({type = "label",
                             caption = {"spidertron-etc.spidertron-extractor-transfer-complete"}})
                .style.font_color = {g = 1}
    end
    for i,item in ipairs(transfer) do
        if i > 8 then break end
        createItemIcon(transfer_config, item)
    end
end
