-- Actual production clean-award callback under mocks. NOT native death/revival acceptance.
local function constants()local n=0;return setmetatable({},{__index=function(t,k)n=n+1;rawset(t,k,n);return n end})end
EvaluateStatStage=constants();AddHealthType=constants();ModCallbacks=constants();PlayerType=constants();FamiliarVariant=constants();EntityType=constants();RoomType=constants()
package.loaded['scripts.saved_designs']={}
local roomType,current,last,floor=RoomType.ROOM_BOSS,{SafeGridIndex=84},{SafeGridIndex=84},'1:0'
local players,states={},{};local saves=0;local callback
local level={GetCurrentRoomDesc=function()return current end,GetLastBossRoomListIndex=function()return 7 end,GetRooms=function()return {Get=function(_,index)assert(index==7);return last end}end}
local game={GetRoom=function()return {GetType=function()return roomType end}end,GetLevel=function()return level end,GetNumPlayers=function()return #players end}
Game=function()return game end
Isaac={GetEntityVariantByName=function()return 17730 end,GetPlayer=function(i)return players[i+1]end}
local items=dofile('scripts/custom_items.lua')
local mod={AddCallback=function(_,id,f)if id==ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD then callback=f end end}
items:Init(mod,{data={}},{State=function(_,p)return states[p]end,FloorToken=function()return floor end,Save=function()saves=saves+1 end},{ApplySetup=function()end})
items.ids.resurrection=738
local function player(has,lives)
 local p={has=has,lives=lives,deaths=0};states[p]={}
 function p:HasCollectible(id)return self.has and id==738 end
 function p:Die()assert(states[self].resurrectionFloor==floor,'token must persist before synchronous Die');self.deaths=self.deaths+1;self.lives=math.max(0,self.lives-1)end
 return p
end
local function reset()roomType=RoomType.ROOM_BOSS;current={SafeGridIndex=84};last={SafeGridIndex=84};floor='1:0';items.ready=true;players={player(true,1)};saves=0 end
local checks=0
local function test(label,f)reset();f();checks=checks+1;print('PASS MOCK: '..label)end
test('unready skips all processing',function()items.ready=false;callback();assert(players[1].deaths==0 and saves==0)end)
test('nonboss room skipped',function()roomType=-1;callback();assert(players[1].deaths==0 and saves==0)end)
test('XL first boss skipped',function()current.SafeGridIndex=69;callback();assert(players[1].deaths==0 and saves==0)end)
test('lastboss calls Die once and saves',function()callback();assert(players[1].deaths==1 and players[1].lives==0 and saves==1)end)
test('repeat award on samefloor does not spend secondlife',function()players[1].lives=2;callback();callback();assert(players[1].deaths==1 and players[1].lives==1)end)
test('next floor rearms death',function()callback();floor='2:0';callback();assert(players[1].deaths==2)end)
test('item absent does not kill',function()players[1].has=false;callback();assert(players[1].deaths==0 and states[players[1]].resurrectionFloor==nil)end)
test('zero extra lives still requests native death',function()players[1].lives=0;callback();assert(players[1].deaths==1)end)
test('players independently gated by item',function()players[2]=player(false,3);callback();assert(players[1].deaths==1 and players[2].deaths==0)end)
test('perplayer floor guard remains independent',function()players[2]=player(true,3);states[players[1]].resurrectionFloor=floor;callback();assert(players[1].deaths==0 and players[2].deaths==1)end)
test('token prevents synchronous reentrant double death',function()local p=players[1];local original=p.Die;function p:Die()original(self);callback()end;callback();assert(p.deaths==1)end)
test('continued samefloor state skips repeat death',function()states[players[1]]={resurrectionFloor=floor};callback();assert(players[1].deaths==0)end)
test('missing last descriptor currently fails open (characterization only)',function()last=nil;callback();assert(players[1].deaths==1)end)
print(checks..' production Forced Resurrection callback MOCK contracts PASS; native revival, floor exit timing and terminal gameover NOT verified')
