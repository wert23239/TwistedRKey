-- Twisted run-chain checks beside the existing PAUSE note; never vanilla save marks.
local Overlay = {}
Overlay.marks = {
    { id = 'moms_heart', alt = 'it_lives', x = -25, y = -19 },
    { id = 'isaac_boss', x = -7, y = -25 },
    { id = 'satan', x = 10, y = -19 },
    { id = 'blue_baby', x = -25, y = -3 },
    { id = 'the_lamb', x = 10, y = -3 },
    { id = 'mega_satan', x = -7, y = 14 },
    { id = 'hush', x = -25, y = 14 },
    { id = 'mother', x = 10, y = 14 },
    { id = 'the_beast', x = 25, y = 14 },
    { id = 'delirium', x = 25, y = -20 },
    { id = 'boss_rush', x = -7, y = -3 },
}

local LAYERS = {moms_heart=1, isaac_boss=2, satan=3, boss_rush=4, blue_baby=5,
    the_lamb=6, mega_satan=7, hush=9, mother=10, the_beast=11}

function Overlay:RenderAt(pos, scale, playerType, sprite)
    local marks = self.tracker:GetCharacterMarks(playerType)
    local count = 0
    self.check.Scale = scale
    for _, mark in ipairs(self.marks) do
        if marks[mark.id] or (mark.alt and marks[mark.alt]) then
            local offset = Vector(mark.x, mark.y)
            if sprite and sprite.GetLayerFrameData and LAYERS[mark.id] then
                -- Baked ANM2 frame position/pivot locate the real native icon.
                local frame = sprite:GetLayerFrameData(LAYERS[mark.id])
                offset = frame:GetPos() + sprite:GetLayer(LAYERS[mark.id]):GetPos()
                    + Vector(frame:GetWidth() - frame:GetPivot().X + 2, -3)
            elseif sprite and sprite.GetLayerFrameData and mark.id == 'delirium' then
                local paper = sprite:GetLayerFrameData(0)
                offset = paper:GetPos() + Vector(-paper:GetPivot().X - 6, -paper:GetPivot().Y + 6)
            end
            self.check:Render(pos + Vector(offset.X * scale.X, offset.Y * scale.Y))
            count = count + 1
        end
    end
    if count == #self.marks then
        self.check.Scale = scale * 2
        self.check:Render(pos + Vector(39 * scale.X, 0))
    end
end

function Overlay:Init(mod, tracker)
    self.tracker = tracker
    self.check = Sprite()
    self.check:Load('gfx/ui/twisted_check.anm2', true)
    self.check:Play('Idle', true)
    -- Permanent menu badge is distinct from temporary pause checks.
    if ModCallbacks.MC_POST_COMPLETION_MARKS_RENDER then
        mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARKS_RENDER, function(_, _, pos, scale, playerType)
            local badge = (tracker.data._completedChains or {})[tostring(tracker:CanonicalType(playerType))]
            if not badge then return end
            -- MenuManager throws during gameplay; the widget hook also runs
            -- on pause. Capability-check the menu context without a Lua error.
            local inMenu, activeMenu = pcall(MenuManager.GetActiveMenu)
            if inMenu and activeMenu == MainMenuType.CHARACTER then
                self.check.Scale = scale * 2
                self.check:Render(pos + Vector(42 * scale.X, 0))
            end
        end)
    end
    -- Vanilla pause rendering works without installing another runtime.
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not Game():IsPaused() or Game():GetNumPlayers() == 0 then return end
        if self.nativePauseRender then return end
        local p = Isaac.GetPlayer(0)
        local pos = Vector(Isaac.GetScreenWidth() / 2 + 110, 48)
        self:RenderAt(pos, Vector(1, 1), p:GetPlayerType())
    end)
    -- RGON supplies the exact note origin/scale; use it if present, only while playing.
    if ModCallbacks.MC_POST_COMPLETION_MARKS_RENDER then
        self.nativePauseRender = true
        mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARKS_RENDER, function(_, sprite, pos, scale, playerType)
            if Game():GetNumPlayers() > 0 and Game():IsPaused() then
                self:RenderAt(pos, scale, playerType, sprite)
            end
        end)
    end
end
return Overlay
