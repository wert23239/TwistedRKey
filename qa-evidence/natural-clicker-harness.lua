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
 nq={tick=0}; Isaac.ExecuteCommand('restart 6')
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not nq then return end
 nq.tick=nq.tick+1
 local t=nq.tick; local p=Isaac.GetPlayer(0); local g=Game(); local room=g:GetRoom()
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
 elseif t>=120 and not nq.entered then
  for i=0,room:GetGridSize()-1 do
   local grid=room:GetGridEntity(i)
   if grid and grid:GetType()==GridEntityType.GRID_TRAPDOOR then
    nq.entered=true;p.Position=grid.Position;p.Velocity=Vector.Zero
    Isaac.DebugString('[NATURAL QA] entering actual boss trapdoor index='..i)
    break
   end
  end
  if t==300 and not nq.entered then nl('trapdoor found',false,'actual boss trapdoor exists',{roomType=room:GetType(),clear=room:IsClear()});nq=nil end
 end
 if nq and nq.entered and g:GetLevel():GetStage()==2 and not nq.arrived then nq.arrived=t end
 if nq and nq.arrived then
  if t==nq.arrived+30 then
   nl('natural floor-two reset',ns().gain==0,'penalty clears on actual trapdoor transition',{before=nq.beforeFloor,after=ns()})
   p:AddHearts(12);p:ResetDamageCooldown();nq.before=ns();p:TakeDamage(1,0,EntityRef(p),0)
  elseif t==nq.arrived+45 then
   local s=ns();nl('natural floor-two hit',s.damage<nq.before.damage and s.gain>0 and s.red<nq.before.red,'red hit reduces damage on naturally entered floor two',{before=nq.before,after=s})
   Isaac.DebugString('[NATURAL QA] DONE');nq=nil
  end
 elseif nq and t==650 then nl('natural transition timeout',false,'stage2 reached',{entered=nq.entered,stage=ns().stage});nq=nil end
end)
