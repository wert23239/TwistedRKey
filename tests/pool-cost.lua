local removed={}
local pool={RemoveCollectible=function(_,id)removed[id]=true end}
Game=function()return {GetItemPool=function()return pool end}end
SFXManager=function()return {}end
Isaac={GetItemConfig=function()return {GetCollectibles=function()return {Size=739}end}end}
local p={items={[51]=1,[157]=1,[733]=1,[735]=1},GetPlayerType=function()return 6 end}
function p:GetCollectibleNum(id)return self.items[id] or 0 end
local key=dofile('scripts/twisted_r_key.lua')
key.GetItemId=function()return 733 end
key.bossTracker={data={_poolBaseline={['6']={['157']=true,['735']=true}}},CanonicalType=function(_,t)return t end}
key:KeepSpentItemsOutOfPool(p)
assert(removed[51] and not removed[157] and not removed[735] and not removed[733],'pool cost excludes restored kit and consumed key')
assert(key.bossTracker.data._spentItems['51'])
removed={};key:OnGameStart(true);assert(removed[51],'continue reapplies spent-item exclusions')
print('PASS: lost acquired items stay out of pool; baseline kit/key excluded; continue reapplies exclusions')
