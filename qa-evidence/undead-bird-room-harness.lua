-- QA ONLY: isolated fresh Hard Eve; scripted damage/native existing-room APIs.
local slot,boot,tick,armed,done=nil,0,0,false,false
local items=require('scripts.custom_items')
local roomTargets={}
local birdDamage=0
local function tr(label,a) Isaac.DebugString('[BIRD QA] '..label..' '..require('json').encode(a)) end
local function report(label,ok,expected,a) tr('ASSERT',{label=label,result=ok and 'PASS' or 'FAIL',expected=expected,actual=a}) end
local function birds() return Isaac.FindByType(EntityType.ENTITY_EFFECT,items.birdVariant,-1,false,false) end
local function sample(p) return {room=Game():GetLevel():GetCurrentRoomIndex(),rooms=items:State(p).birdRooms or 0,birds=#birds(),red=p:GetHearts(),soul=p:GetSoulHearts()} end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then slot=raw;tr('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued) tr('start',{continued=continued,type=Isaac.GetPlayer(0):GetPlayerType(),difficulty=Game().Difficulty,seed=Game():GetSeeds():GetStartSeedString()}) end)
TwistedRKey:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,function(_,e,amount,flags,source)
 if armed and e:ToPlayer() and source and source.Entity and source.Entity.Type==EntityType.ENTITY_EFFECT and source.Entity.Variant==items.birdVariant then
  birdDamage=birdDamage+1;tr('bird-contact',{amount=amount,flags=flags,frame=source.Entity.FrameCount,before=sample(e:ToPlayer())})
 end
end,EntityType.ENTITY_PLAYER)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done or slot~=3 then return end
 if not armed then boot=boot+1;if boot==10 then armed=true;tick=-60;Isaac.ExecuteCommand('restart 5') end;return end
 tick=tick+1;local p=Isaac.GetPlayer(0)
 if tick==0 then
  if p:GetPlayerType()~=5 or Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then tr('STOP',{reason='invalid Hard Eve fixture'});done=true;return end
  local id=Isaac.GetItemIdByName('Undead Bird')
  report('Eve replaces vanilla Dead Bird',id>0 and p:HasCollectible(id) and not p:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD),'custom equipped / vanilla absent',{id=id,custom=p:HasCollectible(id),vanilla=p:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD)})
  local level=Game():GetLevel();local rs=level:GetRooms()
  for i=0,rs.Size-1 do local d=rs:Get(i);if d.Data and d.Data.Type==RoomType.ROOM_DEFAULT and d.SafeGridIndex>=0 and d.SafeGridIndex~=level:GetCurrentRoomIndex() then roomTargets[#roomTargets+1]=d.SafeGridIndex;if #roomTargets==2 then break end end end
  if #roomTargets<2 then tr('STOP',{reason='insufficient existing valid rooms'});done=true;return end
  p:AddMaxHearts(20);p:AddHearts(20);p:SetMinDamageCooldown(0);p:TakeDamage(1,DamageFlag.DAMAGE_RED_HEARTS,EntityRef(p),0)
 elseif tick==10 then
  local a=sample(p);report('damage spawns hostile bird current room',a.rooms==2 and a.birds==1,{rooms=2,birds=1},a)
 elseif tick==30 then tr('existing-room-change',{target=roomTargets[1]});Game():ChangeRoom(roomTargets[1])
 elseif tick==60 then
  local a=sample(p);report('bird persists exactly next room',a.room==roomTargets[1] and a.rooms==1 and a.birds==1,{room=roomTargets[1],rooms=1,birds=1},a)
 elseif tick==70 then tr('existing-room-change',{target=roomTargets[2]});Game():ChangeRoom(roomTargets[2])
 elseif tick==100 then
  local a=sample(p);report('bird expires second subsequent room',a.room==roomTargets[2] and a.rooms==0 and a.birds==0,{room=roomTargets[2],rooms=0,birds=0},a)
  -- Remove room enemies ONLY after lifetime sample, then let newly triggered bird naturally approach.
  for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then e:Remove() end end
  p.Position=Game():GetRoom():GetCenterPos();p.Velocity=Vector.Zero;p:SetMinDamageCooldown(0);p:TakeDamage(1,DamageFlag.DAMAGE_RED_HEARTS,EntityRef(p),0)
  _G.BirdQAHealth=p:GetHearts()+p:GetSoulHearts()
 elseif tick==200 then
  local a=sample(p);a.contactEvents=birdDamage;a.healthBefore=_G.BirdQAHealth
  report('hostile bird pursuit causes actual damage',birdDamage>0 and p:GetHearts()+p:GetSoulHearts()<_G.BirdQAHealth,'native bird-source contact and health loss',a)
  tr('DONE',{scope='scripted hit / valid existing-room engine transitions / natural bird approach; NOT organic room traversal, reset or Continue'});done=true
 end
 -- Prevent incidental hostile bird contacts during lifetime test without altering state.
 if tick>0 and tick<100 then for _,b in ipairs(birds()) do b.Position=p.Position+Vector(100,0);b.Velocity=Vector.Zero end end
end)
