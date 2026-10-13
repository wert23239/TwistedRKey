PlayerType=setmetatable({PLAYER_SAMSON=6},{__index=function(_,k)return k end});CollectibleType=setmetatable({NUM_COLLECTIBLES=733},{__index=function(_,k)return k end});TrinketType={NUM_TRINKETS=190}
Isaac={GetItemConfig=function()return {GetCollectibles=function()return {Size=740}end}end}
local p={items={[51]=1,[735]=1},removed=0}
function p:HasCollectible(id)return id==157 or self.items[id]~=nil end
function p:GetCollectibleNum(id)return self.items[id] or 0 end
function p:RemoveCollectible(id)self.removed=self.removed+1;self.items[id]=nil end
function p:HasTrinket(id)return id==53 end
function p:TryRemoveTrinket()return false end
function p:GetMaxHearts()return 6 end;function p:GetSoulHearts()return 0 end;function p:GetBoneHearts()return 0 end;function p:GetPlayerType()return 6 end
function p:AddMaxHearts()end;function p:AddSoulHearts()end;function p:AddBoneHearts()end;function p:AddBlackHearts()end;function p:AddHearts()end
local s=dofile('scripts/character_setups.lua');s.StripAllItems(p)
assert(p.removed==2 and p:HasCollectible(157),'remove acquired/custom copies while preserving unremovable innate item')
print('PASS: bounded strip handles innate Bloody Lust, custom IDs beyond vanilla count, and non-removable Tick')
