-- QA ONLY: actual native health APIs, scripted grants, isolated slot3 Hard Judas.
local slot,boot,tick,armed,done=nil,0,0,false,false
local function tr(label,a) Isaac.DebugString('[BOW QA] '..label..' '..require('json').encode(a)) end
local function report(label,ok,expected,a) tr('ASSERT',{label=label,result=ok and 'PASS' or 'FAIL',expected=expected,actual=a}) end
local function health(p) return {red=p:GetHearts(),soul=p:GetSoulHearts(),black=p:GetBlackHearts(),max=p:GetMaxHearts()} end
local function clear(p) p:AddHearts(-p:GetHearts());p:AddSoulHearts(-p:GetSoulHearts());p:AddMaxHearts(-p:GetMaxHearts()) end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then slot=raw;tr('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued) tr('start',{continued=continued,type=Isaac.GetPlayer(0):GetPlayerType(),difficulty=Game().Difficulty,seed=Game():GetSeeds():GetStartSeedString()}) end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done or slot~=3 then return end
 if not armed then boot=boot+1;if boot==10 then armed=true;tick=-60;Isaac.ExecuteCommand('restart 3') end;return end
 tick=tick+1;local p=Isaac.GetPlayer(0)
 if tick~=0 then return end
 done=true
 if p:GetPlayerType()~=3 or Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then tr('STOP',{reason='invalid fresh Hard Judas fixture'});return end
 local bow=Isaac.GetItemIdByName('Cursed Bow')
 report('native Judas Cursed Bow kit',bow>0 and p:HasCollectible(bow),'resolved custom bow equipped',{bow=bow,has=p:HasCollectible(bow),seed=Game():GetSeeds():GetStartSeedString()})
 if bow<=0 or not p:HasCollectible(bow) then return end
 local cases={
 {name='red positive gain cap',run=function() clear(p);p:AddMaxHearts(6);p:AddHearts(6) end,expect={red=1,max=6,soul=0}},
 {name='soul positive gain cap',run=function() clear(p);p:AddMaxHearts(2);p:AddHearts(1);p:AddSoulHearts(6) end,expect={red=1,max=2,soul=1}},
 {name='black positive gain cap',run=function() clear(p);p:AddMaxHearts(2);p:AddHearts(1);p:AddBlackHearts(6) end,expect={red=1,max=2,soul=1}},
 {name='container gain not capped',run=function() clear(p);p:AddMaxHearts(8);p:AddHearts(1) end,expect={red=1,max=8,soul=0}},
 {name='HP-up native healing capped',run=function() clear(p);p:AddMaxHearts(2);p:AddHearts(1);p:RemoveCollectible(CollectibleType.COLLECTIBLE_BREAKFAST);p:AddCollectible(CollectibleType.COLLECTIBLE_BREAKFAST,0,true) end,expect={red=2,max=4,soul=0}},
 {name='negative red removal uncapped',run=function() clear(p);p:AddMaxHearts(8);for i=1,6 do p:AddHearts(1) end;p:AddHearts(-4) end,expect={red=2,max=8,soul=0}},
 {name='without bow ordinary red gain',run=function() p:RemoveCollectible(bow);clear(p);p:AddMaxHearts(8);p:AddHearts(6) end,expect={red=6,max=8,soul=0}},
 }
 for _,c in ipairs(cases) do c.run();local a=health(p);local ok=true;for k,v in pairs(c.expect) do ok=ok and a[k]==v end;report(c.name,ok,c.expect,a) end
 p:AddCollectible(bow,0,false)
 clear(p);p:AddMaxHearts(4);for i=1,4 do p:AddHearts(1) end
 p:SetMinDamageCooldown(0);local before=health(p);p:TakeDamage(1,DamageFlag.DAMAGE_RED_HEARTS,EntityRef(p),0);local after=health(p)
 report('incoming halfheart damage not doubled',before.red-after.red==1,'red loss1',{before=before,after=after})
 tr('DONE',{scope='engine API health gains/HP-up/removal/damage; NOT organic pickups/reset/Continue'})
end)
