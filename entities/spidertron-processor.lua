local processorAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-processor-shadow.png",
    width = 320,
    height = 320,
    shift = { 0, -0.2 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local processor = {
    type = "logistic-container",
    name = "spidertron-processor",
    icon = "__spidertron-fef__/graphics/icon/spidertron-processor.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation", "no-automated-item-removal", "no-automated-item-insertion"},
    max_health = 150,
    corpse = "medium-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -12),
    se_allow_in_space = true,
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1, -1.1}, {1, 1}},
    resistances ={{type = "impact", percent = 50}},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
    vehicle_impact_sound =  {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    picture =  processorAnimation(),
    fast_replaceable_group = "",
    minable = {mining_time = 0.2, result = "spidertron-processor"},

    -- container
    inventory_size = 0,
    logistic_mode = "buffer",
    render_not_in_network_icon = false,
}

local item = {
    type = "item",
    name = "spidertron-processor",
    icon = "__spidertron-fef__/graphics/icon/spidertron-processor.png",
    icon_size = 64,
    subgroup = "production-machine",
    order = "q-e",
    stack_size = 50,
    place_result = "spidertron-processor",
}

local recipe = {
    type = "recipe",
    name = "spidertron-processor",
    ingredients = {{"steel-plate", 40}, {"processing-unit", 20}},
    result = "spidertron-processor",
    energy_required = 4,
    enabled = false,
}

data:extend({processor, item, recipe})