-- QA ONLY read-only actual current-room geometry; no game/save mutations.
local g=Game();local r=g:GetRoom();local l=g:GetLevel();local p=Isaac.GetPlayer(0);local doors,grids,entities={},{},{}
for i=0,7 do local d=r:GetDoor(i);if d then doors[#doors+1]={slot=i,target=d.TargetRoomIndex,x=d.Position.X,y=d.Position.Y,open=d:IsOpen()}end end
for i=0,r:GetGridSize()-1 do local d=r:GetGridEntity(i);if d then grids[#grids+1]={index=i,type=d:GetType(),x=d.Position.X,y=d.Position.Y,state=d.State}end end
for _,e in ipairs(Isaac.GetRoomEntities())do entities[#entities+1]={type=e.Type,variant=e.Variant,subtype=e.SubType,x=e.Position.X,y=e.Position.Y,animation=e:GetSprite():GetAnimation()}end
Isaac.DebugString('[NATIVE ROUTE] '..require('json').encode({room=l:GetCurrentRoomIndex(),stage=l:GetStage(),stageType=l:GetStageType(),x=p.Position.X,y=p.Position.Y,red=p:GetHearts(),doors=doors,grids=grids,entities=entities,ascent=g:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH),init=g:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH_INIT)}))
