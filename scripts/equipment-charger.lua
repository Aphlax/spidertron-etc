local EquipmentCharger = {}
EquipmentCharger.name = "equipment-charger"
EquipmentCharger.max_transfer_per_update = 100000000 -- About 12x the max charging rate.

function EquipmentCharger.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= EquipmentCharger.name then return end
    
    -- Create input chest.
    local input = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronFefUtils.getInputContainerName(entity.direction),
        position = v_add(entity.position, v_rotate({ x = -0.5, y = 0.9 }, entity.direction)),
    })
    input.destructible = false
    
    -- Create output chest.
    local output = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronFefUtils.getOutputContainerName(entity.direction),
        position = v_add(entity.position, v_rotate({ x = 0.5, y = 0.9 }, entity.direction)),
    })
    output.destructible = false
    
    -- Store charger.
    global.spidertron_chargers = global.spidertron_chargers or {}
    global.spidertron_chargers[entity.unit_number] = {
        entity = entity,
        unit_number = entity.unit_number,
        input = input,
        output = output,
    }
    
    entity.active = false
    entity.rotatable = false
end
Events.addListener(defines.events.on_built_entity, EquipmentCharger.on_create)
Events.addListener(defines.events.on_robot_built_entity, EquipmentCharger.on_create)
Events.addListener(defines.events.script_raised_built, EquipmentCharger.on_create)
Events.addListener(defines.events.script_raised_revive, EquipmentCharger.on_create)

function EquipmentCharger.delete(charger, unit_number, player_index)
    if charger.input.valid then
        local chest = charger.input.get_inventory(defines.inventory.chest)
        for i = 1, #chest do
            GameUtils.give_items_to_player(chest[i], player_index, charger.input)
        end
        charger.input.destroy()
    end
    if charger.output.valid then
        local chest = charger.output.get_inventory(defines.inventory.chest)
        for i = 1, #chest do
            GameUtils.give_items_to_player(chest[i], player_index, charger.output)
        end
        charger.output.destroy()
    end
    global.spidertron_chargers[unit_number] = nil
end

function EquipmentCharger.on_delete(event)
    if not event.entity or not event.entity.valid or event.entity.name ~= EquipmentCharger.name then return end
    if not global.spidertron_chargers or not global.spidertron_chargers[event.entity.unit_number] then return end
    
    EquipmentCharger.delete(global.spidertron_chargers[event.entity.unit_number], event.entity.unit_number, event.player_index)
end
Events.addListener(defines.events.on_entity_died, EquipmentCharger.on_delete)
Events.addListener(defines.events.on_robot_mined_entity, EquipmentCharger.on_delete)
Events.addListener(defines.events.on_player_mined_entity, EquipmentCharger.on_delete)
Events.addListener(defines.events.script_raised_destroy, EquipmentCharger.on_delete)

function EquipmentCharger.update(tick)
    for unit_number, charger in pairs(global.spidertron_chargers or {}) do
        if not charger.entity.valid or not charger.input.valid or not charger.output.valid then
            EquipmentCharger.delete(charger, unit_number)
            goto continue
        end
        
        if charger.entity.energy == 0 then goto continue end
        local input = charger.input.get_inventory(defines.inventory.chest)
        local output = charger.output.get_inventory(defines.inventory.chest)
        if input.is_empty() or not output.is_empty() then goto continue end
        local equipment_item = input[1]
        if not equipment_item.valid_for_read or equipment_item.type ~= "item-with-entity-data" then goto continue end
        if not equipment_item.grid then
            equipment_item.create_grid()
        end
        if not equipment_item.grid then goto continue end

        local transfer_available = EquipmentCharger.max_transfer_per_update
        for _, equipment in pairs(equipment_item.grid.equipment or {}) do
            if equipment.energy < equipment.max_energy then
                local transfer = math.min(equipment.max_energy - equipment.energy,
                        charger.entity.energy, transfer_available)
                charger.entity.energy = charger.entity.energy - transfer
                equipment.energy = equipment.energy + transfer
                transfer_available = transfer_available - transfer
            end
            if transfer_available == 0 or charger.entity.energy == 0 then goto continue end
        end
        
        -- Fully charged.
        output.insert(equipment_item)
        input.remove({ name = equipment_item.name, count = 1 })
        
        ::continue::
    end
end
Events.repeatingTask(10, EquipmentCharger.update)








