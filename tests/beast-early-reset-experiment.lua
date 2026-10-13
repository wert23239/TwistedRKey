-- Reset after the native Beast completion event, not keyboard timing.
local Beast = {}
function Beast:Init(mod, tracker, key)
    self.tracker, self.key = tracker, key
    self.pending = false
    if ModCallbacks.MC_POST_COMPLETION_EVENT then
        mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, function(_, completion)
            if completion ~= 14 then return end
            tracker:MarkBossKilled('the_beast')
            -- If this was the final required check, keep the normal victorious ending.
            if tracker:AreAllBossesKilled() then return end
            self.pending = true
            tracker.data._beastResetPending = true
            tracker:Save()
            Isaac.DebugString('[TRK Beast] Native completion recorded; reset queued')
        end)
    end
    mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
        if npc.Variant ~= 0 then return end
        if npc.HitPoints <= 0 or npc:IsDead() then
            -- The post-completion hook is too late: Beast queues its ending in
            -- that same native update. Intercept the lethal update instead.
            if not self.pending and not tracker:AreAllBossesKilled() then
                tracker:MarkBossKilled('the_beast')
                -- Preserve the legitimate native mark for this actual kill;
                -- never lower an existing mark or grant one in a disallowed run.
                if Isaac.SetCompletionMark and not Game():AchievementUnlocksDisallowed() then
                    for i = 0, Game():GetNumPlayers() - 1 do
                        local ptype = tracker:CanonicalType(Isaac.GetPlayer(i):GetPlayerType())
                        local value = Game().Difficulty == Difficulty.DIFFICULTY_HARD and 2 or 1
                        if Isaac.GetCompletionMark(ptype, 14) < value then
                            Isaac.SetCompletionMark(ptype, 14, value)
                        end
                    end
                end
                if tracker:AreAllBossesKilled() then return end
                self.pending = true
                tracker.data._beastResetPending = true
                tracker:Save()
                Isaac.DebugString('[TRK Beast] Lethal update intercepted before ending')
            end
            if self.pending then return true end
        end
    end, 951)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not self.pending then return end
        self.pending = false
        tracker.data._beastResetPending = nil
        tracker:Save()
        key:OnUseItem(Isaac.GetPlayer(0), true)
        Isaac.DebugString('[TRK Beast] Built-in R Key transition requested; no forced quit')
    end)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        self.pending = continued and tracker.data._beastResetPending == true or false
    end)
    if ModCallbacks.MC_PRE_MEGA_SATAN_ENDING then
        mod:AddCallback(ModCallbacks.MC_PRE_MEGA_SATAN_ENDING, function()
            -- Leave time to collect the normal Twisted reward, preserving the native mark.
            if not tracker:AreAllBossesKilled() then return true end
        end)
    end
end
return Beast
