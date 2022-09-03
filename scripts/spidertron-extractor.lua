local SpidertronExtractor = {}
SpidertronExtractor.name = "spidertron-extractor"
SpidertronExtractor.config_name = "spidertron-extractor-config"
SpidertronExtractor.window_name = "spidertron-extractor-frame"
SpidertronExtractor.button_name = "spidertron-extractor-config-button"

function SpidertronExtractor.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= SpidertronExtractor.name then return end

    -- Create config chest.
    local config = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronExtractor.config_name,
        position = entity.position,
        create_build_effect_smoke = false,
    })
    config.destructible = false

    -- Store processor.
    global.spidertron_extractors = global.spidertron_extractors or {}
    global.spidertron_extractors[entity.unit_number] = {
        entity = entity,
        unit_number = entity.unit_number,
        config = config,
        spidertron = nil,
    }

    entity.rotatable = false
end
Events.addListener(defines.events.on_built_entity, SpidertronExtractor.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronExtractor.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronExtractor.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronExtractor.on_create)

function SpidertronExtractor.delete(extractor, unit_number)
    if extractor.config.valid then
        extractor.config.destroy()
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


function SpidertronExtractor.on_open_gui(event)
    if event.gui_type ~= defines.gui_type.entity or
            not event.entity or event.entity.name ~= SpidertronExtractor.name then
        return
    end

    local player = game.get_player(event.player_index)
    local frame = player.gui.relative.add({type = "frame", name = SpidertronExtractor.window_name,
                                           direction = "vertical"})
    frame.anchor = { gui = defines.relative_gui_type.container_gui,
                     position = defines.relative_gui_position.right }
    frame.style.size = {165, 165}

    frame.add({type="label", caption = "Configure"})
    frame.add({type="sprite-button", name = SpidertronExtractor.button_name,
               sprite = "item/iron-gear-wheel"})
end
Events.addListener(defines.events.on_gui_opened, SpidertronExtractor.on_open_gui)

function SpidertronExtractor.on_close_gui(event)
    if event.gui_type ~= defines.gui_type.entity or
            not event.entity or event.entity.name ~= SpidertronExtractor.name then
        return
    end

    local player = game.get_player(event.player_index)
    if player.gui.relative[SpidertronExtractor.window_name] then
        player.gui.relative[SpidertronExtractor.window_name].destroy()
    end
end
Events.addListener(defines.events.on_gui_closed, SpidertronExtractor.on_close_gui)

function SpidertronExtractor.on_gui_click(event)
    if not event.element or event.element.name ~= SpidertronExtractor.button_name then
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

function SpidertronExtractor.update(tick)
    for unit_number, extractor in pairs(global.spidertron_extractors or {}) do
        if not extractor.entity.valid or not extractor.config.valid then
            SpidertronExtractor.delete(extractor, unit_number)
            goto continue
        end
        local target = translate(extractor.entity.position, 0, 1)

        if not extractor.spidertron then
            -- check if there is a spidertron near.
            local spiders = extractor.entity.surface.find_entities_filtered(
                    { position = extractor.entity.position, radius = 5, type = "spider-vehicle"})
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
                    extractor.transfer = createTransferConfig(extractor.config)
                    goto break2
                end
                -- otherwise, set a waypoint to the center of this entity
                if v_length(v_sub(spider.position, target)) > 2 then
                    spider.autopilot_destination = target
                    goto continue2
                end
                -- if close enough, just teleport to the target
                spider.teleport(target)
                spider.torso_orientation = 0.5
                spider.stop_spider()

                ::continue2::
            end
            ::break2::
        else
            -- if the spidertron is not at the center anymore, disconnect
            if not extractor.spidertron.valid or
                    v_length(v_sub(extractor.spidertron.position, target)) > 1 then
                extractor.transfer = nil
                extractor.spidertron = nil
            end
        end

        if not extractor.spidertron then
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
                local amount = Math.min(item.count, Math.min(2,
                        Math.min(insertable_count, item_stack.count)))
                inventory.remove({ name = item.name, count = amount })
                output.insert({ name = item.name, count = amount })
                if item.count == amount then
                    table.remove(extractor.transfer, i)
                else
                    item.count = item.count - amount
                end
                goto continue
            end
            ::continue3::
        end
        ::continue::
    end
end
Events.repeatingTask(30, SpidertronExtractor.update)

function createTransferConfig(config)
    local transferConfig = {}
    for i=1, 1000 do
        local item = config.get_request_slot(i)
        if item then
            transferConfig[#transferConfig + 1] = { name = item.name, count = item.count }
        end
    end
    return transferConfig
end

-- todo update gui when connected to spidertron or items are transferred
-- todo update transferConfig when config is changed
