local CharacterSetups = {}

-- Player type constants
local PlayerType = PlayerType
local CollectibleType = CollectibleType

---@class CharacterSetup
---@field items table<number> Items to add
---@field trinkets table<number>|nil Trinkets to add
---@field custom_setup function|nil Custom logic to run after items are added

-- Utility: remove all items from a player
function CharacterSetups.StripAllItems(player)
    -- Remove all collectibles
    local config = Isaac.GetItemConfig()
    local limit = config:GetCollectibles().Size - 1
    for i = 1, limit do
        -- RGON exposes character-innate items through HasCollectible, even when
        -- RemoveCollectible cannot remove them. Iterate real copies, never loop
        -- on HasCollectible (Samson's innate Bloody Lust would hang the game).
        local copies = player:GetCollectibleNum(i, true)
        for _ = 1, copies do player:RemoveCollectible(i) end
    end
    -- Remove all trinkets
    for i = 1, TrinketType.NUM_TRINKETS do
        -- Tick/locked trinkets may refuse removal; avoid an unbounded loop.
        for _ = 1, 2 do
            if not player:HasTrinket(i) or not player:TryRemoveTrinket(i) then break end
        end
    end
    -- Reset stats
    player:AddMaxHearts(-player:GetMaxHearts())
    player:AddSoulHearts(-player:GetSoulHearts())
    player:AddBoneHearts(-player:GetBoneHearts())
    player:AddBlackHearts(-24)
    -- Give back base health based on character
    local pType = player:GetPlayerType()
    if pType == PlayerType.PLAYER_THELOST or pType == PlayerType.PLAYER_THELOST_B then
        -- Lost characters have no health
    elseif pType == PlayerType.PLAYER_KEEPER or pType == PlayerType.PLAYER_KEEPER_B then
        player:AddMaxHearts(2, true) -- Coin hearts
    elseif pType == PlayerType.PLAYER_THEFORGOTTEN then
        player:AddBoneHearts(2)
    elseif pType == PlayerType.PLAYER_BETHANY then
        player:AddMaxHearts(6)
    elseif pType == PlayerType.PLAYER_JACOB then
        player:AddMaxHearts(4)
        player:AddSoulHearts(2)
    else
        player:AddMaxHearts(6)
        player:AddHearts(6)
    end
end

-- Character setup definitions
CharacterSetups.Setups = {
    -- Isaac: normal D6; Knife + Soy Milk is opt-in
    [PlayerType.PLAYER_ISAAC] = {
        items = {
            CollectibleType.COLLECTIBLE_D6,
        },
    },

    -- Azazel: Rock Bottom (one stat boost)
    [PlayerType.PLAYER_AZAZEL] = {
        items = {
            CollectibleType.COLLECTIBLE_ROCK_BOTTOM,
        },
        custom_setup = function(player)
            -- Give a single random stat up then lock with Rock Bottom
            local statUps = {
                CollectibleType.COLLECTIBLE_SPEED_BALL,
                CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM,
                CollectibleType.COLLECTIBLE_CRICKETS_HEAD,
                CollectibleType.COLLECTIBLE_SACRED_HEART,
            }
            local chosen = statUps[math.random(#statUps)]
            player:AddCollectible(chosen, 0, false)
        end,
    },

    -- The Lost: Grounded (can't fly), one flight item
    [PlayerType.PLAYER_THELOST] = {
        items = {},
        custom_setup = function(player)
            -- Remove innate flight by giving Grounded-like effect
            -- Add one flight item that the player can choose to use
            local flightItems = {
                CollectibleType.COLLECTIBLE_FATE,
                CollectibleType.COLLECTIBLE_LORDS_OF_THE_PIT,
                CollectibleType.COLLECTIBLE_DEAD_DOVE,
            }
            local chosen = flightItems[math.random(#flightItems)]
            player:AddCollectible(chosen, 0, false)
            -- Note: True "grounded" requires removing CanFly via
            -- entity flags or costume callbacks (modder can extend)
        end,
    },

    -- Eden: Experimental Treatment + extra boss, single Eden Blessing per run
    [PlayerType.PLAYER_EDEN] = {
        items = {
            CollectibleType.COLLECTIBLE_EXPERIMENTAL_TREATMENT,
        },
        custom_setup = function(player)
            player:AddCollectible(CollectibleType.COLLECTIBLE_EDENS_BLESSING, 0, false)
        end,
    },

    -- Jacob & Esau: Dr. Fetus + My Reflection + No. 2
    [PlayerType.PLAYER_JACOB] = {
        items = {
            CollectibleType.COLLECTIBLE_DR_FETUS,
            CollectibleType.COLLECTIBLE_MY_REFLECTION,
            CollectibleType.COLLECTIBLE_NUMBER_TWO,
        },
    },

    -- Tainted Isaac: Inverse Sacred Orb (Sacred Orb x3)
    [PlayerType.PLAYER_ISAAC_B] = {
        items = {},
        custom_setup = function(player)
            for _ = 1, 3 do
                player:AddCollectible(CollectibleType.COLLECTIBLE_SACRED_ORB, 0, false)
            end
        end,
    },

    -- Tainted Lost: Little Baggy, Planetariums
    [PlayerType.PLAYER_THELOST_B] = {
        items = {
            CollectibleType.COLLECTIBLE_LITTLE_BAGGY,
        },
        custom_setup = function(player)
            -- Grant planetarium chance increase
            local game = Game()
            local level = game:GetLevel()
            -- Mark planetarium visited to increase chances
            -- (actual planetarium spawning needs floor generation hooks)
            player:AddCollectible(CollectibleType.COLLECTIBLE_CRYSTAL_BALL, 0, false)
        end,
    },

    -- Tainted Cain: All items become pickups, The Shovel
    [PlayerType.PLAYER_CAIN_B] = {
        items = {
            CollectibleType.COLLECTIBLE_MOMS_SHOVEL,
        },
        -- Tainted Cain already converts items to pickups via Bag of Crafting
    },

    -- Tainted Keeper: No shop doors, Cursed Penny + Magnet
    [PlayerType.PLAYER_KEEPER_B] = {
        items = {},
        trinkets = {
            TrinketType.TRINKET_CURSED_PENNY,
        },
        custom_setup = function(player)
            player:AddCollectible(CollectibleType.COLLECTIBLE_MAGNETO, 0, false)
        end,
    },

    -- Tainted Eden: TM Trainer, one inverse R key on death
    [PlayerType.PLAYER_EDEN_B] = {
        items = {
            CollectibleType.COLLECTIBLE_TMTRAINER,
        },
    },

    -- Tainted Jacob: Birthright
    [PlayerType.PLAYER_JACOB_B] = {
        items = {
            CollectibleType.COLLECTIBLE_BIRTHRIGHT,
        },
    },
}

-- Apply setup for a given player
function CharacterSetups.ApplySetup(player)
    local pType = player:GetPlayerType()
    local setup = CharacterSetups.Setups[pType]

    if not setup then
        -- Default: no special items, just base character
        Isaac.DebugString("[Twisted R Key] No custom setup for player type " .. tostring(pType))
        return
    end

    -- Add items
    for _, itemId in ipairs(setup.items) do
        player:AddCollectible(itemId, 0, false)
    end

    -- Add trinkets
    if setup.trinkets then
        for _, trinketId in ipairs(setup.trinkets) do
            player:AddTrinket(trinketId, false)
        end
    end

    -- Run custom setup
    if setup.custom_setup then
        setup.custom_setup(player)
    end

    Isaac.DebugString("[Twisted R Key] Applied setup for player type " .. tostring(pType))
end

return CharacterSetups
