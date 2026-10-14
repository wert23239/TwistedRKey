-- QA ONLY: real generated late-boss arenas, scripted kills. Never ship.
-- 06:32 correction: reward may be immediately collected; inventory + pedestal oracle.
-- Earlier archived logs remain unchanged; no retroactive pass assertion.
local matrix={{name='Mother',stage='8c',mark='mother'},{name='Delirium',stage='12',mark='delirium'},{name='Mega Satan',stage='11',mark='mega_satan',grid=-7}}
-- Revision: Mother's actual entrance trap, native Mega room -7; damage not Entity:Kill().
local rq,boot=nil,0
local function out(label,pass,expected,actual) Isaac.DebugString('[LATE QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',expected=expected,actual=actual})) end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,slot,selected,raw) Isaac.DebugString('[LATE SLOT] '..tostring(slot)..' selected='..tostring(selected)..' raw='..tostring(raw)) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event) Isaac.DebugString('[LATE EVENT] '..tostring(event)) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_END,function(_,over) Isaac.DebugString('[LATE END] gameover='..tostring(over)) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not rq then boot=boot+1;if boot==10 then rq={tick=0,case=1};Isaac.ExecuteCommand('restart 6') end;return end
 rq.tick=rq.tick+1;local t=rq.tick;local c=matrix[rq.case];local g=Game();local p=Isaac.GetPlayer(0);local room=g:GetRoom();p:SetMinDamageCooldown(30)
 if t==30 then p:AddHearts(24);Isaac.ExecuteCommand('stage '..c.stage)
 elseif t==60 then
  local level=g:GetLevel();local rooms=level:GetRooms();local target=rooms:Get(level:GetLastBossRoomListIndex())
  for i=0,rooms.Size-1 do local d=rooms:Get(i);if d.Data and d.Data.Type==RoomType.ROOM_BOSS then
   Isaac.DebugString('[LATE ROOM] '..c.name..' '..tostring(d.SafeGridIndex)..' '..tostring(d.Data.Name)..' variant='..tostring(d.Data.Variant))
   if c.name=='Delirium' and string.find(string.lower(d.Data.Name or ''),'delirium') then target=d end
  end end
  if c.grid then g:ChangeRoom(c.grid) else g:ChangeRoom(target.SafeGridIndex) end
 elseif t==75 then
  if c.name=='Mother' then for i=0,room:GetGridSize()-1 do local grid=room:GetGridEntity(i);if grid and grid:GetType()==GridEntityType.GRID_TRAPDOOR then p.Position=grid.Position;p.Velocity=Vector.Zero;Isaac.DebugString('[LATE ENTRY] Mother trap '..i) end end
  elseif c.name=='Mega Satan' then p.Position=room:GetCenterPos();p.Velocity=Vector.Zero end
 elseif t==160 then rq.types={};for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then table.insert(rq.types,{type=e.Type,variant=e.Variant,subtype=e.SubType}) end end;Isaac.DebugString('[LATE FIXTURE] '..c.name..' '..require('json').encode(rq.types))
 elseif t>=180 and t<=1780 and t%15==0 then for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:TakeDamage(999999,DamageFlag.DAMAGE_IGNORE_ARMOR,EntityRef(p),0) end end
 elseif t==1810 then
  local keys=#Isaac.FindByType(5,100,Isaac.GetItemIdByName('Twisted R Key'),false,false)
  local owned=p:GetCollectibleNum(Isaac.GetItemIdByName('Twisted R Key'),true)
  out(c.name..' reward',room:IsClear() and keys+owned==1,'generated boss clear yields exactly one key in inventory OR on pedestal',{stage=g:GetLevel():GetStage(),stageType=g:GetLevel():GetStageType(),roomType=room:GetType(),clear=room:IsClear(),keys=keys,owned=owned,active=p:GetActiveItem(),bosses=rq.types})
  out(c.name..' native check',BossTracker:GetCharacterMarks(p:GetPlayerType())[c.mark]==true,'native completion credits '..c.mark,{marks=BossTracker:GetCharacterMarks(p:GetPlayerType()),chainCount=BossTracker:GetChainCount(p:GetPlayerType())})
  local entities,grids={},{};for _,e in ipairs(Isaac.GetRoomEntities()) do table.insert(entities,{type=e.Type,variant=e.Variant,subtype=e.SubType}) end
  for i=0,room:GetGridSize()-1 do local grid=room:GetGridEntity(i);if grid then table.insert(grids,{index=i,type=grid:GetType(),variant=grid:GetVariant(),state=grid.State}) end end
  Isaac.DebugString('[LATE EXIT INVENTORY] '..c.name..' '..require('json').encode({entities=entities,grids=grids}))
  if rq.case<#matrix then rq.case=rq.case+1;rq.tick=0;Isaac.ExecuteCommand('restart 6') else Isaac.DebugString('[LATE QA] DONE');rq=nil;boot=100 end
 end
end)
