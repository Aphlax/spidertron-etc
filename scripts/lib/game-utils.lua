local GameUtils = {}

function GameUtils.debug(message)
    if not game then
        return log(type(message) == "string" and message or serpent.line(message))
    end
    for _, player in pairs(game.players) do
        player.print({"", type(message) == "string" and message or serpent.line(message)})
    end
end

function GameUtils.give_items_to_player(item_stack, player_index, source_entity)
    local character
    local inventory
    if player_index and game.players[player_index] and game.players[player_index].connected and game.players[player_index].character then
        character = game.players[player_index].character
        inventory = character.get_inventory(defines.inventory.character_main)
    end
    
    if item_stack and item_stack.valid_for_read and item_stack.count > 0 then
        if inventory and inventory.can_insert(item_stack) then
            local inserted = inventory.insert(item_stack)
            if inserted < count then
                character.surface.spill_item_stack(character.position, {name = item_stack.name, count = item_stack.count - inserted})
            end
        elseif source_entity and source_entity.valid then
            source_entity.surface.spill_item_stack(source_entity.position, item_stack)
        end
    end
end

return GameUtils