local TwistedRKeyItem = {}
TwistedRKeyItem.__index = TwistedRKeyItem

local TWISTED_R_KEY_NAME = "Twisted R Key"
local SFX_MANAGER = SFXManager()
local GAME = Game()

function TwistedRKeyItem:Init(mod, characterSetups, bossTracker, progression)
    self.mod = mod
    self.characterSetups = characterSetups
    self.bossTracker = bossTracker
    self.progression = progression
    self.itemId = nil
    self.twistedRKeyUsed = false

    -- Resolve item ID after content is loaded
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
        self.itemId = Isaac.GetItemIdByName(TWISTED_R_KEY_NAME)
        if self.itemId == -1 then
            Isaac.DebugString("[Twisted R Key] ERROR: Could not find item ID for '" .. TWISTED_R_KEY_NAME .. "'")
        else
            Isaac.DebugString("[Twisted R Key] Item ID resolved: " .. tostring(self.itemId))
        end
    end)

    -- Register broadly because custom item IDs may not be resolvable during init.
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemId, rng, player, flags, slot, varData)
        if itemId ~= self:GetItemId() then
            return nil
        end
        return self:OnUseItem(player)
    end)

    -- Spawn Twisted R Key after endgame boss rooms
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function(_, rng, spawnPos)
        self:TrySpawnAfterBoss(spawnPos)
    end)

    -- Handle post-teleport setup
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        if self.twistedRKeyUsed then
            self:OnPostTwistedRestart()
            self.twistedRKeyUsed = false
        end
    end)
end

function TwistedRKeyItem:GetItemId()
    if self.itemId and self.itemId ~= -1 then
        return self.itemId
    end
    -- Fallback: try to resolve
    local id = Isaac.GetItemIdByName(TWISTED_R_KEY_NAME)
    if id ~= -1 then
        self.itemId = id
    end
    return id
end

function TwistedRKeyItem:OnGameStart(continued)
    if not continued and not self.bossTracker.data._twistedRestart then
        self.twistedRKeyUsed = false
    end
    if GAME.GetItemPool then
        for id in pairs(self.bossTracker.data._spentItems or {}) do
            GAME:GetItemPool():RemoveCollectible(tonumber(id))
        end
    end
end

function TwistedRKeyItem:KeepSpentItemsOutOfPool(player)
    if not GAME.GetItemPool then return end
    local key = tostring(self.bossTracker:CanonicalType(player:GetPlayerType()))
    local baseline = (self.bossTracker.data._poolBaseline or {})[key] or {}
    local spent = self.bossTracker.data._spentItems or {}
    self.bossTracker.data._spentItems = spent
    for id = 1, Isaac.GetItemConfig():GetCollectibles().Size - 1 do
        if id ~= self:GetItemId() and player:GetCollectibleNum(id, true) > 0
            and not baseline[tostring(id)] then
            spent[tostring(id)] = true
            GAME:GetItemPool():RemoveCollectible(id)
        end
    end
end

function TwistedRKeyItem:OnUseItem(player, beastTransition)
    Isaac.DebugString("[Twisted R Key] Item used! Initiating twisted restart...")

    -- Save the same living chain before restarting its floor layout.
    self:KeepSpentItemsOutOfPool(player)
    self.bossTracker.data._twistedCycles = (self.bossTracker.data._twistedCycles or 0) + 1
    self.bossTracker:Save()

    -- Mark that we need to do post-teleport setup
    self.twistedRKeyUsed = true
    self.bossTracker.data._twistedRestart = true
    self.bossTracker:Save()

    -- Consume this custom key explicitly before restoring a different active.
    -- Returning Remove=true after the synchronous stage warp removes D6 instead.
    player:RemoveCollectible(self:GetItemId())
    -- Strip all items from the player
    self.characterSetups.StripAllItems(player)

    -- Teleport to Chapter 1 Stage 1
    -- Use the stage API to warp to Basement I
    local level = GAME:GetLevel()
    if beastTransition then
        -- Unlike a stage console warp, native R Key clears the Beast arena mode.
        player:UseActiveItem(CollectibleType.COLLECTIBLE_R_KEY, UseFlag.USE_NOANIM)
    else
        Isaac.ExecuteCommand("stage 1")
    end

    -- Play R Key sound effect
    -- Repentance+ exposes R Key's own sound; older versions use a valid fallback.
    SFX_MANAGER:Play(SoundEffect.SOUND_R_KEY or SoundEffect.SOUND_POWERUP1, 1.0, 0)

    return {
        Discharge = false,
        Remove = false,
        ShowAnim = true,
    }
end

function TwistedRKeyItem:OnPostTwistedRestart()
    Isaac.DebugString("[Twisted R Key] Post-restart: applying character setup...")

    local player = Isaac.GetPlayer(0)
    if not player then return end

    -- Apply the character's twisted setup
    self.characterSetups.ApplySetup(player)

    -- Handle Esau for Jacob & Esau
    if player:GetPlayerType() == PlayerType.PLAYER_JACOB then
        local esau = player:GetOtherTwin()
        if esau then
            self.characterSetups.StripAllItems(esau)
            -- Esau gets a subset of items or shared pool
        end
    end

    self.bossTracker.data._twistedRestart = nil
    self.bossTracker:Save()

    -- Refresh progression
    self.progression:RefreshUnlocks()

    -- Show HUD message
    local killed = self.bossTracker:GetChainCount(player:GetPlayerType())
    local total = #self.bossTracker.REQUIRED_CHECKS
    GAME:GetHUD():ShowItemText("Twisted R Key", killed .. "/" .. total .. " bosses defeated")
end

function TwistedRKeyItem:TrySpawnAfterBoss(spawnPos)
    local room = GAME:GetRoom()
    local roomType = room:GetType()

    -- Only spawn in boss rooms
    if roomType ~= RoomType.ROOM_BOSS then return end

    local level = GAME:GetLevel()
    local stage = level:GetStage()
    local stageType = level:GetStageType()

    -- Check if this is an endgame boss room
    local isEndgameBoss = false
    local endgameStages = {
        LevelStage.STAGE3_2,  -- Mom (Depths II)
        LevelStage.STAGE4_2,  -- Mom's Heart / It Lives (Womb II)
        LevelStage.STAGE5,    -- Cathedral / Sheol
        LevelStage.STAGE6,    -- Chest / Dark Room
        LevelStage.STAGE7,    -- The Void (Delirium)
        LevelStage.STAGE4_3,  -- Blue Womb (Hush)
    }

    for _, s in ipairs(endgameStages) do
        if stage == s then
            isEndgameBoss = true
            break
        end
    end

    -- Also check for Corpse II (Mother), Home (Dogma/Beast)
    if stage == LevelStage.STAGE8 then -- Home
        isEndgameBoss = true
    end

    -- Mines/Ashpit → Corpse path
    if stage >= 9 then -- Repentance alt path stages
        isEndgameBoss = true
    end

    if not isEndgameBoss then return end

    -- Don't spawn if all bosses already killed
    if self.bossTracker:AreAllBossesKilled() then return end

    -- Spawn the Twisted R Key
    local itemId = self:GetItemId()
    if itemId and itemId ~= -1 then
        local centerPos = room:GetCenterPos()
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_COLLECTIBLE,
            itemId,
            spawnPos or centerPos,
            Vector.Zero,
            nil
        )
        Isaac.DebugString("[Twisted R Key] Spawned Twisted R Key in endgame boss room")
    end
end

return TwistedRKeyItem
