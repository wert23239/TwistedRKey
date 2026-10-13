-- Stable playtest rule: Beast is last. Gate at Home, BEFORE arena/ending state.
local Beast = {}
function Beast:OtherChecksComplete(playerType)
    local marks = self.tracker:GetCharacterMarks(playerType)
    for _, id in ipairs(self.tracker.REQUIRED_CHECKS) do
        if id ~= 'the_beast' and not marks[id] then return false end
    end
    return true
end

function Beast:CheckHome()
    if Game():GetNumPlayers() == 0 then return end
    if Game():GetLevel():GetStage() ~= LevelStage.STAGE8 then return end
    if not self:OtherChecksComplete(Isaac.GetPlayer(0):GetPlayerType()) then
        self.pending = true
        Isaac.DebugString('[TRK Beast] Home gated: Beast must be last')
    end
end

function Beast:Init(mod, tracker, key)
    self.tracker, self.key = tracker, key
    self.pending = false
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() self:CheckHome() end)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
        self.pending = false
        self:CheckHome()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not self.pending then return end
        self.pending = false
        -- Ordinary verified Twisted reset while still in the normal Home room.
        -- Do not use an experimental Beast-arena R Key or wait for a death frame.
        key:OnUseItem(Isaac.GetPlayer(0), false)
        Game():GetHUD():ShowItemText('Beast is the finale', 'Finish the other 10 checks first')
    end)
    if ModCallbacks.MC_PRE_MEGA_SATAN_ENDING then
        mod:AddCallback(ModCallbacks.MC_PRE_MEGA_SATAN_ENDING, function()
            if not tracker:AreAllBossesKilled() then return true end
        end)
    end
end
return Beast
