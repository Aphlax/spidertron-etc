local chargerAnimation = animationFactory({
    filename = "__spidertron-fef__/graphics/entity/hr-equipment-charger.png",
    width = 192,
    height = 256,
    shift = { 0, 0 },
    frames = 1,
    frames_per_line = 1,
    offset = 0,
})

local charger = {
    type = "accumulator",
    name = "equipment-charger",
    icon = "__spidertron-fef__/graphics/icon/equipment-charger.png",
    icon_size = 64,
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    max_health = 250,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(0, -12),
    se_allow_in_space = true,
    collision_box = {{-0.8, -1.3}, {0.8, 1.3}},
    selection_box = {{-1, -1.5}, {1, 1.5}},
    resistances ={{ type = "impact", percent = 50 }},
    open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
    close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    picture =  chargerAnimation(),
    fast_replaceable_group = "",
    vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 1.0 },

    -- accumulator
    energy_source = {
        buffer_capacity = "500MJ",
        input_flow_limit = "80MW",
        output_flow_limit = "0kW",
        type = "electric",
        usage_priority = "secondary-input",
    },
    charge_cooldown = 0,
    discharge_cooldown = 0,
}

data:extend({ charger })