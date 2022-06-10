local launcherAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-launcher.png",
    width = 152,
    height = 256,
    shift = { 0, 0 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local launcher = {
    type = "assembling-machine",
    name = "spidertron-launcher",
    icon = "__spidertron-fef__/graphics/icon/spidertron-launcher.png",
    icon_size = 64,
    flags = {"placeable-neutral", "placeable-player", "player-creation", "no-automated-item-removal", "no-automated-item-insertion"},
    max_health = 250,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -12),
    se_allow_in_space = true,
    collision_box = {{-0.8, -1.3}, {0.8, 1.3}},
    selection_box = {{-1, -1.5}, {1, 1.5}},
    resistances ={{ type = "impact",percent = 50  }},
    open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
    close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    animation = {
        north = launcherAnimation(),
        east = launcherAnimation(),
        south = launcherAnimation(),
        west = launcherAnimation(),
    },
    fast_replaceable_group = "",
    vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 1.0 },

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
    icon = "__spidertron-fef__/graphics/icon/spidertron-launcher.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation", "not-blueprintable", "not-deconstructable"},
    max_health = 250,
    open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
    close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
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
    collision_box = {{-0.8, -0.8},{0.8, 0.8}},
    selection_box = {{-0.8, -0.8},{0.8, 0.8}},
    selection_priority = 52,
}

local recipe_cat = {
    type = "recipe-category",
    name = "spidertron-fef",
}

local recipe = {
    type = "recipe",
    name = "spidertron-launch",
    icon = "__base__/graphics/icons/spidertron.png",
    icon_size = 64,
    category = "spidertron-fef",
    subgroup = "equipment",
    enabled = false,
    energy_required = 1,
    ingredients = {},
    results= {},
}

data:extend({ recipe_cat, recipe, launcher, container })