local TwistedRKey = RegisterMod("Twisted R Key", 1)

-- Core modules
local CharacterSetups = require("scripts.character_setups")
local BossTracker = require("scripts.boss_tracker")
local Progression = require("scripts.progression")
local TwistedRKeyItem = require("scripts.twisted_r_key")
local LoadoutPresets = require("scripts.loadout_presets")
local CharacterMechanics = require("scripts.character_mechanics")

-- Initialize modules with mod reference
BossTracker:Init(TwistedRKey)
Progression:Init(TwistedRKey, BossTracker)
TwistedRKeyItem:Init(TwistedRKey, CharacterSetups, BossTracker, Progression)
LoadoutPresets:Init(TwistedRKey, CharacterSetups, BossTracker)
CharacterMechanics:Init(TwistedRKey, BossTracker, CharacterSetups)

-- Save/Load data
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
    BossTracker:OnGameStart(continued)
    LoadoutPresets:OnGameStart(continued)
    CharacterMechanics:OnGameStart(continued)
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

-- Repentance+ accepts built-in Lua console helpers even when unknown custom
-- command dispatch is unavailable. These are deliberate user/testing actions.
function TRKLoadout(mode)
    if mode == "normal" or mode == "knife" then
        LoadoutPresets.mode = mode
        BossTracker.data._isaacLoadoutMode = mode
        BossTracker:Save()
        print("Isaac preset: " .. mode .. " (fresh run / Twisted reset)")
    elseif mode == "apply" then
        LoadoutPresets:ApplyIsaac(Isaac.GetPlayer(0))
    elseif mode == "status" then
        local p = Isaac.GetPlayer(0)
        local report = "mode=" .. LoadoutPresets.mode .. " player=" .. p:GetPlayerType()
            .. " D6=" .. p:GetCollectibleNum(105)
            .. " Knife=" .. p:GetCollectibleNum(114)
            .. " Soy=" .. p:GetCollectibleNum(330)
        print(report)
        Isaac.DebugString("[TRK loadout] " .. report)
    else
        print("TRKLoadout: normal / knife / apply / status")
    end
end
