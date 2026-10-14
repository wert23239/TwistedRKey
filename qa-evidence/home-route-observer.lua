-- QA ONLY / NOT YET LIVE EXECUTED. Append inside main.lua scope after backup.
-- Read-only observer for operator-driven Home route; NO warps, input, damage,
-- synthetic completion, forced room changes, save writes or auto-restarts.
-- Known-crash hard-chain-finale-harness.lua must NOT be installed alongside it.
local slot, armed, tick, lastRoom = nil, false, 0, nil
local function trace(label, value)
    Isaac.DebugString('[HOME OBSERVER] '..label..' '..require('json').encode(value))
end
local function snapshot(label)
    local g = Game()
    if g:GetNumPlayers() ~= 1 then return end
    local p, level = Isaac.GetPlayer(0), g:GetLevel()
    local rooms, entities = {}, {}
    local list = level:GetRooms()
    for i = 0, list.Size - 1 do
        local d = list:Get(i)
        rooms[#rooms+1] = {index=d.SafeGridIndex, valid=d.Data~=nil,
            name=d.Data and d.Data.Name, variant=d.Data and d.Data.Variant}
    end
    for _, e in ipairs(Isaac.GetRoomEntities()) do
        if e.Type==950 or e.Type==951 or e.Type==960 or (e.Type==5 and e.Variant==380) then
            local sprite=e:GetSprite()
            entities[#entities+1]={type=e.Type,variant=e.Variant,subtype=e.SubType,
                hp=e.HitPoints,x=e.Position.X,y=e.Position.Y,
                animation=sprite:GetAnimation(),frame=sprite:GetFrame()}
        end
    end
    trace(label,{tick=tick,stage=level:GetStage(),stageType=level:GetStageType(),
        room=level:GetCurrentRoomIndex(),seed=g:GetSeeds():GetStartSeedString(),
        count=BossTracker:GetChainCount(6),cycles=BossTracker.data._twistedCycles,
        badge=(BossTracker.data._completedChains or {})['6'],rooms=rooms,entities=entities})
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)
    if selected then slot=raw; armed=false; trace('selected slot',{slot=slot}) end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
    tick,lastRoom=0,nil
    local g=Game()
    armed=continued and slot==3 and g:GetNumPlayers()==1
        and Isaac.GetPlayer(0):GetPlayerType()==6 and g.Difficulty==1
        and g:GetSeeds():GetStartSeedString()=='MZ34 RR8V'
        and BossTracker:GetChainCount(6)==10
        and (BossTracker.data._twistedCycles or 0)>=1
    trace('guard',{armed=armed,slot=slot,continued=continued})
    if armed then snapshot('continued ten-check chain') end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
    if not armed then return end
    tick=tick+1
    local index=Game():GetLevel():GetCurrentRoomIndex()
    if index~=lastRoom or tick%120==0 then snapshot('route observation');lastRoom=index end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event)
    if armed then snapshot('native completion '..tostring(event)) end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,function(_,save)
    if armed then snapshot('exit save='..tostring(save)) end
    armed=false
end)
