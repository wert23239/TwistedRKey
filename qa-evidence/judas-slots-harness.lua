-- QA ONLY: slot3, Hard Judas; native collisions and external Ctrl, never fake input.
local slot,phase,tick,pick,before=nil,'boot',0,nil,nil
local function snap(p)return {seed=Game():GetSeeds():GetStartSeedString(),type=p:GetPlayerType(),hard=Game().Difficulty,t0=p:GetTrinket(0),t1=p:GetTrinket(1),c0=p:GetCard(0),c1=p:GetCard(1),purple=p:HasTrinket(5),purse=p:HasCollectible(139),book=p:HasCollectible(34),cycle=BossTracker.data._twistedCycles or 0,stage=Game():GetLevel():GetStage()}end
local function log(l,a)Isaac.DebugString('[JUDAS SLOTS QA] '..l..' '..require('json').encode(a))end
local function check(l,ok,e,a)log('ASSERT',{label=l,result=ok and 'PASS' or 'FAIL',expected=e,actual=a})end
local function spawn(p,id)pick=Isaac.Spawn(5,350,id,p.Position,Vector.Zero,nil):ToPickup();pick.Wait=0 end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw;log('slot',{slot=raw})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 if slot~=3 then phase='done';log('STOP',{reason='slot not 3'});return end
 if continued then phase='continue';tick=0 elseif phase~='init' then phase='boot';tick=0 else tick=0 end
end)
TwistedRKey:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION,function(_,pickup,collider)if slot==3 and pick and pickup.InitSeed==pick.InitSeed then log('native-collision',{phase=phase,id=pickup.SubType,player=collider:ToPlayer()~=nil})end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if slot~=3 or phase=='done' then return end;tick=tick+1;local p=Isaac.GetPlayer(0)
 if pick and pick:Exists() and (phase=='second' or phase=='third') then pick.Position=p.Position;pick.Velocity=Vector.Zero end
 if phase=='boot' and tick==10 then
  if Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then phase='done';log('STOP',{reason='not Hard single player'});return end
  phase='init';tick=0;Isaac.ExecuteCommand('restart 3')
 elseif phase=='init' and tick==60 then local a=snap(p);check('Judas starting real two-slot kit',a.type==3 and a.purple and a.purse and a.book and ((a.t0==5 and a.t1==0) or (a.t1==5 and a.t0==0)),'Purple Heart single slot, Moms Purse, Book',a);spawn(p,1);phase='second';tick=0
 elseif phase=='second' and tick==90 then local a=snap(p);a.exists=pick and pick:Exists();check('native second trinket pickup allowed',not a.exists and a.purple and (a.t0==1 or a.t1==1),'real Swallowed Penny in spare slot',a);before=a;spawn(p,2);phase='third';tick=0
 elseif phase=='third' and tick==90 then local a=snap(p);a.exists=pick and pick:Exists();check('native third trinket cannot replace Purple Heart',a.exists and a.t0==before.t0 and a.t1==before.t1,'third trinket remains, both slots unchanged',a);if pick and pick:Exists()then pick:Remove()end
  p:AddCollectible(CollectibleType.COLLECTIBLE_POLYDACTYLY,0,false);p:SetCard(0,Card.CARD_FOOL);p:SetCard(1,Card.CARD_MAGICIAN);before=snap(p);phase='tap';tick=0;log('READY',{action='external short Ctrl tap',actual=before})
 elseif phase=='tap' then local a=snap(p);if a.c0==before.c1 and a.c1==before.c0 then check('external short Ctrl cycles actual card slots',a.purple and a.t0==before.t0 and a.t1==before.t1,'cards swap while real trinkets stay',a);phase='release';tick=0 end
 elseif phase=='release' and tick>60 and not Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0) then local id=Isaac.GetItemIdByName('Twisted R Key');p:AddCollectible(id,0,false);p:UseActiveItem(id,UseFlag.USE_NOANIM,0);phase='reset';tick=0
 elseif phase=='reset' and tick==120 then local a=snap(p);check('actual key restores Judas kit',a.type==3 and a.stage==1 and a.cycle==1 and a.purse and a.book and a.purple and a.c0==0 and a.c1==0 and ((a.t0==5 and a.t1==0)or(a.t1==5 and a.t0==0)),'cycle1 starting kit, Purple Heart only, no cards',a);phase='done';log('DONE',{reason='normal save then cold Continue',actual=a})
 elseif phase=='continue' and tick==60 then local a=snap(p);check('cold Continue retains Judas reset kit',a.type==3 and a.hard==1 and a.stage==1 and a.cycle==1 and a.purse and a.book and a.purple and ((a.t0==5 and a.t1==0)or(a.t1==5 and a.t0==0)),'compare SAME seed with saved cycle1 kit',a);phase='done';log('DONE',{reason='read-only Continue snapshot'})end
 if tick%300==0 then log('WAIT',{phase=phase,tick=tick,actual=snap(p)})end
end)
