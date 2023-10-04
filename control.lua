require("scripts.lib.utils")
GameUtils = require("scripts.lib.game-utils")
GuiUtils = require("scripts.lib.gui-utils")
SpidertronEtcUtils = require("scripts.lib.spidertron-etc-utils")
Events = require("scripts.lib.events")
Informatron = require("scripts.informatron")

-- Self-contained.
require("scripts.spidertron-launcher")
require("scripts.spidertron-processor")
require("scripts.equipment-charger")
require("scripts.spidertron-extractor")
require("scripts.spidertron-sender")
require("scripts.equipment-gantry-limit")

remote.add_interface("spidertron-etc", {
    informatron_menu = function()
        return Informatron.menu
    end,
    informatron_page_content = function(data)
        return Informatron.pageContent(data.page_name, data.element)
    end
})
