-- QA ONLY, PREPARED Oct13 04:32; live PASS Oct13 05:02 lane (native event3).
-- Append inside main.lua scope only after backing up all native/mod saves and mod.
-- Guards selected slot3. Uses a real Boss Rush room/native completion; no synthetic marks.
local rq,boot,selectedSlot=nil,0,nil
local function trace(label,a) Isaac.DebugString('[RUSH TRACE] '..label..' '..require('json').encode(a)) end
local function report(label,ok,a) Isaac.DebugString('[RUSH QA] '..require('json').encode({label=label,result=ok and 'PASS' or 'FAIL',actual=a})) end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then selectedSlot=raw;trace('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event) if rq and event==3 then rq.native=true;trace('native Boss Rush',{event=event,tick=rq.tick}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not rq then
  if selectedSlot~=3 then return end
  boot=boot+1;if boot==10 then rq={tick=0};Isaac.ExecuteCommand('restart 6') end;return
 end
 rq.tick=rq.tick+1;local t=rq.tick;local p=Isaac.GetPlayer(0);local g=Game();local room=g:GetRoom();p:SetMinDamageCooldown(30)
 if t==30 then trace('seed',{seed=g:GetSeeds():GetStartSeedString(),difficulty=g.Difficulty});Isaac.ExecuteCommand('stage 6')
 elseif t==60 then Isaac.ExecuteCommand('goto s.bossrush')
 elseif t==120 then
  rq.valid=room:GetType()==RoomType.ROOM_BOSSRUSH
  trace('room',{type=room:GetType(),valid=rq.valid})
  if not rq.valid then report('Boss Rush room fixture',false,{type=room:GetType()});rq=nil;boot=10000;return end
  -- Collecting the engine reward pedestal starts the waves; never emulate completion.
  local pickups=Isaac.FindByType(EntityType.ENTITY_PICKUP,PickupVariant.PICKUP_COLLECTIBLE,-1,false,false)
  if #pickups>0 then p.Position=pickups[1].Position;p.Velocity=Vector.Zero;trace('start pedestal',{subtype=pickups[1].SubType})
  else report('Boss Rush start fixture',false,{reason='no generated start pedestal'});rq=nil;boot=10000;return end
 elseif t>150 and t%15==0 then
  for _,e in ipairs(Isaac.GetRoomEntities())do if e:IsActiveEnemy(false)then e:TakeDamage(999999,DamageFlag.DAMAGE_IGNORE_ARMOR,EntityRef(p),0)end end
 end
 if rq and rq.native then
  report('native Boss Rush credits canonical chain',BossTracker:GetCharacterMarks(p:GetPlayerType()).boss_rush==true,{native=rq.native,marks=BossTracker:GetCharacterMarks(p:GetPlayerType()),count=BossTracker:GetChainCount(p:GetPlayerType())})
  Isaac.DebugString('[RUSH QA] DONE');rq=nil;boot=10000
 elseif rq and t==15000 then report('Boss Rush native timeout',false,{clear=room:IsClear(),marks=BossTracker:GetCharacterMarks(p:GetPlayerType())});rq=nil;boot=10000 end
end)
