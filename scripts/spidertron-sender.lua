local SpidertronSender = {}
SpidertronSender.name = "spidertron-sender"
SpidertronSender.remote = "spidertron-remote"
SpidertronSender.launch_signal = "spidertron-launch"
SpidertronSender.window_name = "spidertron-sender-window"
SpidertronSender.record_button = "spidertron-sender-record-button"
SpidertronSender.State = {
    insert_remote = 1, remote_not_connected = 2, spidertron_far_away = 3, record_path = 4,
    path_too_long = 5, ready = 6,
}

local recordPath, fillWaypoints, setStateMessage
local MAX_PATH_LENGTH = 6

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
        state = SpidertronSender.State.insert_remote,
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

        SpidertronSender.update_connection_state(sender)
        SpidertronSender.update_spidertron(sender)

        ::continue::
    end
end
Events.repeatingTask(30, 6, SpidertronSender.update)

function SpidertronSender.update_connection_state(sender)
    local inventory = sender.entity.get_inventory(defines.inventory.chest)
    local remote = inventory[1]

    -- Is everything ok with the connected spidertron?
    if sender.spidertron and remote and remote.valid_for_read and
            remote.name == SpidertronSender.remote and remote.connected_entity and
            remote.connected_entity.valid and
            remote.connected_entity.unit_number == sender.spidertron.unit_number then
        return true
    end
    sender.spidertron = nil
    sender.path = nil

    if not remote or not remote.valid_for_read or remote.name ~= SpidertronSender.remote then
        sender.state = SpidertronSender.State.insert_remote
        SpidertronSender.on_gui_update(sender)
        return false
    end
    local spider = remote.connected_entity
    if not spider or not spider.valid then
        sender.state = SpidertronSender.State.remote_not_connected
        SpidertronSender.on_gui_update(sender)
        return false
    end
    if spider.surface.index ~= sender.entity.surface.index then
        sender.state = SpidertronSender.State.spidertron_far_away
        SpidertronSender.on_gui_update(sender)
        return false
    end

    sender.spidertron = spider
    recordPath(sender)
    SpidertronSender.on_gui_update(sender)
    return false
end

function SpidertronSender.update_spidertron(sender)
    if not sender.spidertron or not sender.path or #sender.path == 0 then return end
    local launch_signal = {type = "virtual", name = SpidertronSender.launch_signal}
    local signal = sender.entity.get_merged_signal(launch_signal)
    if signal > 0 then
        sender.spidertron.autopilot_destination = nil
        for _,step in pairs(sender.path) do
            sender.spidertron.add_autopilot_destination(step)
        end
    end
end

function SpidertronSender.on_open_gui(event)
    if event.gui_type ~= defines.gui_type.entity or
            not event.entity or event.entity.name ~= SpidertronSender.name then
        return
    end
    local sender = global.spidertron_senders[event.entity.unit_number]
    if not sender or not sender.entity.valid then return end

    if sender.state == SpidertronSender.State.path_too_long then
        sender.state = SpidertronSender.State.ready
    end

    local player = game.get_player(event.player_index)
    if player.gui.relative[SpidertronSender.window_name] then
        player.gui.relative[SpidertronSender.window_name].destroy()
    end
    local anchor = { gui = defines.relative_gui_type.container_gui,
                     position = defines.relative_gui_position.left }
    local frame = GuiUtils.createFrame(event, SpidertronSender.window_name, anchor, true)

    local div1 = frame.add({type = "flow", direction = "horizontal", name = "div1"})
    div1.add({type = "label", caption = {"spidertron-etc.spidertron-sender-state"}})
    local state_label = div1.add({type = "label", name = "state_message", caption = ""})
    local signal_icon = div1.add({type = "sprite", name = "signal_icon", resize_to_sprite = false,
                                  sprite = "virtual-signal/" .. SpidertronSender.launch_signal})
    signal_icon.style.width = 20
    signal_icon.style.height = 20
    signal_icon.tooltip = {"", {"virtual-signal-name." .. SpidertronSender.launch_signal}}
    setStateMessage(sender, state_label, signal_icon)

    frame.add({type = "line"})

    local div2 = frame.add({type = "flow", direction = "vertical", name = "div2"})
    div2.style.vertically_stretchable = true
    local waypoints_div = div2.add({type = "table", column_count = 2, name = "waypoints_div"})
    fillWaypoints(sender, waypoints_div)

    local div3 = frame.add({type = "flow", direction = "horizontal"})
    local record_button = div3.add({type = "button", name = SpidertronSender.record_button,
                                    caption = {"spidertron-etc.spidertron-sender-record-button"}})
    record_button.style.horizontally_stretchable = true
end
Events.addListener(defines.events.on_gui_opened, SpidertronSender.on_open_gui)

function SpidertronSender.on_close_gui(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity or
            event.entity.name ~= SpidertronSender.name then
        return
    end

    local player = game.get_player(event.player_index)
    if player.gui.relative[SpidertronSender.window_name] then
        player.gui.relative[SpidertronSender.window_name].destroy()
    end
end
Events.addListener(defines.events.on_gui_closed, SpidertronSender.on_close_gui)

function SpidertronSender.on_gui_click(event)
    if not event.element or not event.element.valid or
            event.element.name ~= SpidertronSender.record_button then
        return
    end
    local player = game.get_player(event.player_index)
    local sender = global.spidertron_senders[player.opened.unit_number]
    if not sender then return end

    if SpidertronSender.update_connection_state(sender) then
        recordPath(sender)
        SpidertronSender.on_gui_update(sender)
    end
end
Events.addListener(defines.events.on_gui_click, SpidertronSender.on_gui_click)

function SpidertronSender.on_gui_update(sender)
    for _,player in pairs(game.players) do
        local frame = player.gui.relative[SpidertronSender.window_name]
        if not frame or player.opened.unit_number ~= sender.entity.unit_number then goto continue end

        setStateMessage(sender, frame["div1"]["state_message"], frame["div1"]["signal_icon"])

        local waypoints_div = frame["div2"]["waypoints_div"]
        waypoints_div.clear()
        fillWaypoints(sender, waypoints_div)

        ::continue::
    end
end

function recordPath(sender)
    sender.state = SpidertronSender.State.record_path
    if #sender.spidertron.autopilot_destinations > 0 then
        sender.state = SpidertronSender.State.ready
        sender.path = {}
        for _,step in pairs(sender.spidertron.autopilot_destinations) do
            sender.path[#sender.path + 1] = {x = step.x, y = step.y}
            if #sender.path >= MAX_PATH_LENGTH then
                sender.state = SpidertronSender.State.path_too_long
                return
            end
        end
    end
end

function fillWaypoints(sender, list_div)
    for i,step in ipairs(sender.path or {}) do
        local camera_div = list_div.add({type = "frame", style = "inside_deep_frame"})
        camera_div.style.width = 135
        camera_div.style.height = 135

        local camera = camera_div.add({
            type = "camera",
            position = step,
            zoom = 0.2,
            surface_index = sender.entity.surface.index,
        })
        camera.style.vertically_stretchable = true
        camera.style.horizontally_stretchable = true

        local label_div = camera.add({type = "frame"})
        label_div.style.padding = 0
        label_div.add({type = "label",
                       caption = {"spidertron-etc.spidertron-sender-waypoint", i}})
    end
    while #list_div.children < MAX_PATH_LENGTH do
        local div = list_div.add({type = "flow"})
        div.style.width = 135
        div.style.height = 135
    end
end

function setStateMessage(sender, state_label, icon)
    if sender.state == SpidertronSender.State.insert_remote then
        state_label.caption = {"spidertron-etc.spidertron-sender-insert-remote"}
        state_label.style.font_color = {r = 1}
    elseif sender.state == SpidertronSender.State.remote_not_connected then
        state_label.caption = {"spidertron-etc.spidertron-sender-not-connected"}
        state_label.style.font_color = {r = 1}
    elseif sender.state == SpidertronSender.State.spidertron_far_away then
        state_label.caption = {"spidertron-etc.spidertron-sender-too-far-away"}
        state_label.style.font_color = {r = 1}
    elseif sender.state == SpidertronSender.State.record_path then
        state_label.caption = {"spidertron-etc.spidertron-sender-record-path"}
        state_label.style.font_color = {r = 1, g = 1}
    elseif sender.state == SpidertronSender.State.path_too_long then
        state_label.caption = {"spidertron-etc.spidertron-sender-too-many-steps", MAX_PATH_LENGTH}
        state_label.style.font_color = {r = 1, g = 1}
    elseif sender.state == SpidertronSender.State.ready then
        state_label.caption = {"spidertron-etc.spidertron-sender-ready"}
        state_label.style.font_color = {g = 1}
    end
    icon.visible = sender.state == SpidertronSender.State.ready
end
