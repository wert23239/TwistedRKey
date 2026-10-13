CollectibleType={COLLECTIBLE_CLICKER=482,COLLECTIBLE_BREAKFAST=25}
ModCallbacks={MC_POST_GAME_STARTED=1,MC_POST_NEW_LEVEL=2,MC_POST_GET_COLLECTIBLE=3,MC_POST_PICKUP_INIT=4,MC_POST_PICKUP_UPDATE=5,MC_PRE_ADD_COLLECTIBLE=6,MC_PRE_USE_ITEM=7,MC_POST_PEFFECT_UPDATE=8}
EntityType={ENTITY_PICKUP=5};PickupVariant={PICKUP_COLLECTIBLE=100}
local removed, callbacks={},{}
Game=function()return {GetItemPool=function()return {RemoveCollectible=function(_,id)removed[id]=true end}end}end
local mod={AddCallback=function(_,id,f)callbacks[id]=f end}
local e=dofile('scripts/item_exclusions.lua');e:Init(mod)
callbacks[1]();assert(removed[482]);removed={};callbacks[2]();assert(removed[482])
assert(callbacks[3](nil,482)==25 and callbacks[3](nil,51)==nil)
assert(callbacks[6](nil,482)==false and callbacks[6](nil,51)==nil)
local pickup={SubType=482,Morph=function(self,_,_,id)self.SubType=id end};callbacks[4](nil,pickup);assert(pickup.SubType==25)
pickup.SubType=482;callbacks[5](nil,pickup);assert(pickup.SubType==25)
assert(callbacks[7]()==true)
local p={HasCollectible=function()return true end,RemoveCollectible=function(_,id)assert(id==482);removed.inventory=true end};callbacks[8](nil,p);assert(removed.inventory)
print('PASS: Clicker pool start/reset, selection fallback, direct grant rejection, spawned/rerolled pedestal replacement, use cancellation, held-item removal')
