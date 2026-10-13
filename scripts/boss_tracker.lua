local json = require("json")

local BossTracker = {}
BossTracker.__index = BossTracker

-- Endgame boss entity types/variants for detection
BossTracker.BOSSES = {
    { id = "mom",           name = "Mom",               entityType = EntityType.ENTITY_MOM,              variant = 0 },
    { id = "moms_heart",    name = "Mom's Heart",       entityType = EntityType.ENTITY_MOMS_HEART,       variant = 0 },
    { id = "it_lives",      name = "It Lives",          entityType = EntityType.ENTITY_MOMS_HEART,       variant = 1 },
    { id = "isaac_boss",    name = "Isaac",             entityType = EntityType.ENTITY_ISAAC,             variant = 0 },
    { id = "blue_baby",     name = "???",               entityType = EntityType.ENTITY_ISAAC,             variant = 1 },
    { id = "satan",         name = "Satan",             entityType = EntityType.ENTITY_SATAN,             variant = 0 },
    { id = "the_lamb",      name = "The Lamb",          entityType = EntityType.ENTITY_THE_LAMB,          variant = 0 },
    { id = "mega_satan",    name = "Mega Satan",        entityType = EntityType.ENTITY_MEGA_SATAN,        variant = 0 },
    { id = "hush",          name = "Hush",              entityType = EntityType.ENTITY_HUSH,              variant = 0 },
    { id = "delirium",      name = "Delirium",          entityType = EntityType.ENTITY_DELIRIUM,          variant = 0 },
    { id = "mother",        name = "Mother",            entityType = 912,                                 variant = 0 }, -- Mother entity type
    { id = "dogma",         name = "Dogma",             entityType = 950,                                 variant = 0 }, -- Dogma entity type
    { id = "the_beast",     name = "The Beast",         entityType = 951,                                 variant = 0 }, -- The Beast entity type
}

-- All boss IDs for easy iteration
BossTracker.REQUIRED_CHECKS = {
    'moms_heart', 'isaac_boss', 'satan', 'boss_rush', 'blue_baby',
    'the_lamb', 'mega_satan', 'hush', 'delirium', 'mother', 'the_beast',
}
BossTracker.COMPLETION_MAP = {
    [0] = 'moms_heart', [1] = 'isaac_boss', [2] = 'satan', [3] = 'boss_rush',
    [4] = 'blue_baby', [5] = 'the_lamb', [6] = 'mega_satan', [9] = 'hush',
    [12] = 'delirium', [13] = 'mother', [14] = 'the_beast',
}

BossTracker.ALL_BOSS_IDS = {}
for _, boss in ipairs(BossTracker.BOSSES) do
    table.insert(BossTracker.ALL_BOSS_IDS, boss.id)
end

function BossTracker:Init(mod)
    self.mod = mod
    self.data = {}
    self.runData = {} -- Bosses killed in current R Key cycle
    self:Load()
    if ModCallbacks.MC_POST_SAVESLOT_LOAD then
        mod:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, function(_, _, selected, rawSlot)
            if selected and rawSlot ~= 0 then self:Load() end
        end)
    end
    if ModCallbacks.MC_POST_COMPLETION_EVENT then
        self.nativeCompletions = true
        mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, function(_, completion)
            local boss = self.COMPLETION_MAP[completion]
            if boss then self:MarkBossKilled(boss) end
        end)
    end
    if ModCallbacks.MC_POST_COMPLETION_MARK_GET then
        mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARK_GET, function(_, completion, playerType)
            local boss = self.COMPLETION_MAP[completion]
            if boss then self:MarkBossKilled(boss, playerType) end
        end)
    end
    -- Vanilla Boss Rush does not have one unique boss NPC: only final clear counts.
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if Game():GetRoom():GetType() == RoomType.ROOM_BOSSRUSH then
            self:MarkBossKilled('boss_rush')
        end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, isGameOver)
        if isGameOver then
            self.data._characters = {}
            self.data._chainBosses = {}
            self:Save()
        end
    end)

    -- Register boss death detection
    mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
        self:OnBossDeath(npc)
    end)
end

function BossTracker:OnGameStart(continued)
    if continued then
        self:Load()
    else
        self:Load()
        local seed = Game():GetSeeds():GetStartSeedString()
        if self.data._twistedRestart and self.data._chainSeed == seed then return end
        self.data._twistedRestart = nil
        self.data._chainSeed = seed
        self.runData = {}
        self.data._characters = {}
        self.data._chainBosses = {}
        self.data._twistedCycles = 0
        self.data._spentItems = {}
        self.data._hardChain = Game().Difficulty == Difficulty.DIFFICULTY_HARD
        self:Save()
    end
end

function BossTracker:OnBossDeath(npc)
    -- Native completion events avoid premature checks from multi-phase/duplicate
    -- NPCs (Satan, Mega Satan, Delirium transformations, etc).
    if self.nativeCompletions then return end
    for _, boss in ipairs(self.BOSSES) do
        if npc.Type == boss.entityType and (npc.Variant == boss.variant or boss.variant == -1) then
            self:MarkBossKilled(boss.id)
            Isaac.DebugString("[Twisted R Key] Boss killed: " .. boss.name)
            break
        end
    end
end

function BossTracker:MarkBossKilled(bossId, playerType)
    self.data[bossId] = true -- retain legacy global progression, not character marks
    self.data._chainBosses = self.data._chainBosses or {}
    self.data._chainBosses[bossId] = true
    self.runData[bossId] = true
    if playerType ~= nil then
        self:MarkCharacterBoss(playerType, bossId)
    else
        for i = 0, Game():GetNumPlayers() - 1 do
            self:MarkCharacterBoss(Isaac.GetPlayer(i):GetPlayerType(), bossId)
        end
    end
    self:Save()
end

function BossTracker:CanonicalType(playerType)
    if playerType == PlayerType.PLAYER_LAZARUS2 then return PlayerType.PLAYER_LAZARUS end
    if playerType == PlayerType.PLAYER_ESAU then return PlayerType.PLAYER_JACOB end
    return playerType
end

function BossTracker:MarkCharacterBoss(playerType, bossId)
    playerType = self:CanonicalType(playerType)
    self.data._characters = self.data._characters or {}
    local key = tostring(playerType)
    self.data._characters[key] = self.data._characters[key] or {}
    if bossId == 'it_lives' then bossId = 'moms_heart' end
    self.data._characters[key][bossId] = true
    if self.data._hardChain and (self.data._twistedCycles or 0) > 0 and self:IsCharacterChainComplete(playerType) then
        self.data._completedChains = self.data._completedChains or {}
        -- The award is created only from THIS chain, never legacy/global data.
        self.data._completedChains[key] = self.data._completedChains[key] or {
            seed = Game():GetSeeds():GetStartSeedString(), checks = #self.REQUIRED_CHECKS, hard = true,
        }
    end
end

function BossTracker:IsCharacterChainComplete(playerType)
    local marks = self:GetCharacterMarks(playerType)
    for _, id in ipairs(self.REQUIRED_CHECKS) do
        if not marks[id] then return false end
    end
    return true
end

function BossTracker:GetCharacterMarks(playerType)
    playerType = self:CanonicalType(playerType)
    return (self.data._characters or {})[tostring(playerType)] or {}
end

function BossTracker:IsBossKilled(bossId)
    return self.data[bossId] == true
end

function BossTracker:GetChainCount(playerType)
    local count = 0
    local marks = self:GetCharacterMarks(playerType)
    for _, id in ipairs(self.REQUIRED_CHECKS) do if marks[id] then count = count + 1 end end
    return count
end

function BossTracker:GetKilledCount()
    local count = 0
    for _, id in ipairs(self.ALL_BOSS_IDS) do
        if self.data[id] then
            count = count + 1
        end
    end
    return count
end

function BossTracker:GetTotalBossCount()
    return #self.ALL_BOSS_IDS
end

function BossTracker:AreAllBossesKilled()
    return self:IsCharacterChainComplete(Isaac.GetPlayer(0):GetPlayerType())
end

function BossTracker:ResetRunData()
    self.runData = {}
end

-- Persistence using Isaac's mod data system
function BossTracker:Save()
    local saveData = json.encode(self.data)
    self.mod:SaveData(saveData)
end

function BossTracker:Load()
    if self.mod:HasData() then
        local raw = self.mod:LoadData()
        local success, decoded = pcall(json.decode, raw)
        if success and type(decoded) == "table" then
            -- Extract boss data (may be nested if sharing save with other modules)
            if decoded.bosses then
                self.data = decoded.bosses
            else
                self.data = decoded
            end
        else
            self.data = {}
        end
    else
        self.data = {}
    end
end

-- Get save-compatible data table
function BossTracker:GetSaveTable()
    return self.data
end

function BossTracker:LoadFromTable(tbl)
    if tbl and type(tbl) == "table" then
        self.data = tbl
    end
end

return BossTracker
