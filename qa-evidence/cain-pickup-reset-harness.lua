-- QA ONLY slot3 Hard single-player; real engine pickups/raw Q/native key.
local slot,phase,tick,pick,before=nil,'boot',0,nil,nil
local function snap(p) local s=CharacterMechanics:State(p);return {type=p:GetPlayerType(),seed=Game():GetSeeds():GetStartSeedString(),difficulty=Game().Difficulty,pending=s.pending,effect=s.effect,floor=s.floor,pill=p:GetPill(0),card=p:GetCard(0),lucky=p:HasCollectible(46),stage=Game():GetLevel():GetStage(),cycle=BossTracker.data._twistedCycles or 0}end
local function log(l,a)Isaac.DebugString('[CAIN PICKUP QA] '..l..' '..require('json').encode(a))end
local function check(l,ok,e,a)log('ASSERT',{label=l,result=ok and 'PASS' or 'FAIL',expected=e,actual=a})end
local function spawn(p)pick=Isaac.Spawn(EntityType.ENTITY_PICKUP,PickupVariant.PICKUP_TAROTCARD,Card.CARD_FOOL,p.Position,Vector.Zero,nil):ToPickup();pick.Wait=0 end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw;log('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 if slot~=3 then phase='done';log('STOP',{reason='unguarded slot'});return end
 if continued then if (BossTracker.data._twistedCycles or 0)==0 then phase='raw';log('RESUME',snap(Isaac.GetPlayer(0))) else phase='continue' end;tick=0 elseif phase~='init' then phase='boot';tick=0 else tick=0 end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION,function(_,pickup,collider)
 if phase=='locked' or phase=='unlocked' then log('native-pickup-collision',{phase=phase,variant=pickup.Variant,subtype=pickup.SubType,player=collider:ToPlayer()~=nil})end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if slot~=3 or phase=='done' then return end;tick=tick+1;local p=Isaac.GetPlayer(0)
 if phase=='raw' and tick%30==0 then local a=snap(p);a.rawQ=Input.IsButtonPressed(Keyboard.KEY_Q,0);a.trigger=Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD,p.ControllerIndex);a.controls=p.ControlsEnabled;a.controller=p.ControllerIndex;a.ready=CharacterMechanics.ready;log('input-observe',a)end
 if phase=='continue' and tick==60 then local a=snap(p);check('cold Continue retains Cain reset pending kit',a.type==2 and a.difficulty==1 and a.pending and a.pill>0 and a.card==0 and a.lucky and a.stage==1 and a.cycle==1,'HardCain stage1 cycle1 pending pill LuckyFoot; compare seed/effect/floor with prior log',a);before=a;phase='done';log('DONE',{reason='read-only cold Continue; external Q follow-up allowed'})
 elseif phase=='boot' and tick==10 then
  if Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then phase='done';log('STOP',{reason='not Hard single player'});return end
  phase='init';tick=0;Isaac.ExecuteCommand('restart 2')
 elseif phase=='init' and tick==60 then before=snap(p);check('fresh pending kit',before.type==2 and before.pending and before.pill>0 and before.lucky,'Cain pending pill LuckyFoot',before);spawn(p);phase='locked';tick=0
 elseif phase=='locked' then
  if pick and pick:Exists() then pick.Position=p.Position;pick.Velocity=Vector.Zero end
  if tick==60 then local a=snap(p);a.pickupExists=pick and pick:Exists();check('native locked card collision rejected',a.pickupExists and a.pending and a.card==0 and a.pill==before.pill,'real Fool remains; pending pill unchanged',a);phase='raw';tick=0;log('READY',{action='external Q once then release',actual=a})end
 elseif phase=='raw' and not CharacterMechanics:State(p).pending then phase='release';tick=0;log('consumed',snap(p))
 elseif phase=='release' and tick>60 and not Input.IsButtonPressed(Keyboard.KEY_Q,0) then
  if pick and pick:Exists() then pick:Remove()end;spawn(p);phase='unlocked';tick=0
 elseif phase=='unlocked' then
  if pick and pick:Exists() then pick.Position=p.Position;pick.Velocity=Vector.Zero end
  if tick==90 then local a=snap(p);a.pickupExists=pick and pick:Exists();check('native unlocked card pickup succeeds',not a.pickupExists and not a.pending and a.card==Card.CARD_FOOL,'actual Fool acquired after Q',a)
   local id=Isaac.GetItemIdByName('Twisted R Key');p:AddCollectible(id,0,false);p:UseActiveItem(id,UseFlag.USE_NOANIM,0);phase='reset';tick=0 end
 elseif phase=='reset' and tick==120 then local a=snap(p);check('actual key resets Cain kit and relocks',a.type==2 and a.stage==1 and a.cycle==1 and a.pending and a.pill>0 and a.card==0 and a.lucky,'stage1 cycle1 pending pill/card0 LuckyFoot',a);phase='done';log('DONE',{reason='save normally then cold Continue same snapshot',actual=a})
 end
end)

TwistedRKey:AddCallback(ModCallbacks.MC_USE_PILL,function(_,effect,p,flags)if slot==3 and before and before.cycle==1 then local a=snap(p);a.nativeEffect=effect;check('production render polling consumes exact pending pill after cold Continue',effect==before.effect and not a.pending and a.pill==0 and a.seed==before.seed,'native selected effect; pending false; pocket empty; same seed',a)end end)
