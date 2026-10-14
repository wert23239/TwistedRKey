-- QA ONLY read-only observer. Fresh isolated Hard Lazarus slot3, supported RGON.
-- No restart/warp/item grant/Die/boss damage or save edits. Operator sets fixture.
-- Register AFTER production modules. Do not infer revival from type/lives alone.
local items=require('scripts.custom_items')
local slot,armed,tick,attempts,awardFrame=nil,false,0,0,nil
local function log(label,a)Isaac.DebugString('[LAZARUS FLOOR QA] '..label..' '..require('json').encode(a))end
local function sample()
 local g=Game();local l=g:GetLevel();local p=Isaac.GetPlayer(0)
 local cur=l:GetCurrentRoomDesc();local last=l:GetRooms():Get(l:GetLastBossRoomListIndex())
 return {tick=tick,stage=l:GetStage(),stageType=l:GetStageType(),room=l:GetCurrentRoomIndex(),roomType=g:GetRoom():GetType(),current=cur and cur.SafeGridIndex,last=last and last.SafeGridIndex,lastData=last and last.Data~=nil,type=p:GetPlayerType(),dead=p:IsDead(),lives=p:GetExtraLives(),health=p:GetHearts()+p:GetSoulHearts(),item=items.ready and p:HasCollectible(items.ids.resurrection),token=items:State(p).resurrectionFloor,awards=attempts}
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 local p=Isaac.GetPlayer(0)
 armed=slot==3 and not continued and Game().Difficulty==1 and Game():GetNumPlayers()==1 and p:GetPlayerType()==PlayerType.PLAYER_LAZARUS
 tick=0;attempts=0;awardFrame=nil
 log('guard',{armed=armed,slot=slot,continued=continued,seed=Game():GetSeeds():GetStartSeedString()})
 if armed then log('start',sample())end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,function()
 if not armed then return end;attempts=attempts+1;awardFrame=tick
 log('after-production-award',sample())
 -- nil return: NEVER suppress or replace native clean award.
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,function()if armed then log('native-new-level',sample())end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_END,function(_,over)
 if armed then log('native-game-end',{over=over,state=sample()});if over then armed=false end end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not armed then return end;tick=tick+1
 if awardFrame and tick-awardFrame<=240 and (tick-awardFrame)%10==0 then log('post-award',sample())end
end)
