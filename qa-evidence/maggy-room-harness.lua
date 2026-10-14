-- QA ONLY: actual generated floor rooms, scripted engine enemy kills.
-- No synthetic clean-award callback, no direct RoomCleared/ConvertHeart calls.
local slot,boot,tick,armed,done=nil,0,0,false,false
local targets,which,entered,lastRooms,clears={},0,0,0,0
local candidate=0
local function tr(label,a) Isaac.DebugString('[ROOM QA] '..label..' '..require('json').encode(a)) end
local function report(label,ok,expected,a) tr('ASSERT',{label=label,result=ok and 'PASS' or 'FAIL',expected=expected,actual=a}) end
local function nextRoom() candidate=candidate+1;if not targets[candidate] then done=true;tr('STOP',{reason='not enough populated rooms'});return end;Game():ChangeRoom(targets[candidate]);entered=tick end
local function obs(p) local s=CharacterMechanics:State(p);return {rooms=s.rooms,red=p:GetHearts(),rotten=p:GetRottenHearts(),soul=p:GetSoulHearts(),charge=p:GetActiveCharge(2),stage=Game():GetLevel():GetStage(),pocket=p:GetActiveItem(2),yum=p:HasCollectible(45),cycle=BossTracker.data._twistedCycles}end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then slot=raw;tr('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued) tr('start',{continued=continued,type=Isaac.GetPlayer(0):GetPlayerType(),difficulty=Game().Difficulty,seed=Game():GetSeeds():GetStartSeedString()}) end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,function() if armed and not done then clears=clears+1;tr('native-clean-award',{index=Game():GetLevel():GetCurrentRoomIndex(),clears=clears,state=obs(Isaac.GetPlayer(0))}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done or slot~=3 then return end
 if not armed then boot=boot+1;if boot==10 then armed=true;tick=-30;Isaac.ExecuteCommand('restart 1')end;return end
 tick=tick+1;local p=Isaac.GetPlayer(0);local level=Game():GetLevel()
 if tick==0 then
  if p:GetPlayerType()~=1 or Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then done=true;tr('STOP',{reason='invalid Hard Maggy fixture'});return end
  local rs=level:GetRooms()
  for i=0,rs.Size-1 do local d=rs:Get(i);if d.Data and d.Data.Type==RoomType.ROOM_DEFAULT and not d.Clear then targets[#targets+1]=d.SafeGridIndex end end
  tr('targets',{indices=targets,count=#targets})
  if #targets<5 then done=true;tr('STOP',{reason='fewer than five uncleared normal rooms'});return end
  p:AddHearts(20);report('fresh room counter',CharacterMechanics:State(p).rooms==0,'rooms0',obs(p))
  which=1;nextRoom()
 end
 if which>=1 and which<=5 then
  p:AddHearts(20)
  if tick-entered>30 and tick%5==0 then for _,e in ipairs(Isaac.GetRoomEntities())do if e:IsActiveEnemy(false) and e:IsVulnerableEnemy() then e:TakeDamage(10000,0,EntityRef(p),0)end end end
  local room=Game():GetRoom()
  if tick-entered==20 and room:GetAliveEnemiesCount()==0 then
   tr('SKIP',{index=level:GetCurrentRoomIndex(),reason='empty/trap default room cannot certify combat award'});nextRoom();return
  end
  if tick-entered>60 and room:IsClear() then
   local s=CharacterMechanics:State(p);local expected=which%4
   report('native room '..which,s.rooms==expected and p:GetActiveCharge(2)==expected and p:GetRottenHearts()==math.floor(which/4),'rooms/charge'..expected..' rotten'..math.floor(which/4),{index=level:GetCurrentRoomIndex(),clears=clears,state=obs(p)})
   if which<5 then which=which+1;nextRoom()
   else which=6;entered=tick;Game():ChangeRoom(targets[1]) end
  elseif tick-entered>1200 then done=true;tr('STOP',{reason='room-clear timeout',which=which,index=level:GetCurrentRoomIndex(),alive=room:GetAliveEnemiesCount(),state=obs(p)})end
 elseif which==6 and tick-entered==60 then
  report('revisit clear room no charge',CharacterMechanics:State(p).rooms==1 and p:GetRottenHearts()==1,'rooms1 rotten1',obs(p))
  local old=p:GetRottenHearts();p:UseActiveItem(639,UseFlag.USE_NOANIM,2)
  report('external manual Yuck rejected',p:GetRottenHearts()==old and CharacterMechanics:State(p).rooms==1,'unchanged rotten/rooms',obs(p))
  local id=Isaac.GetItemIdByName('Twisted R Key');p:AddCollectible(id,0,false);p:UseActiveItem(id,UseFlag.USE_NOANIM,0);which=7;entered=tick
 elseif which==7 and tick-entered==90 then
  report('actual Twisted restores Maggy room progress',level:GetStage()==1 and CharacterMechanics:State(p).rooms==1 and p:GetActiveItem(2)==639 and p:HasCollectible(45) and (BossTracker.data._twistedCycles or 0)==1,'stage1 cycle1 rooms1 Yum/pocketYuck',obs(p))
  done=true;tr('DONE',{reason='five actual native clean awards, revisit, external Yuck, actual key; scripted engine kills NOT organic input/combat'})
 end
end)
