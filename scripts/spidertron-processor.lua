local SpidertronProcessor = {}
SpidertronProcessor.name = "spidertron-processor"

function SpidertronProcessor.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= SpidertronProcessor.name then return end
    
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
    
    -- Store processor.
    global.spidertron_processors = global.spidertron_processors or {}
    global.spidertron_processors[entity.unit_number] = {
        entity = entity,
        unit_number = entity.unit_number,
        input = input,
        output = output,
    }
    
    entity.active = false
    entity.rotatable = false
end
Events.addListener(defines.events.on_built_entity, SpidertronProcessor.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronProcessor.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronProcessor.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronProcessor.on_create)

function SpidertronProcessor.delete(processor, unit_number, player_index)
    if processor.input.valid then
        local chest = processor.input.get_inventory(defines.inventory.chest)
        for i = 1, #chest do
            GameUtils.give_items_to_player(chest[i], player_index, processor.input)
        end
        processor.input.destroy()
    end
    if processor.output.valid then
        local chest = processor.output.get_inventory(defines.inventory.chest)
        for i = 1, #chest do
            GameUtils.give_items_to_player(chest[i], player_index, processor.output)
        end
        processor.output.destroy()
    end
    global.spidertron_processors[unit_number] = nil
end

function SpidertronProcessor.on_delete(event)
    if not event.entity or not event.entity.valid or event.entity.name ~= SpidertronProcessor.name then return end
    if not global.spidertron_processors or not global.spidertron_processors[event.entity.unit_number] then return end
    
    SpidertronProcessor.delete(global.spidertron_processors[event.entity.unit_number], event.entity.unit_number, event.player_index)
end
Events.addListener(defines.events.on_entity_died, SpidertronProcessor.on_delete)
Events.addListener(defines.events.on_robot_mined_entity, SpidertronProcessor.on_delete)
Events.addListener(defines.events.on_player_mined_entity, SpidertronProcessor.on_delete)
Events.addListener(defines.events.script_raised_destroy, SpidertronProcessor.on_delete)

function SpidertronProcessor.update(tick)
    for unit_number, processor in pairs(global.spidertron_processors or {}) do
        if not processor.entity.valid or not processor.input.valid or not processor.output.valid then
            SpidertronProcessor.delete(processor, unit_number)
            goto continue
        end
        
        local input = processor.input.get_inventory(defines.inventory.chest)
        local output = processor.output.get_inventory(defines.inventory.chest)
        if input.is_empty() or not output.is_empty() then goto continue end
        local spidertron_item = input[1]
        if not spidertron_item.valid_for_read or not (spidertron_item.name == "spidertron") then goto continue end
        
        local spidertron = processor.entity.surface.create_entity({
            force = processor.entity.force,
            position = processor.entity.position,
            direction = processor.entity.direction,
            name = spidertron_item.name,
            item = spidertron_item,
            create_build_effect_smoke = false,
        })
        if not spidertron then goto continue end
        input.remove({ name = spidertron_item.name, count = 1})
        
        for _,i in pairs(range(1000)) do
            local item = processor.entity.get_request_slot(i)
            if item then
                spidertron.set_request_slot(item, i)
            else
                spidertron.clear_request_slot(i)
            end
        end
        
        spidertron.mine({
            inventory = output,
            force = true,
            raise_destroyed = false,
            ignore_mineable = true,
        })
        
        ::continue::
    end
end
repeatingTask(60, SpidertronProcessor.update)






