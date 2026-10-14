-- QA ONLY: guarded slot3; real external Q/Ctrl input required, never fake input.
local slot,boot,phase,tick=nil,0,'boot',0
local before,used,dropFrames={},nil,0
local lastQ=false
local function log(l,a) Isaac.DebugString('[INPUT QA] '..l..' '..require('json').encode(a))end
local function snap(p) local s=CharacterMechanics:State(p);return {type=p:GetPlayerType(),pending=s.pending,effect=s.effect,pill=p:GetPill(0),speed=p.MoveSpeed,range=p.TearRange,tears=p.MaxFireDelay,luck=p.Luck,shot=p.ShotSpeed,purple=p:HasTrinket(5),t0=p:GetTrinket(0),t1=p:GetTrinket(1),stage=Game():GetLevel():GetStage()}end
local function report(l,ok,e,a)log('ASSERT',{label=l,result=ok and 'PASS' or 'FAIL',expected=e,actual=a})end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw;log('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_USE_PILL,function(_,effect,p,flags)used=effect;log('native-pill-use',{effect=effect,flags=flags,actual=snap(p)})end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if slot~=3 or phase=='done' then return end
 local p=Isaac.GetPlayer(0);tick=tick+1
 if phase=='boot' then if tick==10 then if Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then phase='done';log('STOP',{reason='not Hard single player'});return end;Isaac.ExecuteCommand('restart 2');phase='cain-init';tick=0 end
 elseif phase=='cain-init' and tick==60 then before=snap(p);report('Cain pending before raw input',before.type==2 and before.pending and before.pill>0,'Cain pending real pill',before);phase='cain-input';tick=0;log('READY',{action='press Q once',before=before,seed=Game():GetSeeds():GetStartSeedString()})
 elseif phase=='cain-input' then
  local q=Input.IsButtonPressed(Keyboard.KEY_Q,0)
  if q~=lastQ then log('raw-Q',{pressed=q,controller=p.ControllerIndex,controls=p.ControlsEnabled,rawAction=Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD,p.ControllerIndex)});lastQ=q end
  if not CharacterMechanics:State(p).pending then local a=snap(p);a.nativeEffect=used;report('raw Q consumes exact negative pill and unlocks',a.pill==0 and used==before.effect,'empty pill; native exact selected negative effect; pending false',a);log('negative-effect-stats',{before=before,after=a});phase='cain-release';tick=0 end
 elseif phase=='cain-release' then
  if not Input.IsButtonPressed(Keyboard.KEY_Q,0) and tick>60 then Isaac.ExecuteCommand('stage 2');phase='cain-floor';tick=0 end
 elseif phase=='cain-floor' and tick==60 then local a=snap(p);report('new engine floor re-locks after raw consumption',a.stage==2 and a.pending and a.pill>0,'floor2 pending pill',a);Isaac.ExecuteCommand('restart 3');phase='judas-init';tick=0
 elseif phase=='judas-init' and tick==60 then local a=snap(p);report('Judas has real Purple Heart before hold',a.type==3 and a.purple and (a.t0==5 or a.t1==5),'actual Purple Heart slot',a);phase='judas-hold';tick=0;log('READY',{action='hold LEFT CTRL for >=2 seconds then release',actual=a})
 elseif phase=='judas-hold' then
  local held=Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0)
  if held then dropFrames=dropFrames+1 end
  if dropFrames>=90 and not held then local a=snap(p);a.rawHoldFrames=dropFrames;report('raw held-drop retains actual Purple Heart',a.purple and (a.t0==5 or a.t1==5),'Purple Heart retained after >=90 frames raw Ctrl',a);phase='done';log('DONE',{reason='raw Cain Q and Judas held Ctrl; debug floor transition; not organic combat'})end
 end
 if tick%300==0 then log('WAIT',{phase=phase,tick=tick,dropFrames=dropFrames,actual=snap(p)})end
end)
