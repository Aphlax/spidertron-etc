local SpidertronCrafting = {}
SpidertronCrafting.window_name = "spidertron-crafting-frame"

function SpidertronCrafting.on_open_spidertron(event)
    if event.gui_type ~= defines.gui_type.entity or
            not event.entity or event.entity.name ~= "spidertron" then
        return
    end

    -- TODO: check if crafting is supported in this spidertron.

    local gui = game.players[event.player_index].gui.relative
    local frame = gui.add({ type = "frame", name = SpidertronCrafting.window_name })
    frame.anchor = { gui = defines.relative_gui_type.spider_vehicle_gui,
                    position = defines.relative_gui_position.right }
    frame.style.size = {150, 150}

    -- TODO: add content.
end
Events.addListener(defines.events.on_gui_opened, SpidertronCrafting.on_open_spidertron)


function SpidertronCrafting.on_close_spidertron(event)
    if event.gui_type ~= defines.gui_type.entity or
            not event.entity or event.entity.name ~= "spidertron" then
        return
    end

    local gui = game.players[event.player_index].gui.relative
    if gui[SpidertronCrafting.window_name] then
        gui[SpidertronCrafting.window_name].destroy()
    end
end
Events.addListener(defines.events.on_gui_closed, SpidertronCrafting.on_close_spidertron)

return SpidertronCrafting