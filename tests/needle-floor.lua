-- Deterministic engine-order regression; not an in-game test.
Game=function()return {}end
package.loaded['scripts.saved_designs']={}
CacheFlag={CACHE_DAMAGE=1};PlayerType={PLAYER_BLUEBABY=4}
local floor=1; local saves=0;local s={}
local p={red=6,counter=0}
function p:HasCollectible(id)return id==735 end
function p:GetHearts()return self.red end
function p:GetBloodLustCounter()return self.counter end
function p:AddCacheFlags()end
function p:EvaluateItems()end
function p:GetPlayerType()return 6 end
local items=dofile('scripts/custom_items.lua')
items.ready=true;items.ids={needle=735,bird=737};items.tracker={data={}};items.mechanics={State=function()return s end,FloorToken=function()return tostring(floor)end,Save=function()saves=saves+1 end}
items:Update(p);p.red=5;p.counter=1;items:Update(p);assert(s.needleGain==0.5)
p.red=6;items:Update(p);p.red=5;p.counter=2;items:Update(p);assert(math.abs(s.needleGain-1.2)<1e-8)
-- New floor observed before the engine resets its old counter.
floor=2;items:Update(p);assert(s.needleGain==0 and s.needleCounter==2)
p.counter=0;items:Update(p);assert(s.needleCounter==0,'late engine counter reset rebased')
p.red=4;p.counter=1;items:Update(p);assert(s.needleGain==0.5,'floor-two first hit penalized')
floor=3;items:Update(p);p.counter=0;items:Update(p)
-- Health loss observed one tick before the corresponding counter increment.
p.red=3;items:Update(p);p.counter=1;items:Update(p);assert(s.needleGain==0.5,'split-tick health/counter ordering')
-- Soul-only increment must not add a red-hit penalty.
p.counter=2;items:Update(p);assert(s.needleGain==0.5)
assert(saves>=3,'floor reset persisted')
-- Twisted reset must clear the penalty even if an engine warp reuses a floor token.
items.tracker.data._twistedCycles=1;items:Update(p);assert(s.needleGain==0)
p.counter=0;items:Update(p);p.red=2;p.counter=1;items:Update(p);assert(s.needleGain==0.5)
-- On continue the same saved state/token must keep its existing penalty.
local saved=s;items:Update(p);assert(s==saved and s.needleGain==0.5)
s.needleFloor=tostring(floor);items:Update(p);assert(s.needleGain==0.5,'legacy continued penalty retained')
print('PASS: first/healed hit, delayed floor-two/three counter resets, split-tick red hit, soul-only exclusion, floor persistence, same-floor Twisted reset, retained continue state')
