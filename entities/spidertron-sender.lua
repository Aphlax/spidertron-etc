local senderAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-sender-shadow.png",
    width = 128,
    height = 128,
    shift = { 0.5, -0.2 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local sender = {
    type = "container",
    name = "spidertron-sender",
    icon = "__spidertron-fef__/graphics/icon/spidertron-sender.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation", "no-automated-item-insertion", "no-automated-item-removal"},
    max_health = 250,
    open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
    close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
    se_allow_in_space = true,
    picture = senderAnimation(),
    collision_box = {{-0.45, -0.45},{0.45, 0.45}},
    selection_box = {{-0.5, -0.5},{0.5, 0.5}},
    minable = {mining_time = 0.2, result = "spidertron-sender"},

    -- Container.
    inventory_size = 1,
    enable_inventory_bar = false,
    circuit_wire_connection_point = {
        wire = {red = {-0.2, -0.19}, green = {-0.35, -0.2}},
        shadow = {red = {0.75, 0.42}, green = {0.5, 0.42}},
    },
    circuit_wire_max_distance = 10,
}

local launch_signal = {
    type = "virtual-signal",
    name = "spidertron-launch",
    icon = "__spidertron-fef__/graphics/icon/spidertron-launch.png",
    icon_size = 64,
    subgroup = "virtual-signal-special",
    order = "f[spidertron]-[1]",
}

local item = {
    type = "item",
    name = "spidertron-sender",
    icon = "__spidertron-fef__/graphics/icon/spidertron-sender.png",
    icon_size = 64,
    subgroup = "transport",
    order = "b[personal-transport]-x",
    stack_size = 50,
    place_result = "spidertron-sender",
}

local recipe = {
    type = "recipe",
    name = "spidertron-sender",
    ingredients = {{"steel-plate", 5}, {"processing-unit", 10}},
    result = "spidertron-sender",
    energy_required = 4,
    enabled = false,
}

data:extend({sender, launch_signal, item, recipe})
