-- Production Items + Mechanics composition; mock engine/serialization, NOT native QA.
local function constants() local n=0;return setmetatable({},{__index=function(t,k)n=n+1;rawset(t,k,n);return n end})end
for _,name in ipairs({'EvaluateStatStage','AddHealthType','ModCallbacks','PlayerType','FamiliarVariant','EntityType','TrinketType','ActiveSlot','CollectibleType','PillEffect'})do _G[name]=constants()end
package.loaded['scripts.saved_designs']={}
local V={};V.__index=V
Vector=setmetatable({},{__call=function(_,x,y)return setmetatable({X=x,Y=y},V)end});Vector.Zero=Vector(0,0)
function V.__add(a,b)return Vector(a.X+b.X,a.Y+b.Y)end
function V.__sub(a,b)return Vector(a.X-b.X,a.Y-b.Y)end
function V.__mul(a,b)return Vector(a.X*b,a.Y*b)end
function V:Resized(n)local d=math.sqrt(self.X*self.X+self.Y*self.Y);return d==0 and Vector(0,0) or Vector(self.X*n/d,self.Y*n/d)end
function V:Distance(b)local a=self-b;return math.sqrt(a.X*a.X+a.Y*a.Y)end
EntityRef=function(e)return {Entity=e}end
local players,spawned={},{}
local game={GetNumPlayers=function()return #players end}
Game=function()return game end
Isaac={GetPlayer=function(i)return players[i+1]end,GetEntityVariantByName=function()return 17730 end,
 GetItemIdByName=function(name)return name=='Undead Bird' and 737 or 999 end,
 GetItemConfig=function()return {GetCollectibles=function()return {Size=1}end}end}
function Isaac.Spawn(_,variant,_,position,velocity,owner)
 assert(variant==17730)
 local e={Position=position,Velocity=velocity,FrameCount=20,data={},owner=owner,alive=true}
 function e:GetData()return self.data end
 function e:Exists()return self.alive end
 function e:Remove()self.alive=false end
 spawned[#spawned+1]=e;return e
end
local function player(seed)
 local p={InitSeed=seed,Position=Vector(0,0),kind=PlayerType.PLAYER_EVE,hits=0}
 function p:GetPlayerType()return self.kind end
 function p:HasCollectible(id)return id==737 end
 function p:RemoveCollectible()end
 function p:GetTrinket()return 0 end
 function p:Exists()return true end
 function p:ToPlayer()return self end
 function p:TakeDamage()self.hits=self.hits+1 end
 return p
end
local callbacks={};local mod={AddCallback=function(_,id,f)callbacks[id]=callbacks[id] or {};table.insert(callbacks[id],f)end}
local tracker={data={},Save=function()end};local setups={ApplySetup=function()end}
local m=dofile('scripts/character_mechanics.lua');m:Init(mod,tracker,setups)
local items=dofile('scripts/custom_items.lua');items:Init(mod,tracker,m,setups)
local function call(id,...)for _,f in ipairs(callbacks[id] or {})do f(nil,...)end end
local function start(continued)items:OnGameStart(continued);m:OnGameStart(continued)end
local checks=0
local function test(label,f)f();checks=checks+1;print('PASS MOCK COMPOSITION: '..label)end
local p=player(17);players={p};start(false)
test('fresh Eve starts with no hostile room budget',function()assert(not m:State(p).birdRooms);items:Update(p);assert(#spawned==0)end)
test('damage callback persists budget through real Mechanics Save',function()call(ModCallbacks.MC_ENTITY_TAKE_DMG,p);assert(tracker.data._characterMechanics.players['0'].birdRooms==2)end)
test('update spawns once per live effect',function()items:Update(p);items:Update(p);assert(#spawned==1 and spawned[1].data.twistedOwner==p)end)
test('room replacement discards cache and new bird pursues',function()spawned[1]:Remove();call(ModCallbacks.MC_POST_NEW_ROOM);assert(m:State(p).birdRooms==1 and items.birds['17']==nil);items:Update(p);local e=spawned[2];assert(e and e.Position.X==50);call(ModCallbacks.MC_POST_EFFECT_UPDATE,e);assert(e.Position.X<50 and e.Velocity.X==0)end)
test('saved nextroom budget reloads without OnGameStart decrement',function()
 -- Explicit serialized boundary copy; neither Lua tables nor entity handles are save data.
 tracker.data._characterMechanics={players={['0']={type=p.kind,rooms=0,birdRooms=1}},cleared={}}
 for _,e in ipairs(spawned)do e:Remove()end
 start(true);assert(m:State(p).birdRooms==1);local before=#spawned;items:Update(p);assert(#spawned==before+1)
end)
test('reloaded bird uses live owner and can request contact damage',function()local e=spawned[#spawned];e.Position=Vector(1,0);call(ModCallbacks.MC_POST_EFFECT_UPDATE,e);assert(p.hits==1 and e.data.twistedOwner==p)end)
test('room callback after Continue consumes budget (ordering characterization)',function()call(ModCallbacks.MC_POST_NEW_ROOM);assert(m:State(p).birdRooms==0);local e=spawned[#spawned];call(ModCallbacks.MC_POST_EFFECT_UPDATE,e);assert(not e:Exists());local before=#spawned;items:Update(p);assert(#spawned==before)end)
test('fresh restart discards prior saved bird budget',function()m:State(p).birdRooms=2;m:Save();start(false);assert(not m:State(p).birdRooms);local before=#spawned;items:Update(p);assert(#spawned==before)end)
test('Twisted restart also clears mechanics bird budget',function()m:State(p).birdRooms=2;m:Save();tracker.data._twistedRestart=true;start(false);assert(not m:State(p).birdRooms)end)
test('two players have independently saved room budgets',function()players[2]=player(18);call(ModCallbacks.MC_ENTITY_TAKE_DMG,players[2]);assert(m:State(players[2]).birdRooms==2 and not m:State(p).birdRooms);items:Update(players[2]);assert(spawned[#spawned].data.twistedOwner==players[2])end)
print(checks..' new bird lifecycle composition contracts PASS; native Continue callback ordering, key reset and nextroom damage remain UNVERIFIED')
