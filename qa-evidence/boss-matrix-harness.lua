-- QA ONLY: real generated arenas, scripted kills. Never ship.
local matrix={{name='Mom',stage='6',mark=nil},{name='Isaac',stage='10a',mark='isaac_boss'},{name='Satan',stage='10',mark='satan'},{name='Blue Baby',stage='11a',mark='blue_baby'},{name='Lamb',stage='11',mark='the_lamb'},{name='Hush',stage='9',mark='hush'}}
local rq,boot=nil,0
local function out(label,pass,expected,actual) Isaac.DebugString('[MATRIX QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',expected=expected,actual=actual})) end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,slot,selected,raw) Isaac.DebugString('[MATRIX SLOT] '..tostring(slot)..' selected='..tostring(selected)..' raw='..tostring(raw)) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event) Isaac.DebugString('[MATRIX EVENT] '..tostring(event)) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not rq then boot=boot+1;if boot==10 then rq={tick=0,case=1};Isaac.ExecuteCommand('restart 6') end;return end
 rq.tick=rq.tick+1;local t=rq.tick;local c=matrix[rq.case];local g=Game();local p=Isaac.GetPlayer(0);local room=g:GetRoom()
 if t==30 then p:AddHearts(24);Isaac.ExecuteCommand('stage '..c.stage)
 elseif t==60 then local d=g:GetLevel():GetRooms():Get(g:GetLevel():GetLastBossRoomListIndex()); g:ChangeRoom(d.SafeGridIndex)
 elseif t==85 then rq.types={};for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then table.insert(rq.types,{type=e.Type,variant=e.Variant,subtype=e.SubType}) end end;Isaac.DebugString('[MATRIX FIXTURE] '..c.name..' '..require('json').encode(rq.types))
 elseif t>=100 and t<=580 and t%15==0 then for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:Kill() end end
 elseif t==610 then
  local keys=#Isaac.FindByType(5,100,Isaac.GetItemIdByName('Twisted R Key'),false,false)
  out(c.name..' reward',room:IsClear() and keys==1,'generated boss clear yields exactly one key',{stage=g:GetLevel():GetStage(),stageType=g:GetLevel():GetStageType(),roomType=room:GetType(),clear=room:IsClear(),keys=keys,bosses=rq.types})
  if c.mark then out(c.name..' native check',BossTracker:GetCharacterMarks(p:GetPlayerType())[c.mark]==true,'native completion credits '..c.mark,{marks=BossTracker:GetCharacterMarks(p:GetPlayerType()),chainCount=BossTracker:GetChainCount(p:GetPlayerType())}) end
  if rq.case<#matrix then rq.case=rq.case+1;rq.tick=0;Isaac.ExecuteCommand('restart 6') else Isaac.DebugString('[MATRIX QA] DONE');rq=nil;boot=100 end
 end
end)
