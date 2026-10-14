-- QA ONLY. Append to clean main for a NEW isolated fresh Hard Eve slot3 fixture.
-- No restart, room changes, positioning, boss manipulation, or lifetime-test replay.
local items=require('scripts.custom_items')
local slot,armed,tick,attempts=nil,false,0,0
local updates={}
local function log(label,a) Isaac.DebugString('[BIRD CONTACT QA] '..label..' '..require('json').encode(a)) end
local function birds()return Isaac.FindByType(EntityType.ENTITY_EFFECT,items.birdVariant,-1,false,false)end
local function sample(p)
 local a={tick=tick,room=Game():GetLevel():GetCurrentRoomIndex(),health=p:GetHearts()+p:GetSoulHearts(),cooldown=p:GetDamageCooldown(),rooms=items:State(p).birdRooms,attempts=attempts,friendly=#Isaac.FindByType(EntityType.ENTITY_FAMILIAR,FamiliarVariant.DEAD_BIRD,-1,false,false),birds={}}
 for _,e in ipairs(birds())do a.birds[#a.birds+1]={seed=e.InitSeed,frame=e.FrameCount,updates=updates[e.InitSeed] or 0,x=e.Position.X,y=e.Position.Y,vx=e.Velocity.X,vy=e.Velocity.Y,distance=e.Position:Distance(p.Position),owner=e:GetData().twistedOwner==p,animation=e:GetSprite():GetAnimation(),spriteFrame=e:GetSprite():GetFrame()}end
 return a
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 local p=Isaac.GetPlayer(0)
 armed=slot==3 and not continued and p:GetPlayerType()==PlayerType.PLAYER_EVE and Game().Difficulty==1 and Game():GetNumPlayers()==1
 tick=0;attempts=0;updates={};log('guard',{armed=armed,slot=slot,continued=continued,seed=Game():GetSeeds():GetStartSeedString()})
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE,function(_,e)
 if armed then updates[e.InitSeed]=(updates[e.InitSeed] or 0)+1 end
end,items.birdVariant)
TwistedRKey:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,function(_,e,amount,flags,source)
 if not armed or not e:ToPlayer() or not source or not source.Entity then return end
 local b=source.Entity
 local isBird=b.Type==EntityType.ENTITY_EFFECT and b.Variant==items.birdVariant
 if isBird then attempts=attempts+1 end
 log('damage-attempt',{bird=isBird,sourceType=b.Type,sourceVariant=b.Variant,amount=amount,flags=flags,frame=b.FrameCount,before=sample(e:ToPlayer())})
end,EntityType.ENTITY_PLAYER)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not armed then return end;tick=tick+1;local p=Isaac.GetPlayer(0)
 if tick==30 then
  -- A single new contact fixture trigger. Do not clear cooldown again or pin/move birds.
  if not p:HasCollectible(items.ids.bird) or p:GetHearts()+p:GetSoulHearts()<3 then log('STOP',{reason='custom item absent or insufficient health'});armed=false;return end
  log('before-trigger',sample(p));p:SetMinDamageCooldown(0);p:TakeDamage(1,DamageFlag.DAMAGE_RED_HEARTS,EntityRef(p),0)
 end
 if tick>=30 and tick%10==0 then log('sample',sample(p))end
 if tick==270 then log('DONE',{scope='contact/update/cooldown/familiar telemetry only; not lifetime/Continue/reset acceptance'});armed=false end
end)
