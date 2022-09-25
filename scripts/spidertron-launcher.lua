local SpidertronLauncher = {}
SpidertronLauncher.name = "spidertron-launcher"
SpidertronLauncher.container_name = "spidertron-launcher-container"

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
    })
    container.destructible = false
    
    -- Store launcher.
    global.spidertron_launchers = global.spidertron_launchers or {}
    global.spidertron_launchers[entity.unit_number] = {
        entity = entity,
        unit_number = entity.unit_number,
        container = container,
    }
end
Events.addListener(defines.events.on_built_entity, SpidertronLauncher.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronLauncher.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronLauncher.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronLauncher.on_create)

function SpidertronLauncher.delete(launcher, unit_number, player_index)
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

function SpidertronLauncher.update(tick)
    for unit_number, launcher in pairs(global.spidertron_launchers or {}) do
        if not launcher.entity.valid or not launcher.container.valid then
            SpidertronLauncher.delete(launcher, unit_number)
            goto continue
        end
        
        local input = launcher.container.get_inventory(defines.inventory.chest)
        local output = launcher.entity.surface.find_entities_filtered({position = launcher.entity.position, type = "spider-vehicle"})
        if input.is_empty() or #output > 0 then goto continue end
        local spidertron_item = input[1]
        if not spidertron_item.valid_for_read or spidertron_item.name ~= "spidertron" then goto continue end
        
        launcher.entity.surface.create_entity({
            force = launcher.entity.force,
            position = launcher.entity.position,
            direction = launcher.entity.direction,
            name = spidertron_item.name,
            item = spidertron_item,
        })
        input.remove({ name = spidertron_item.name, count = 1})
        
        ::continue::
    end
end
Events.repeatingTask(60, SpidertronLauncher.update)






