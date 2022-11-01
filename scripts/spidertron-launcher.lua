local SpidertronLauncher = {}
SpidertronLauncher.name = "spidertron-launcher"
SpidertronLauncher.container_name = "spidertron-launcher-container"

local launchSpider

function SpidertronLauncher.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= SpidertronLauncher.name then return end
    
    entity.active = false
    entity.rotatable = false
    
    -- Create input chest.
    local container = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronLauncher.container_name,
        position = entity.position,
        direction = entity.direction,
        raise_built = false,
        create_build_effect_smoke = false,
    })
    container.destructible = false
    
    -- Store launcher.
    global.spidertron_launchers = global.spidertron_launchers or {}
    global.spidertron_launchers[entity.unit_number] = {
        entity = entity,
        container = container,
        internal_inventory = game.create_inventory(1),
        task_start = nil,
    }
end
Events.addListener(defines.events.on_built_entity, SpidertronLauncher.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronLauncher.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronLauncher.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronLauncher.on_create)

function SpidertronLauncher.delete(launcher, unit_number, player_index)
    if not launcher.internal_inventory.is_empty() and launcher.container.valid then
        GameUtils.give_items_to_player(launcher.internal_inventory[1], player_index, launcher.container)
    end
    if launcher.container.valid then
        local chest = launcher.container.get_inventory(defines.inventory.chest)
        for i = 1, #chest do
            GameUtils.give_items_to_player(chest[i], player_index, launcher.container)
        end
        launcher.container.destroy()
    end
    global.spidertron_launchers[unit_number] = nil
end

function SpidertronLauncher.on_delete(event)
    local entity = event.entity
    if not entity or not entity.valid or entity.name ~= SpidertronLauncher.name then return end
    if not global.spidertron_launchers or not global.spidertron_launchers[entity.unit_number] then return end
    
    SpidertronLauncher.delete(global.spidertron_launchers[entity.unit_number], entity.unit_number, event.player_index)
end
Events.addListener(defines.events.on_entity_died, SpidertronLauncher.on_delete)
Events.addListener(defines.events.on_robot_mined_entity, SpidertronLauncher.on_delete)
Events.addListener(defines.events.on_player_mined_entity, SpidertronLauncher.on_delete)
Events.addListener(defines.events.script_raised_destroy, SpidertronLauncher.on_delete)

function SpidertronLauncher.on_open_gui(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity or
            event.entity.name ~= SpidertronLauncher.name then return end
    if not global.spidertron_launchers or
            not global.spidertron_launchers[event.entity.unit_number] then return end
    local launcher = global.spidertron_launchers[event.entity.unit_number]
    if launcher.container.valid then
        game.get_player(event.player_index).opened = launcher.container
    end
end
Events.addListener(defines.events.on_gui_opened, SpidertronLauncher.on_open_gui)

function SpidertronLauncher.update(tick)
    for unit_number, launcher in pairs(global.spidertron_launchers or {}) do
        if not launcher.entity.valid or not launcher.container.valid then
            SpidertronLauncher.delete(launcher, unit_number)
            goto continue
        end

        if launcher.task_start == nil then
            local input = launcher.container.get_inventory(defines.inventory.chest)
            local output = launcher.entity.surface.find_entities_filtered(
                    {position = launcher.entity.position, radius = 2, type = "spider-vehicle"})
            if input.is_empty() or #output > 0 then goto continue end
            local spidertron_item = input[1]
            if not spidertron_item.valid_for_read then goto continue end
            if not spidertron_item.prototype.place_result or
                    spidertron_item.prototype.place_result.type ~= "spider-vehicle" then
                goto continue
            end

            launcher.task_start = tick
            launcher.internal_inventory.insert(spidertron_item)
            input.remove({name = spidertron_item.name, count = 1})

            launchSpider(launcher, tick)
        else
            launchSpider(launcher, tick)
        end

            ::continue::
        end
end
Events.repeatingTask(60, 4, SpidertronLauncher.update)

function launchSpider(launcher, tick)
    local task_time = tick - launcher.task_start
    if task_time == 0 * 60 then
        local animation_speed, time_to_live = 0.5, 7 * 60
        rendering.draw_animation({
            animation = "spidertron-launcher-animation",
            surface = launcher.entity.surface,
            target = launcher.entity,
            render_layer = "object",
            time_to_live = time_to_live - 1 / animation_speed,
            animation_speed = animation_speed,
            animation_offset = -(tick % time_to_live) * animation_speed,
        })

        local spidertron = launcher.entity.surface.create_entity({
            force = launcher.entity.force,
            position = launcher.entity.position,
            direction = launcher.entity.direction,
            name = launcher.internal_inventory[1].prototype.place_result.name,
            item = launcher.internal_inventory[1],
            raise_built = false,
            create_build_effect_smoke = false,
        })
        local color = spidertron.color
        spidertron.mine({force = true, raise_destroyed = false, ignore_mineable = true})
        rendering.draw_animation({
            animation = "spidertron-launcher-animation-tint",
            surface = launcher.entity.surface,
            target = launcher.entity,
            render_layer = "130", -- object + 1
            time_to_live = time_to_live - 1 / animation_speed,
            animation_speed = animation_speed,
            animation_offset = -(tick % time_to_live) * animation_speed,
            tint = color,
        })

        game.play_sound({
            path = "spidertron-launcher-sound",
            position = launcher.entity.position,
            volume_modifier = 0.8,
        })
        launcher.entity.active = true
    elseif task_time >= 4 * 60 and not launcher.internal_inventory.is_empty() then
        launcher.entity.surface.create_entity({
            force = launcher.entity.force,
            position = translate(launcher.entity.position, 0, -0.2),
            direction = launcher.entity.direction,
            name = launcher.internal_inventory[1].prototype.place_result.name,
            item = launcher.internal_inventory[1],
        })
        launcher.internal_inventory.clear()
    elseif task_time >= 7 * 60 then
        launcher.task_start = nil
        launcher.entity.active = false
    end
end
