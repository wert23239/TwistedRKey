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
BossTracker.ALL_BOSS_IDS = {}
for _, boss in ipairs(BossTracker.BOSSES) do
    table.insert(BossTracker.ALL_BOSS_IDS, boss.id)
end

function BossTracker:Init(mod)
    self.mod = mod
    self.data = {}
    self.runData = {} -- Bosses killed in current R Key cycle

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
        self.runData = {}
    end
end

function BossTracker:OnBossDeath(npc)
    for _, boss in ipairs(self.BOSSES) do
        if npc.Type == boss.entityType and (npc.Variant == boss.variant or boss.variant == -1) then
            self:MarkBossKilled(boss.id)
            Isaac.DebugString("[Twisted R Key] Boss killed: " .. boss.name)
            break
        end
    end
end

function BossTracker:MarkBossKilled(bossId)
    if not self.data[bossId] then
        self.data[bossId] = true
        self.runData[bossId] = true
        self:Save()
    end
end

function BossTracker:IsBossKilled(bossId)
    return self.data[bossId] == true
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
    return self:GetKilledCount() >= self:GetTotalBossCount()
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
