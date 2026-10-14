-- QA ONLY: generated Mausoleum II then native Dad's Note collision.
-- No forced rooms, arena, flags, synthetic marks, enemy damage or stage13.
local slot,armed,tick=nil,false,0
local function log(label,a) Isaac.DebugString('[ASCENT QA] '..label..' '..require('json').encode(a)) end
local function state()
 local g=Game();local l=g:GetLevel();local r=g:GetRoom();local p=Isaac.GetPlayer(0);local doors,exits={},{}
 for i=0,7 do local d=r:GetDoor(i);if d then doors[#doors+1]={slot=i,target=d.TargetRoomIndex,open=d:IsOpen(),x=d.Position.X,y=d.Position.Y}end end
 for i=0,r:GetGridSize()-1 do local e=r:GetGridEntity(i);if e and (e:GetType()==17 or e:GetType()==18) then exits[#exits+1]={type=e:GetType(),x=e.Position.X,y=e.Position.Y,state=e.State}end end
 return {tick=tick,stage=l:GetStage(),stageType=l:GetStageType(),room=l:GetCurrentRoomIndex(),roomType=r:GetType(),doors=doors,exits=exits,px=p.Position.X,py=p.Position.Y,anim=p:GetSprite():GetAnimation(),controls=p.ControlsEnabled,note=p:HasCollectible(668),count=BossTracker:GetChainCount(6),cycles=BossTracker.data._twistedCycles}
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,yes,raw)if yes then slot=raw;log('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 local g=Game();local p=Isaac.GetPlayer(0)
 armed=continued and slot==3 and p:GetPlayerType()==6 and g.Difficulty==1 and g:GetSeeds():GetStartSeedString()=='MZ34 RR8V' and BossTracker:GetChainCount(6)==10
 log('guard',{armed=armed,continued=continued,slot=slot,seed=g:GetSeeds():GetStartSeedString()})
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,function()if armed then log('native room',state())end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,function()if armed then log('native level',state())end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not armed then return end
 tick=tick+1
 if tick==30 and not (Game():GetLevel():GetStage()==6 and Game():GetLevel():GetStageType()==4) then Isaac.ExecuteCommand('stage 6c');return end
 if tick==100 then
  local c=Isaac.GetItemConfig():GetCollectible(668)
  if not c or (c.Name~="Dad's Note" and c.Name~="#DADS_NOTE_NAME") or Game():GetLevel():GetStage()~=6 then log('STOP',{reason='invalid Note/Mausoleum fixture',name=c and c.Name});armed=false;return end
  local p=Isaac.GetPlayer(0);local pos=Game():GetRoom():FindFreePickupSpawnPosition(p.Position+Vector(60,0),0,true)
  local note=Isaac.Spawn(5,100,668,pos,Vector.Zero,nil)
  log('native Note spawned',state());p.Position=note.Position;p.Velocity=Vector.Zero
 end
 if tick%120==0 then log('progress',state())end
 if tick==1800 then log('STOP',{reason='observation limit; no finale mutation'});armed=false end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,function(_,save)if armed then log('exit',{save=save,state=state()})end;armed=false end)
