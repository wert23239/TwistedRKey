-- Actual production callbacks under mocks; NOT engine/gameplay acceptance.
local function constants() local n=0;return setmetatable({},{__index=function(t,k)n=n+1;rawset(t,k,n);return n end})end
EvaluateStatStage=constants();AddHealthType=constants();ModCallbacks=constants();PlayerType=constants();FamiliarVariant=constants();EntityType=constants()
package.loaded['scripts.saved_designs']={}
local V={};V.__index=V
Vector=setmetatable({},{__call=function(_,x,y)return setmetatable({X=x,Y=y},V)end});Vector.Zero=Vector(0,0)
function V.__add(a,b)return Vector(a.X+b.X,a.Y+b.Y)end
function V.__sub(a,b)return Vector(a.X-b.X,a.Y-b.Y)end
function V.__mul(a,b)return Vector(a.X*b,a.Y*b)end
function V:Resized(n)local d=math.sqrt(self.X*self.X+self.Y*self.Y);if d==0 then return Vector(0,0)end;return Vector(self.X*n/d,self.Y*n/d)end
function V:Distance(b)local a=self-b;return math.sqrt(a.X*a.X+a.Y*a.Y)end

EntityRef=function(e)return {Entity=e}end
Game=function()return {}end
Isaac={GetEntityVariantByName=function()return 17730 end}
local callbacks={};local mod={AddCallback=function(_,id,f,filter)callbacks[id]={f=f,filter=filter}end}
local state={birdRooms=2};local saves=0
local items=dofile('scripts/custom_items.lua')
items:Init(mod,{data={}},{State=function()return state end,Save=function()saves=saves+1 end},{ApplySetup=function()end})
items.ready=true;items.ids.bird=737
local p={Position=Vector(0,0),hits={}}
function p:Exists()return true end
function p:HasCollectible(id)return id==737 end
function p:TakeDamage(a,flags,source,cooldown)self.hits[#self.hits+1]={a,flags,source,cooldown}end
local e={Position=Vector(100,0),Velocity=Vector(0,0),FrameCount=1,data={twistedOwner=p}}
function e:GetData()return self.data end
function e:Remove()self.removed=true end
local update=callbacks[ModCallbacks.MC_POST_EFFECT_UPDATE]
local checks=0
local function test(label,f)f();checks=checks+1;print('PASS MOCK: '..label)end
test('registered custom variant filter',function()assert(update.filter==17730)end)
test('custom effect advances despite engine zero velocity',function()update.f(nil,e);assert(e.Position.X==98.9 and e.data.twistedBirdVelocity.X==-1.1 and e.Velocity.X==0 and #p.hits==0);update.f(nil,e);assert(e.Position.X<97.1 and e.data.twistedBirdVelocity.X<-1.8)end)
test('outside post-movement distance gate does not damage',function()e.Position=Vector(20,0);e.FrameCount=20;update.f(nil,e);assert(#p.hits==0)end)
test('inside gate only scheduled frames damage',function()e.Position=Vector(10,0);e.FrameCount=19;update.f(nil,e);assert(#p.hits==0);e.FrameCount=20;update.f(nil,e);assert(#p.hits==1)end)
test('native damage request amount/source/cooldown',function()local h=p.hits[1];assert(h[1]==1 and h[2]==0 and h[3].Entity==e and h[4]==30)end)
test('expired state removes effect',function()state.birdRooms=0;update.f(nil,e);assert(e.removed);state.birdRooms=2 end)
test('missing owner removes effect',function()e.removed=false;e.data.twistedOwner=nil;update.f(nil,e);assert(e.removed);e.data.twistedOwner=p end)
test('friendly Dead Bird suppression uses owner custom item',function()local familiar={Player=p,Remove=function(self)self.removed=true end};local cb=callbacks[ModCallbacks.MC_FAMILIAR_UPDATE];assert(cb.filter==FamiliarVariant.DEAD_BIRD);cb.f(nil,familiar);assert(familiar.removed);familiar.removed=false;familiar.Player={HasCollectible=function()return false end};cb.f(nil,familiar);assert(not familiar.removed)end)
print(checks..' production bird callback contracts PASS; mocked movement/damage APIs, NOT native acceptance')
