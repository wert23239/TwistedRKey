-- QA ONLY read-only current native descriptors and route flags.
local g=Game();local l=g:GetLevel();local rooms={};local list=l:GetRooms()
for i=0,list.Size-1 do local d=list:Get(i);rooms[#rooms+1]={index=d.SafeGridIndex,valid=d.Data~=nil,name=d.Data and d.Data.Name,type=d.Data and d.Data.Type,variant=d.Data and d.Data.Variant}end
local flags={}
for k,v in pairs(GameStateFlag)do if type(v)=='number' then flags[k]=g:GetStateFlag(v)end end
Isaac.DebugString('[ASCENT ROOMS] '..require('json').encode({stage=l:GetStage(),stageType=l:GetStageType(),room=l:GetCurrentRoomIndex(),seed=g:GetSeeds():GetStartSeedString(),rooms=rooms,flags=flags,note=Isaac.GetPlayer(0):HasCollectible(668)}))
