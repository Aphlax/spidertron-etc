local extractorAnimation = animationFactory({
    filename = "__spidertron-etc__/graphics/entity/hr-spidertron-extractor-shadow.png",
    width = 384,
    height = 256,
    shift = {0, -0.3},
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})
local blank_image = {
    direction_count = 4,
    frame_count = 1,
    filename = "__spidertron-etc__/graphics/blank.png",
    width = 1,
    height = 1,
    priority = "low"
}

local extractor = {
    type = "logistic-container",
    name = "spidertron-extractor",
    icon = "__spidertron-etc__/graphics/icon/spidertron-extractor.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation", "not-rotatable", "no-automated-item-insertion", "no-automated-item-removal"},
    max_health = 500,
    corpse = "small-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -12),
    resistances ={{type = "impact", percent = 50}},
    open_sound = {filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43},
    close_sound = {filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43},
    vehicle_impact_sound =  {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    se_allow_in_space = true,
    picture = extractorAnimation(),
    collision_box = {{-0.8, -0.8},{0.8, 0.8}},
    selection_box = {{-0.8, -0.8},{0.8, 0.8}},
    map_color = {r = 0.816, g = 0.792, b = 0.533},
    minable = {mining_time = 0.2, result = "spidertron-extractor"},

    -- container
    inventory_size = 0,
    enable_inventory_bar = false,
    logistic_mode = "buffer",
    max_logistic_slots = 20,
    render_not_in_network_icon = false,
}

local output = {
    type = "container",
    name = "spidertron-extractor-output",
    icon = "__spidertron-etc__/graphics/icon/spidertron-etc-container.png",
    icon_size = 64,
    flags = {"placeable-player", "not-blueprintable", "not-rotatable", "not-deconstructable", "placeable-off-grid", "no-automated-item-insertion"},
    max_health = 100,
    se_allow_in_space = true,
    allow_copy_paste = false,
    collision_box = {{-0.6, -0.6}, {0.6, 0.6}},
    selection_box = {{-0.6, -0.6}, {0.6, 0.6}},
    picture = blank_image,
    fast_replaceable_group = "",

    -- container
    inventory_size = 1,
    enable_inventory_bar = false,
    selection_priority = 0,
}

local wire_connection = {
    wire = {red = {0.1, -0.17}, green = {-0.1, -0.15}},
    shadow = {red = {1.9+0.1, 1.1}, green = {1.9-0.1, 1.12}},
}
local signal = {
    type = "constant-combinator",
    name = "spidertron-extractor-signal",
    icon = "__spidertron-etc__/graphics/icon/spidertron-etc-container.png",
    icon_size = 64,
    flags = {"placeable-player", "not-blueprintable", "not-rotatable", "not-deconstructable", "placeable-off-grid"},
    max_health = 100,
    se_allow_in_space = true,
    allow_copy_paste = false,
    collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
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
    icon = "__spidertron-etc__/graphics/icon/spidertron-docked.png",
    icon_size = 64,
    subgroup = "virtual-signal-special",
    order = "f[spidertron]-[2]",
}

local transfer_signal = {
    type = "virtual-signal",
    name = "spidertron-transfer-complete",
    icon = "__spidertron-etc__/graphics/icon/spidertron-transfer-complete.png",
    icon_size = 64,
    subgroup = "virtual-signal-special",
    order = "f[spidertron]-[3]",
}

local item = {
    type = "item",
    name = "spidertron-extractor",
    icon = "__spidertron-etc__/graphics/icon/spidertron-extractor.png",
    icon_size = 64,
    subgroup = "transport",
    order = "b[personal-transport]-z[extractor]",
    stack_size = 5,
    place_result = "spidertron-extractor",
}

local gear_ingredient = mods["aai-industry"] and "electric-motor" or "iron-gear-wheel"
local recipe = {
    type = "recipe",
    name = "spidertron-extractor",
    ingredients = {{"steel-plate", 30}, {gear_ingredient, 20}, {"processing-unit", 25}},
    result = "spidertron-extractor",
    energy_required = 10,
    enabled = false,
}

local technology = {
    type = "technology",
    name = "spidertron-extractor",
    icon = "__spidertron-etc__/graphics/technology/spidertron-extractor.png",
    icon_size = 256,
    order = "d-e-f",
    prerequisites = {"spidertron"},
    unit = {
        count = 500,
        ingredients = {
            {"automation-science-pack", 1},
            {"logistic-science-pack", 1},
            {"military-science-pack", 1},
            {"chemical-science-pack", 1},
            {"production-science-pack", 1},
            {"utility-science-pack", 1},
        },
        time = 30,
    },
    effects = {
        {type = "unlock-recipe", recipe = "spidertron-extractor"},
        {type = "unlock-recipe", recipe = "spidertron-sender"},
    },
}

data:extend({extractor, output, signal, docked_signal, transfer_signal, item, recipe, technology})
