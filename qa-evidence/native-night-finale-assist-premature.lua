-- ARCHIVED FAILED QA FIXTURE: NOT SAFE TO AUTO-DEPLOY.
-- Oct13 1202 native Home/bed succeeded, but Dogma intro later hit NULL room transition.
-- Current Home descriptors do NOT validate the special future arena. Do not repeat TV
-- until actual special-arena descriptor Data is independently proven valid.
-- QA ONLY. Load once at actual native night Home, after a full save backup.
-- No staging/warps/forced room creation/TV activation/flags/marks/save writes.
-- Protect test player and damage ACTUAL engine-spawned finale bosses in UPDATE.
local g=Game();local p=Isaac.GetPlayer(0);local l=g:GetLevel()
local mod=RegisterMod('Native night finale QA',1)
local d=l:GetCurrentRoomDesc()
assert(g:GetNumPlayers()==1 and p:GetPlayerType()==6 and g.Difficulty==1
 and g:GetSeeds():GetStartSeedString()=='MZ34 RR8V' and l:GetStage()==13
 and l:GetStageType()==1 and d.Data and d.Data.Variant==4
 and g:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH),'Refused non-native night Home')
local tick=0;local stopped=false
local function trace(label,value)Isaac.DebugString('[NATIVE FINALE QA] '..label..' '..require('json').encode(value))end
trace('armed native night Home',{room=l:GetCurrentRoomIndex(),name=d.Data.Name})
mod:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if stopped or g:GetNumPlayers()~=1 then return end
 tick=tick+1;p:SetMinDamageCooldown(60)
 if tick%60~=0 then return end
 local cd=g:GetLevel():GetCurrentRoomDesc()
 if not cd.Data then trace('invalid current descriptor; damage refused',{room=l:GetCurrentRoomIndex()});return end
 for _,e in ipairs(Isaac.GetRoomEntities())do
  if (e.Type==950 or e.Type==951) and e:IsActiveEnemy(false) then
   trace('actual boss damage',{type=e.Type,variant=e.Variant,hp=e.HitPoints,room=l:GetCurrentRoomIndex(),roomName=cd.Data.Name,descriptorValid=true})
   e:TakeDamage(999999,0,EntityRef(p),0)
  end
 end
end)
mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT,function(_,event)
 trace('native completion',{event=event,stage=l:GetStage(),room=l:GetCurrentRoomIndex()})
 if event==14 then stopped=true end
end)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,function(_,save)stopped=true;trace('exit',{save=save})end)
return true
