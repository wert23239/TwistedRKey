-- Run in Lua 5.3+ (or Lupa); this checks state transitions, not engine rendering.
PlayerType={PLAYER_MAGDALENE=1,PLAYER_CAIN=2,PLAYER_JUDAS=3}
TrinketType={TRINKET_PURPLE_HEART=5}
CollectibleType={COLLECTIBLE_YUM_HEART=45,COLLECTIBLE_YUCK_HEART=639,COLLECTIBLE_LUCKY_FOOT=46,COLLECTIBLE_BOOK_OF_BELIAL=34,COLLECTIBLE_MOMS_PURSE=139}
ActiveSlot={SLOT_POCKET=2}
PillEffect={PILLEFFECT_SPEED_DOWN=13,PILLEFFECT_RANGE_DOWN=11,PILLEFFECT_TEARS_DOWN=15,PILLEFFECT_LUCK_DOWN=17,PILLEFFECT_SHOT_SPEED_DOWN=47,PILLEFFECT_AMNESIA=25,PILLEFFECT_PARALYSIS=22,PILLEFFECT_RETRO_VISION=37}
PillColor={PILL_BLUE_BLUE=1};UseFlag={USE_NOANIM=1}
ButtonAction={ACTION_PILLCARD=1,ACTION_DROP=2};InputHook={GET_ACTION_VALUE=2,IS_ACTION_TRIGGERED=1}
PickupVariant={PICKUP_TAROTCARD=300,PICKUP_PILL=70,PICKUP_TRINKET=350}
ModCallbacks={MC_POST_PEFFECT_UPDATE=1,MC_PRE_SPAWN_CLEAN_AWARD=2,MC_POST_NEW_LEVEL=3,MC_PRE_USE_ITEM=4,MC_INPUT_ACTION=5,MC_PRE_PICKUP_COLLISION=6,MC_POST_RENDER=7}
local stage, roomIndex, pressed=1,0,false
local paused=false
local players={};local callbacks={}
local game={IsPaused=function()return paused end,GetNumPlayers=function()return #players end,GetLevel=function()return {
 GetDungeonPlacementSeed=function()return stage*100 end,GetStage=function()return stage end,GetStageType=function()return 0 end,GetCurrentRoomIndex=function()return roomIndex end}end,
 GetRoom=function()return {GetSpawnSeed=function()return roomIndex+1000 end}end,
 GetHUD=function()return {ShowItemText=function()end}end}
function Game()return game end
Isaac={GetPlayer=function(i)return players[i+1]end,GetItemConfig=function()return {GetCollectible=function()return {MaxCharges=4}end}end}
Input={IsActionTriggered=function()return pressed end}
local function player(kind,red,soul,rotten)
 local p={InitSeed=#players+1,ControllerIndex=#players,kind=kind,red=red or 0,soul=soul or 0,rotten=rotten or 0,max=red or 0,items={},pills={},cards={},trinkets={0,0},active=0}
 function p:ToPlayer()return self end
 function p:GetPlayerType()return self.kind end
 function p:GetHearts()return self.red end
 function p:GetRottenHearts()return self.rotten end
 function p:GetSoulHearts()return self.soul end
 function p:AddHearts(n)self.red=math.max(0,self.red+n);if self.red==0 then self.rotten=0 end end
 function p:AddRottenHearts(n)self.red=self.red+n;self.rotten=self.rotten+n/2 end
 function p:AddSoulHearts(n)self.soul=self.soul+n end
 function p:AddMaxHearts(n)self.max=self.max+n end
 function p:GetActiveItem()return self.active end
 function p:SetPocketActiveItem(id)self.active=id end
 function p:SetActiveCharge(n)self.charge=n end
 function p:HasCollectible(id)return self.items[id]end
 function p:AddCollectible(id)self.items[id]=true end
 function p:HasTrinket(id)return self.trinkets[1]==id or self.trinkets[2]==id end
 function p:AddTrinket(id)self.trinkets[self.trinkets[1]==0 and 1 or 2]=id end
 function p:GetTrinket(i)return self.trinkets[i+1]end
 function p:GetCollectibleRNG()return {RandomInt=function()return 0 end}end
 function p:SetCard(i,id)self.cards[i]=id end
 function p:SetPill(i,id)self.pills[i]=id end
 function p:UsePill(effect)self.lastEffect=effect end
 function p:UseActiveItem(id,flags,slot)callbacks[4](nil,id,nil,self,flags,slot)end
 players[#players+1]=p;return p
end
local maggy=player(1,8,4,0);local cain=player(2,4,0,0);local judas=player(3,2,0,0);local other=player(99,6,0,0)
local saves=0;local tracker={data={},Save=function()saves=saves+1 end}
local mod={AddCallback=function(_,id,f)callbacks[id]=f end}
local setups={ApplySetup=function()end}
local m=dofile('scripts/character_mechanics.lua');m:Init(mod,tracker,setups);m:OnGameStart(false)
assert(maggy.active==639 and maggy.items[45]);assert(cain.items[46]);assert(judas.items[34] and judas.items[139] and judas:HasTrinket(5));assert(next(other.items)==nil)
for i=1,3 do roomIndex=i;m:RoomCleared();m:RoomCleared()end
assert(maggy.rotten==0 and m:State(maggy).rooms==3,'no duplicate-room charge')
roomIndex=4;m:RoomCleared();assert(maggy.rotten==1 and maggy.red==8 and maggy.soul==4,'red conversion preserves health')
for i=5,16 do roomIndex=i;m:RoomCleared()end
assert(maggy.rotten==4 and maggy.red==8)
for i=17,20 do roomIndex=i;m:RoomCleared()end
assert(maggy.rotten==5 and maggy.red==10 and maggy.soul==2 and maggy.max==10,'soul conversion exchanges capacity')
for i=21,24 do roomIndex=i;m:RoomCleared()end
assert(maggy.rotten==6 and maggy.red==12 and maggy.soul==0)
assert(not m:ConvertHeart(maggy),'already rotten gives no extra healing')
assert(m:State(cain).pending and cain.pills[0]==1)
assert(m:BlockInput(cain,0,2)==false and m:BlockInput(cain,2,1)==0)
pressed=true;m:UpdatePlayer(cain)
assert(m:State(cain).pending, 'effect update must not poll trigger edges')
paused=true;callbacks[7]();assert(m:State(cain).pending,'paused render must not consume')
paused=false;cain.ControlsEnabled=false;callbacks[7]();assert(m:State(cain).pending,'disabled controls must not consume')
cain.ControlsEnabled=true;callbacks[7]();pressed=false
assert(m:State(cain).pending and not cain.lastEffect,'render queues only; no native effect in render')
m:UpdatePlayer(cain)
assert(not m:State(cain).pending and cain.pills[0]==0 and cain.lastEffect==13)
assert(not cain.items[654] and next(other.items)==nil,'no False PHD or unrelated player effects')
assert(m:BlockInput(cain,0,1)==nil,'pocket items unlock after taking pill')
m:GiveCainPill(cain,false);assert(not m:State(cain).pending,'no duplicate floor pill')
stage=2;m:GiveCainPill(cain,false);assert(m:State(cain).pending,'new floor locks again')
roomIndex=25;m:RoomCleared();assert(m:State(maggy).rooms==1)
m:OnGameStart(true);assert(m:State(maggy).rooms==1 and m:State(cain).pending,'continue preserves progress')
assert(m:BlockInput(judas,0,2)==false,'sticky Purple Heart');assert(m:BlockInput(judas,1,2)==nil,'Judas can still cycle pocket slots')
assert(callbacks[6](nil,{Variant=300},cain)==true,'cannot replace required pill')
judas.trinkets[2]=35;assert(callbacks[6](nil,{Variant=350},judas)==true,'cannot swap out sticky trinket when full')
assert(callbacks[6](nil,{Variant=300},other)==nil)
-- Render input requests are transient, not save/floor/reset state.
pressed=true;callbacks[7]();pressed=false
assert(m.cainInputRequests[cain.InitSeed], 'render captured edge')
m:OnGameStart(true);m:UpdatePlayer(cain)
assert(m:State(cain).pending, 'Continue must discard queued input edge')
pressed=true;callbacks[7]();pressed=false
stage=3;m:GiveCainPill(cain,false);m:UpdatePlayer(cain)
assert(m:State(cain).pending, 'new floor must discard old-floor input edge')
pressed=true;callbacks[7]();pressed=false
m:Apply(cain,true);m:UpdatePlayer(cain)
assert(m:State(cain).pending, 'key kit restore must discard queued input edge')
print('PASS: 4-room/unique-room trigger, red/soul conversions, all-rotten cap, per-player isolation, negative pill consume/unlock/new-floor/continue, sticky trinket, baseline items. Engine black-heart/half-heart behavior and input timing still require game testing.')
