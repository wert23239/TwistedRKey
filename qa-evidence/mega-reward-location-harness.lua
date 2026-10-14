-- QA ONLY: reproduce earlier SSP6 AGB0 missing-pedestal result.
-- Actual native Mega events; center vs away. Count BOTH inventory and pedestal.
local qa,slot,boot,done=nil,nil,0,false
local function trace(label,a) Isaac.DebugString('[MEGA LOCATION] '..label..' '..require('json').encode(a)) end
local function report(label,ok,expected,a) trace('ASSERT',{label=label,result=ok and 'PASS' or 'FAIL',expected=expected,actual=a}) end
local function inventory(p)
 local id=Isaac.GetItemIdByName('Twisted R Key'); local slots={}
 for s=0,3 do slots[tostring(s)]=p:GetActiveItem(s) end
 return {owned=p:GetCollectibleNum(id,true),pedestals=#Isaac.FindByType(5,100,id,false,false),slots=slots,id=id}
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then slot=raw;trace('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued) trace('start',{continued=continued,seed=Game():GetSeeds():GetStartSeedString(),type=Isaac.GetPlayer(0):GetPlayerType(),difficulty=Game().Difficulty}) end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,function() if qa then trace('clean award',{trial=qa.trial,tick=qa.tick,inventory=inventory(Isaac.GetPlayer(0)),position={x=Isaac.GetPlayer(0).Position.X,y=Isaac.GetPlayer(0).Position.Y}}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event) if qa then qa.native=event==6 or qa.native;trace('native',{event=event,trial=qa.trial,tick=qa.tick}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT,function(_,p) if qa and p.Variant==100 then trace('pickup init',{trial=qa.trial,tick=qa.tick,subtype=p.SubType,x=p.Position.X,y=p.Position.Y}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done then return end
 if not qa then if slot~=3 then return end;boot=boot+1;if boot==10 then qa={trial=1,tick=-30};Isaac.ExecuteCommand('restart 6') end;return end
 qa.tick=qa.tick+1;local t=qa.tick;local g=Game();local p=Isaac.GetPlayer(0);local room=g:GetRoom();p:SetMinDamageCooldown(30)
 if t==0 then Isaac.ExecuteCommand('seed SSP6 AGB0')
 elseif t==30 then
  if p:GetPlayerType()~=6 or g.Difficulty~=1 or g:GetSeeds():GetStartSeedString()~='SSP6 AGB0' then report('fixed seed fixture',false,'Hard Samson SSP6 AGB0',{type=p:GetPlayerType(),difficulty=g.Difficulty,seed=g:GetSeeds():GetStartSeedString()});done=true;return end
  trace('fixed seed fixture',{trial=qa.trial,seed=g:GetSeeds():GetStartSeedString(),inventory=inventory(p)})
  Isaac.ExecuteCommand('stage 11')
 elseif t==60 then g:ChangeRoom(-7)
 elseif t==75 then p.Position=room:GetCenterPos();p.Velocity=Vector.Zero
 elseif t==160 then
  local bosses={};for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then bosses[#bosses+1]={type=e.Type,variant=e.Variant} end end
  qa.valid=#bosses>0;trace('fixture',{trial=qa.trial,bosses=bosses})
  if qa.trial==2 then p.Position=room:GetCenterPos()+Vector(0,150);p.Velocity=Vector.Zero end
 elseif t>=180 and t<=1780 and t%15==0 then for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:TakeDamage(999999,DamageFlag.DAMAGE_IGNORE_ARMOR,EntityRef(p),0) end end
 end
 if qa.native and t%60==0 then trace('post native inventory',{trial=qa.trial,tick=t,inventory=inventory(p)}) end
 if t==1810 then
  local inv=inventory(p);inv.seed=g:GetSeeds():GetStartSeedString();inv.clear=room:IsClear();inv.native=qa.native;inv.mega=BossTracker:GetCharacterMarks(6).mega_satan
  report('Mega reward '..(qa.trial==1 and 'center' or 'away'),qa.valid and inv.clear and inv.native and inv.owned+inv.pedestals==1,'exactly one key in inventory OR on pedestal',inv)
  report('native Mega '..qa.trial,qa.native and inv.mega==true,'real event6 credits Mega',inv)
  if qa.trial==1 then qa={trial=2,tick=-30};Isaac.ExecuteCommand('restart 6') else done=true;trace('DONE',{reason='two controlled placements, no synthetic marks'}) end
 end
 if t>2200 then done=true;trace('STOP',{reason='timeout'}) end
end)
