local EquipmentCharger = {}
EquipmentCharger.name = "equipment-charger"
EquipmentCharger.pad_name = "equipment-charger-pad"

local MAX_TRANSFER_PER_UPDATE = 100000000 -- About 12x the max charging rate.
local PAD_MAX_TRANSFER_PER_UPDATE = MAX_TRANSFER_PER_UPDATE / 50 -- About 5x the max charging rate.

function EquipmentCharger.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end

    if entity and entity.name == EquipmentCharger.pad_name then
        global.equipment_charger_pads = global.equipment_charger_pads or {}
        global.equipment_charger_pads[entity.unit_number] = entity
        return
    end
    if not entity or entity.name ~= EquipmentCharger.name then return end

    -- Create input chest.
    local input = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronFefUtils.getInputContainerName(entity.direction),
        position = v_add(entity.position, v_rotate({ x = -0.5, y = 0.4 }, entity.direction)),
        raise_built = false,
        create_build_effect_smoke = false,
    })
    input.destructible = false

    -- Create output chest.
    local output = entity.surface.create_entity({
        force = entity.force,
        name = SpidertronFefUtils.getOutputContainerName(entity.direction),
        position = v_add(entity.position, v_rotate({ x = 0.5, y = 0.4 }, entity.direction)),
        raise_built = false,
        create_build_effect_smoke = false,
    })
    output.destructible = false

    -- Store charger.
    global.spidertron_chargers = global.spidertron_chargers or {}
    global.spidertron_chargers[entity.unit_number] = {
        entity = entity,
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

        if EquipmentCharger.chargeItem(charger.entity, equipment_item, MAX_TRANSFER_PER_UPDATE) then
            -- Fully charged.
            output.insert(equipment_item)
            input.remove({ name = equipment_item.name, count = 1 })
        end
        
        ::continue::
    end
    for unit_number, charger in pairs(global.equipment_charger_pads or {}) do
        if not charger.valid then
            global.equipment_charger_pads[unit_number] = nil
            goto continue
        end

        local characters = charger.surface.find_entities_filtered({
            type = "character",
            area = {
                left_top = translate(charger.position, -1.95, 0),
                right_bottom = translate(charger.position, 1.95, 1.95 * 2),
            },
        })
        for _, character in pairs(characters) do
            local armor = character.get_inventory(defines.inventory.character_armor)
            if not armor.is_empty() then
                EquipmentCharger.chargeItem(charger, armor[1], PAD_MAX_TRANSFER_PER_UPDATE)
            end
        end

        ::continue::
    end
end
Events.repeatingTask(10, 1, EquipmentCharger.update)

-- Returns true if all parts have been charged.
function EquipmentCharger.chargeItem(entity, equipment_item, transfer_available)
    if not equipment_item.valid_for_read then return false end
    if not equipment_item.grid and equipment_item.type == "item-with-entity-data" then
        equipment_item.create_grid()
    end
    if not equipment_item.grid then return false end

    for _, equipment in pairs(equipment_item.grid.equipment or {}) do
        if equipment.energy < equipment.max_energy then
            local transfer = math.min(equipment.max_energy - equipment.energy,
                    entity.energy, transfer_available)
            entity.energy = entity.energy - transfer
            equipment.energy = equipment.energy + transfer
            transfer_available = transfer_available - transfer
        end
        if transfer_available == 0 or entity.energy == 0 then return false end
    end

    return true
end
