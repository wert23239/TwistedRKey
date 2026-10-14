-- Approved Beast-LAST fallback contracts; mocked callbacks, NOT gameplay.
local callbacks={}
ModCallbacks={MC_POST_NEW_LEVEL=1,MC_POST_GAME_STARTED=2,MC_POST_UPDATE=3,MC_PRE_MEGA_SATAN_ENDING=4}
LevelStage={STAGE8=13}
local stage,players,marks=1,1,{}
local notices,resets=0,0
local player={GetPlayerType=function()return 6 end}
Isaac={GetPlayer=function()return player end,DebugString=function()end}
Game=function()return {GetNumPlayers=function()return players end,GetLevel=function()return {GetStage=function()return stage end}end,GetHUD=function()return {ShowItemText=function()notices=notices+1 end}end}end
local tracker={REQUIRED_CHECKS={'moms_heart','isaac_boss','satan','boss_rush','blue_baby','the_lamb','mega_satan','hush','delirium','mother','the_beast'},GetCharacterMarks=function()return marks end}
function tracker:AreAllBossesKilled()for _,id in ipairs(self.REQUIRED_CHECKS)do if not marks[id]then return false end end;return true end
local key={OnUseItem=function(_,p,arena)assert(p==player and arena==false,'only normal Home reset, never experimental arena reset');resets=resets+1;stage=1 end}
local mod={AddCallback=function(_,id,fn)callbacks[id]=fn end}
local b=dofile('scripts/beast_reset.lua');b:Init(mod,tracker,key)
callbacks[1]();callbacks[3]();assert(resets==0,'non-Home floors not gated')
stage=13;players=0;callbacks[1]();callbacks[3]();assert(resets==0,'empty player list safe')
players=1;callbacks[1]();assert(b.pending and resets==0,'early Home queues outside level callback')
callbacks[3]();callbacks[3]();assert(resets==1 and notices==1 and not b.pending,'exactly one deferred ordinary reset')
assert(callbacks[4]()==true,'incomplete chain suppresses Mega ending')
for _,id in ipairs(tracker.REQUIRED_CHECKS)do if id~='the_beast'then marks[id]=true end end
stage=13;callbacks[1]();callbacks[3]();assert(resets==1 and not b.pending,'ten checks permit Beast-last Home')
assert(callbacks[4]()==true,'ten checks still not complete')
marks.the_beast=true;assert(callbacks[4]()==nil,'full chain leaves normal victory untouched')
-- Continue/start cannot inherit stale pending state when ten prerequisites exist.
b.pending=true;callbacks[2]();callbacks[3]();assert(resets==1 and not b.pending)
marks.mother=nil;callbacks[2]();callbacks[3]();assert(resets==2,'continued early Home is gated again')
print('PASS: approved Home-only Beast-LAST gate, player guard, deferred once-only ordinary reset, ten-check admission, continue/start reevaluation, complete normal victory; mock only')
