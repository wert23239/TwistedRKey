-- Source-only draft inventory contracts, NOT native gameplay acceptance.
-- Exercise every randomized grant branch without modifying game/save files.
local function constants()
 local n=0
 return setmetatable({}, {__index=function(t,k) n=n+1;rawset(t,k,n);return n end})
end
PlayerType=constants();CollectibleType=constants();TrinketType=constants()
local logs={}
Isaac={DebugString=function(s) logs[#logs+1]=s end}
local planetariumReads=0
function Game()return {GetLevel=function()planetariumReads=planetariumReads+1;return {} end}end
local s=dofile('scripts/character_setups.lua')
local C,P,T=CollectibleType,PlayerType,TrinketType
local originalRandom=math.random
local branch=1
math.random=function(n) assert(branch<=n);return branch end
local function run(kind,expected,trinkets)
 local p={items={},trinkets={},kind=kind,CanFly=true}
 function p:GetPlayerType() return self.kind end
 function p:AddCollectible(id,charge,first)
  assert(charge==0 and first==false,'draft grants have no explicit initial charge')
  self.items[#self.items+1]=id
 end
 function p:AddTrinket(id,first)assert(first==false);self.trinkets[#self.trinkets+1]=id end
 s.ApplySetup(p)
 assert(#p.items==#expected,'unexpected item count')
 for i,id in ipairs(expected)do assert(p.items[i]==id,'unexpected branch grant')end
 trinkets=trinkets or {}
 assert(#p.trinkets==#trinkets)
 for i,id in ipairs(trinkets)do assert(p.trinkets[i]==id)end
 return p
end
local checks=0
local function test(label,f)f();checks=checks+1;print('PASS source-only: '..label)end
test('Isaac D6 base draft',function()run(P.PLAYER_ISAAC,{C.COLLECTIBLE_D6})end)
for i,id in ipairs({C.COLLECTIBLE_SPEED_BALL,C.COLLECTIBLE_MAGIC_MUSHROOM,C.COLLECTIBLE_CRICKETS_HEAD,C.COLLECTIBLE_SACRED_HEART})do
 branch=i;test('Azazel random branch '..i,function()run(P.PLAYER_AZAZEL,{C.COLLECTIBLE_ROCK_BOTTOM,id})end)
end
for i,id in ipairs({C.COLLECTIBLE_FATE,C.COLLECTIBLE_LORDS_OF_THE_PIT,C.COLLECTIBLE_DEAD_DOVE})do
 branch=i;test('Lost random branch '..i..' remains flying (grounded NOT implemented)',function()
  local p=run(P.PLAYER_THELOST,{id});assert(p.CanFly==true)
 end)
end
test('Eden grants Experimental Treatment + Blessing only (extra boss NOT implemented here)',function()
 run(P.PLAYER_EDEN,{C.COLLECTIBLE_EXPERIMENTAL_TREATMENT,C.COLLECTIBLE_EDENS_BLESSING})
end)
test('Jacob grants Dr Fetus + Reflection + No 2 to passed player only',function()
 run(P.PLAYER_JACOB,{C.COLLECTIBLE_DR_FETUS,C.COLLECTIBLE_MY_REFLECTION,C.COLLECTIBLE_NUMBER_TWO})
end)
test('Tainted Isaac grants three ordinary Sacred Orbs (inverse filter NOT implemented here)',function()
 run(P.PLAYER_ISAAC_B,{C.COLLECTIBLE_SACRED_ORB,C.COLLECTIBLE_SACRED_ORB,C.COLLECTIBLE_SACRED_ORB})
end)
test('Tainted Lost Baggy + Crystal Ball; level read is not planetarium hook',function()
 run(P.PLAYER_THELOST_B,{C.COLLECTIBLE_LITTLE_BAGGY,C.COLLECTIBLE_CRYSTAL_BALL});assert(planetariumReads==1)
end)
test('Tainted Cain grants Moms Shovel; no conversion implementation in setup',function()run(P.PLAYER_CAIN_B,{C.COLLECTIBLE_MOMS_SHOVEL})end)
test('Tainted Keeper Magneto + Cursed Penny; no shop-door hook in setup',function()
 run(P.PLAYER_KEEPER_B,{C.COLLECTIBLE_MAGNETO},{T.TRINKET_CURSED_PENNY})
end)
test('Tainted Eden TMTRAINER only; no death callback in setup',function()run(P.PLAYER_EDEN_B,{C.COLLECTIBLE_TMTRAINER})end)
test('Tainted Jacob Birthright grant',function()run(P.PLAYER_JACOB_B,{C.COLLECTIBLE_BIRTHRIGHT})end)
test('undefined character leaves inventory alone and logs',function()
 local before=#logs;run(-999,{});assert(#logs==before+1 and logs[#logs]:find('No custom setup',1,true))
end)
math.random=originalRandom
assert(checks==17)
print('TOTAL: 17/17 source contracts PASS. Incomplete draft behaviors are documented limitations, NOT gameplay passes.')
