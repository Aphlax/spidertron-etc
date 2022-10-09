local chargerAnimation = animationFactory({
    filename = "__spidertron-etc__/graphics/entity/hr-equipment-charger-shadow.png",
    width = 320,
    height = 320,
    shift = {0, -0.2},
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})
local chargerPadAnimation = animationFactory({
    filename = "__spidertron-etc__/graphics/entity/hr-equipment-charger-pad-shadow.png",
    width = 320,
    height = 320,
    shift = {0, 2},
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local charger = {
    type = "accumulator",
    name = "equipment-charger",
    icon = "__spidertron-etc__/graphics/icon/equipment-charger.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation", "not-rotatable"},
    max_health = 150,
    corpse = "medium-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -12),
    se_allow_in_space = true,
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1, -1.1}, {1, 1}},
    resistances ={{type = "impact", percent = 50}},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
    vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    picture =  chargerAnimation(),
    fast_replaceable_group = "",
    minable = {mining_time = 0.2, result = "equipment-charger"},

    -- accumulator
    energy_source = {
        buffer_capacity = "250MJ",
        input_flow_limit = "80MW",
        output_flow_limit = "0kW",
        type = "electric",
        usage_priority = "secondary-input",
    },
    charge_cooldown = 30,
    discharge_cooldown = 30,
}

local charger_pad = {
    type = "accumulator",
    name = "equipment-charger-pad",
    icon = "__spidertron-etc__/graphics/icon/equipment-charger-pad.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation", "not-rotatable"},
    max_health = 100,
    corpse = "medium-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -6 + 2 * 32),
    se_allow_in_space = true,
    collision_box = {{ -1.95, 0 }, { 1.95, 1.95 * 2 }},
    collision_mask = {"floor-layer", "object-layer", "water-tile"},
    selection_box = {{ -2, 0 }, { 2, 2 * 2 }},
    resistances ={{type = "impact", percent = 100}},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
    picture =  chargerPadAnimation(),
    fast_replaceable_group = "",
    minable = {mining_time = 0.2, result = "equipment-charger-pad"},

    -- accumulator
    energy_source = {
        buffer_capacity = "50MJ",
        input_flow_limit = "4MW",
        output_flow_limit = "0kW",
        type = "electric",
        usage_priority = "secondary-input",
    },
    charge_cooldown = 30,
    discharge_cooldown = 30,
}

local item = {
    type = "item",
    name = "equipment-charger",
    icon = "__spidertron-etc__/graphics/icon/equipment-charger.png",
    icon_size = 64,
    subgroup = "production-machine",
    order = "q-c",
    stack_size = 50,
    place_result = "equipment-charger",
}

local pad_item = {
    type = "item",
    name = "equipment-charger-pad",
    icon = "__spidertron-etc__/graphics/icon/equipment-charger-pad.png",
    icon_size = 64,
    subgroup = "production-machine",
    order = "q-d",
    stack_size = 50,
    place_result = "equipment-charger-pad",
}

local recipe = {
    type = "recipe",
    name = "equipment-charger",
    category = "crafting",
    ingredients = {{"steel-plate", 10}, {"accumulator", 40}, {"advanced-circuit", 8}},
    energy_required = 8,
    result = "equipment-charger",
    enabled = false,
}

local pad_recipe = {
    type = "recipe",
    name = "equipment-charger-pad",
    category = "crafting",
    ingredients = {{"steel-plate", 4}, {"accumulator", 8}, {"advanced-circuit", 20}},
    energy_required = 4,
    result = "equipment-charger-pad",
    enabled = false,
}

local technology = {
    type = "technology",
    name = "equipment-charger",
    icon = "__spidertron-etc__/graphics/technology/equipment-charger.png",
    icon_size = 256,
    order = "b",
    prerequisites = {"battery-equipment", "equipment-gantry", "electric-energy-accumulators"},
    unit = {
        count = 100,
        ingredients = {
            {"automation-science-pack", 1},
            {"logistic-science-pack", 1},
            {"chemical-science-pack", 1},
        },
        time = 30,
    },
    effects = {
        {type = "unlock-recipe", recipe = "equipment-charger"},
        {type = "unlock-recipe", recipe = "equipment-charger-pad"},
    },
}

data:extend({charger, charger_pad, item, pad_item, recipe, pad_recipe, technology})