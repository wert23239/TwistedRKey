-- QA ONLY: engine health edge cases, not organic room-clear/input coverage.
-- Append in main.lua scope; guarded selected slot3, fresh Hard single player.
local slot,boot,tick,armed,done=nil,0,0,false,false
local function tr(label,a) Isaac.DebugString('[HEALTH QA] '..label..' '..require('json').encode(a)) end
local function report(label,ok,expected,a) tr('ASSERT',{label=label,result=ok and 'PASS' or 'FAIL',expected=expected,actual=a}) end
local function health(p) return {red=p:GetHearts(),rotten=p:GetRottenHearts(),soul=p:GetSoulHearts(),black=p:GetBlackHearts(),max=p:GetMaxHearts()} end
local function clear(p)
 p:AddHearts(-p:GetHearts());p:AddSoulHearts(-p:GetSoulHearts());p:AddMaxHearts(-p:GetMaxHearts())
end
TwistedRKey:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw) if selected then slot=raw;tr('slot',{slot=raw}) end end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 tr('start',{continued=continued,type=Isaac.GetPlayer(0):GetPlayerType(),difficulty=Game().Difficulty,seed=Game():GetSeeds():GetStartSeedString()})
end)
TwistedRKey:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if done or slot~=3 then return end
 if not armed then boot=boot+1;if boot==10 then armed=true;tick=-30;Isaac.ExecuteCommand('restart 1')end;return end
 tick=tick+1;local p=Isaac.GetPlayer(0)
 if tick==0 then
  if p:GetPlayerType()~=1 or Game().Difficulty~=1 or Game():GetNumPlayers()~=1 then done=true;tr('STOP',{reason='invalid Hard Maggy fixture'});return end
  report('Maggy engine starting kit',p:HasCollectible(45) and p:GetActiveItem(2)==639,'Yum Heart and pocket Yuck Heart',{yum=p:HasCollectible(45),pocket=p:GetActiveItem(2)})
  local cases={
   {name='normal red preserves soul',max=8,red=8,soul=4,expect={red=8,rotten=1,soul=4,max=8}},
   {name='existing rotten preserved',max=8,red=6,rotten=2,soul=4,expect={red=8,rotten=2,soul=4,max=8}},
   {name='half red converts once',max=2,red=1,soul=2,expect={red=2,rotten=1,soul=2,max=2}},
   {name='half soul exchanges capacity',max=0,red=0,soul=1,expect={red=2,rotten=1,soul=0,max=2}},
   {name='black exchanges without damage',max=0,red=0,black=2,expect={red=2,rotten=1,soul=0,max=2}},
   {name='all rotten does not heal',max=4,red=0,rotten=4,expect={red=4,rotten=2,soul=0,max=4},noConvert=true},
  }
  for _,c in ipairs(cases) do
   clear(p);p:AddMaxHearts(c.max);p:AddHearts(c.red)
   if c.rotten then p:AddRottenHearts(c.rotten) end
   if c.soul then p:AddSoulHearts(c.soul) end
   if c.black then p:AddBlackHearts(c.black) end
   local before=health(p);local converted=CharacterMechanics:ConvertHeart(p);local after=health(p)
   local ok=converted==(not c.noConvert)
   for k,v in pairs(c.expect)do ok=ok and after[k]==v end
   report(c.name,ok,c.expect,{before=before,after=after,converted=converted})
  end
  clear(p);p:AddMaxHearts(8);p:AddHearts(8)
 elseif tick==30 then Isaac.ExecuteCommand('restart 2')
 elseif tick==60 then
  local s=CharacterMechanics:State(p)
  report('Cain actual starting pill lock',p:GetPlayerType()==2 and p:HasCollectible(46) and s.pending==true and p:GetPill(0)==s.color,'Lucky Foot; pending negative pill',{type=p:GetPlayerType(),lucky=p:HasCollectible(46),pending=s.pending,pill=p:GetPill(0),effect=s.effect,color=s.color})
  Isaac.ExecuteCommand('stage 2')
 elseif tick==90 then
  local s=CharacterMechanics:State(p)
  report('Cain engine floor-two lock',Game():GetLevel():GetStage()==2 and s.pending==true and p:GetPill(0)==s.color,'stage2 pending negative pill',{stage=Game():GetLevel():GetStage(),pending=s.pending,pill=p:GetPill(0),effect=s.effect})
  Isaac.ExecuteCommand('restart 3')
 elseif tick==120 then
  report('Judas actual starting kit',p:GetPlayerType()==3 and p:HasCollectible(34) and p:HasCollectible(139) and p:HasTrinket(5),'Belial, Moms Purse, real Purple Heart',{type=p:GetPlayerType(),belial=p:HasCollectible(34),purse=p:HasCollectible(139),purple=p:HasTrinket(5),trinket0=p:GetTrinket(0),trinket1=p:GetTrinket(1)})
  done=true;tr('DONE',{reason='engine health API cases and starting kits; no synthetic room clears; no raw input certification'})
 end
end)
