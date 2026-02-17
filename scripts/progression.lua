local Progression = {}
Progression.__index = Progression

-- Define unlock thresholds: beat N bosses to unlock a character setup
-- Characters unlock in order as you beat more endgame bosses
Progression.UNLOCKS = {
    { bossesRequired = 0,  playerType = PlayerType.PLAYER_ISAAC,    name = "Isaac" },
    { bossesRequired = 1,  playerType = PlayerType.PLAYER_AZAZEL,   name = "Azazel" },
    { bossesRequired = 2,  playerType = PlayerType.PLAYER_THELOST,  name = "The Lost" },
    { bossesRequired = 3,  playerType = PlayerType.PLAYER_EDEN,     name = "Eden" },
    { bossesRequired = 4,  playerType = PlayerType.PLAYER_JACOB,    name = "Jacob & Esau" },
    { bossesRequired = 5,  playerType = PlayerType.PLAYER_ISAAC_B,  name = "Tainted Isaac" },
    { bossesRequired = 6,  playerType = PlayerType.PLAYER_THELOST_B, name = "Tainted Lost" },
    { bossesRequired = 7,  playerType = PlayerType.PLAYER_CAIN_B,   name = "Tainted Cain" },
    { bossesRequired = 8,  playerType = PlayerType.PLAYER_KEEPER_B, name = "Tainted Keeper" },
    { bossesRequired = 9,  playerType = PlayerType.PLAYER_EDEN_B,   name = "Tainted Eden" },
    { bossesRequired = 10, playerType = PlayerType.PLAYER_JACOB_B,  name = "Tainted Jacob" },
}

function Progression:Init(mod, bossTracker)
    self.mod = mod
    self.bossTracker = bossTracker
    self.unlockedCharacters = {}
end

function Progression:OnGameStart(continued)
    self:RefreshUnlocks()
end

function Progression:RefreshUnlocks()
    local killed = self.bossTracker:GetKilledCount()
    self.unlockedCharacters = {}

    for _, unlock in ipairs(self.UNLOCKS) do
        if killed >= unlock.bossesRequired then
            self.unlockedCharacters[unlock.playerType] = true
        end
    end

    Isaac.DebugString("[Twisted R Key] Unlocked " .. self:GetUnlockedCount() .. "/" .. #self.UNLOCKS .. " character setups")
end

function Progression:IsCharacterUnlocked(playerType)
    return self.unlockedCharacters[playerType] == true
end

function Progression:GetUnlockedCount()
    local count = 0
    for _ in pairs(self.unlockedCharacters) do
        count = count + 1
    end
    return count
end

function Progression:GetNextUnlock()
    local killed = self.bossTracker:GetKilledCount()
    for _, unlock in ipairs(self.UNLOCKS) do
        if killed < unlock.bossesRequired then
            return unlock
        end
    end
    return nil -- All unlocked
end

function Progression:Save()
    -- Progression is derived from boss kills, no separate save needed
end

return Progression
