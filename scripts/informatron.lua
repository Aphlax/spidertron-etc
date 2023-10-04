local Informatron = {}

local createImageContainer

Informatron.open_informatron_button = "open-informatron"
Informatron.menu = {}

function Informatron.pageContent(page_name, element)
    if page_name == "spidertron-etc" then
        local overview = createImageContainer("overview_container", element, 460)
                .add({type="button", name="overview_image", style="informatron_spidertron-etc"})
        overview.style.width = 440
        overview.style.height = 345
        element.add({type="label", name="content_1", caption={"spidertron-etc.content_1_spidertron-etc"}})
        local sender = createImageContainer("sender_container", element, 774)
                .add({type="button", name="sender_image", style="informatron_spidertron-etc_sender"})
        sender.style.width = 754
        sender.style.height = 298
        element.add({type="label", name="content_2", caption={"spidertron-etc.content_2_spidertron-etc"}})
        local combinator = createImageContainer("combinator_container", element, 347)
                .add({type="button", name="combinator_image", style="informatron_spidertron-etc_combinator"})
        combinator.style.width = 327
        combinator.style.height = 298
        element.add({type="label", name="content_3", caption={"spidertron-etc.content_3_spidertron-etc"}})
    end
end

function Informatron.on_gui_click(event)
    if not event.element or not event.element.valid or
            event.element.name ~= Informatron.open_informatron_button then
        return
    end
    if game.active_mods["informatron"] then
        remote.call("informatron", "informatron_open_to_page", {
            player_index = event.player_index,
            interface = "spidertron-etc",
            page_name = "spidertron-etc"
        })
    end
end
Events.addListener(defines.events.on_gui_click, Informatron.on_gui_click)

function createImageContainer(name, parent, width)
    local image_container = parent.add({type="flow", name=name.."_outer", direction="horizontal"})
            .add({type="frame", name=name, style="informatron_image_container", direction="vertical"})
    image_container.style.maximal_width = width
    image_container.style.horizontally_stretchable = false
    image_container.style.horizontal_align = "center"
    return image_container
end

return Informatron