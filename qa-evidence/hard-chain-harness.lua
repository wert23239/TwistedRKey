-- QA ONLY, PREPARED 05:32; NOT LIVE EXECUTED. Append inside main.lua scope.
-- Back up all native/config/mod-data/mod files first. Guard selected slot3.
-- ONE Hard Samson run; no restarts between checks, no synthetic completion calls.
-- Debug arenas/scripted damage are NOT organic combat. Lamb modal requires No.
-- Stops after ten native checks; operator must finish actual Beast-LAST/Home.
local cases={
 {mark='moms_heart',event=0,stage='8'},
 {mark='isaac_boss',event=1,stage='10a'},
 {mark='satan',event=2,stage='10'},
 {mark='boss_rush',event=3,stage='6',rush=true},
 {mark='blue_baby',event=4,stage='11a'},
 {mark='the_lamb',event=5,stage='11'},
 {mark='mega_satan',event=6,stage='11',grid=-7},
 {mark='hush',event=9,stage='9'},
 {mark='delirium',event=12,stage='12'},
 {mark='mother',event=13,stage='8c',mother=true},
}
local q,selected,boot,finished,awaitingBeast=nil,nil,0,false,false
local function trace(label,a)Isaac.DebugString('[CHAIN TRACE] '..label..' '..require('json').encode(a))end
local function report(label,ok,expected,a)Isaac.DebugString('[CHAIN QA] '..require('json').encode({label=label,result=ok and 'PASS' or 'FAIL',expected=expected,actual=a}))end
local function stop(reason)trace('STOP',{reason=reason});q=nil;finished=true end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,isSelected,raw)if isSelected then selected=raw;trace('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event)
 trace('native',{event=event,case=q and q.case,tick=q and q.tick})
 if q and event==cases[q.case].event then q.native=true end
 if awaitingBeast and event==14 then
  local p=Isaac.GetPlayer(0);local badge=(BossTracker.data._completedChains or {})[tostring(BossTracker:CanonicalType(p:GetPlayerType()))]
  report('actual Beast-LAST permanent Hard badge',BossTracker:GetChainCount(p:GetPlayerType())==11 and badge and badge.hard==true,'11 actual checks in one Hard chain, >=1 Twisted cycle, permanent Hard badge',{count=BossTracker:GetChainCount(p:GetPlayerType()),cycles=BossTracker.data._twistedCycles,badge=badge})
 end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if finished then return end
 if not q then
  if selected~=3 then return end
  boot=boot+1;if boot==10 then q={case=1,tick=0};Isaac.ExecuteCommand('restart 6')end;return
 end
 q.tick=q.tick+1;local t=q.tick;local c=cases[q.case];local g=Game();local p=Isaac.GetPlayer(0);local room=g:GetRoom();p:SetMinDamageCooldown(30)
 if t==20 then
  if q.case==1 then
   q.seed=g:GetSeeds():GetStartSeedString();q.oldBadge=(BossTracker.data._completedChains or {})['6']
   if g.Difficulty~=Difficulty.DIFFICULTY_HARD or p:GetPlayerType()~=6 or q.oldBadge then
    report('fresh isolated Hard Samson fixture',false,'Hard Samson with no preexisting badge',{difficulty=g.Difficulty,type=p:GetPlayerType(),badge=q.oldBadge});stop('invalid fixture');return
   end
  elseif g:GetSeeds():GetStartSeedString()~=q.seed then stop('seed changed: no single-chain certification');return end
 elseif t==30 then Isaac.ExecuteCommand('stage '..c.stage)
 elseif t==60 then
  if c.rush then Isaac.ExecuteCommand('goto s.bossrush')
  elseif c.grid then g:ChangeRoom(c.grid)
  else
   local level=g:GetLevel();local rooms=level:GetRooms();local target=rooms:Get(level:GetLastBossRoomListIndex())
   if c.mark=='delirium' then for i=0,rooms.Size-1 do local d=rooms:Get(i);if d.Data and string.find(string.lower(d.Data.Name or ''),'delirium')then target=d end end end
   if not target then stop('no boss room');return end;g:ChangeRoom(target.SafeGridIndex)
  end
 elseif t==90 then
  if c.mother then for i=0,room:GetGridSize()-1 do local grid=room:GetGridEntity(i);if grid and grid:GetType()==GridEntityType.GRID_TRAPDOOR then p.Position=grid.Position;p.Velocity=Vector.Zero;break end end
  elseif c.grid then p.Position=room:GetCenterPos();p.Velocity=Vector.Zero
  elseif c.rush then
   local pedestals=Isaac.FindByType(5,100,-1,false,false)
   if #pedestals==0 or room:GetType()~=RoomType.ROOM_BOSSRUSH then stop('invalid Boss Rush start');return end
   p.Position=pedestals[1].Position;p.Velocity=Vector.Zero
  end
 elseif t==170 then
  q.fixture=false
  for _,e in ipairs(Isaac.GetRoomEntities())do if e:IsActiveEnemy(false)then q.fixture=true end end
  if not q.fixture then stop('empty boss fixture: '..c.mark);return end
  p.Position=room:GetCenterPos()+Vector(0,150);p.Velocity=Vector.Zero
 elseif t>180 and t%15==0 and not q.native then
  for _,e in ipairs(Isaac.GetRoomEntities())do if e:IsActiveEnemy(false)then e:TakeDamage(999999,DamageFlag.DAMAGE_IGNORE_ARMOR,EntityRef(p),0)end end
 end
 if q.native and not q.after then q.after=t+90 end
 if q.keyCheck and q.after and t==q.after then
  local ok=g:GetLevel():GetStage()==1 and BossTracker.data._twistedCycles==1 and BossTracker:GetChainCount(p:GetPlayerType())==1
  report('actual Twisted use retains first native check',ok,'Basement1, cycle1, count1',{stage=g:GetLevel():GetStage(),cycles=BossTracker.data._twistedCycles,count=BossTracker:GetChainCount(p:GetPlayerType())})
  if not ok then stop('key reset mismatch');return end
  q.case=2;q.tick=0;q.native=nil;q.after=nil;q.keyCheck=nil;return
 end
 if q.after and t==q.after then
  local count=BossTracker:GetChainCount(p:GetPlayerType());local ok=count==q.case and BossTracker:GetCharacterMarks(p:GetPlayerType())[c.mark]==true
  report(c.mark..' native single-chain accumulation',ok,'count '..q.case..' and native event '..c.event,{count=count,marks=BossTracker:GetCharacterMarks(p:GetPlayerType()),seed=g:GetSeeds():GetStartSeedString()})
  if not ok then stop('chain accumulation mismatch');return end
  if q.case==1 then p:UseActiveItem(Isaac.GetItemIdByName('Twisted R Key'),UseFlag.USE_NOANIM);q.after=t+60;q.keyCheck=true;return end
  if q.case==#cases then
   local badge=(BossTracker.data._completedChains or {})['6']
   report('ten checks withhold Beast-LAST badge',count==10 and not badge and (BossTracker.data._twistedCycles or 0)>0,'10 checks, no badge, >=1 actual Twisted use',{count=count,badge=badge,cycles=BossTracker.data._twistedCycles})
   awaitingBeast=true;stop('TEN CHECKS: finish actual Home/Beast; menu/cold reload still require separate observation');return
  end
  q.case=q.case+1;q.tick=0;q.native=nil;q.after=nil

 end
 if t==15000 then report(c.mark..' timeout',false,'actual native event before timeout',{clear=room:IsClear(),count=BossTracker:GetChainCount(p:GetPlayerType())});stop('timeout')end
end)
