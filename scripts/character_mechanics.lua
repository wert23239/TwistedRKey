-- Custom normal-character mechanics. State is saved with the existing mod data.
local Mechanics = {}
local GAME = Game()
local PURPLE = TrinketType.TRINKET_PURPLE_HEART
local POCKET = ActiveSlot.SLOT_POCKET
local YUCK = CollectibleType.COLLECTIBLE_YUCK_HEART
local NEGATIVE = {
    PillEffect.PILLEFFECT_SPEED_DOWN, PillEffect.PILLEFFECT_RANGE_DOWN,
    PillEffect.PILLEFFECT_TEARS_DOWN, PillEffect.PILLEFFECT_LUCK_DOWN,
    PillEffect.PILLEFFECT_SHOT_SPEED_DOWN, PillEffect.PILLEFFECT_AMNESIA,
    PillEffect.PILLEFFECT_PARALYSIS, PillEffect.PILLEFFECT_RETRO_VISION,
}

function Mechanics:State(player)
    local index = 0
    for i = 0, GAME:GetNumPlayers() - 1 do
        if Isaac.GetPlayer(i).InitSeed == player.InitSeed then index = i; break end
    end
    local key = tostring(index)
    local s = self.data.players[key]
    if not s or s.type ~= player:GetPlayerType() then
        s = { type = player:GetPlayerType(), rooms = 0 }
        self.data.players[key] = s
    end
    return s
end

function Mechanics:Save()
    self.tracker.data._characterMechanics = self.data
    self.tracker:Save()
end

function Mechanics:FloorToken()
    local level = GAME:GetLevel()
    return tostring(level:GetDungeonPlacementSeed()) .. ':' .. level:GetStage()
        .. ':' .. level:GetStageType()
end

function Mechanics:GiveCainPill(player, force)
    local s = self:State(player)
    local floor = self:FloorToken()
    if not force and s.floor == floor then return end
    s.floor, s.pending = floor, true
    if self.cainInputRequests then self.cainInputRequests[player.InitSeed] = nil end
    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUCKY_FOOT)
    s.effect = NEGATIVE[rng:RandomInt(#NEGATIVE) + 1]
    s.color = PillColor.PILL_BLUE_BLUE
    player:SetCard(0, 0)
    player:SetPill(0, s.color)
    GAME:GetHUD():ShowItemText('Unlucky Foot', 'Take the negative pill to unlock pocket items')
end

function Mechanics:Apply(player, restoreKit)
    local kind = player:GetPlayerType()
    local baseline = kind == PlayerType.PLAYER_CAIN and CollectibleType.COLLECTIBLE_LUCKY_FOOT
        or kind == PlayerType.PLAYER_JUDAS and CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL
    if restoreKit and baseline and not player:HasCollectible(baseline) then
        local config = Isaac.GetItemConfig():GetCollectible(baseline)
        player:AddCollectible(baseline, config and config.MaxCharges or 0, false)
    end
    if kind == PlayerType.PLAYER_MAGDALENE then
        if player:HasCollectible(CollectibleType.COLLECTIBLE_YUM_HEART) then player:RemoveCollectible(CollectibleType.COLLECTIBLE_YUM_HEART) end
        if player:GetActiveItem(POCKET) ~= YUCK then player:SetPocketActiveItem(YUCK, POCKET, true) end
        player:SetActiveCharge(self:State(player).rooms, POCKET)
    elseif kind == PlayerType.PLAYER_CAIN then
        self:GiveCainPill(player, restoreKit)
    elseif kind == PlayerType.PLAYER_JUDAS then
        if restoreKit and not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_PURSE) then
            player:AddCollectible(CollectibleType.COLLECTIBLE_MOMS_PURSE, 0, false)
        end
        -- Purple Heart occupies a real trinket slot, not a hidden stat effect.
        if not player:HasTrinket(PURPLE) then player:AddTrinket(PURPLE, false) end
    end
end

function Mechanics:ConvertHeart(player)
    local rotten = player:GetRottenHearts()
    local normal = math.max(0, player:GetHearts() - rotten * 2)
    if normal > 0 then
        -- Rebuild red health to avoid accidentally removing an existing rotten
        -- heart when AddHearts(-2) targets the rightmost heart.
        player:AddHearts(-player:GetHearts())
        player:AddHearts(math.max(0, normal - 2))
        player:AddRottenHearts((rotten + 1) * 2)
        return true
    elseif player:GetSoulHearts() > 0 then
        -- Rotten hearts require red containers. Exchange soul/black health for
        -- one container without using damage (no black-heart explosion).
        local amount = math.min(2, player:GetSoulHearts())
        player:AddSoulHearts(-amount)
        player:AddMaxHearts(2)
        player:AddRottenHearts(2)
        return true
    end
    return false -- all filled health is already rotten: do not heal for free
end

function Mechanics:RoomCleared()
    local room = GAME:GetRoom()
    local key = self:FloorToken() .. ':' .. GAME:GetLevel():GetCurrentRoomIndex()
        .. ':' .. room:GetSpawnSeed()
    if self.data.cleared[key] then return end
    self.data.cleared[key] = true
    for i = 0, GAME:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:GetPlayerType() == PlayerType.PLAYER_MAGDALENE then
            local s = self:State(player)
            s.rooms = s.rooms + 1
            if s.rooms >= 4 then
                s.rooms = 0
                self.forcedUse = true
                player:UseActiveItem(YUCK, UseFlag.USE_NOANIM, POCKET)
                self.forcedUse = false
                GAME:GetHUD():ShowItemText('Yuck Heart', 'Another heart rots')
            end
            player:SetActiveCharge(s.rooms, POCKET)
        end
    end
    self:Save()
end

function Mechanics:UpdatePlayer(player)
    local kind = player:GetPlayerType()
    if kind == PlayerType.PLAYER_MAGDALENE then
        self:Apply(player, false)
    elseif kind == PlayerType.PLAYER_CAIN then
        local s = self:State(player)
        if s.pending then
            player:SetCard(0, 0)
            player:SetPill(0, s.color)
            local requests = self.cainInputRequests or {}
            if requests[player.InitSeed] then
                requests[player.InitSeed] = nil
                s.pending = false
                player:SetPill(0, 0)
                self:Save()
                player:UsePill(s.effect, s.color, UseFlag.USE_NOANIM)
                GAME:GetHUD():ShowItemText('Unlucky Foot', 'Pocket items unlocked for this floor')
            end
        end
    elseif kind == PlayerType.PLAYER_JUDAS then
        self:Apply(player, false)
    end
end

-- Input trigger edges are reliable in MC_POST_RENDER, not player-effect
-- updates (live cold Continue can otherwise swallow Q while pending stays true).
function Mechanics:ReadCainInput(player)
    if player:GetPlayerType() ~= PlayerType.PLAYER_CAIN or player.ControlsEnabled == false then return end
    local s = self:State(player)
    if not s.pending then return end
    self.readInput = true
    local take = Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
    self.readInput = false
    if not take then return end
    -- Rendering must only observe input. Native pill effects/cache evaluation
    -- run on the next player-effect update, never inside the render stack.
    self.cainInputRequests = self.cainInputRequests or {}
    self.cainInputRequests[player.InitSeed] = true
end

function Mechanics:BlockInput(entity, hook, action)
    if self.readInput or not entity then return end
    local player = entity:ToPlayer()
    if not player then return end
    local kind = player:GetPlayerType()
    local blocked = kind == PlayerType.PLAYER_MAGDALENE and action == ButtonAction.ACTION_PILLCARD
        or kind == PlayerType.PLAYER_CAIN and self:State(player).pending
            and (action == ButtonAction.ACTION_PILLCARD or action == ButtonAction.ACTION_DROP)
        or kind == PlayerType.PLAYER_JUDAS and player:HasTrinket(PURPLE)
            and action == ButtonAction.ACTION_DROP
    if blocked then
        -- A short drop-button tap cycles pocket/trinket slots. Only suppress
        -- Judas's held drop action; do not lock his card/pill slot switching.
        if kind == PlayerType.PLAYER_JUDAS and hook == InputHook.IS_ACTION_TRIGGERED then return end
        if hook == InputHook.GET_ACTION_VALUE then return 0 end
        return false
    end
end

function Mechanics:OnGameStart(continued)
    self.cainInputRequests = {} -- input edges never survive Continue/restart
    self.data = continued and self.tracker.data._characterMechanics or nil
    self.data = self.data or { players = {}, cleared = {} }
    self.ready = true
    for i = 0, GAME:GetNumPlayers() - 1 do self:Apply(Isaac.GetPlayer(i), not continued) end
    self:Save()
end

function Mechanics:Init(mod, tracker, setups)
    self.tracker, self.data = tracker, { players = {}, cleared = {} }
    local original = setups.ApplySetup
    setups.ApplySetup = function(player)
        original(player)
        self:Apply(player, true)
        self:Save()
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        if self.ready then self:UpdatePlayer(player) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not self.ready or GAME:IsPaused() then return end
        for i = 0, GAME:GetNumPlayers() - 1 do self:ReadCainInput(Isaac.GetPlayer(i)) end
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if self.ready then self:RoomCleared() end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        if not self.ready then return end
        for i = 0, GAME:GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if player:GetPlayerType() == PlayerType.PLAYER_CAIN then self:GiveCainPill(player, false) end
        end
        self:Save()
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, _, _, player, _, slot)
        if player:GetPlayerType() == PlayerType.PLAYER_MAGDALENE and slot == POCKET then
            if self.forcedUse then self:ConvertHeart(player) end
            return true -- replace vanilla healing; manual/external use cannot rot early
        end
    end, YUCK)
    mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
        return self:BlockInput(entity, hook, action)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, function(_, pickup, collider)
        local player = collider:ToPlayer()
        if not player then return end
        if player:GetPlayerType() == PlayerType.PLAYER_CAIN and self:State(player).pending
            and (pickup.Variant == PickupVariant.PICKUP_TAROTCARD or pickup.Variant == PickupVariant.PICKUP_PILL) then
            return true
        end
        if player:GetPlayerType() == PlayerType.PLAYER_JUDAS and player:HasTrinket(PURPLE)
            and pickup.Variant == PickupVariant.PICKUP_TRINKET
            and player:GetTrinket(0) ~= 0 and player:GetTrinket(1) ~= 0 then return true end
    end)
end

return Mechanics
