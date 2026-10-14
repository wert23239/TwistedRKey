-- QA ONLY. Load ONCE after observed external-input native floor2->3 transition.
local mod=RegisterMod('Natural floor3 acceptance evidence',1)
local tick,done=0,false
local before,healed
local function snap()
 local p=Isaac.GetPlayer(0)
 local trk=require('scripts.custom_items')
 return {stage=Game():GetLevel():GetStage(),kind=p:GetPlayerType(),seed=Game():GetSeeds():GetStartSeedString(),damage=p.Damage,red=p:GetHearts(),gain=trk:State(p).needleGain or 0}
end
local function log(label,pass,a)Isaac.DebugString('[NATURAL3 ACCEPT] '..require('json').encode({label=label,result=pass and 'PASS' or 'FAIL',actual=a}))end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done then return end
 tick=tick+1;local p=Isaac.GetPlayer(0)
 if tick==1 then
  local s=snap()
  if s.stage~=3 or s.kind~=6 or s.seed~='L40L 6JZB' then log('guard',false,s);done=true;return end
  log('native floor3 clears penalty',s.gain==0,s)
  p:AddHearts(12);p:ResetDamageCooldown();before=snap();p:TakeDamage(1,0,EntityRef(p),0)
 elseif tick==16 then
  local s=snap();log('native floor3 hit',s.damage<before.damage and s.gain>0 and s.red<before.red,{before=before,after=s})
  p:AddHearts(12);p:ResetDamageCooldown();healed=snap();p:TakeDamage(1,0,EntityRef(p),0)
 elseif tick==31 then
  local s=snap();log('native floor3 healed hit',s.damage<healed.damage and s.gain>healed.gain and s.red<healed.red,{before=healed,after=s})
  done=true;Isaac.DebugString('[NATURAL3 ACCEPT] DONE')
 end
end)
