-- HP-up / red-hit ordering regression. Mock hypotheses, NOT a native reproduction.
Game=function()return {}end
package.loaded['scripts.saved_designs']={}
CacheFlag={CACHE_DAMAGE=1};PlayerType={PLAYER_BLUEBABY=4}
local state={};local p={red=6,maxRed=6,counter=0}
function p:HasCollectible(id)return id==735 end
function p:GetHearts()return self.red end
function p:GetBloodLustCounter()return self.counter end
function p:AddCacheFlags()end
function p:EvaluateItems()end
function p:GetPlayerType()return 6 end
local items=dofile('scripts/custom_items.lua')
items.ready=true;items.ids={needle=735,bird=737};items.tracker={data={}}
items.mechanics={State=function()return state end,FloorToken=function()return '1' end,Save=function()end}
local function reset()state={};p.red=6;p.maxRed=6;p.counter=0;items:Update(p)end
-- Dog Food adds a heart container and fills red health (simulated grant only).
reset();p.maxRed=8;p.red=8;items:Update(p);items:BeforeDamage(p)
p.red=7;p.counter=1;items:Update(p)
assert(state.needleGain==0.5,'HP-up followed by observed red hit should invert Bloody Lust')
print('PASS MOCK: filled HP-up then same-update red loss/counter increment')
-- Counter can be observed before the corresponding red-health loss.
-- This ordering is a hypothesis to investigate, not the user's proven root cause.
reset();p.maxRed=8;p.red=8;items:Update(p);items:BeforeDamage(p)
p.counter=1;items:Update(p);p.red=7;items:Update(p)
assert(state.needleGain==0.5,'HP-up then counter-first red hit must not lose the penalty')
print('PASS MOCK: HP-up then counter-first red hit')
