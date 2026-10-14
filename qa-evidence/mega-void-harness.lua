-- QA ONLY. Generated Mega arena/scripted damage, actual generated Void trap entry.
local vq,boot,selectedSlot=nil,0,nil
local function report(label,pass,actual) Isaac.DebugString('[VOID QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',actual=actual})) end
local function trace(label,actual) Isaac.DebugString('[VOID TRACE] '..label..' '..require('json').encode(actual)) end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,slot,selected,raw) if selected then selectedSlot=raw;trace('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,function() if vq then trace('clean-award',{tick=vq.tick,trial=vq.trial,stage=Game():GetLevel():GetStage(),grid=Game():GetLevel():GetCurrentRoomIndex()}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event) if vq then trace('completion',{tick=vq.tick,trial=vq.trial,event=event}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not vq then if selectedSlot~=3 then return end;boot=boot+1;if boot==10 then vq={tick=0,trial=1,phase='mega'};Isaac.ExecuteCommand('restart 6') end;return end
 vq.tick=vq.tick+1;local t=vq.tick;local g=Game();local p=Isaac.GetPlayer(0);local room=g:GetRoom();p:SetMinDamageCooldown(30)
 if vq.phase=='mega' then
  if t==30 then trace('seed',{trial=vq.trial,seed=g:GetSeeds():GetStartSeedString()});p:AddHearts(24);Isaac.ExecuteCommand('stage 11')
  elseif t==60 then g:ChangeRoom(-7)
  elseif t==75 then p.Position=room:GetCenterPos();p.Velocity=Vector.Zero
  elseif t==160 then p.Position=room:GetCenterPos()+Vector(0,150);p.Velocity=Vector.Zero;local bosses={};for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then table.insert(bosses,{type=e.Type,variant=e.Variant}) end end;vq.valid=#bosses>0;trace('fixture',{bosses=bosses,trial=vq.trial})
  elseif t>=180 and t<=1780 and t%15==0 then for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:TakeDamage(999999,DamageFlag.DAMAGE_IGNORE_ARMOR,EntityRef(p),0) end end
  elseif t==1810 then
   local keys=#Isaac.FindByType(5,100,Isaac.GetItemIdByName('Twisted R Key'),false,false)
   report('Mega reward trial '..vq.trial,vq.valid and room:IsClear() and keys==1,{keys=keys,clear=room:IsClear(),valid=vq.valid,seed=g:GetSeeds():GetStartSeedString()})
   report('Mega native trial '..vq.trial,vq.valid and BossTracker:GetCharacterMarks(p:GetPlayerType()).mega_satan==true,{marks=BossTracker:GetCharacterMarks(p:GetPlayerType())})
   for i=0,room:GetGridSize()-1 do local grid=room:GetGridEntity(i);if grid and grid:GetType()==GridEntityType.GRID_TRAPDOOR and string.find(grid:GetSprite():GetFilename(),'Void') then vq.portal=i;trace('generated portal',{index=i,state=grid.State,sprite=grid:GetSprite():GetFilename()});break end end
   if vq.portal then vq.phase='enter';vq.tick=0
   elseif vq.trial<3 then vq.trial=vq.trial+1;vq.tick=0;Isaac.ExecuteCommand('restart 6')
   else report('generated Void portal fixture',false,{reason='No generated Void portal across three trials; entry NOT tested'});Isaac.DebugString('[VOID QA] DONE');vq=nil;boot=10000 end
  end
 elseif vq.phase=='enter' then
  if t==30 then local grid=room:GetGridEntity(vq.portal);p.Position=grid.Position;p.Velocity=Vector.Zero end
  if g:GetLevel():GetStage()==LevelStage.STAGE7 then
   report('actual generated Void entry',true,{stage=g:GetLevel():GetStage(),marks=BossTracker:GetCharacterMarks(p:GetPlayerType())});vq.phase='key';vq.tick=0
  elseif t==900 then local grid=room:GetGridEntity(vq.portal);report('actual generated Void entry',false,{stage=g:GetLevel():GetStage(),state=grid and grid.State,distance=grid and p.Position:Distance(grid.Position)});Isaac.DebugString('[VOID QA] DONE');vq=nil;boot=10000 end
 elseif vq.phase=='key' then
  if t==90 then p:UseActiveItem(Isaac.GetItemIdByName('Twisted R Key'),UseFlag.USE_NOANIM)
  elseif t==150 then report('key after Void entry preserves Mega chain',g:GetLevel():GetStage()==1 and BossTracker.data._twistedCycles==1 and BossTracker:GetCharacterMarks(p:GetPlayerType()).mega_satan==true,{stage=g:GetLevel():GetStage(),cycles=BossTracker.data._twistedCycles,marks=BossTracker:GetCharacterMarks(p:GetPlayerType())});Isaac.DebugString('[VOID QA] DONE');vq=nil;boot=10000 end
 end
end)
