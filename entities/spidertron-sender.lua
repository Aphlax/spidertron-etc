local senderAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-sender.png",
    width = 128,
    height = 128,
    shift = { 0, -0.5 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local sender = {
    type = "container",
    name = "spidertron-sender",
    icon = "__spidertron-fef__/graphics/icon/spidertron-sender.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation", "no-automated-item-insertion", "no-automated-item-removal"},
    max_health = 250,
    open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
    close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
    se_allow_in_space = true,
    picture = senderAnimation(),
    collision_box = {{-0.45, -0.45},{0.45, 0.45}},
    selection_box = {{-0.5, -0.5},{0.5, 0.5}},

    -- Container.
    inventory_size = 1,
    enable_inventory_bar = false,
    circuit_wire_connection_point = {
        wire = {red = {-0.3, -0.3}, green = {0.3, -0.3}},
        shadow = {red = {0.3, 0.2}, green = {0.9, 0.2}},
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

data:extend({sender, launch_signal})
