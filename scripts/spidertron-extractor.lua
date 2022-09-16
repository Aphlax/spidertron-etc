local SpidertronExtractor = {}
SpidertronExtractor.name = "spidertron-extractor"
SpidertronExtractor.config_name = "spidertron-extractor-config"
SpidertronExtractor.signal_name = "spidertron-extractor-signal"
SpidertronExtractor.window_name = "spidertron-extractor-frame"
SpidertronExtractor.button_name = "spidertron-extractor-config-button"
SpidertronExtractor.docked_signal = "spidertron-docked"
SpidertronExtractor.transfer_complete_signal = "spidertron-transfer-complete"

local createTransferConfig, createItemIcon, fillTransferConfigGui
local MIN_DISTANCE = 8

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

    -- Create config chest.
    local config = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronExtractor.config_name,
        position = entity.position,
        create_build_effect_smoke = false,
    })
    config.destructible = false

    -- Create signal constant combinator
    local signal = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronExtractor.signal_name,
        position = translate(entity.position, 0.5, -0.5),
        create_build_effect_smoke = false,
    })
    signal.destructible = false

    -- Store processor.
    global.spidertron_extractors = global.spidertron_extractors or {}
    global.spidertron_extractors[entity.unit_number] = {
        entity = entity,
        config = config,
        signal = signal,
        spidertron = nil,
        transfer = nil,
        transfer_config = nil,
    }
    global.spidertron_extractor_configs = global.spidertron_extractor_configs or {}
    global.spidertron_extractor_configs[config.unit_number] = entity.unit_number

    entity.rotatable = false
end
Events.addListener(defines.events.on_built_entity, SpidertronExtractor.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronExtractor.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronExtractor.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronExtractor.on_create)

function SpidertronExtractor.delete(extractor, unit_number)
    if extractor.config.valid then
        global.spidertron_extractor_configs[extractor.config.unit_number] = nil
        extractor.config.destroy()
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
        if not extractor.entity.valid or not extractor.config.valid or not extractor.signal.valid then
            SpidertronExtractor.delete(extractor, unit_number)
            goto continue
        end
        local target = translate(extractor.entity.position, 0, 1)

        -- connect with spidertron
        if not extractor.spidertron then
            -- check if there is a spidertron near.
            local spiders = extractor.entity.surface.find_entities_filtered({
                position = extractor.entity.position,
                radius = MIN_DISTANCE / 2,
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
                        v_length(v_sub(spider.autopilot_destination, target)) > 1 then
                    goto continue2
                end
                -- if the spidertron is at the target, set the spidertron as connected
                if v_length(v_sub(spider.position, target)) < 1 and spider.speed == 0 then
                    extractor.spidertron = spider
                    -- The current state of the transfer.
                    extractor.transfer = createTransferConfig(extractor.config)
                    -- The starting state of the transfer (for when it changes mid-transfer).
                    extractor.transfer_config = createTransferConfig(extractor.config)
                    SpidertronExtractor.on_gui_update(extractor)
                    break
                end
                -- otherwise, set a waypoint to the center of this entity
                if v_length(v_sub(spider.position, target)) > 2 then
                    spider.autopilot_destination = target
                    goto continue2
                end
                -- if close enough, just teleport to the target
                if spider.speed == 0 then
                    spider.teleport(target)
                    spider.torso_orientation = 0.5
                    spider.stop_spider()
                end

                ::continue2::
            end
        else
            -- if the spidertron is not at the center anymore, disconnect
            if not extractor.spidertron.valid or
                    v_length(v_sub(extractor.spidertron.position, target)) > 1 then
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

        -- transfer items
        local trunk = extractor.spidertron.get_inventory(defines.inventory.spider_trunk)
        local trash = extractor.spidertron.get_inventory(defines.inventory.spider_trash)
        local output = extractor.entity.get_inventory(defines.inventory.chest)
        for i, item in ipairs(extractor.transfer or {}) do
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
Events.repeatingTask(30, SpidertronExtractor.update)


function SpidertronExtractor.on_open_gui(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity then return end
    if event.entity.name == SpidertronExtractor.signal_name then
        game.get_player(event.player_index).opened = nil
        return
    end
    if event.entity.name ~= SpidertronExtractor.name then return end
    local extractor = global.spidertron_extractors[event.entity.unit_number]
    if not extractor or not extractor.entity.valid then return end

    local player = game.get_player(event.player_index)
    local frame = player.gui.relative.add({type = "frame", name = SpidertronExtractor.window_name,
                                           direction = "vertical"})
    frame.anchor = { gui = defines.relative_gui_type.container_gui,
                     position = defines.relative_gui_position.right }
    frame.style.size = {165, 165}

    local div1 = frame.add({type = "flow", direction = "horizontal"})
    div1.add({type = "label", caption = "Configure"}).style.top_margin = 10
    div1.add({type = "sprite-button", name = SpidertronExtractor.button_name,
              sprite = "item/iron-gear-wheel"})

    local div2 = frame.add({type = "flow", direction = "horizontal"})
    div2.add({type = "label", caption = "Items:"}).style.bottom_margin = 4
    local item_config = div2.add({type = "flow", direction = "horizontal", name = "item_config"})
    for i = 1,64 do
        local item = extractor.config.get_request_slot(i)
        if item then
            createItemIcon(item_config, item)
        end
    end
    if #item_config.children == 0 then
        item_config.add({type = "label", caption = "Configure Items"}).style.font_color = {r = 1}
    end

    local div3 = frame.add({type = "flow", direction = "horizontal", name = "div3"})
    div3.add({type = "label", caption = "Spidertron:"}).style.bottom_margin = 4
    local caption = extractor.spidertron and "Connected" or "None"
    div3.add({type = "label", caption = caption, name = "state_label"}).style.font_color =
        extractor.spidertron and {g = 1} or {r = 1}

    if extractor.transfer then
        local div4 = frame.add({type = "flow", direction = "horizontal", name = "div4"})
        div4.add({type = "label", caption = "Transfer:"})
        local transfer_config = div4.add({type = "flow", direction = "horizontal",
                                          name = "transfer_config"})
        fillTransferConfigGui(transfer_config, extractor.transfer)
    end
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

    if event.entity.name == SpidertronExtractor.config_name then
        local unit_number = (global.spidertron_extractor_configs or {})[event.entity.unit_number]
        if not unit_number or not (global.spidertron_extractors or {})[unit_number] then return end
        SpidertronExtractor.on_transfer_update((global.spidertron_extractors or {})[unit_number])
    end
end
Events.addListener(defines.events.on_gui_closed, SpidertronExtractor.on_close_gui)

function SpidertronExtractor.on_gui_click(event)
    if not event.element or not event.element.valid or
            event.element.name ~= SpidertronExtractor.button_name then
        return
    end
    local player = game.get_player(event.player_index)
    local extractor = global.spidertron_extractors[player.opened.unit_number]
    if not extractor then
        return
    end

    player.opened = extractor.config
end
Events.addListener(defines.events.on_gui_click, SpidertronExtractor.on_gui_click)

function SpidertronExtractor.on_gui_update(extractor)
    for _,player in pairs(game.players) do
        local frame = player.gui.relative[SpidertronExtractor.window_name]
        if not frame or player.opened.unit_number ~= extractor.entity.unit_number then goto continue end

        local state_label = frame["div3"]["state_label"]
        state_label.caption = extractor.spidertron and "Connected" or "None"
        state_label.style.font_color = extractor.spidertron and {g = 1} or {r = 1}

        if extractor.transfer then
            if not frame["div4"] then
                local div4 = frame.add({type = "flow", direction = "horizontal", name = "div4"})
                div4.add({type = "label", caption = "Transfer:"})
                div4.add({type = "flow", direction = "horizontal", name = "transfer_config"})
            end
            local transfer_config = frame["div4"]["transfer_config"]
            transfer_config.clear()
            fillTransferConfigGui(transfer_config, extractor.transfer)
        else
            if frame["div4"] then
                frame["div4"].destroy()
            end
        end

        ::continue::
    end
end

function SpidertronExtractor.on_transfer_update(extractor)
    local new_config = createTransferConfig(extractor.config)
    for _,item in pairs(new_config) do
        local old
        for _,old_item in pairs(extractor.transfer_config or {}) do
            if old_item.name == item.name then
                old = old_item
                break
            end
        end
        if old then
            if item.count > old.count then
                local done = false
                for _,current_item in pairs(extractor.transfer or {}) do
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
            end
        elseif extractor.transfer then
            extractor.transfer[#extractor.transfer + 1] = {name = item.name, count = item.count}
        end
    end
    extractor.transfer_config = new_config
end

function createTransferConfig(config)
    local transferConfig = {}
    for i=1, 64 do
        local item = config.get_request_slot(i)
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
        transfer_config.add({type = "label", caption = "Done"}).style.font_color = {g = 1}
    end
    for _,item in pairs(transfer) do
        createItemIcon(transfer_config, item)
    end
end
