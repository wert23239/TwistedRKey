-- Isolated rendering contract tests: not pixel placement or actual menu evidence.
local renders, callbacks = {}, {}
local V = {}; V.__index=V
function Vector(x,y) return setmetatable({X=x,Y=y},V) end
function V.__add(a,b) return Vector(a.X+b.X,a.Y+b.Y) end
function V.__mul(a,b) return Vector(a.X*b,a.Y*b) end
Sprite=function() return {Load=function()end,Play=function()end,Render=function(self,pos) renders[#renders+1]={pos=pos,scale=self.Scale} end} end
ModCallbacks={MC_POST_COMPLETION_MARKS_RENDER=1,MC_POST_RENDER=2}
MainMenuType={CHARACTER=7};local menu=7;MenuManager={GetActiveMenu=function() if menu=='game' then error('gameplay') end return menu end}
local paused,numPlayers=false,0
Game=function()return {IsPaused=function()return paused end,GetNumPlayers=function()return numPlayers end}end
Isaac={GetPlayer=function()return {GetPlayerType=function()return 6 end}end,GetScreenWidth=function()return 640 end}
local marks={};local tracker={data={_completedChains={['6']={hard=true}}},CanonicalType=function(_,t)return t==8 and 6 or t end,GetCharacterMarks=function(_,t)return t==6 and marks or {} end}
local mod={AddCallback=function(_,id,fn) callbacks[id]=callbacks[id] or {};table.insert(callbacks[id],fn) end}
local o=dofile('scripts/completion_overlay.lua');o:Init(mod,tracker)
local function render(t) renders={};for _,fn in ipairs(callbacks[1])do fn(nil,nil,Vector(100,50),Vector(2,3),t)end end
render(6);assert(#renders==1 and renders[1].pos.X==184 and renders[1].scale.X==4,'permanent character menu badge')
render(9);assert(#renders==0,'unearned character cannot inherit badge')
render(8);assert(#renders==1,'canonical revived character badge')
menu=2;render(6);assert(#renders==0,'badge only on character menu')
menu='game';paused=true;numPlayers=1;render(6);assert(#renders==0,'earned badge does not create live checks after death')
for _,m in ipairs(o.marks)do marks[m.id]=true end
render(6);assert(#renders==12,'eleven living checks plus full-chain pause glyph')
assert(renders[12].pos.X==178 and renders[12].scale.Y==6,'full-chain pause glyph scaled')
render(9);assert(#renders==0,'pause marks remain character isolated')
marks.the_beast=nil;render(6);assert(#renders==10,'Beast-last missing mark withholds full-chain glyph')
marks={it_lives=true};render(6);assert(#renders==1,'It Lives canonical display alias')
paused=false;render(6);assert(#renders==0,'no overlay in active unpaused game')
print('PASS: menu badge earned/canonical/character-isolated/menu-only; pause 11 checks/full glyph, Beast-last incomplete, It Lives alias, gameplay menu exception guarded; mock only')
