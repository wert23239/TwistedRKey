-- Run with an isolated Lua runtime; never touches actual game save/awards.
local saved
local function copy(t) if type(t)~='table' then return t end local n={} for k,v in pairs(t) do n[k]=copy(v) end return n end
package.preload.json=function()return {encode=function(t)saved=copy(t);return 'save'end,decode=function()return copy(saved)end}end
EntityType={ENTITY_MOM=1,ENTITY_MOMS_HEART=2,ENTITY_ISAAC=3,ENTITY_SATAN=4,ENTITY_THE_LAMB=5,ENTITY_MEGA_SATAN=6,ENTITY_HUSH=7,ENTITY_DELIRIUM=8}
ModCallbacks={MC_POST_NPC_DEATH=1,MC_PRE_SPAWN_CLEAN_AWARD=2,MC_POST_GAME_END=3,MC_POST_COMPLETION_MARK_GET=4}
PlayerType={PLAYER_LAZARUS2=8,PLAYER_LAZARUS=9,PLAYER_ESAU=10,PLAYER_JACOB=11}
Difficulty={DIFFICULTY_HARD=1};RoomType={ROOM_BOSSRUSH=17}
local game={Difficulty=1};function game:GetNumPlayers()return 1 end;function game:GetSeeds()return {GetStartSeedString=function()return 'TEST' end}end;function game:GetRoom()return {GetType=function()return 1 end}end
Game=function()return game end
local player={GetPlayerType=function()return 0 end};Isaac={GetPlayer=function()return player end,DebugString=function()end}
local callbacks={};local mod={HasData=function()return saved~=nil end,LoadData=function()return 'save'end,SaveData=function()end,AddCallback=function(_,id,fn)callbacks[id]=fn end}
local t=dofile('scripts/boss_tracker.lua');t:Init(mod);t:OnGameStart(false)
t.data.the_lamb=true;t:Save();assert(not t:GetCharacterMarks(0).the_lamb,'legacy marks never become chain checks')
t:MarkBossKilled('it_lives');assert(t:GetCharacterMarks(0).moms_heart);assert(not t.data._completedChains)
callbacks[3](nil,false);assert(t:GetCharacterMarks(0).moms_heart,'non-terminal game-end preserves living chain')
t:OnGameStart(true);assert(t:GetCharacterMarks(0).moms_heart,'quit/continue preserves checks')
t:ResetRunData();assert(t:GetCharacterMarks(0).moms_heart,'Twisted reset preserves checks')
t.data._twistedCycles=1;for _,id in ipairs(t.REQUIRED_CHECKS)do t:MarkBossKilled(id)end
assert(t.data._completedChains['0'].hard and t:IsCharacterChainComplete(0));assert(#t.REQUIRED_CHECKS==11)
callbacks[3](nil,true);assert(next(t:GetCharacterMarks(0))==nil);assert(t.data._completedChains['0'],'death preserves earned badge')
t:OnGameStart(false);assert(next(t:GetCharacterMarks(0))==nil);assert(t.data._completedChains['0'],'fresh run retains badge')
game.Difficulty=0;t:OnGameStart(false);for _,id in ipairs(t.REQUIRED_CHECKS)do t:MarkBossKilled(id,9)end
assert(not t.data._completedChains['9'],'normal mode cannot award badge')
game.Difficulty=1;t:OnGameStart(false);t.data._twistedCycles=1;for _,id in ipairs(t.REQUIRED_CHECKS)do t:MarkBossKilled(id,8)end
assert(t.data._completedChains['9'],'revived Lazarus uses original character badge')
t:OnGameStart(false);for i,id in ipairs(t.REQUIRED_CHECKS)do t:MarkBossKilled(id,i%2==0 and 0 or 9)end
assert(not t:IsCharacterChainComplete(0) and not t:IsCharacterChainComplete(9),'separate characters cannot combine marks')
print('PASS: 11 hard-only checks, legacy isolation, continue/key persistence, death/new-run reset, permanent badges, Lazarus identity, no cross-character aggregation')
-- Additional award lifecycle contracts: exercise the actual native callback wiring.
ModCallbacks.MC_POST_COMPLETION_EVENT=5
callbacks={};t:Init(mod);game.Difficulty=1;t:OnGameStart(false)
for event,id in pairs(t.COMPLETION_MAP)do if id~='the_beast' then callbacks[5](nil,event) end end
callbacks[5](nil,7);callbacks[5](nil,11)
assert(t:GetChainCount(0)==10 and not t:IsCharacterChainComplete(0),'Greed and Dogma not required; Beast is last')
assert(not (t.data._completedChains or {})['0'] or t.data._completedChains['0'].hard,'existing badge remains permanent')
-- Use a never-awarded character to avoid confusing old permanent awards with new ones.
player.GetPlayerType=function()return 20 end;t:OnGameStart(false)
for event in pairs(t.COMPLETION_MAP)do callbacks[5](nil,event)end
assert(t:GetChainCount(20)==11 and not (t.data._completedChains or {})['20'],'all checks without a Twisted cycle do not award')
t:OnGameStart(false);t.data._twistedCycles=1
for event,id in pairs(t.COMPLETION_MAP)do if id~='the_beast' then callbacks[5](nil,event) end end
assert(not (t.data._completedChains or {})['20'],'ten checks do not award')
callbacks[5](nil,14)
assert(t.data._completedChains['20'].checks==11 and t.data._completedChains['20'].seed=='TEST','native Beast finale awards Hard chain')
t:Save();t.data={};t:Load();assert(t.data._completedChains['20'].hard,'cold save reload retains permanent award')
callbacks[3](nil,true);assert(next(t:GetCharacterMarks(20))==nil and t.data._completedChains['20'].hard,'terminal death clears marks not badge')
t:OnGameStart(false);assert(t.data._completedChains['20'].hard and t:GetChainCount(20)==0,'new run does not borrow awarded-chain checks')
print('PASS: native callback mapping, ignored Greed/Dogma events, Beast-last award, no-cycle rejection, cold badge reload, death/new-run permanent badge; mock only')
