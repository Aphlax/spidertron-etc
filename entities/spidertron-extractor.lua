local extractorAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-extractor.png",
    width = 192,
    height = 192,
    shift = { 0, 0 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})
local blank_image = {
    direction_count = 4,
    frame_count = 1,
    filename = "__spidertron-fef__/graphics/blank.png",
    width = 1,
    height = 1,
    priority = "low"
}

local extractor = {
    type = "container",
    name = "spidertron-extractor",
    icon = "__spidertron-fef__/graphics/icon/spidertron-extractor.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation", "no-automated-item-insertion"},
    max_health = 250,
    open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
    close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
    se_allow_in_space = true,
    picture = extractorAnimation(),
    inventory_size = 1,
    enable_inventory_bar = false,
    collision_box = {{-0.8, -0.8},{0.8, 0.8}},
    selection_box = {{-1, -1},{1, 1}},
}

local config = {
    type = "logistic-container",
    name = "spidertron-extractor-config",
    icon = "__spidertron-fef__/graphics/icon/spidertron-fef-container.png",
    icon_size = 64,
    flags = {"placeable-player", "not-blueprintable", "not-rotatable", "not-deconstructable", "placeable-off-grid", "no-automated-item-insertion", "no-automated-item-removal"},
    max_health = 1000,
    alert_icon_shift = util.by_pixel(0, -12),
    se_allow_in_space = true,
    allow_copy_paste = false,
    collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
    selection_box = {{-0.1, -0.1}, {0.1, 0.1}},
    vehicle_impact_sound =  {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    picture = blank_image,
    fast_replaceable_group = "",

    -- container
    inventory_size = 0,
    logistic_mode = "buffer",
    max_logistic_slots = 64,
    render_not_in_network_icon = false,
    selection_priority = 0,
}

local wire_connection = {
    wire = {red = {-0.1, 0}, green = {0.1, 0}},
    shadow = {red = {1.2-0.1, 0}, green = {1.2+0.1, 0}},
}
local signal = {
    type = "constant-combinator",
    name = "spidertron-extractor-signal",
    icon = "__spidertron-fef__/graphics/icon/spidertron-fef-container.png",
    icon_size = 64,
    flags = {"placeable-player", "not-blueprintable", "not-rotatable", "not-deconstructable", "placeable-off-grid"},
    max_health = 500,
    se_allow_in_space = true,
    allow_copy_paste = false,
    collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
    collision_mask = {"floor-layer"},
    selection_box = {{-0.4, -0.4}, {0.4, 0.4}},
    sprites = {
        north = blank_image,
        east = blank_image,
        south = blank_image,
        west = blank_image,
    },
    activity_led_sprites = {
        north = blank_image,
        east = blank_image,
        south = blank_image,
        west = blank_image,
    },
    activity_led_light = {intensity = 0.8, size = 1},
    activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
    fast_replaceable_group = "",

    -- constant-combinator
    item_slot_count = 106, -- 80 inventory, 20 trash, 4 ammo, 2 virtual signals.
    scale_info_icons = false,
    selectable_in_game = true,
    selection_priority = 52,
    circuit_wire_connection_points =
        {wire_connection,  wire_connection,  wire_connection,  wire_connection},
    circuit_wire_max_distance = 10
}

local docked_signal = {
    type = "virtual-signal",
    name = "spidertron-docked",
    icon = "__spidertron-fef__/graphics/icon/spidertron-docked.png",
    icon_size = 64,
    subgroup = "virtual-signal-special",
    order = "f[spidertron]-[2]",
}

local transfer_signal = {
    type = "virtual-signal",
    name = "spidertron-transfer-complete",
    icon = "__spidertron-fef__/graphics/icon/spidertron-transfer-complete.png",
    icon_size = 64,
    subgroup = "virtual-signal-special",
    order = "f[spidertron]-[3]",
}

data:extend({extractor, config, signal, docked_signal, transfer_signal})
