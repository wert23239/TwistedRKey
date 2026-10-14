-- QA ONLY: read-only cold Continue guard; no restart/input/state modification.
local slot,wait,done=nil,nil,false
local function tr(label,a) Isaac.DebugString('[ROOM QA] '..label..' '..require('json').encode(a))end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw;tr('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 if slot~=3 or not continued then tr('STOP',{reason='not positively guarded slot3 cold Continue'});done=true;return end
 wait=0
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done or wait==nil then return end;wait=wait+1;if wait~=30 then return end
 local p=Isaac.GetPlayer(0);local s=CharacterMechanics:State(p)
 local a={type=p:GetPlayerType(),difficulty=Game().Difficulty,seed=Game():GetSeeds():GetStartSeedString(),rooms=s.rooms,charge=p:GetActiveCharge(2),pocket=p:GetActiveItem(2),yum=p:HasCollectible(45),cycle=BossTracker.data._twistedCycles}
 local ok=a.type==1 and a.difficulty==1 and a.seed=='3PWL 28FM' and a.rooms==1 and a.charge==1 and a.pocket==639 and a.yum and a.cycle==1
 tr('ASSERT',{label='cold Continue retains actual Maggy progress',result=ok and 'PASS' or 'FAIL',expected='same3PWL28FM HardMaggy cycle1 rooms/charge1 Yum/pocketYuck',actual=a});done=true;tr('DONE',{reason='read-only cold Continue observation'})
end)
