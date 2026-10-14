-- Actual setup wrapper composition + saved designs, MOCK engine only.
local function constants(seed)
 local n=seed or 2000
 return setmetatable({}, {__index=function(t,k)n=n+1;rawset(t,k,n);return n end})
end
for _,name in ipairs({'PlayerType','CollectibleType','TrinketType','ActiveSlot','PillEffect','PillColor','UseFlag','ButtonAction','InputHook','PickupVariant','ModCallbacks','EvaluateStatStage','AddHealthType','EntityType','FamiliarVariant'})do _G[name]=constants()end
local P,C=PlayerType,CollectibleType
C.COLLECTIBLE_D6=105;C.COLLECTIBLE_MOMS_KNIFE=114;C.COLLECTIBLE_SOY_MILK=330
C.COLLECTIBLE_ISAACS_HEART=276
local players,legacyLogs={},{}
local game={GetNumPlayers=function()return #players end,GetLevel=function()return {GetDungeonPlacementSeed=function()return 101 end,GetStage=function()return 1 end,GetStageType=function()return 0 end}end,GetHUD=function()return {ShowItemText=function()end}end}
Game=function()return game end
Isaac={GetPlayer=function(i)return players[i+1]end,GetItemConfig=function()return {GetCollectible=function()return {MaxCharges=4}end,GetCollectibles=function()return {Size=1}end}end,GetEntityVariantByName=function()return 17730 end,DebugString=function(s)legacyLogs[#legacyLogs+1]=s end}
local itemIds={['Unlucky Foot']=734,['Panic Needle']=735,['Cursed Bow']=736,['Undead Bird']=737,['Forced Resurrection']=738}
Isaac.GetItemIdByName=function(n)return assert(itemIds[n])end
local descriptions={};EID={addCollectible=function(_,id,text,name)descriptions[id]={text=text,name=name}end}
local function player(kind,seed)
 local p={kind=kind,InitSeed=seed or 1,items={},trinkets={},grants={}}
 function p:GetPlayerType()return self.kind end
 function p:HasCollectible(id)return (self.items[id] or 0)>0 end
 function p:GetCollectibleNum(id)return self.items[id] or 0 end
 function p:AddCollectible(id,charge,first)assert(first==false);self.items[id]=(self.items[id] or 0)+1;self.grants[#self.grants+1]={id=id,charge=charge}end
 function p:RemoveCollectible(id)self.items[id]=nil end
 function p:GetTrinket(i)return self.trinkets[i+1] or 0 end
 function p:HasTrinket(id)for _,t in pairs(self.trinkets)do if t==id then return true end end return false end
 function p:AddTrinket(id)self.trinkets[#self.trinkets+1]=id end
 function p:GetOtherTwin()return self.twin end
 function p:GetActiveItem()return self.active or 0 end
 function p:SetPocketActiveItem(id)self.active=id end
 function p:SetActiveCharge(n)self.charge=n end
 function p:GetCollectibleRNG()return {RandomInt=function()return 0 end}end
 function p:SetCard()end;function p:SetPill()end
 return p
end
local tracker={data={},Save=function()end};local mod={AddCallback=function()end}
local setups=dofile('scripts/character_setups.lua')
local presets=dofile('scripts/loadout_presets.lua');presets:Init(mod,setups,tracker)
local mechanics=dofile('scripts/character_mechanics.lua');mechanics:Init(mod,tracker,setups)
local items=dofile('scripts/custom_items.lua');items:Init(mod,tracker,mechanics,setups)
items.ids={foot=734,needle=735,bow=736,bird=737,resurrection=738}
local checks=0
local function test(label,f)
 tracker.data={};mechanics.data={players={},cleared={}};items.ready=true;presets.mode='normal';legacyLogs={};players={}
 f();checks=checks+1;print('PASS MOCK COMPOSITION: '..label)
end
local function run(kind)
 local p=player(kind);players={p};setups.ApplySetup(p);return p
end
local function exact(p,ids)
 local expected={};for _,id in ipairs(ids)do expected[id]=(expected[id] or 0)+1 end
 for id,n in pairs(expected)do assert(p.items[id]==n,'missing/wrong count '..id)end
 for id,n in pairs(p.items)do assert(expected[id]==n,'unexpected final grant '..id)end
end
test('Samson Blood Puppy565 and Bloody Lust plus Needle restored without duplicate',function()
 local p=run(P.PLAYER_SAMSON);exact(p,{565,C.COLLECTIBLE_BLOODY_LUST,735});setups.ApplySetup(p);exact(p,{565,C.COLLECTIBLE_BLOODY_LUST,735});p.items={};setups.ApplySetup(p);exact(p,{565,C.COLLECTIBLE_BLOODY_LUST,735})
end)
test('ready Blue Baby uses saved design instead of legacy empty fallback',function()exact(run(P.PLAYER_BLUEBABY),{725,358,378,675});assert(#legacyLogs==0)end)
test('ready Eden uses saved697/240 without legacy branch execution',function()local p=run(P.PLAYER_EDEN);exact(p,{697,240});assert(#legacyLogs==0);setups.ApplySetup(p);exact(p,{697,240})end)
test('ready Bethany restores saved569',function()exact(run(P.PLAYER_BETHANY),{569});assert(#legacyLogs==0)end)
test('ready Tainted Lost saved619 included; legacy level read bypassed',function()exact(run(P.PLAYER_THELOST_B),{431,75,619});assert(#legacyLogs==0)end)
test('ready Tainted Eden saved721',function()exact(run(P.PLAYER_EDEN_B),{721});assert(#legacyLogs==0)end)
test('Jacob saved276 main and heart grant to actual returned twin only',function()
 local p=player(P.PLAYER_JACOB);local twin=player(-999,2);local other=player(-998,3);p.twin=twin;players={p,twin,other};setups.ApplySetup(p);exact(p,{276});exact(twin,{276});exact(other,{})
end)
test('missing Jacob twin safely skipped, not engine twin certification',function()exact(run(P.PLAYER_JACOB),{276})end)
test('restored baseline and trinkets supplement design and do not duplicate owned grants',function()
 tracker.data._startingKits={[tostring(P.PLAYER_BLUEBABY)]={items={124,725},trinkets={71}}}
 local p=run(P.PLAYER_BLUEBABY);exact(p,{124,725,358,378,675});assert(p:HasTrinket(71));setups.ApplySetup(p);exact(p,{124,725,358,378,675});assert(#p.trinkets==1)
end)
test('revived Lazarus uses original startingkit key and custom resurrection',function()
 tracker.data._startingKits={[tostring(P.PLAYER_LAZARUS)]={items={46},trinkets={53}}}
 local p=run(P.PLAYER_LAZARUS2);exact(p,{46,738});assert(p:HasTrinket(53));assert(#legacyLogs==0)
end)
test('unready Items delegates through presets and mechanics to legacy setup',function()
 items.ready=false;local p=run(P.PLAYER_EDEN);exact(p,{C.COLLECTIBLE_EXPERIMENTAL_TREATMENT,C.COLLECTIBLE_EDENS_BLESSING});assert(#legacyLogs==1)
end)
test('normal Isaac bypasses saved114/330 in wrapper',function()exact(run(P.PLAYER_ISAAC),{105})end)
test('knife Isaac remains controlled by preset wrapper',function()presets.mode='knife';exact(run(P.PLAYER_ISAAC),{105,114,330})end)
test('duplicate baseline copies currently collapse (limitation characterization)',function()
 tracker.data._startingKits={[tostring(P.PLAYER_BLUEBABY)]={items={124,124},trinkets={}}}
 local p=run(P.PLAYER_BLUEBABY);assert(p:GetCollectibleNum(124)==1,'Give is ownership gated, not multiplicity restoration')
end)
test('EID resurrection description matches verified clean-award timing',function()
 players={player(P.PLAYER_LAZARUS)};tracker.data._twistedRestart=true;items:OnGameStart(false)
 assert(descriptions[738].text=='Lose a life when clearing the final boss of a floor#Your normal extra lives still work#No spare life means game over')
end)
assert(checks==15)
print('15/15 saved-design/setup-wrapper MOCK contracts PASS. Native final inventories, twins, reset multiplicity and remaining draft mechanics UNVERIFIED; duplicate starting-kit limitation retained.')
