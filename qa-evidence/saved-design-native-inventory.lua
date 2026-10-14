-- QA ONLY: scripted native inventory API acceptance, NOT organic character runs.
local qa=RegisterMod('SavedDesignInventoryQA',1)
local slot,armed,tick=nil,false,0
local function log(label,a)Isaac.DebugString('[SAVED DESIGN QA] '..label..' '..require('json').encode(a))end
qa:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD,function(_,_,selected,raw)if selected then slot=raw end end)
qa:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function(_,continued)
 tick=0;armed=slot==3 and not continued and Game().Difficulty==1 and Game():GetNumPlayers()==1
 log('guard',{armed=armed,slot=slot,continued=continued,type=Isaac.GetPlayer(0):GetPlayerType(),seed=Game():GetSeeds():GetStartSeedString()})
end)
local cases={
 {name='Blue Baby',kind=PlayerType.PLAYER_BLUEBABY,ids={725,358,378,675}},
 {name='Eden',kind=PlayerType.PLAYER_EDEN,ids={697,240}},
 {name='Bethany',kind=PlayerType.PLAYER_BETHANY,ids={569}},
 {name='Tainted Lost',kind=PlayerType.PLAYER_THELOST_B,ids={431,75,619}},
 {name='Tainted Eden',kind=PlayerType.PLAYER_EDEN_B,ids={721}},
}
qa:AddCallback(ModCallbacks.MC_POST_UPDATE,function()
 if not armed then return end;tick=tick+1
 if tick%60~=30 then return end
 local i=math.floor(tick/60)+1;local c=cases[i];local p=Isaac.GetPlayer(0)
 if not c then armed=false;log('DONE',{cases=#cases,dead=p:IsDead(),tick=tick});return end
 p:SetMinDamageCooldown(600)
 -- Engine type change and real inventory; production saved-design wrapper called.
 p:ChangePlayerType(c.kind)
 local size=Isaac.GetItemConfig():GetCollectibles().Size
 for id=1,size-1 do for n=1,p:GetCollectibleNum(id,true) do p:RemoveCollectible(id) end end
 local setups=require('scripts.character_setups');setups.ApplySetup(p)
 local first,second={},{};local pass=p:GetPlayerType()==c.kind and not p:IsDead()
 for _,id in ipairs(c.ids)do first[tostring(id)]=p:GetCollectibleNum(id,true);pass=pass and first[tostring(id)]==1 end
 setups.ApplySetup(p)
 for _,id in ipairs(c.ids)do second[tostring(id)]=p:GetCollectibleNum(id,true);pass=pass and second[tostring(id)]==1 end
 log('inventory',{name=c.name,pass=pass,type=p:GetPlayerType(),expected=c.kind,first=first,second=second,dead=p:IsDead(),tick=tick})
 if not pass then armed=false;log('STOP',{case=c.name});end
end)
