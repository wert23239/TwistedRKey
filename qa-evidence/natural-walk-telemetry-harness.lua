-- QA ONLY, not release.
local nq
local function ns()
 local p=Isaac.GetPlayer(0)
 return {stage=Game():GetLevel():GetStage(),damage=p.Damage,red=p:GetHearts(),gain=CustomItems:State(p).needleGain or 0,counter=p:GetBloodLustCounter(),kind=p:GetPlayerType()}
end
local function nl(label,pass,expected,actual)
 Isaac.DebugString('[NATURAL QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',expected=expected,actual=actual or ns()}))
end
function TRKNaturalQA()
 nq={tick=0,target=2}; Isaac.ExecuteCommand('restart 6')
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not nq then return end
 nq.tick=nq.tick+1
 local t=nq.tick; local p=Isaac.GetPlayer(0); local g=Game(); local room=g:GetRoom()
 if t>=90 and t%15==0 and not nq.entered and not nq.resetAt then for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:Kill() end end end
 if t==30 then
  p:AddHearts(12);p:ResetDamageCooldown();nq.before=ns();p:TakeDamage(1,0,EntityRef(p),0)
 elseif t==45 then
  nl('pre-trapdoor hit',p.Damage<nq.before.damage,'damage decreases on floor one',{before=nq.before,after=ns()})
  local misses=0;local pool=g:GetItemPool()
  for typ=0,5 do for seed=1,500 do if pool:GetCollectible(typ,false,seed)==CollectibleType.COLLECTIBLE_CLICKER then misses=misses+1 end end end
  nl('Clicker pool samples',misses==0,'zero Clicker in 3000 seeded draws across pools 0-5',{draws=3000,clicker=misses})
  nq.ped=Isaac.Spawn(5,100,25,p.Position+Vector(100,0),Vector.Zero,nil):ToPickup()
  -- Simulate a late pedestal mutation (reroll/other-mod route), not initial spawn.
  nq.ped:Morph(5,100,CollectibleType.COLLECTIBLE_CLICKER,true,true,false)
 elseif t==60 then
  nl('Clicker late pedestal mutation',nq.ped:Exists() and nq.ped.SubType==25,'late Clicker mutation replaced by Breakfast',{subtype=nq.ped.SubType})
  nq.ped:Remove()
  nq.beforeFloor=ns();g:ChangeRoom(g:GetLevel():GetRooms():Get(g:GetLevel():GetLastBossRoomListIndex()).SafeGridIndex)
 elseif t==90 then
  local killed=0
  for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:Kill();killed=killed+1 end end
  Isaac.DebugString('[NATURAL QA] killed boss entities='..killed)
 elseif t>=120 and not nq.entered and not nq.resetAt then
  for i=0,room:GetGridSize()-1 do
   local grid=room:GetGridEntity(i)
   if grid and grid:GetType()==GridEntityType.GRID_TRAPDOOR then
    nq.entered=true;nq.enterTick=t;nq.trap=grid.Position;p.Position=grid.Position+Vector(0,45);p.Velocity=Vector.Zero
    Isaac.DebugString('[NATURAL QA] entering actual boss trapdoor index='..i)
    break
   end
  end
  if t==300 and not nq.entered then nl('trapdoor found',false,'actual boss trapdoor exists',{roomType=room:GetType(),clear=room:IsClear()});nq=nil end
 end
 if nq and nq.entered and not nq.arrived and g:GetLevel():GetStage()~=nq.target then
  local grid=room:GetGridEntity(room:GetGridIndex(nq.trap))
  if (t-nq.enterTick)%30==0 then Isaac.DebugString('[TRAP TELEMETRY] '..require('json').encode({tick=t,stage=ns().stage,clear=room:IsClear(),state=grid and grid.State,anim=grid and grid:GetSprite():GetAnimation(),frame=grid and grid:GetSprite():GetFrame(),playerAnim=p:GetSprite():GetAnimation(),controls=p.ControlsEnabled,position={p.Position.X,p.Position.Y},distance=p.Position:Distance(nq.trap)})) end
  if t-nq.enterTick>60 and p.ControlsEnabled then
   if p.Position:Distance(nq.trap)>5 then p.Velocity=(nq.trap-p.Position):Resized(3) else p.Velocity=Vector.Zero end
  end
 end
 if nq and nq.resetAt and t==nq.resetAt then
  nq.resets=nq.resets+1
  nq.cycle=BossTracker.data._twistedCycles or 0
  if nq.resets==1 then p:AddCollectible(CollectibleType.COLLECTIBLE_PENTAGRAM,0,false) end
  p:UseActiveItem(Isaac.GetItemIdByName('Twisted R Key'),0,-1)
 elseif nq and nq.resetAt and t==nq.resetAt+40 then
  local id=tostring(CollectibleType.COLLECTIBLE_PENTAGRAM)
  local misses=0;local pool=g:GetItemPool()
  for typ=0,5 do for seed=1,500 do local c=pool:GetCollectible(typ,false,seed);if c==CollectibleType.COLLECTIBLE_CLICKER or c==CollectibleType.COLLECTIBLE_PENTAGRAM then misses=misses+1 end end end
  nl('reset '..nq.resets..' retains spent exclusion',BossTracker.data._spentItems[id]==true and not p:HasCollectible(CollectibleType.COLLECTIBLE_PENTAGRAM) and misses==0 and (BossTracker.data._twistedCycles or 0)==nq.cycle+1,'Pentagram spent, stripped; no Pentagram/Clicker in3000 draws; cycle increments',{spent=BossTracker.data._spentItems[id],held=p:HasCollectible(CollectibleType.COLLECTIBLE_PENTAGRAM),bannedDraws=misses,cycle=BossTracker.data._twistedCycles,stage=ns().stage})
  p:AddHearts(12);p:ResetDamageCooldown();nq.before=ns();p:TakeDamage(1,0,EntityRef(p),0)
 elseif nq and nq.resetAt and t==nq.resetAt+55 then
  nl('reset '..nq.resets..' Needle hit',p.Damage<nq.before.damage and ns().gain>0,'post-key red hit reduces damage',{before=nq.before,after=ns()})
  if nq.resets==1 then nq.resetAt=t+30 else Isaac.DebugString('[NATURAL QA] DONE');nq=nil;return end
 end
 if nq and nq.entered and g:GetLevel():GetStage()==nq.target and not nq.arrived then nq.arrived=t end
 if nq and nq.arrived then
  if t==nq.arrived+30 then
   nl('natural floor-'..nq.target..' reset',ns().gain==0,'penalty clears on actual trapdoor transition',{before=nq.beforeFloor,after=ns()})
   p:AddHearts(12);p:ResetDamageCooldown();nq.before=ns();p:TakeDamage(1,0,EntityRef(p),0)
  elseif t==nq.arrived+45 then
   local s=ns();nl('natural floor-'..nq.target..' hit',s.damage<nq.before.damage and s.gain>0 and s.red<nq.before.red,'red hit reduces damage on naturally entered floor '..nq.target,{before=nq.before,after=s})
   if nq.target==2 then
    nq.target=3;nq.arrived=nil;nq.entered=nil;nq.beforeFloor=ns()
    g:ChangeRoom(g:GetLevel():GetRooms():Get(g:GetLevel():GetLastBossRoomListIndex()).SafeGridIndex)
    nq.killAt=t+30
   else
    nq.resetAt=t+30;nq.arrived=nil;nq.entered=nil;nq.resets=0
   end
  end
 elseif nq and t==1600 then nl('natural transition timeout',false,'stage2 reached',{entered=nq.entered,stage=ns().stage});nq=nil end
end)

local qaBooted=false; local qaDelay=0; TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function() if not qaBooted then qaDelay=qaDelay+1; if qaDelay==10 then qaBooted=true; TRKNaturalQA() end end end)
