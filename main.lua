local TwistedRKey = RegisterMod("Twisted R Key", 1)

-- Core modules
local CharacterSetups = require("scripts.character_setups")
local BossTracker = require("scripts.boss_tracker")
local Progression = require("scripts.progression")
local TwistedRKeyItem = require("scripts.twisted_r_key")

-- Initialize modules with mod reference
BossTracker:Init(TwistedRKey)
Progression:Init(TwistedRKey, BossTracker)
TwistedRKeyItem:Init(TwistedRKey, CharacterSetups, BossTracker, Progression)

-- Save/Load data
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
    BossTracker:OnGameStart(continued)
    Progression:OnGameStart(continued)
    TwistedRKeyItem:OnGameStart(continued)
end)

TwistedRKey:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
    if shouldSave then
        BossTracker:Save()
        Progression:Save()
    end
end)

Isaac.DebugString("[Twisted R Key] Mod loaded successfully!")
