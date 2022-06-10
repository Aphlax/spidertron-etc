local processorAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-spidertron-processor.png",
    width = 192,
    height = 256,
    shift = { 0, 0 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local processor = {
    type = "logistic-container",
    name = "spidertron-processor",
    icon = "__spidertron-fef__/graphics/icon/spidertron-processor.png",
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
    picture =  processorAnimation({ offset = 0 }),
    fast_replaceable_group = "",
    vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 1.0 },

    -- container
    inventory_size = 0,
    logistic_mode = "requester",
}

data:extend({ processor })