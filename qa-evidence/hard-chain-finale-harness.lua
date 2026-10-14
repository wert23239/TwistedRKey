-- KNOWN QA REPRODUCER: debug Home/Dogma path crashed RoomTransition::change_room.
-- DO NOT auto-deploy as a successful finale fixture; native Beast/badge NOT verified.
-- QA only: continue the actual ten-check MZ34 RR8V Hard Samson chain.
-- Never synthesize a completion event or a mark; actual engine damage only.
local tick,ready=0,false
local function tr(label,a)Isaac.DebugString('[FINALE TRACE] '..label..' '..require('json').encode(a))end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 local p=Isaac.GetPlayer(0);local count=BossTracker:GetChainCount(p:GetPlayerType())
 ready=continued and p:GetPlayerType()==6 and Game().Difficulty==1 and count==10 and Game():GetSeeds():GetStartSeedString()=='MZ34 RR8V'
 tr('cold ten-check Continue',{ready=ready,continued=continued,count=count,seed=Game():GetSeeds():GetStartSeedString(),cycles=BossTracker.data._twistedCycles})
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event)
 tr('actual native finale',{event=event,count=BossTracker:GetChainCount(6),badge=(BossTracker.data._completedChains or {})['6']})
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not ready then return end
 tick=tick+1;local g=Game();local p=Isaac.GetPlayer(0);p:SetMinDamageCooldown(30)
 if tick==30 and g:GetLevel():GetStage()~=13 then Isaac.ExecuteCommand('stage 13')end
 if tick==80 then
  local level=g:GetLevel();local rooms=level:GetRooms();local a={}
  for i=0,rooms.Size-1 do local d=rooms:Get(i);if d.Data then a[#a+1]={index=d.SafeGridIndex,name=d.Data.Name,type=d.Data.Type,variant=d.Data.Variant}end end
  tr('generated Home',{stage=level:GetStage(),type=level:GetStageType(),count=BossTracker:GetChainCount(6),rooms=a})
 end
 if tick==110 then g:ChangeRoom(82)end
 if tick==160 then
  for _,e in ipairs(Isaac.FindByType(5,380,-1,false,false))do p.Position=e.Position;p.Velocity=Vector.Zero;tr("Mom bed entry",{subtype=e.SubType,x=e.Position.X,y=e.Position.Y});break end
 end
 if tick==450 then g:ChangeRoom(109)end
 if tick==520 then p.Position=Vector(320,200);p.Velocity=Vector.Zero end
 if tick>1400 and tick%30==0 then
  for _,e in ipairs(Isaac.GetRoomEntities())do if (e.Type==950 or e.Type==951) and e:IsActiveEnemy(false)then e:TakeDamage(999999,0,EntityRef(p),0)end end
 end
 if tick==650 or tick==1000 or tick==2000 then
  local a={};for _,e in ipairs(Isaac.GetRoomEntities())do a[#a+1]={type=e.Type,variant=e.Variant,subtype=e.SubType,x=e.Position.X,y=e.Position.Y}end
  tr("Home/fight progression",{tick=tick,stage=g:GetLevel():GetStage(),room=g:GetLevel():GetCurrentRoomIndex(),entities=a})
 end
 if tick==100 then
  local a={};for _,e in ipairs(Isaac.GetRoomEntities())do a[#a+1]={type=e.Type,variant=e.Variant,subtype=e.SubType,x=e.Position.X,y=e.Position.Y}end
  tr('Home entities',{room=g:GetRoom():GetRoomShape(),entities=a})
 end
end)
