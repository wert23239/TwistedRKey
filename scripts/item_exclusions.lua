-- Clicker breaks character chains; Gnawed Leaf trivializes combat with idle invincibility.
local Exclusions = {}
local CLICKER = CollectibleType.COLLECTIBLE_CLICKER
local BLOCKED = { [CLICKER] = true, [CollectibleType.COLLECTIBLE_GNAWED_LEAF] = true }
local FALLBACK = CollectibleType.COLLECTIBLE_BREAKFAST

function Exclusions:ApplyPool()
    for id in pairs(BLOCKED) do Game():GetItemPool():RemoveCollectible(id) end
end

function Exclusions:Init(mod)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function() self:ApplyPool() end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() self:ApplyPool() end)
    mod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, function(_, id)
        if BLOCKED[id] then return FALLBACK end
    end)
    local function replace(_, pickup)
        if BLOCKED[pickup.SubType] then
            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, FALLBACK, true, true, false)
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, replace, PickupVariant.PICKUP_COLLECTIBLE)
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, replace, PickupVariant.PICKUP_COLLECTIBLE)
    if ModCallbacks.MC_PRE_ADD_COLLECTIBLE then
        mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function(_, id)
            if BLOCKED[id] then return false end
        end)
    end
    mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function() return true end, CLICKER)
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        for id in pairs(BLOCKED) do
            if player:HasCollectible(id) then player:RemoveCollectible(id) end
        end
    end)
end

return Exclusions
