-- Clicker changes the character and breaks a character-scoped living chain.
local Exclusions = {}
local CLICKER = CollectibleType.COLLECTIBLE_CLICKER
local FALLBACK = CollectibleType.COLLECTIBLE_BREAKFAST

function Exclusions:ApplyPool()
    Game():GetItemPool():RemoveCollectible(CLICKER)
end

function Exclusions:Init(mod)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function() self:ApplyPool() end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() self:ApplyPool() end)
    mod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, function(_, id)
        if id == CLICKER then return FALLBACK end
    end)
    local function replace(_, pickup)
        if pickup.SubType == CLICKER then
            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, FALLBACK, true, true, false)
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, replace, PickupVariant.PICKUP_COLLECTIBLE)
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, replace, PickupVariant.PICKUP_COLLECTIBLE)
    if ModCallbacks.MC_PRE_ADD_COLLECTIBLE then
        mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function(_, id)
            if id == CLICKER then return false end
        end)
    end
    mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function() return true end, CLICKER)
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        if player:HasCollectible(CLICKER) then player:RemoveCollectible(CLICKER) end
    end)
end

return Exclusions
