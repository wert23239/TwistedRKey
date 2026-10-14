-- QA ONLY, not release content. Append in main.lua scope; read-only, always nil.
-- COMPLETE1202 night-Home checkpoint only. No TV/warps/damage/flags/save calls.
-- First validate logging on a SAFE native Home door before considering finale.
local transitionSlot, transitionArmed = nil, false
local function transitionLog(message)
    -- Logging failure must never become a destination override or block gameplay.
    pcall(function() Isaac.DebugString('[ROOM TARGET] '..message) end)
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)
    if selected then transitionSlot=raw; transitionArmed=false end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
    transitionArmed=false
    local ok,guard=pcall(function()
        local g=Game();local l=g:GetLevel()
        return continued and transitionSlot==3 and g:GetNumPlayers()==1
            and Isaac.GetPlayer(0):GetPlayerType()==6 and g.Difficulty==1
            and g:GetSeeds():GetStartSeedString()=='MZ34 RR8V'
            and BossTracker:GetChainCount(6)==10
            and (BossTracker.data._twistedCycles or 0)>=1
            and l:GetStage()==13 and l:GetStageType()==1
    end)
    transitionArmed=ok and guard==true
    transitionLog('guard armed='..tostring(transitionArmed)..' slot='..tostring(transitionSlot))
end)
if ModCallbacks.MC_PRE_CHANGE_ROOM then
    TwistedRKey:AddCallback(ModCallbacks.MC_PRE_CHANGE_ROOM,function(_,target,dimension)
        if not transitionArmed then return nil end
        -- Emit exact raw destination BEFORE accessing descriptor data. Even a
        -- descriptor inspection failure leaves the requested destination logged.
        transitionLog('requested target='..tostring(target)..' dimension='..tostring(dimension))
        local ok,detail=pcall(function()
            local l=Game():GetLevel()
            local d=l:GetRoomByIdx(target,dimension) -- EXACT callback dimension
            local data=d and d.Data
            return require('json').encode({target=target,dimension=dimension,
                current=l:GetCurrentRoomIndex(),stage=l:GetStage(),stageType=l:GetStageType(),
                descriptor=d~=nil,valid=data~=nil,grid=d and d.GridIndex,
                safe=d and d.SafeGridIndex,name=data and data.Name,
                type=data and data.Type,variant=data and data.Variant,shape=data and data.Shape})
        end)
        transitionLog(ok and ('descriptor '..detail) or ('inspection-error '..tostring(detail)))
        return nil -- NEVER return the descriptor table: that would override target.
    end)
else
    transitionLog('UNSUPPORTED MC_PRE_CHANGE_ROOM; no numeric fallback registered')
end
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,function()
    transitionArmed=false
end)
