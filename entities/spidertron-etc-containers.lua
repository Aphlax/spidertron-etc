
local container = {
    type = "container",
    icon = "__spidertron-etc__/graphics/icon/spidertron-etc-container.png",
    icon_size = 64,
    flags = {"placeable-player", "not-blueprintable", "not-deconstructable", "no-automated-item-removal"},
    max_health = 100,
    open_sound = {filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43},
    close_sound = {filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43},
    se_allow_in_space = true,
    allow_copy_paste = false,
    picture = {
        direction_count = 4,
        frame_count = 1,
        filename = "__spidertron-etc__/graphics/blank.png",
        width = 1,
        height = 1,
        priority = "low"
    },
    inventory_size = 1,
    enable_inventory_bar = false,
    collision_mask = {},
    collision_box = {{-0.3, -0.8},{0.3, 0.8}},
    selection_box = {{-0.3, -0.8},{0.3, 0.8}},
    selection_priority = 52,
}

local input_vertical = table.deepcopy(container)
input_vertical.name = "spidertron-etc-input-vertical"
local output_vertical = table.deepcopy(container)
output_vertical.flags = {"placeable-player", "not-blueprintable", "not-deconstructable", "no-automated-item-insertion"}
output_vertical.name = "spidertron-etc-output-vertical"

container.collision_box = {{-0.8, -0.3},{0.8, 0.3}}
container.selection_box = {{-0.8, -0.3},{0.8, 0.3}}
local input_horizontal = table.deepcopy(container)
input_horizontal.name = "spidertron-etc-input-horizontal"
local output_horizontal = table.deepcopy(container)
output_horizontal.name = "spidertron-etc-output-horizontal"
output_horizontal.flags = {"placeable-player", "not-blueprintable", "not-deconstructable", "no-automated-item-insertion"}

data:extend({input_vertical, output_vertical, input_horizontal, output_horizontal})