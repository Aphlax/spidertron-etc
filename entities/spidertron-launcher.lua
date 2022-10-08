require("__spidertron-fef__/scripts/lib/utils.lua")

local launcherAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-launcher-shadow.png",
    width = 448,
    height = 320,
    shift = { 0.75, 0 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local launcher = {
    type = "assembling-machine",
    name = "spidertron-launcher",
    icon = "__spidertron-fef__/graphics/icon/spidertron-launcher.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation", "not-rotatable", "no-automated-item-removal", "no-automated-item-insertion"},
    max_health = 250,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -12),
    se_allow_in_space = true,
    collision_box = {{-2.8, -2.2}, {2.8, 2.2}},
    selection_box = {{-2.9, -2.3}, {2.9, 2.3}},
    resistances ={{ type = "impact", percent = 50 }},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
    vehicle_impact_sound =  {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    animation = {
        north = launcherAnimation(),
        east = launcherAnimation(),
        south = launcherAnimation(),
        west = launcherAnimation(),
    },
    fast_replaceable_group = "",
    minable = {mining_time = 1, result = "spidertron-launcher"},

    -- assembly-machine
    crafting_categories = {"spidertron-fef"},
    fixed_recipe = "spidertron-launch",
    crafting_speed = 1,
    ingredient_count = 0,
    energy_usage = "250kW",
    energy_source = {
      buffer_capacity = "1kJ",
      drain = "100kW",
      input_flow_limit = "100MW",
      type = "electric",
      usage_priority = "secondary-input"
    },
    working_sound = {
      apparent_volume = 1.5,
      idle_sound = {
        filename = "__base__/sound/idle1.ogg",
        volume = 0.6
      },
      sound = {
        {
          filename = "__base__/sound/assembling-machine-t1-1.ogg",
          volume = 0.5
        },
        {
          filename = "__base__/sound/assembling-machine-t1-2.ogg",
          volume = 0.5
        }
      }
    },
    working_visualisations =
    {
      {
        effect = "uranium-glow",
        light = {intensity = 0.5, size = 8, shift = {0.0, 0.0}, color = {r = 1, g = 0.9, b = 0.5}}
      },
    },
}

local container = {
    type = "container",
    name = "spidertron-launcher-container",
    icon = "__spidertron-fef__/graphics/icon/spidertron-fef-container.png",
    icon_size = 64,
    flags = {"placeable-neutral", "not-blueprintable", "not-deconstructable", "no-automated-item-removal",},
    max_health = 250,
    open_sound = {filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43},
    close_sound = {filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43},
    se_allow_in_space = true,
    picture = {
        direction_count = 4,
        frame_count = 1,
        filename = "__spidertron-fef__/graphics/blank.png",
        width = 1,
        height = 1,
        priority = "low"
    },
    inventory_size = 1,
    enable_inventory_bar = false,
    collision_mask = {},
    collision_box = {{-1.9, -1.5}, {1.9, 1.5}},
    selection_box = {{-1.9, -1.5}, {1.9, 1.5}},
    selection_priority = 52,
}

local recipe_cat = {
    type = "recipe-category",
    name = "spidertron-fef",
}

local launch_recipe = {
    type = "recipe",
    name = "spidertron-launch",
    icon = "__base__/graphics/icons/spidertron.png",
    icon_size = 64,
    category = "spidertron-fef",
    subgroup = "equipment",
    enabled = false,
    energy_required = 7,
    ingredients = {},
    results= {},
}

local animation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-launcher-shadow.png",
    width = 448,
    height = 320,
    shift = {0.75, 0},
    extras = {
        frame_count = 151,
        line_length = 12,
        frame_sequence = flatten({
            range(90),
            replicate({91}, 30),
            replicate({92}, 30),
            map(range(60), function(n) return n + 91 end), -- Total: 210
        }),
    },
})()
animation.type = "animation"
animation.name = "spidertron-launcher-animation"

local animation_tint = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-launcher-tint.png",
    width = 448,
    height = 320,
    shift = {0.75, 0},
    extras = {
        frame_count = 151,
        line_length = 12,
        frame_sequence = flatten({
            range(90),
            replicate({91}, 30),
            replicate({92}, 30),
            map(range(60), function(n) return n + 91 end), -- Total: 210
        }),
    },
})()
animation_tint.type = "animation"
animation_tint.name = "spidertron-launcher-animation-tint"

local sound = {
    type = "sound",
    name = "spidertron-launcher-sound",
    filename = "__base__/sound/silo-doors.ogg",
}

local item = {
    type = "item",
    name = "spidertron-launcher",
    icon = "__spidertron-fef__/graphics/icon/spidertron-launcher.png",
    icon_size = 64,
    subgroup = "transport",
    order = "b[personal-transport]-y",
    stack_size = 1,
    place_result = "spidertron-launcher",
}

local gear_ingredient = mods["aai-industry"] and {"electric-motor", 80} or {"iron-gear-wheel", 100}
local recipe = {
    type = "recipe",
    name = "spidertron-launcher",
    ingredients = {{"concrete", 100}, {"steel-plate", 100}, gear_ingredient, {"processing-unit", 10}},
    result = "spidertron-launcher",
    energy_required = 40,
    enabled = false,
}

local technology = {
    type = "technology",
    name = "spidertron-launcher",
    icon = "__spidertron-fef__/graphics/technology/spidertron-launcher.png",
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
        {type = "unlock-recipe", recipe = "spidertron-launcher"},
        {type = "unlock-recipe", recipe = "spidertron-processor"}
    },
}

data:extend({
    launcher, container,
    animation, animation_tint, sound,
    recipe_cat, launch_recipe,
    item, recipe, technology
})