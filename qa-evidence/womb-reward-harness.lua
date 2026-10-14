-- QA ONLY: generated Womb II plus explicit Heart/It Lives arena fixtures. Never ship.
local rq, boot= nil,0
local function out(label,pass,expected,actual)
 Isaac.DebugString('[REWARD QA] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',expected=expected,actual=actual}))
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event) Isaac.DebugString('[REWARD EVENT] '..tostring(event)) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not rq then
  boot=boot+1;if boot==10 then rq={tick=0,case=1};Isaac.ExecuteCommand('restart 6') end
  return
 end
 rq.tick=rq.tick+1; local t=rq.tick;local p=Isaac.GetPlayer(0);local g=Game();local room=g:GetRoom()
 if t==30 then p:AddHearts(12);Isaac.ExecuteCommand('stage 8')
 elseif t==60 then g:ChangeRoom(g:GetLevel():GetRooms():Get(g:GetLevel():GetLastBossRoomListIndex()).SafeGridIndex)
 elseif t==85 then
  rq.types={}
  for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then
   table.insert(rq.types,{type=e.Type,variant=e.Variant,subtype=e.SubType})
   if rq.case>1 then e:Remove() end
  end end
  if rq.case>1 then
   local e=Isaac.Spawn(EntityType.ENTITY_MOMS_HEART,rq.case-2,0,room:GetCenterPos(),Vector.Zero,nil)
   rq.types={{type=e.Type,variant=e.Variant,subtype=e.SubType}};room:SetClear(false)
  end
  Isaac.DebugString('[REWARD QA] fixture '..rq.case..' bosses='..require('json').encode(rq.types))
 elseif t>=100 and t<=250 and t%15==0 then
  for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:Kill() end end
 elseif t==280 then
  local keys=0;for _,e in ipairs(Isaac.FindByType(5,100,Isaac.GetItemIdByName('Twisted R Key'),false,false)) do keys=keys+1 end
  out('Womb II case '..rq.case..' reward',room:IsClear() and keys==1,'cleared real boss fixture yields exactly one named Twisted R Key',{stage=g:GetLevel():GetStage(),roomType=room:GetType(),clear=room:IsClear(),keys=keys,bosses=rq.types,explicitFixture=rq.case>1})
  out('Womb II case '..rq.case..' native check',BossTracker:GetCharacterMarks(p:GetPlayerType()).moms_heart==true,'engine completion event credits canonical Heart check',{marks=BossTracker:GetCharacterMarks(p:GetPlayerType()),chainCount=BossTracker:GetChainCount(p:GetPlayerType())})
  if rq.case<3 then rq.case=rq.case+1;rq.tick=0;Isaac.ExecuteCommand('restart 6') else Isaac.DebugString('[REWARD QA] DONE');rq=nil;boot=100 end
 end
end)
