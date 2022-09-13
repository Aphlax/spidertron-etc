local GuiUtils = {}

function GuiUtils.createFrame(event, name, anchor)
    local player = game.get_player(event.player_index)
    local frame = player.gui.relative.add(
            {type = "frame", name = name, direction="vertical", anchor = anchor})
    frame.style.minimal_width = 300
    frame.style.vertically_stretchable = "stretch_and_expand"

    local title_div = frame.add({type = "flow", direction = "horizontal"})
    title_div.add({
        type = "label",
        style = "frame_title",
        caption = { "spidertron-etc.settings-frame-title"},
        ignored_by_interaction = true
    })
    local title_empty = title_div.add({
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true
    })
    title_empty.style.horizontally_stretchable = "on"
    title_empty.style.left_margin = 4
    title_empty.style.right_margin = 0
    title_empty.style.height = 24
    --[[
    local title_informatron = title_div.add({
        type="sprite-button",
        name="goto_informatron_delivery_cannons",
        sprite = "virtual-signal/informatron",
        style="informatron_close_button",
        tooltip={"space-exploration.informatron-open-help"}
    })
    title_informatron.style.width = 28
    title_informatron.style.height = 28
    --]]
    return frame
end

return GuiUtils
