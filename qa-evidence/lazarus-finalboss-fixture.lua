-- QA ONLY separate from read-only observer. Single fresh slot3 Hard Lazarus.
-- Existing generated finalboss descriptor only; no manual award/player Die.
local TwistedRKey=RegisterMod('LazarusFixtureQA',1)
local tick,armed=0,false
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 tick=0;local p=Isaac.GetPlayer(0)
 armed=not continued and Game().Difficulty==1 and Game():GetNumPlayers()==1 and p:GetPlayerType()==PlayerType.PLAYER_LAZARUS
 Isaac.DebugString('[LAZARUS FIXTURE QA] fresh guard '..tostring(armed))
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not armed then return end;tick=tick+1
 if tick==30 then
  local l=Game():GetLevel();local d=l:GetRooms():Get(l:GetLastBossRoomListIndex())
  if not d or not d.Data or d.Data.Type~=RoomType.ROOM_BOSS then armed=false;Isaac.DebugString('[LAZARUS FIXTURE QA] invalid finalboss');return end
  Isaac.DebugString('[LAZARUS FIXTURE QA] existing boss '..d.SafeGridIndex)
  Game():ChangeRoom(d.SafeGridIndex)
 elseif tick==90 then
  if Game():GetRoom():GetType()~=RoomType.ROOM_BOSS then armed=false;return end
  local n=0;for _,e in ipairs(Isaac.GetRoomEntities()) do if e:IsActiveEnemy(false) then n=n+1;e:TakeDamage(99999,0,EntityRef(Isaac.GetPlayer(0)),0) end end
  Isaac.DebugString('[LAZARUS FIXTURE QA] scripted boss damage targets '..n)
 elseif tick==400 then
  armed=false;local p=Isaac.GetPlayer(0)
  Isaac.DebugString('[LAZARUS FIXTURE QA] done '..require('json').encode({dead=p:IsDead(),type=p:GetPlayerType(),lives=p:GetExtraLives(),health=p:GetHearts()+p:GetSoulHearts()}))
 end
end)
