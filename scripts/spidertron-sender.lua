local SpidertronSender = {}
SpidertronSender.name = "spidertron-sender"
SpidertronSender.remote = "spidertron-remote"
SpidertronSender.launch_signal = "spidertron-launch"

local updateConnectionState, recordPath, updateSpidertron

function SpidertronSender.on_create(event)
    local entity
    if event.entity and event.entity.valid then
        entity = event.entity
    end
    if event.created_entity and event.created_entity.valid then
        entity = event.created_entity
    end
    if not entity or entity.name ~= SpidertronSender.name then return end
    
    -- Store sender.
    global.spidertron_senders = global.spidertron_senders or {}
    global.spidertron_senders[entity.unit_number] = {
        entity = entity,
        spidertron = nil,
        path = nil,
    }
end
Events.addListener(defines.events.on_built_entity, SpidertronSender.on_create)
Events.addListener(defines.events.on_robot_built_entity, SpidertronSender.on_create)
Events.addListener(defines.events.script_raised_built, SpidertronSender.on_create)
Events.addListener(defines.events.script_raised_revive, SpidertronSender.on_create)

function SpidertronSender.delete(unit_number)
    global.spidertron_senders[unit_number] = nil
end

function SpidertronSender.on_delete(event)
    if not event.entity or not event.entity.valid or event.entity.name ~= SpidertronSender.name then return end
    if not global.spidertron_senders or not global.spidertron_senders[event.entity.unit_number] then return end

    SpidertronSender.delete(event.entity.unit_number)
end
Events.addListener(defines.events.on_entity_died, SpidertronSender.on_delete)
Events.addListener(defines.events.on_robot_mined_entity, SpidertronSender.on_delete)
Events.addListener(defines.events.on_player_mined_entity, SpidertronSender.on_delete)
Events.addListener(defines.events.script_raised_destroy, SpidertronSender.on_delete)

function SpidertronSender.update(tick)
    for unit_number, sender in pairs(global.spidertron_senders or {}) do
        if not sender.entity.valid then
            SpidertronSender.delete(unit_number)
            goto continue
        end

        updateConnectionState(sender)
        updateSpidertron(sender)

        ::continue::
    end
end
Events.repeatingTask(60, SpidertronSender.update)

function updateConnectionState(sender)
    -- Todo: what if there is another spider connected? what if no spider is connected anymore?
    -- Todo: GUI & error messages
    local inventory = sender.entity.get_inventory(defines.inventory.chest)
    local remote = inventory[1]
    if not remote or  not remote.valid_for_read or remote.name ~= SpidertronSender.remote then return end
    local spider = remote.connected_entity
    if not spider or not spider.valid then return end
    if sender.spidertron and spider.unit_number == sender.spidertron.unit_number then return end

    if spider.surface.index ~= sender.entity.surface.index then return end

    sender.spidertron = spider
    recordPath(sender)
end

function recordPath(sender)
    if #sender.spidertron.autopilot_destinations > 0 then
        sender.path = {}
        for _,step in pairs(sender.spidertron.autopilot_destinations) do
            sender.path[#sender.path + 1] = {x = step.x, y = step.y}
        end
    end
end

function updateSpidertron(sender)
    local launch_signal = {type = "virtual", name = SpidertronSender.launch_signal}
    if not sender.spidertron or not sender.path or #sender.path == 0 then return end
    local signal =
        sender.entity.get_merged_signal(launch_signal, defines.circuit_connector_id.container)
    if signal > 0 then
        sender.spidertron.autopilot_destination = nil
        for _,step in pairs(sender.path) do
            sender.spidertron.add_autopilot_destination(step)
        end
    end
end
