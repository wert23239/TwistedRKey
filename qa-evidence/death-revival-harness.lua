-- QA ONLY; append inside main.lua locals on backed-up installation. Live executed Oct13 03:32 lane: 3 PASS.
-- Real native Heart completion -> 1up revival -> terminal death. Never synthesize marks.
local dq,boot,selectedSlot=nil,0,nil
local function report(label,pass,actual)
 Isaac.DebugString('[DEATH QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',actual=actual}))
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,slot,selected,raw)
 if selected then selectedSlot=raw;Isaac.DebugString('[DEATH SLOT] '..tostring(raw)) end
end)
-- Registered after production tracker; inspect cleared marks only after its callback.
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_END,function(_,over)
 if not dq then return end
 if over then
  report('terminal death clears living chain',dq.revivalPassed and next(BossTracker:GetCharacterMarks(dq.character))==nil,
   {revivalPassed=dq.revivalPassed,marks=BossTracker:GetCharacterMarks(dq.character),phase=dq.phase})
  Isaac.DebugString('[DEATH QA] DONE');dq=nil;boot=10000
 else Isaac.DebugString('[DEATH END] non-terminal') end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not dq then
  if selectedSlot~=3 then return end
  boot=boot+1;if boot==10 then dq={tick=0,phase='heart'};Isaac.ExecuteCommand('restart 6') end;return
 end
 dq.tick=dq.tick+1;local t=dq.tick;local p=Isaac.GetPlayer(0);local g=Game()
 if dq.phase=='heart' then
  p:SetMinDamageCooldown(30)
  if t==30 then dq.character=p:GetPlayerType();Isaac.ExecuteCommand('stage 8')
  elseif t==60 then local d=g:GetLevel():GetRooms():Get(g:GetLevel():GetLastBossRoomListIndex());g:ChangeRoom(d.SafeGridIndex)
  elseif t>=100 and t<=580 and t%15==0 then
   for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:TakeDamage(999999,DamageFlag.DAMAGE_IGNORE_ARMOR,EntityRef(p),0) end end
  elseif t==610 then
   local marked=BossTracker:GetCharacterMarks(dq.character).moms_heart==true
   report('native Heart prerequisite',marked,{marks=BossTracker:GetCharacterMarks(dq.character)})
   if not marked then Isaac.DebugString('[DEATH QA] STOP invalid prerequisite');dq=nil;boot=10000;return end
   Isaac.ExecuteCommand('stage 1');dq.phase='revival';dq.tick=0
  end
 elseif dq.phase=='revival' then
  if t==30 then p:AddCollectible(CollectibleType.COLLECTIBLE_1UP,0,false);dq.before=p:GetExtraLives();p:Die()
  elseif t>60 and not p:IsDead() and p:GetExtraLives()<dq.before then
   dq.revivalPassed=BossTracker:GetCharacterMarks(dq.character).moms_heart==true
   report('1up revival retains living chain',dq.revivalPassed,{type=p:GetPlayerType(),livesBefore=dq.before,livesAfter=p:GetExtraLives(),marks=BossTracker:GetCharacterMarks(dq.character)})
   dq.phase='terminal';dq.tick=0
  elseif t==900 then report('revival fixture timeout',false,{dead=p:IsDead(),extraLives=p:GetExtraLives()});dq=nil;boot=10000 end
 elseif dq.phase=='terminal' and t==60 then
  if p:GetExtraLives()~=0 then report('terminal fixture no extra lives',false,{extraLives=p:GetExtraLives()});dq=nil;boot=10000;return end
  p:Die()
 end
end)
