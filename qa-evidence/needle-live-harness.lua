-- QA ONLY: append to main.lua in a backed-up isolated test install. Never ship.
-- Console: lua TRKNeedleQA('start'); then manual continue/natural commands below.
-- No automatic exit, save-slot switching, audio edits, or claimed natural transitions.
local qa, qaPassed, qaFailed
local function qaSnapshot()
    local p = Isaac.GetPlayer(0)
    return {damage=p.Damage, red=p:GetHearts(), counter=p:GetBloodLustCounter(),
        gain=CustomItems:State(p).needleGain or 0, stage=Game():GetLevel():GetStage(),
        cycle=BossTracker.data._twistedCycles or 0, kind=p:GetPlayerType()}
end
local function qaLog(label, expected, passed, actual)
    if passed ~= nil then
        if passed then qaPassed=qaPassed+1 else qaFailed=qaFailed+1 end
    end
    Isaac.DebugString('[NEEDLE QA] '..require('json').encode({label=label,
        expected=expected,result=passed==nil and 'OBSERVED' or (passed and 'PASS' or 'FAIL'),
        actual=actual or qaSnapshot()}))
end
local function qaHit(label)
    local p=Isaac.GetPlayer(0)
    p:AddHearts(12); p:ResetDamageCooldown()
    qa.before=qaSnapshot(); qa.hitLabel=label
    qa.damageAccepted=p:TakeDamage(1,0,EntityRef(p),0)
end
local function qaHitResult()
    local now=qaSnapshot()
    qaLog(qa.hitLabel,'red health decreases; damage decreases; needle gain increases',
        now.red<qa.before.red and now.damage<qa.before.damage and now.gain>qa.before.gain,
        {before=qa.before,after=now,damageAccepted=qa.damageAccepted})
end
function TRKNeedleQA(mode)
    qaPassed,qaFailed=qaPassed or 0,qaFailed or 0
    local p=Isaac.GetPlayer(0)
    if mode=='start' then
        qaPassed,qaFailed=0,0
        qa={tick=0}
        Isaac.ExecuteCommand('restart 6')
    elseif mode=='save-continue' then
        -- After automatic DONE: quit normally to menu, then Continue; do NOT restart.
        BossTracker.data._needleQA=qaSnapshot(); BossTracker:Save()
        qaLog('continue checkpoint','quit normally, Continue, then TRKNeedleQA("resume")')
    elseif mode=='resume' then
        local before=BossTracker.data._needleQA
        local now=qaSnapshot()
        qaLog('continued state','same stage/cycle/kind/gain and damage',before~=nil and
            before.stage==now.stage and before.cycle==now.cycle and before.kind==now.kind and
            math.abs(before.gain-now.gain)<0.00001 and math.abs(before.damage-now.damage)<0.00001,
            {before=before,after=now})
        BossTracker.data._needleQA=nil; BossTracker:Save()
        qa={tick=0,resume=true}
    elseif mode=='natural-before' then
        qa={natural=qaSnapshot()}
        qaLog('natural transition checkpoint','take an ordinary trapdoor, then natural-after')
    elseif mode=='natural-after' then
        local before=qa and qa.natural
        local now=qaSnapshot()
        qaLog('natural floor reset','stage changes and penalty clears',before~=nil and
            before.stage~=now.stage and now.gain==0,{before=before,after=now})
        qa={tick=0,resume=true}
    elseif mode=='clear' then
        qa=nil; BossTracker.data._needleQA=nil; BossTracker:Save()
    else
        print('TRKNeedleQA: start / save-continue / resume / natural-before / natural-after / clear')
    end
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
    if not qa or not qa.tick then return end
    qa.tick=qa.tick+1
    local t=qa.tick
    local p=Isaac.GetPlayer(0)
    if qa.resume then
        if t==30 then qaHit('post-continue/natural hit')
        elseif t==40 then qaHitResult();qaLog('DONE','manual continuation segment finished',nil,
            {passed=qaPassed,failed=qaFailed});qa=nil end
        return
    end
    if t==20 then
        local id=Isaac.GetItemIdByName('Panic Needle')
        qaLog('runtime prerequisites','REPENTOGON counter API and named Panic Needle on Samson',
            REPENTOGON~=nil and p.GetBloodLustCounter~=nil and id>0 and p:HasCollectible(id)
            and p:GetPlayerType()==PlayerType.PLAYER_SAMSON)
    elseif t==30 then qaHit('floor-one hit')
    elseif t==40 then qaHitResult()
    elseif t==60 then qaHit('healed floor-one hit')
    elseif t==70 then qaHitResult();qa.upBefore=p.Damage;p:AddCollectible(CollectibleType.COLLECTIBLE_PENTAGRAM)
    elseif t==80 then qaLog('ordinary damage-up','Pentagram raises damage',p.Damage>qa.upBefore,
        {before=qa.upBefore,after=p.Damage})
    elseif t==100 then Isaac.ExecuteCommand('stage 2')
    elseif t==140 then qaLog('floor-two reset','stage=2 and gain=0',qaSnapshot().stage==2 and qaSnapshot().gain==0)
    elseif t==150 then qaHit('floor-two hit')
    elseif t==160 then qaHitResult()
    elseif t==220 then Isaac.ExecuteCommand('stage 3')
    elseif t==260 then qaLog('floor-three reset','stage=3 and gain=0',qaSnapshot().stage==3 and qaSnapshot().gain==0)
    elseif t==270 then qaHit('floor-three hit')
    elseif t==280 then qaHitResult()
    elseif t==300 then
        qa.cycle=BossTracker.data._twistedCycles or 0
        local id=Isaac.GetItemIdByName('Twisted R Key')
        qaLog('key ID','custom ID resolved by name',id>0,{id=id})
        if id>0 then p:AddCollectible(id);p:UseActiveItem(id,UseFlag.USE_NOANIM) end
    elseif t==350 then
        local s=qaSnapshot()
        qaLog('Twisted reset','Basement I, incremented cycle, zero penalty, Pentagram stripped',
            s.stage==1 and s.cycle==qa.cycle+1 and s.gain==0 and
            not p:HasCollectible(CollectibleType.COLLECTIBLE_PENTAGRAM))
    elseif t==360 then qaHit('post-Twisted hit')
    elseif t==370 then qaHitResult()
    elseif t==390 then
        local id=CollectibleType.COLLECTIBLE_CLICKER
        qa.kind=p:GetPlayerType();p:AddCollectible(id)
        p:UseActiveItem(id,UseFlag.USE_NOANIM)
        qa.pickup=Isaac.Spawn(EntityType.ENTITY_PICKUP,PickupVariant.PICKUP_COLLECTIBLE,id,p.Position,Vector.Zero,nil):ToPickup()
    elseif t==410 then
        qaLog('Clicker grant/use','not held and character unchanged',
            not p:HasCollectible(CollectibleType.COLLECTIBLE_CLICKER) and p:GetPlayerType()==qa.kind)
        qaLog('Clicker spawned pedestal','replaced with Breakfast',qa.pickup and qa.pickup:Exists()
            and qa.pickup.SubType==CollectibleType.COLLECTIBLE_BREAKFAST,
            {subtype=qa.pickup and qa.pickup.SubType})
        if qa.pickup and qa.pickup:Exists() then qa.pickup:Remove() end
        qaLog('DONE','automated debug-warp segment finished; natural/continue/pool RNG coverage still separate',nil,
            {passed=qaPassed,failed=qaFailed});qa=nil
    end
end)
