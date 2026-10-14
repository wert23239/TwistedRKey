-- QA ONLY: new floor3 acceptance, no replay of prior pool/reset checks.
local q,selectedSlot
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then selectedSlot=raw;Isaac.DebugString("[NATURAL3 QA] selected slot="..raw) end end)
local function snap()
 local p=Isaac.GetPlayer(0)
 return {stage=Game():GetLevel():GetStage(),damage=p.Damage,red=p:GetHearts(),gain=CustomItems:State(p).needleGain or 0,seed=Game():GetSeeds():GetStartSeedString(),kind=p:GetPlayerType()}
end
local function log(label,pass,a)
 Isaac.DebugString('[NATURAL3 QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',actual=a}))
end
function TRKNaturalThree()
 if selectedSlot~=3 then error('QA requires slot3') end
 if Isaac.GetPlayer(0):GetPlayerType()~=6 then error('QA requires Samson') end
 q={t=0};Isaac.ExecuteCommand('stage 2')
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not q then return end
 q.t=q.t+1;local t=q.t;local g=Game();local p=Isaac.GetPlayer(0);local room=g:GetRoom()
 if t==30 then
  if g:GetLevel():GetStage()~=2 then log('fixture floor2',false,snap());q=nil;return end
  p:AddHearts(12);p:ResetDamageCooldown();q.before=snap();p:TakeDamage(1,0,EntityRef(p),0)
 elseif t==45 then
  q.penalty=snap()
  -- Prerequisite only; prior floor2 coverage stands separately.
  if q.penalty.gain<=0 then log('fixture penalty prerequisite',false,snap());q=nil;return end
  local d=g:GetLevel():GetRooms():Get(g:GetLevel():GetLastBossRoomListIndex())
  if not d or not d.Data then log('fixture boss descriptor',false,snap());q=nil;return end
  g:ChangeRoom(d.SafeGridIndex)
 end
 if t>=75 and not q.arrived and g:GetLevel():GetStage()==2 then
  for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:Kill() end end
  if not q.trap then
   for i=0,room:GetGridSize()-1 do local grid=room:GetGridEntity(i)
    if grid and grid:GetType()==GridEntityType.GRID_TRAPDOOR then
     q.trap=grid.Position;q.entry=t;p.Position=q.trap+Vector(0,45);p.Velocity=Vector.Zero
     Isaac.DebugString('[NATURAL3 QA] actual trapdoor located; waiting for native transition')
     break
    end
   end
  elseif t-q.entry>60 and p.ControlsEnabled then
   local dist=p.Position:Distance(q.trap)
   p.Velocity=dist>5 and (q.trap-p.Position):Resized(3) or Vector.Zero
  end
  if t%60==0 then Isaac.DebugString('[NATURAL3 QA] telemetry '..require('json').encode({tick=t,stage=g:GetLevel():GetStage(),playerAnim=p:GetSprite():GetAnimation(),controls=p.ControlsEnabled,clear=room:IsClear(),trap=q.trap and {q.trap.X,q.trap.Y},pos={p.Position.X,p.Position.Y}})) end
 end
 if q.trap and g:GetLevel():GetStage()==3 and not q.arrived then q.arrived=t end
 if q.arrived then
  if t==q.arrived+30 then
   local s=snap();log('natural floor3 clears penalty',s.gain==0,{before=q.penalty,after=s})
   p:AddHearts(12);p:ResetDamageCooldown();q.before=snap();p:TakeDamage(1,0,EntityRef(p),0)
  elseif t==q.arrived+45 then
   local s=snap();log('natural floor3 hit',s.damage<q.before.damage and s.gain>0 and s.red<q.before.red,{before=q.before,after=s})
   p:AddHearts(12);q.healed=snap();p:ResetDamageCooldown();p:TakeDamage(1,0,EntityRef(p),0)
  elseif t==q.arrived+60 then
   local s=snap();log('natural floor3 healed hit',s.damage<q.healed.damage and s.gain>q.healed.gain,{before=q.healed,after=s})
   Isaac.DebugString('[NATURAL3 QA] DONE');q=nil
  end
 elseif t>=1800 then log('natural floor3 timeout',false,snap());q=nil end
end)
