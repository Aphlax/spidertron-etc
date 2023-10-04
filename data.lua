require("entities.utils_entity")

require("entities.spidertron-etc-containers")

require("entities.spidertron-launcher")
require("entities.spidertron-processor")
require("entities.spidertron-extractor")
require("entities.spidertron-sender")
require("entities.equipment-charger")

if mods["informatron"] then
    informatron_make_image("informatron_spidertron-etc", "__spidertron-etc__/graphics/overview.png", 1123, 880)
    informatron_make_image("informatron_spidertron-etc_sender", "__spidertron-etc__/graphics/informatron/sender.png", 1764, 697)
    informatron_make_image("informatron_spidertron-etc_combinator", "__spidertron-etc__/graphics/informatron/combinator.png", 585, 534)
end
