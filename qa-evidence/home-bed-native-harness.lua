-- QA ONLY: generated Home entry, then native door/bed movement; STOP before TV.
-- No ChangeRoom, forced arena, enemy damage, synthetic marks, or bed timer bypass.
local selected, armed, tick, routeStep, target, bedAt, stopped = nil,false,0,1,nil,nil,false
local path={97,109,108,82}
local function log(label,a) Isaac.DebugString('[HOME BED QA] '..label..' '..require('json').encode(a)) end
local function stop(reason) stopped=true;target=nil;log('STOP',{reason=reason,tick=tick}) end
local function state()
 local g=Game();local l=g:GetLevel();local r=g:GetRoom();local p=Isaac.GetPlayer(0);local doors,beds={},{}
 for i=0,7 do local d=r:GetDoor(i);if d then doors[#doors+1]={slot=i,target=d.TargetRoomIndex,open=d:IsOpen(),x=d.Position.X,y=d.Position.Y}end end
 for _,e in ipairs(Isaac.FindByType(5,380,-1,false,false))do beds[#beds+1]={subtype=e.SubType,animation=e:GetSprite():GetAnimation(),frame=e:GetSprite():GetFrame(),x=e.Position.X,y=e.Position.Y}end
 return {tick=tick,room=l:GetCurrentRoomIndex(),stage=l:GetStage(),doors=doors,beds=beds,px=p.Position.X,py=p.Position.Y,panim=p:GetSprite():GetAnimation(),pframe=p:GetSprite():GetFrame(),controls=p.ControlsEnabled,count=BossTracker:GetChainCount(6),cycles=BossTracker.data._twistedCycles}
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,yes,raw)if yes then selected=raw;log('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 local g=Game();local p=Isaac.GetPlayer(0)
 armed=continued and selected==3 and p:GetPlayerType()==6 and g.Difficulty==1 and g:GetSeeds():GetStartSeedString()=='MZ34 RR8V' and BossTracker:GetChainCount(6)==10 and (BossTracker.data._twistedCycles or 0)>=1
 log('guard',{armed=armed,continued=continued,slot=selected,seed=g:GetSeeds():GetStartSeedString()})
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,function()if armed then log('native room',state())end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not armed or stopped then return end
 tick=tick+1
 if tick==30 and Game():GetLevel():GetStage()~=13 then Isaac.ExecuteCommand('stage 13');return end
 if tick<90 then return end
 if tick%120==0 then log('progress',state())end
 if Game():GetLevel():GetStage()~=13 then stop('Home generation absent');return end
 local idx=Game():GetLevel():GetCurrentRoomIndex()
 if idx==82 then
  if not bedAt then
   local bed=Isaac.FindByType(5,380,10,false,false)[1]
   if not bed then stop('Mom bed subtype10 absent');return end
   target=bed.Position;bedAt=tick;log('bed approach',state())
  end
  if tick-bedAt>600 then stop('bed observation completed; NO TV entry');log('bed final',state())end
 else
  if idx==path[routeStep] then routeStep=routeStep+1;target=nil;log('native door arrived',state())end
  local nextIndex=path[routeStep]
  local door=nil
  for i=0,7 do local d=Game():GetRoom():GetDoor(i);if d and d.TargetRoomIndex==nextIndex then door=d;break end end
  if not door or not door:IsOpen() then stop('expected native open door absent to '..tostring(nextIndex));log('door blockage',state());return end
  local center=Game():GetRoom():GetCenterPos();target=door.Position+(door.Position-center):Resized(45)
 end
 if tick>1800 then stop('native route timeout')end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE,function(_,p)
 if armed and not stopped and target and p.ControlsEnabled then local delta=target-p.Position;p.Velocity=delta:Length()>4 and delta:Resized(4) or Vector.Zero end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,function(_,save)if armed then log('exit',{save=save,state=state()})end;armed=false end)
