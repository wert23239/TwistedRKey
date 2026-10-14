
-- QA ONLY: read-only descriptor provisioning, no TV/room/input/flags/damage/save calls.
local function arenaAudit()
 local g=Game(); local l=g:GetLevel();local rows={}
 for dim=-1,2 do
  for index=-20,168 do
   local ok,d=pcall(function()return l:GetRoomByIdx(index,dim)end)
   if index<0 or (ok and d and d.Data) then
    local row={index=index,dimension=dim,ok=ok,valid=ok and d~=nil and d.Data~=nil}
    if ok and d then row.grid=d.GridIndex;row.safe=d.SafeGridIndex;if d.Data then row.name=d.Data.Name;row.type=d.Data.Type;row.variant=d.Data.Variant;row.shape=d.Data.Shape end end
    rows[#rows+1]=row
   end
  end
 end
 Isaac.DebugString('[ARENA AUDIT] '..require('json').encode({stage=l:GetStage(),stageType=l:GetStageType(),room=l:GetCurrentRoomIndex(),seed=g:GetSeeds():GetStartSeedString(),count=BossTracker:GetChainCount(6),cycle=BossTracker.data._twistedCycles,ascent=g:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH),init=g:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH_INIT),descriptors=rows}))
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 if continued and Game():GetNumPlayers()==1 and Isaac.GetPlayer(0):GetPlayerType()==6 and Game():GetSeeds():GetStartSeedString()=='MZ34 RR8V' then arenaAudit() end
end)
