local EquipmentGantryLimit = {}
EquipmentGantryLimit.name = "equipment-gantry"
EquipmentGantryLimit.chest_names =
        {"equipment-gantry-container-equipment", "equipment-gantry-container-equipment-horizontal"}

function EquipmentGantryLimit.on_init()
    global.equipment_gantry_chests = global.equipment_gantry_chests or {}
    for _, surface in pairs(game.surfaces) do
        for _, name in pairs(EquipmentGantryLimit.chest_names) do
            local chests = surface.find_entities_filtered({name = name})
            for _, chest in pairs(chests) do
                if chest and chest.valid then
                    global.equipment_gantry_chests[chest.unit_number] = chest
                end
            end
        end
    end
end
script.on_init(EquipmentGantryLimit.on_init)

function EquipmentGantryLimit.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.destination and event.destination.valid then -- For clone event.
        entity = event.destination
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= EquipmentGantryLimit.name then return end

    -- Find equipment input chest.
    local name = EquipmentGantryLimit.chest_names[(entity.direction % 4 == 0) and 2 or 1]
    local position = v_add(entity.position, direction_vector(entity.direction))
    local chest = entity.surface.find_entities_filtered({position = position, name = name})[1]
    if not chest or not chest.valid then return end

    -- Store chest.
    global.equipment_gantry_chests = global.equipment_gantry_chests or {}
    global.equipment_gantry_chests[chest.unit_number] = chest
end
Events.addListener(defines.events.on_built_entity, EquipmentGantryLimit.on_create)
Events.addListener(defines.events.on_robot_built_entity, EquipmentGantryLimit.on_create)
Events.addListener(defines.events.script_raised_built, EquipmentGantryLimit.on_create)
Events.addListener(defines.events.script_raised_revive, EquipmentGantryLimit.on_create)
-- Clone.
Events.addListener(defines.events.on_entity_cloned, EquipmentGantryLimit.on_create)

function EquipmentGantryLimit.update(tick)
    for unit_number, chest in pairs(global.equipment_gantry_chests or {}) do
        if not chest.valid then
            global.equipment_gantry_chests[unit_number] = nil
            goto continue
        end

        local inventory = chest.get_inventory(defines.inventory.chest)
        if inventory.is_empty() then
            inventory.set_bar()
        else
            inventory.set_bar(1)
        end

        ::continue::
    end
end
Events.repeatingTask(15, 2, EquipmentGantryLimit.update)

return EquipmentGantryLimit
