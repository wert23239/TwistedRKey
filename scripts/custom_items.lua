local Items = {}
local GAME = Game()
local DESIGNS = require('scripts.saved_designs')
local BLOOD_GAIN = { 0, 0.5, 1.2, 2.1, 3.2, 4.5, 6 }
local NAMES = { foot = 'Unlucky Foot', needle = 'Panic Needle', bow = 'Cursed Bow', bird = 'Undead Bird', resurrection = 'Forced Resurrection' }

function Items:State(player)
    return self.mechanics:State(player)
end

function Items:Give(player, id)
    if id and id > 0 and not player:HasCollectible(id) then
        local config = Isaac.GetItemConfig():GetCollectible(id)
        player:AddCollectible(id, config and config.MaxCharges or 0, false)
    end
end

function Items:Apply(player, restore)
    local kind = player:GetPlayerType()
    local designKind = kind == PlayerType.PLAYER_LAZARUS2 and PlayerType.PLAYER_LAZARUS or kind
    if restore then
        local kit = (self.tracker.data._startingKits or {})[tostring(designKind)]
        if kit then
            for _, id in ipairs(kit.items) do self:Give(player, id) end
            for _, id in ipairs(kit.trinkets) do
                if not player:HasTrinket(id) then player:AddTrinket(id, false) end
            end
        end
    end
    local design = DESIGNS[designKind]
    if design and kind ~= PlayerType.PLAYER_ISAAC then
        for _, id in ipairs(design.items) do self:Give(player, id) end
    end
    if kind == PlayerType.PLAYER_CAIN then self:Give(player, self.ids.foot)
    elseif kind == PlayerType.PLAYER_JUDAS then self:Give(player, self.ids.bow)
    elseif kind == PlayerType.PLAYER_SAMSON then
        self:Give(player, CollectibleType.COLLECTIBLE_BLOODY_LUST)
        self:Give(player, self.ids.needle)
    elseif kind == PlayerType.PLAYER_EVE then
        -- Replace the normal bird, otherwise both friendly and hostile birds spawn.
        player:RemoveCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD)
        self:Give(player, self.ids.bird)
    elseif kind == PlayerType.PLAYER_LAZARUS or kind == PlayerType.PLAYER_LAZARUS2 then
        self:Give(player, self.ids.resurrection)
    elseif kind == PlayerType.PLAYER_JACOB then
        local twin = player:GetOtherTwin()
        if twin then self:Give(twin, CollectibleType.COLLECTIBLE_ISAACS_HEART) end
    end
end

function Items:OnGameStart(continued)
    self.ids = {}
    for id, name in pairs(NAMES) do self.ids[id] = Isaac.GetItemIdByName(name) end
    self.ready = true
    if EID and EID.addCollectible then
        local descriptions = {
            foot = "Cain starts each floor with a required negative pill#Take it before using other pocket consumables#No False PHD damage/black-heart benefits",
            needle = "Keep Bloody Lust#Red-health hits subtract twice its corresponding damage gain#Penalty resets each floor#Ordinary damage-ups still work",
            bow = "Filled red, soul and black health gains cap at half a heart#Includes healing from HP-up items#Does not increase incoming damage",
            bird = "On damage, a hostile bird pursues you for this room and the next#The bird can hurt you",
            resurrection = "Lose a life when leaving a floor#Your normal extra lives still work#No spare life means game over",
        }
        for id, text in pairs(descriptions) do EID:addCollectible(self.ids[id], text, NAMES[id]) end
    end
    if not continued and not self.tracker.data._twistedRestart then
        self.tracker.data._startingKits = {}
        for i = 0, GAME:GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local kit = {items = {}, trinkets = {}}
            for id = 1, Isaac.GetItemConfig():GetCollectibles().Size - 1 do
                for _ = 1, p:GetCollectibleNum(id, true) do table.insert(kit.items, id) end
            end
            for slot = 0, 1 do
                local t = p:GetTrinket(slot)
                if t > 0 then table.insert(kit.trinkets, t) end
            end
            self.tracker.data._startingKits[tostring(p:GetPlayerType())] = kit
        end
        for i = 0, GAME:GetNumPlayers() - 1 do self:Apply(Isaac.GetPlayer(i), false) end
    end
    self.tracker:Save()
end

function Items:CapturePoolBaseline()
    self.tracker.data._poolBaseline = {}
    local size = Isaac.GetItemConfig():GetCollectibles().Size
    for i = 0, GAME:GetNumPlayers() - 1 do
        local p = Isaac.GetPlayer(i)
        local key = tostring(self.tracker:CanonicalType(p:GetPlayerType()))
        local baseline = self.tracker.data._poolBaseline[key] or {}
        for id = 1, size - 1 do
            if p:GetCollectibleNum(id, true) > 0 then baseline[tostring(id)] = true end
        end
        self.tracker.data._poolBaseline[key] = baseline
    end
    self.tracker:Save()
end

function Items:Update(player)
    if not self.ready then return end
    local s = self:State(player)
    local birdKey = tostring(player.InitSeed)
    if player:HasCollectible(self.ids.needle) then
        local floor = self.mechanics:FloorToken()
        local red = player:GetHearts()
        local counter = player.GetBloodLustCounter and math.min(6, player:GetBloodLustCounter()) or 0
        if s.needleFloor ~= floor then
            s.needleFloor, s.needleGain, s.needleCounter, s.needleRed = floor, 0, counter, red
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE); player:EvaluateItems()
        elseif counter > (s.needleCounter or 0) then
            if red < (s.needleRed or red) then
                s.needleGain = (s.needleGain or 0) + BLOOD_GAIN[counter + 1] - BLOOD_GAIN[(s.needleCounter or 0) + 1]
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE); player:EvaluateItems()
                self.mechanics:Save()
            end
            s.needleCounter = counter
        end
        s.needleRed = red
    end
    if player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY then
        -- No custom double damage: just remove Pyromaniac's protection.
        if player:HasCollectible(CollectibleType.COLLECTIBLE_PYROMANIAC) then
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_PYROMANIAC)
        end
    end
    if player:HasCollectible(self.ids.bird) and (s.birdRooms or 0) > 0 then
        if not self.birds[birdKey] or not self.birds[birdKey]:Exists() then
            self.birds[birdKey] = Isaac.Spawn(EntityType.ENTITY_EFFECT, self.birdVariant, 0, player.Position + Vector(50, 0), Vector.Zero, player)
            self.birds[birdKey]:GetData().twistedOwner = player
        end
    end
end

function Items:Init(mod, tracker, mechanics, setups)
    self.tracker, self.mechanics, self.ids, self.birds = tracker, mechanics, {}, {}
    self.birdVariant = Isaac.GetEntityVariantByName('Twisted Undead Bird')
    local original = setups.ApplySetup
    setups.ApplySetup = function(player)
        local kind = player:GetPlayerType()
        if kind == PlayerType.PLAYER_LAZARUS2 then kind = PlayerType.PLAYER_LAZARUS end
        if self.ready and DESIGNS[kind] and kind ~= PlayerType.PLAYER_ISAAC then
            self:Apply(player, true)
            mechanics:Apply(player, true)
        else original(player) end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, p) self:Update(p) end)
    if ModCallbacks.MC_EVALUATE_STAT then
        mod:AddCallback(ModCallbacks.MC_EVALUATE_STAT, function(_, p, _, value)
            if self.ready and p:HasCollectible(self.ids.needle) then
                return math.max(0.5, value - 2 * (self:State(p).needleGain or 0))
            end
        end, EvaluateStatStage.FLAT_DAMAGE)
    end
    if ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS then
        mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS, function(_, p, amount, healthType)
            if not self.ready or amount <= 0 or not p:HasCollectible(self.ids.bow) then return end
            -- Containers stay containers. Filled red/soul/black health gains cap at half a heart,
            -- including the healing supplied by HP-up collectibles.
            if healthType == AddHealthType.RED or healthType == AddHealthType.SOUL or healthType == AddHealthType.BLACK then
                return math.min(amount, 1)
            end
        end)
    end
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity)
        local p = entity:ToPlayer()
        if self.ready and p and p:HasCollectible(self.ids.bird) then
            self:State(p).birdRooms = 2
            self.mechanics:Save()
        end
    end, EntityType.ENTITY_PLAYER)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        if not self.ready then return end
        for i = 0, GAME:GetNumPlayers() - 1 do
            local s = self:State(Isaac.GetPlayer(i))
            s.birdRooms = math.max(0, (s.birdRooms or 0) - 1)
            self.birds[tostring(Isaac.GetPlayer(i).InitSeed)] = nil
        end
        self.mechanics:Save()
    end)
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
        local p = familiar.Player
        if self.ready and p and p:HasCollectible(self.ids.bird) then familiar:Remove() end
    end, FamiliarVariant.DEAD_BIRD)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
        local p = effect:GetData().twistedOwner
        if not p or not p:Exists() or (self:State(p).birdRooms or 0) <= 0 then effect:Remove(); return end
        effect.Velocity = effect.Velocity * 0.7 + (p.Position - effect.Position):Resized(1.1)
        if effect.Position:Distance(p.Position) < 14 and effect.FrameCount % 20 == 0 then
            p:TakeDamage(1, 0, EntityRef(effect), 30)
        end
    end, self.birdVariant)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not self.ready or GAME:GetRoom():GetType() ~= RoomType.ROOM_BOSS then return end
        local level = GAME:GetLevel()
        local current = level:GetCurrentRoomDesc()
        local last = level:GetRooms():Get(level:GetLastBossRoomListIndex())
        if last and current.SafeGridIndex ~= last.SafeGridIndex then return end -- XL first boss is not floor-end
        for i = 0, GAME:GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local state = self:State(p)
            local floor = self.mechanics:FloorToken()
            if p:HasCollectible(self.ids.resurrection) and state.resurrectionFloor ~= floor then
                state.resurrectionFloor = floor
                p:Die() -- resolve the old floor's extra life before the next floor replenishes it
            end
        end
        self.mechanics:Save()
    end)

end

return Items
